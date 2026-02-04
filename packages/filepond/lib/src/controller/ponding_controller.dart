// ignore_for_file: public_member_api_docs, sort_constructors_first

part of 'controller.dart';

/// FilepondController manages file selection, upload, and state updates for the Filepond widget.
///
/// Usage:
///   - Instantiate with a [baseUrl] for uploads.
///   - Call [attachFile] to prompt the user to pick a file.
///   - Call [uploadFile] to upload a [FilepondFile].
///   - Listen to [operationsStream] for file operation events (insert, uploaded, etc.).
///
/// Example:
/// ```dart
/// final controller = FilepondController(baseUrl: 'http://localhost:3000/upload');
/// controller.attachFile();
/// controller.uploadFile(controller.files.first);
/// controller.operationsStream.listen((op) { ... });
/// ```
class FilepondController with UploadProgressMixin {
  /// List of files managed by this controller.
  var files = <FilepondFile>[];

  /// The base URL to which files will be uploaded.
  final String baseUrl;

  /// The key path in the response data where the uploaded file info is located.
  final String pondLocation;
  final bool allowEdit;
  AttachingNotifier notifier = AttachingNotifier();

  /// Creates a [FilepondController].
  ///
  /// [baseUrl] is required and should point to your upload endpoint.
  /// [pondLocation] is the path in the response JSON to the uploaded file info (default: 'filepond').
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
  }) {
    files = initialFiles?.toList() ?? [];
  }
  final List<FilepondFile>? initialFiles;
  // ValueChanged() onFilesChanges;
  ValueChanged<List<FilepondFile>>? onFilesChange;

  /// Returns true if all files have been uploaded (i.e., have a non-null [filepond] property).
  bool get allUploaded =>
      files.isNotEmpty && files.every((f) => f.filepond != null);
  final _operationsController = StreamController<FilepondOperation>.broadcast();

  /// Stream of file operations (insert, uploaded, etc.) for UI updates.
  Stream<FilepondOperation> get operationsStream =>
      _operationsController.stream;
  bool? uploadDirectly;
  final String uploadName;
  // void notifyFilesChanged() {
  //   if (onFilesChanges != null) {
  //     onFilesChanges!(List.from(files));
  //   }
  // }

  /// Returns the index of the given [file] in the [files] list by matching its [id].
  ///
  /// Returns -1 if the file is not found.
  // int index(FilepondFile file) => files.indexWhere((f) => f.id == file.id);

  ///the lenght
  int? maxLength;
  SourceType? sourceType;
  final Dio? dioClient;

  /// Updates the given [file] in the [files] list.
  ///
  /// Emits a [FilepondOperation.updated] event on success.
  void updateFile(FilepondFile oldFile, FilepondFile newFile) {
    var i = files.indexOf(oldFile);

    if (i == -1) {
      _operationsController.add(
        FilepondOperation.failed(oldFile, i, 'File not found in the list!'),
      );

      return;
    } else {
      files[i] = newFile;
      _operationsController.add(FilepondOperation.update(oldFile, newFile));
    }
  }

  Future<(int?, FilepondFile?)> attachFileToController(
    File originalFile,
  ) async {
    var file = await compressImageFileWithIsolate(originalFile, quality: 60);
    if (file == null) {
      Logger.warn(message: 'failed to compress ${originalFile.path}');
      return (null, null);
    }
    // final compressedFiles = await Future.wait(
    //   (maxLength == null ? images : images.take(maxLength!)).map(
    //     (photo) => compressImageFileWithIsolate(File(photo.path)),
    //   ),
    // );
    // Logger.warn(message: 'compressed files ${compressedFiles.length} ');
    // final file = compressedFiles[i];
    // final photo = (maxLength == null ? images : images.take(maxLength!))
    //     .elementAt(i);
    // if (file == null) {
    //   Logger.warn(message: 'File compress failed for ${photo.path} ');
    //   ;
    // }
    var filepondFile = FilepondFile(
      id: file.path,
      file: file.readAsBytesSync(),
      uploadName: uploadName,
      fileName: basename(file.path),
    );
    files.add(filepondFile);
    final int index = files.indexOf(filepondFile);
    return (index, filepondFile);
  }

  /// Prompts the user to pick a file and adds it to [files].
  ///
  /// Emits a [FilepondOperation.insert] event on success.
  Future<void> attachFile() async {
    if ((maxLength ?? 0) <= files.length) return;

    try {
      switch (sourceType) {
        // case null:
        //   // TODO: Handle this case.
        //   throw UnimplementedError();
        case SourceType.files:
          var result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
          );
          if (result != null) {
            File file = File(result.files.single.path!);
            var filepondFile = FilepondFile(
              id: file.path,
              file: file.readAsBytesSync(),
              fileName: basename(file.path),
            );

            // Check if the file is already in the list
            bool alreadyExists = files.isEmpty
                ? false
                : files.any((f) => f.fileName == basename(file.path));
            if (alreadyExists) {
              final int index = files.indexOf(filepondFile);

              _operationsController.add(
                FilepondOperation.dublicate(filepondFile, index),
              );
              return;
            }

            files.add(filepondFile);
            final int index = files.indexOf(filepondFile);

            print(file.path);
            _operationsController.add(
              FilepondOperation.insert(filepondFile, index),
            );
          } else {
            // User canceled the picker
          }
        case SourceType.gallery:
          final ImagePicker picker = ImagePicker();
          // Pick an image.
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image == null) return;
          // var compressedFiles = await compressImageFileWithIsolate(
          //   File(image.path),
          // );
          // Logger.warn(message: 'compressed files ${compressedFiles?.path} ');
          // var file = await compressImageFileWithIsolate(File(image.path));
          // // final compressedFiles = await Future.wait(
          // //   (maxLength == null ? images : images.take(maxLength!)).map(
          // //     (photo) => compressImageFileWithIsolate(File(photo.path)),
          // //   ),
          // // );
          // // Logger.warn(message: 'compressed files ${compressedFiles.length} ');
          // final file = compressedFiles[i];
          // final photo = (maxLength == null ? images : images.take(maxLength!))
          //     .elementAt(i);
          // if (file == null) {
          //   Logger.warn(message: 'File compress failed for ${photo.path} ');
          //   ;
          // }
          // final Directory? downloadsDir = Platform.isAndroid
          //     ? await getDownloadsDirectory()
          //     : await getApplicationDocumentsDirectory();

          // var file = await compressAndGetFile(f, downloadsDir!.path);
          // File file = File(comprassed.path);
          // var file = await compressImageFileWithIsolate(File(photo.path));
          // File file = File(comprassed.path);
          // if (file == null) {
          //   Logger.warn(message: 'File compress failed for ${photo.path} ');
          //   return;
          // }

          // var filepondFile = FilepondFile(
          //   id: file.path,
          //   file: file.readAsBytesSync(),
          //   uploadName: uploadName,
          //   fileName: basename(file.path),
          // );

          // files.add(filepondFile);
          // final int index = files.indexOf(filepondFile);
          var attached = await attachFileToController(File(image.path)!);
          Logger.warn(message: 'index of file ${files.indexOf(attached.$2!)}');
          if (attached.$1 == null || attached.$2 == null) {
            return;
          }
          onFilesChange?.call(files);
          _operationsController.add(
            FilepondOperation.insert(attached.$2!, attached.$1!),
          );

          // for (var i = 0; i < compressedFiles.length; i++) {
          //   // Logger.warn(message: 'dealing with ${photo?.path}');

          if (uploadDirectly == true) {
            uploadAll();
          }
        // }

        case SourceType.camera:
          final ImagePicker picker = ImagePicker();

          final XFile? photo = await picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear,
            imageQuality: 80,
          );

          notifier.attaching();
          // var compressedFiles = await compressImageFileWithIsolate(
          //   File(photo!.path),
          // );
          // Logger.warn(message: 'compressed files ${compressedFiles?.path} ');
          // var file = await compressImageFileWithIsolate(File(image.path));
          // // final compressedFiles = await Future.wait(
          // //   (maxLength == null ? images : images.take(maxLength!)).map(
          // //     (photo) => compressImageFileWithIsolate(File(photo.path)),
          // //   ),
          // // );
          // // Logger.warn(message: 'compressed files ${compressedFiles.length} ');
          // final file = compressedFiles[i];
          // final photo = (maxLength == null ? images : images.take(maxLength!))
          //     .elementAt(i);
          // if (file == null) {
          //   Logger.warn(message: 'File compress failed for ${photo.path} ');
          //   ;
          // }
          // final Directory? downloadsDir = Platform.isAndroid
          //     ? await getDownloadsDirectory()
          //     : await getApplicationDocumentsDirectory();

          // var file = await compressAndGetFile(f, downloadsDir!.path);
          // File file = File(comprassed.path);
          // var file = await compressImageFileWithIsolate(File(photo.path));
          // File file = File(comprassed.path);
          // if (file == null) {
          //   Logger.warn(message: 'File compress failed for ${photo.path} ');
          //   return;
          // }

          // var filepondFile = FilepondFile(
          //   id: file.path,
          //   file: file.readAsBytesSync(),
          //   uploadName: uploadName,
          //   fileName: basename(file.path),
          // );

          // files.add(filepondFile);
          // final int index = files.indexOf(filepondFile);
          var attached = await attachFileToController(File(photo!.path));
          Logger.warn(message: 'index of file ${files.indexOf(attached.$2!)}');
          if (attached.$1 == null || attached.$2 == null) {
            return;
          }
          onFilesChange?.call(files);
          _operationsController.add(
            FilepondOperation.insert(attached.$2!, attached.$1!),
          );
          // if (photo != null) {
          //   // final Directory? downloadsDir = await getDownloadsDirectory();

          //   // var file = await compressAndGetFile(photo, downloadsDir!.path);
          //   var file = await compressImageFileWithIsolate(File(photo.path));
          //   // File file = File(comprassed.path);
          //   if (file == null) {
          //     return;
          //   }

          //   var filepondFile = FilepondFile(
          //     id: file.path,
          //     file: file.readAsBytesSync(),
          //     fileName: basename(file.path),
          //   );

          //   files.add(filepondFile);
          //   final int index = files.indexOf(filepondFile);

          //   _operationsController.add(
          //     FilepondOperation.insert(filepondFile, index),
          //   );
          if (uploadDirectly == true) {
            uploadAll();
          }
        // }
        // case SourceType.ask:
        //   // TODO: Handle this case.
        //   throw UnimplementedError();
        default:
          return;
      }
      Logger.warn(message: 'attached files  ${files.length}');
    } catch (e) {
      print(e);
    }

    notifier.attached();
  }

  /// Resolves a nested value from [data] using a '/'-separated [path].
  ///
  /// Throws if the path is invalid.
  dynamic resolveNestedValueOrThrow(Map<String, dynamic> data, String path) {
    final keys = path.split('/');
    dynamic current = data;

    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        throw Exception('Invalid path: $path');
      }
    }

    return current;
  }

  /// Uploads the given [file] to [baseUrl].
  ///
  /// Emits a [FilepondOperation.uploaded] event on success.
  /// Updates upload progress via [updateUploadProgress].
  Future<void> uploadFile(FilepondFile file) async {
    // await Future.delayed(Duration(seconds: 2)); // Add 2 seconds delay
    Logger.warn(message: 'trying to upload');

    Dio dio = dioClient ?? Dio()
      ..interceptors.addAll([AwesomeDioInterceptor()]);

    // final formData =;
    final id = file.fileName;
    final int index = files.indexOf(file);
    // Handle case where file might not be found (though unlikely if called from within the controller's managed files)
    if (index == -1) {
      _operationsController.add(
        FilepondOperation.failed(
          file,
          -1,
          'File not found in the list for upload update!',
        ),
      );
      return;
    }

    try {
      var res = await dio.post(
        baseUrl,
        data: FormData.fromMap(
          {
            uploadName: MultipartFile.fromBytes(
              file.file.toList(),
              filename: file.fileName,
            ),
          },
          ListFormat.multi,
          false,
          file.fileName!,
        ),

        onSendProgress: (sent, total) {
          if (total > 0) {
            updateUploadProgress(id!, sent / total);
          }
        },
      );
      if (res.statusCode == 200) {
        final pondResult;

        try {
          // pondResult = resolveNestedValueOrThrow(res.data, pondLocation);
          // files = files
          //     .map((e) => e.id == file.id ? e.copyWith(filepond: res.data) : e)
          //     .toList();
          final updatedFile = file.copyWith(
            filepond: res.data,
            uploading: false,
          );
          files[index] = updatedFile;

          _operationsController.add(
            FilepondOperation.uploaded(
              // file.copyWith(filepond: res.data, uploading: false),
              updatedFile,
              index,
            ),
          );
          onFilesChange?.call(files);
        } catch (e) {
          _operationsController.add(
            FilepondOperation.failed(
              file.copyWith(uploading: false),
              index,
              e.toString(),
            ),
          );
          return;
        }
      }
    } catch (e) {
      _operationsController.add(
        FilepondOperation.failed(file.copyWith(uploading: false), index),
      );
    }
    // onFilesChange?.call(files);
  }

  /// Uploads all files that have not been uploaded yet.
  ///
  /// Calls [uploadFile] for each file whose [filepond] property is null.
  /// Waits for all uploads to complete.
  Future<void> uploadAll() async {
    Logger.warn(message: 'trying to upload all ');
    Logger.warn(message: '${files.length}');
    if (files.isEmpty) return;
    // final filesToUpload = files.where((f) => f.filepond == null).toList();
    // for (final file in filesToUpload) {
    //   await uploadFile(file);
    // }
    final filesToUpload = files.where((f) => f.filepond == null).toList();
    Logger.warn(message: 'filles to upload length ${filesToUpload.length}');
    Logger.warn(message: 'filles in controller length ${files.length}');
    await Future.wait(filesToUpload.map(uploadFile));
  }

  /// Removes the given [file] from the controller.
  ///
  /// Emits a [FilepondOperation.removed] event on success.
  void removeFile(FilepondFile file) {
    // print(files.e);
    final int index = files.indexOf(file);
    print('_controller.removeFile:[index]:$index');
    if (index != -1) {
      files.removeAt(index);
      _operationsController.add(FilepondOperation.remove(file, index));
    } else {
      Logger.warn(message: 'removing');
      _operationsController.add(FilepondOperation.failed(file, index));
    }
  }

  Future<File> compressAndGetFile(XFile file, String targetPath) async {
    var bytes = await file.readAsBytes();
    var result = await FlutterImageCompress.compressWithList(
      bytes,
      // targetPath,
      quality: 88,
      // rotate: 180,
      // format: CompressFormat.jpeg,
    );
    // final bytes = await result?.readAsBytes();

    // print(
    //   'The src file size: ${File(file.path).lengthSync()}, '
    //   'the result bytes length: ${bytes?.length}',
    // );

    var name = basename(file.path);
    File ffile = await File('$targetPath/$name').create();
    ffile.writeAsBytesSync(result);
    return ffile;
  }

  Future<File> fileFromUint8List(Uint8List data, String filename) async {
    // Get the temporary directory of the app
    final directory = await getTemporaryDirectory();

    // Create a file path with the given filename
    final filePath = '${directory.path}/$filename';

    // Create the file and write the data
    final file = File(filePath);
    await file.writeAsBytes(data);

    return file;
  }
}

// You could also pass a file path and read/write within the isolate
Future<String> _compressImageFileInBackground(Map<String, dynamic> args) async {
  final String filePath = args['filePath'];
  final String targetPath = args['targetPath'];
  final int quality = args['quality'];
  debugPrint('Compressing image in seprate isolate');
  final File originalFile = File(filePath);
  final Uint8List originalBytes = await originalFile.readAsBytes();

  final image = img.decodeImage(originalBytes);
  if (image == null) {
    throw Exception("Failed to decode image file in isolate.");
  }

  final compressedBytes = img.encodeJpg(image, quality: quality);
  final File compressedFile = File(targetPath);
  await compressedFile.writeAsBytes(compressedBytes);

  return targetPath;
}

Future<File?> compressImageFileWithIsolate(
  File originalFile, {
  int quality = 80,
}) async {
  try {
    final targetPath =
        '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
    final Map<String, dynamic> args = {
      'filePath': originalFile.absolute.path,
      'targetPath': targetPath,
      'quality': quality,
    };
    // final String resultPath = await compute(
    //   _compressImageFileInBackground,
    //   args,
    // );
    Logger.warn(message: 'compressing ${basename(originalFile.path)}');

    // Use Isolate.run instead of compute
    final String resultPath = await Isolate.run(
      () => _compressImageFileInBackground(
        args,
      ), // Pass a function that takes no arguments
      // and captures 'args'
    );
    return File(resultPath);
  } catch (e) {
    print('Error compressing image file in isolate: $e');
    return null;
  }
}
