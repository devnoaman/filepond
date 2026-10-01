// The deprecated `uploading` flag is still written so it keeps mirroring
// `status == FilepondFileStatus.uploading` for existing consumers.
// ignore_for_file: deprecated_member_use_from_same_package

part of 'controller.dart';

/// FilepondController manages file selection, upload, and state updates for
/// the Filepond widget.
///
/// Every file in [files] carries an explicit [FilepondFile.status]:
/// `pending → uploading → uploaded | failed`. Read the controller-level
/// getters ([isSettled], [hasFailed], [isUploading]) to decide whether a form
/// can be submitted, and listen to the controller (it is a [ChangeNotifier])
/// or [filesListenable] to rebuild on status changes.
///
/// Example:
/// ```dart
/// final controller = FilepondController(baseUrl: 'https://api.example.com/upload');
/// await controller.attachFile();          // pick + add (+ upload if uploadDirectly)
/// await controller.uploadAll();           // pending and failed files
/// if (controller.hasFailed) await controller.retryAllFailed();
/// final canSubmit = controller.isSettled;
/// controller.dispose();                   // cancels in-flight uploads
/// ```
class FilepondController extends ChangeNotifier with UploadProgressMixin {
  /// Creates a [FilepondController].
  ///
  /// [baseUrl] is required and should point to your upload endpoint.
  /// [pondLocation] is the '/'-separated path to the pond id inside a JSON
  /// object response (default: 'filepond'). A plain string response is used
  /// as the pond id directly; an empty [pondLocation] stores the whole JSON
  /// response, encoded as a string.
  FilepondController({
    required this.baseUrl,
    this.pondLocation = 'filepond',
    this.maxLength,
    this.sourceType = SourceType.camera,
    this.uploadDirectly = false,
    this.allowEdit = false,
    this.dioClient,
    this.uploadName = 'files',
    this.initialFiles,
    this.onFilesChange,
    this.allowedExtensions = const ['pdf', 'jpg', 'png', 'jpeg'],
  }) {
    files = (initialFiles ?? const <FilepondFile>[])
        .map(_normalizeIncoming)
        .toList();
  }

  /// List of files managed by this controller.
  ///
  /// Prefer the controller methods ([addFile], [removeFile], [updateFile]) to
  /// mutate it, so listeners and [operationsStream] stay in sync.
  var files = <FilepondFile>[];

  /// The URL to which files will be uploaded.
  final String baseUrl;

  /// Path in a JSON object response to the uploaded file's pond id.
  final String pondLocation;
  final bool allowEdit;
  AttachingNotifier notifier = AttachingNotifier();

  final List<FilepondFile>? initialFiles;

  /// Called with [files] after every change to the list, including status
  /// changes (uploading, uploaded, failed) and removals.
  ValueChanged<List<FilepondFile>>? onFilesChange;

  bool? uploadDirectly;

  /// Multipart field name used for the uploaded file.
  final String uploadName;

  /// Maximum number of files; `null` means no limit.
  int? maxLength;
  SourceType? sourceType;

  /// Extensions accepted by the [SourceType.files] picker.
  final List<String> allowedExtensions;

  /// Dio client used for uploads. The controller never mutates it.
  final Dio? dioClient;

  final _operationsController = StreamController<FilepondOperation>.broadcast();
  final Map<String, CancelToken> _cancelTokens = {};
  late final ValueNotifier<List<FilepondFile>> _filesNotifier = ValueNotifier(
    List.unmodifiable(files),
  );
  Dio? _ownDio;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // State getters
  // ---------------------------------------------------------------------------

  /// Stream of file operations (insert, uploading, uploaded, failed, ...).
  Stream<FilepondOperation> get operationsStream =>
      _operationsController.stream;

  /// Rebuild-friendly view of [files]; a new unmodifiable list is published on
  /// every change (including status changes).
  ValueListenable<List<FilepondFile>> get filesListenable => _filesNotifier;

  /// True if there is at least one file and all files have a pond id.
  ///
  /// This is `false` for an empty list. To decide whether a form can be
  /// submitted, use [isSettled] instead.
  bool get allUploaded =>
      files.isNotEmpty && files.every((f) => f.filepond != null);

  /// True when at least one file failed to upload.
  bool get hasFailed => files.any((f) => f.isFailed);

  /// True while any file is waiting for, or in the middle of, an upload.
  bool get isUploading => files.any((f) => f.isUploading || f.isPending);

  /// True when every picked file is uploaded (also true when there are no
  /// files). This is the "can submit" check.
  bool get isSettled => files.every((f) => f.isUploaded);

  /// Files whose last upload attempt failed.
  List<FilepondFile> get failedFiles =>
      files.where((f) => f.isFailed).toList(growable: false);

  /// Whether the controller was disposed.
  bool get isDisposed => _disposed;

  bool get _isFull => maxLength != null && files.length >= maxLength!;

  Dio get _dio =>
      dioClient ??
      (_ownDio ??= (Dio()
        ..interceptors.add(
          LogInterceptor(
            logPrint: (Object? message) =>
                Logger.warn(message: message.toString()),
          ),
        )));

  // ---------------------------------------------------------------------------
  // Adding / updating / removing
  // ---------------------------------------------------------------------------

  /// Adds an already-built [file] to the controller.
  ///
  /// Emits [FilepondOperation.insert] and calls [onFilesChange]. Returns
  /// `false` (and adds nothing) when [maxLength] is reached or, with
  /// [checkDuplicates], when a file with the same name or the same bytes is
  /// already in the list (a [FilepondOperation.dublicate] is emitted).
  /// Starts the upload when [uploadDirectly] is true.
  bool addFile(FilepondFile file, {bool checkDuplicates = true}) {
    if (_disposed || _isFull) return false;

    if (checkDuplicates) {
      final existing = _indexOfDuplicate(file);
      if (existing != -1) {
        _emit(FilepondOperation.dublicate(file, existing, 'Duplicate file'));
        return false;
      }
    }

    final added = _normalizeIncoming(file);
    files.add(added);
    final index = files.length - 1;
    _emit(FilepondOperation.insert(added, index));
    _notifyFilesChanged();

    if (uploadDirectly == true) unawaited(uploadFile(added));
    return true;
  }

  /// Replaces [oldFile] (matched by id) with [newFile], e.g. after editing an
  /// image. A replacement without a pond id starts as `pending`.
  ///
  /// Emits [FilepondOperation.update] on success.
  void updateFile(FilepondFile oldFile, FilepondFile newFile) {
    final i = _indexOfId(oldFile.id);

    if (i == -1) {
      _emit(
        FilepondOperation.failed(oldFile, i, 'File not found in the list!'),
      );
      return;
    }

    _cancelUpload(oldFile.id, 'File replaced');
    if (oldFile.id != newFile.id) _clearProgress(files[i]);
    final replacement = _normalizeIncoming(newFile);
    files[i] = replacement;
    _emit(FilepondOperation.update(oldFile, replacement));
    _notifyFilesChanged();
  }

  /// Removes [file] (matched by id), cancelling its upload if one is in
  /// flight. A cancelled upload emits neither `uploaded` nor `failed`.
  ///
  /// Emits [FilepondOperation.remove] and calls [onFilesChange].
  void removeFile(FilepondFile file) {
    final index = _indexOfId(file.id);
    if (index == -1) {
      _emit(FilepondOperation.failed(file, index, 'File not found in the list!'));
      return;
    }

    final removed = files.removeAt(index);
    _cancelUpload(removed.id, 'File removed');
    _clearProgress(removed);
    _emit(FilepondOperation.remove(removed, index));
    _notifyFilesChanged();
  }

  // ---------------------------------------------------------------------------
  // Picking
  // ---------------------------------------------------------------------------

  /// Prompts the user to pick a file from [sourceType] and adds it to [files].
  ///
  /// Emits [FilepondOperation.insert] on success. Does nothing when the user
  /// cancels the picker or [maxLength] is reached.
  Future<void> attachFile() async {
    if (_disposed || _isFull) return;

    try {
      switch (sourceType) {
        case SourceType.files:
          await _attachFromFilePicker();
        case SourceType.gallery:
          await _attachFromImagePicker(ImageSource.gallery);
        case SourceType.camera:
          await _attachFromImagePicker(ImageSource.camera);
        case SourceType.ask:
        case null:
          Logger.warn(message: 'attachFile: source type $sourceType is not supported');
      }
    } catch (e, stackTrace) {
      Logger(logPrefix: '⚠️ Ponding warning').emmit('attachFile failed: $e', stackTrace);
    } finally {
      notifier.attached();
    }
  }

  Future<void> _attachFromFilePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final picked = result?.files ?? const <PlatformFile>[];
    final path = picked.isEmpty ? null : picked.first.path;
    if (path == null) return; // user cancelled

    notifier.attaching();
    final file = File(path);
    addFile(
      FilepondFile(
        id: file.path,
        file: await file.readAsBytes(),
        fileName: basename(file.path),
        uploadName: uploadName,
      ),
    );
  }

  Future<void> _attachFromImagePicker(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = source == ImageSource.camera
        ? await picker.pickImage(
            source: source,
            preferredCameraDevice: CameraDevice.rear,
            imageQuality: 80,
          )
        : await picker.pickImage(source: source);
    if (picked == null) return; // user cancelled

    notifier.attaching();
    // Camera files always get a unique name, so they skip the duplicate check.
    await attachFileToController(
      File(picked.path),
      checkDuplicates: source != ImageSource.camera,
    );
  }

  /// Compresses [originalFile] (JPEG, in an isolate) and adds it via
  /// [addFile]. Returns the index and file that were added, or
  /// `(null, null)` when compression failed or the file was rejected.
  Future<(int?, FilepondFile?)> attachFileToController(
    File originalFile, {
    bool checkDuplicates = true,
  }) async {
    final file = await compressImageFileWithIsolate(originalFile, quality: 60);
    if (file == null) {
      Logger.warn(message: 'failed to compress ${originalFile.path}');
      return (null, null);
    }

    final filepondFile = FilepondFile(
      id: file.path,
      file: await file.readAsBytes(),
      uploadName: uploadName,
      fileName: basename(file.path),
    );
    if (!addFile(filepondFile, checkDuplicates: checkDuplicates)) {
      return (null, null);
    }
    final index = _indexOfId(filepondFile.id);
    return (index, files[index]);
  }

  // ---------------------------------------------------------------------------
  // Uploading
  // ---------------------------------------------------------------------------

  /// Uploads [file] (matched by id) to [baseUrl].
  ///
  /// Status goes `uploading`, then `uploaded` on any 2xx response, or
  /// `failed` (with [FilepondFile.error]) on an exception or non-2xx
  /// response. Every step replaces the file in [files], emits an operation
  /// and calls [onFilesChange]. If the file is removed while uploading, the
  /// result is dropped and nothing is emitted. Does nothing if the file is
  /// already uploading.
  Future<void> uploadFile(FilepondFile file) async {
    if (_disposed) return;

    final startIndex = _indexOfId(file.id);
    if (startIndex == -1) {
      _emit(
        FilepondOperation.failed(
          file,
          -1,
          'File not found in the list for upload!',
        ),
      );
      return;
    }
    if (files[startIndex].isUploading) return;

    final uploadingFile = files[startIndex].copyWith(
      status: FilepondFileStatus.uploading,
      uploading: true,
      error: null,
    );
    files[startIndex] = uploadingFile;
    _resetProgress(uploadingFile);
    _emit(FilepondOperation.uploading(uploadingFile, startIndex));
    _notifyFilesChanged();

    final cancelToken = CancelToken();
    _cancelTokens[file.id] = cancelToken;

    Response<dynamic>? response;
    Object? failure;
    try {
      response = await _dio.post<dynamic>(
        baseUrl,
        data: _formDataFor(uploadingFile),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total <= 0 || cancelToken.isCancelled) return;
          _updateProgress(uploadingFile, sent / total);
        },
      );
    } catch (e) {
      failure = e;
    } finally {
      if (identical(_cancelTokens[file.id], cancelToken)) {
        _cancelTokens.remove(file.id);
      }
    }

    // Cancelled (removed, replaced, disposed): it was not a failure.
    if (_disposed || cancelToken.isCancelled) return;

    // Find the file again: the list may have changed while awaiting.
    final index = _indexOfId(file.id);
    if (index == -1) return;
    final current = files[index];

    String? pondId;
    String? errorMessage;
    if (failure != null) {
      errorMessage = _errorMessageFor(failure);
    } else if (!_isSuccessStatus(response?.statusCode)) {
      errorMessage =
          _serverMessage(response?.data) ??
          'Upload failed (HTTP ${response?.statusCode})';
    } else {
      try {
        pondId = _extractPondId(response?.data);
      } catch (e) {
        errorMessage = e.toString();
      }
    }

    if (errorMessage == null) {
      final uploaded = current.copyWith(
        status: FilepondFileStatus.uploaded,
        uploading: false,
        filepond: pondId,
        error: null,
      );
      files[index] = uploaded;
      _updateProgress(uploaded, 1.0);
      _emit(FilepondOperation.uploaded(uploaded, index));
    } else {
      final failed = current.copyWith(
        status: FilepondFileStatus.failed,
        uploading: false,
        error: errorMessage,
      );
      files[index] = failed;
      _emit(FilepondOperation.failed(failed, index, errorMessage));
    }
    _notifyFilesChanged();
  }

  /// Uploads every file whose status is `pending` or `failed`, in parallel.
  /// Files that are already uploading or uploaded are left alone.
  Future<void> uploadAll() async {
    final toUpload = files
        .where((f) => f.status.isUploadable)
        .toList(growable: false);
    if (toUpload.isEmpty) return;
    await Future.wait(toUpload.map(uploadFile));
  }

  /// Retries the upload of [file] (matched by id). Only failed files are
  /// retried; anything else is ignored.
  Future<void> retryUpload(FilepondFile file) async {
    final index = _indexOfId(file.id);
    if (index == -1 || !files[index].isFailed) return;
    await uploadFile(files[index]);
  }

  /// Retries every failed file, in parallel.
  Future<void> retryAllFailed() async {
    final failed = failedFiles;
    if (failed.isEmpty) return;
    await Future.wait(failed.map(uploadFile));
  }

  /// Resolves a nested value from [data] using a '/'-separated [path].
  ///
  /// Throws if the path is invalid.
  dynamic resolveNestedValueOrThrow(Map<String, dynamic> data, String path) {
    final keys = path.split('/');
    dynamic current = data;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        throw FormatException('Invalid path: $path');
      }
    }

    return current;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancels in-flight uploads and closes all streams. A cancelled upload
  /// emits nothing. The controller must not be used afterwards.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final token in _cancelTokens.values) {
      token.cancel('Controller disposed');
    }
    _cancelTokens.clear();
    disposeUploadProgress();
    _operationsController.close();
    _filesNotifier.dispose();
    _ownDio?.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _indexOfId(String id) => files.indexWhere((f) => f.id == id);

  int _indexOfDuplicate(FilepondFile file) => files.indexWhere(
    (f) =>
        (file.fileName != null && f.fileName == file.fileName) ||
        (f.file.lengthInBytes == file.file.lengthInBytes &&
            listEquals(f.file, file.file)),
  );

  /// Files that come in from outside (initial files, [addFile],
  /// [updateFile]) can't be mid-upload, and a file with a pond id is
  /// uploaded even when its status was never set (legacy callers).
  FilepondFile _normalizeIncoming(FilepondFile file) {
    if (file.filepond != null && !file.isUploaded) {
      return file.copyWith(
        status: FilepondFileStatus.uploaded,
        uploading: false,
        error: null,
      );
    }
    if (file.filepond == null && (file.isUploading || file.isUploaded)) {
      return file.copyWith(status: FilepondFileStatus.pending, uploading: false);
    }
    return file;
  }

  void _emit(FilepondOperation operation) {
    if (!_operationsController.isClosed) _operationsController.add(operation);
  }

  void _notifyFilesChanged() {
    if (_disposed) return;
    onFilesChange?.call(files);
    _filesNotifier.value = List.unmodifiable(files);
    notifyListeners();
  }

  void _cancelUpload(String id, String reason) {
    _cancelTokens.remove(id)?.cancel(reason);
  }

  // Progress is published under the id and, for backward compatibility,
  // under the file name as well.
  void _updateProgress(FilepondFile file, double progress) {
    updateUploadProgress(file.id, progress);
    final name = file.fileName;
    if (name != null && name != file.id) updateUploadProgress(name, progress);
  }

  void _resetProgress(FilepondFile file) => _updateProgress(file, 0);

  void _clearProgress(FilepondFile file) {
    clearUploadProgress(file.id);
    final name = file.fileName;
    if (name != null && name != file.id) clearUploadProgress(name);
  }

  FormData _formDataFor(FilepondFile file) => FormData.fromMap({
    uploadName: MultipartFile.fromBytes(file.file, filename: file.fileName),
  }, ListFormat.multi);

  static bool _isSuccessStatus(int? code) =>
      code != null && code >= 200 && code < 300;

  String _extractPondId(dynamic data) {
    if (data is String) return data;
    if (data == null) {
      throw const FormatException('Server returned an empty response');
    }
    if (data is Map<String, dynamic> && pondLocation.isNotEmpty) {
      final value = resolveNestedValueOrThrow(data, pondLocation);
      if (value == null) {
        throw FormatException('No pond id at "$pondLocation"');
      }
      return value is String ? value : jsonEncode(value);
    }
    return jsonEncode(data);
  }

  String _errorMessageFor(Object error) {
    if (error is DioException) {
      return _serverMessage(error.response?.data) ??
          (error.response?.statusCode != null
              ? 'Upload failed (HTTP ${error.response!.statusCode})'
              : error.message ?? error.toString());
    }
    return error.toString();
  }

  /// Best-effort human-readable message from an error response body.
  static String? _serverMessage(dynamic data) {
    if (data is Map) {
      for (final key in const ['message', 'error', 'detail', 'msg']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is Map) {
          final nested = _serverMessage(value);
          if (nested != null) return nested;
        }
      }
      return null;
    }
    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty && text.length <= 300 && !text.startsWith('<')) {
        return text;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // File helpers (unchanged public API)
  // ---------------------------------------------------------------------------

  Future<File> compressAndGetFile(XFile file, String targetPath) async {
    final bytes = await file.readAsBytes();
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 88,
    );

    final name = basename(file.path);
    final compressed = await File('$targetPath/$name').create();
    await compressed.writeAsBytes(result);
    return compressed;
  }

  Future<File> fileFromUint8List(Uint8List data, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(data);
    return file;
  }
}

Future<String> _compressImageFileInBackground(Map<String, dynamic> args) async {
  final String filePath = args['filePath'];
  final String targetPath = args['targetPath'];
  final int quality = args['quality'];
  final originalBytes = await File(filePath).readAsBytes();

  final image = img.decodeImage(originalBytes);
  if (image == null) {
    throw Exception('Failed to decode image file in isolate.');
  }

  final compressedBytes = img.encodeJpg(image, quality: quality);
  await File(targetPath).writeAsBytes(compressedBytes);

  return targetPath;
}

/// Re-encodes [originalFile] as JPEG at [quality] in a background isolate.
/// Returns `null` when the image can't be decoded or written.
Future<File?> compressImageFileWithIsolate(
  File originalFile, {
  int quality = 80,
}) async {
  try {
    final targetPath =
        '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
    final args = <String, dynamic>{
      'filePath': originalFile.absolute.path,
      'targetPath': targetPath,
      'quality': quality,
    };
    final resultPath = await Isolate.run(
      () => _compressImageFileInBackground(args),
    );
    return File(resultPath);
  } catch (e) {
    Logger.warn(message: 'Error compressing image file in isolate: $e');
    return null;
  }
}
