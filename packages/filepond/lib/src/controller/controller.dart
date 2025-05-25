// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filepond/src/controller/filepond_operation.dart';
import 'package:filepond/src/models/filepond_file.dart';
import 'package:filepond/src/upload_file_mixin.dart';
import 'package:path/path.dart';

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

  /// Creates a [FilepondController].
  ///
  /// [baseUrl] is required and should point to your upload endpoint.
  /// [pondLocation] is the path in the response JSON to the uploaded file info (default: 'filepond').
  FilepondController({required this.baseUrl, this.pondLocation = 'filepond'});

  /// Returns true if all files have been uploaded (i.e., have a non-null [filepond] property).
  bool get allUploaded =>
      files.isNotEmpty && files.every((f) => f.filepond != null);
  final _operationsController = StreamController<FilepondOperation>.broadcast();

  /// Stream of file operations (insert, uploaded, etc.) for UI updates.
  Stream<FilepondOperation> get operationsStream =>
      _operationsController.stream;

  /// Returns the index of the given [file] in the [files] list by matching its [id].
  ///
  /// Returns -1 if the file is not found.
  int index(FilepondFile file) => files.indexWhere((f) => f.id == file.id);

  /// Updates the given [file] in the [files] list.
  ///
  /// Emits a [FilepondOperation.updated] event on success.
  void updateFile(FilepondFile oldFile, FilepondFile newFile) {
    var i = index(oldFile);

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

  /// Prompts the user to pick a file and adds it to [files].
  ///
  /// Emits a [FilepondOperation.insert] event on success.
  Future<void> attachFile() async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      var filepondFile = FilepondFile(id: file.path, file: file);

      // Check if the file is already in the list
      bool alreadyExists =
          files.isEmpty ? false : files.any((f) => f.file.path == file.path);
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
      _operationsController.add(FilepondOperation.insert(filepondFile, index));
    } else {
      // User canceled the picker
    }
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

    Dio dio = Dio()..interceptors.addAll([AwesomeDioInterceptor()]);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.file.path,
        filename: basename(file.file.path),
      ),
    });
    final id = file.file.path;
    final int index = files.indexOf(file);
    try {
      var res = await dio.post(
        baseUrl,
        data: formData,

        onSendProgress: (sent, total) {
          if (total > 0) {
            updateUploadProgress(id, sent / total);
          }
        },
      );
      if (res.statusCode == 200) {
        _operationsController.add(FilepondOperation.uploaded(file, index));
        final pondResult;

        try {
          pondResult = resolveNestedValueOrThrow(res.data, pondLocation);
          files =
              files
                  .map(
                    (e) =>
                        e.id == file.id ? e.copyWith(filepond: pondResult) : e,
                  )
                  .toList();
        } catch (e) {
          _operationsController.add(
            FilepondOperation.failed(file, index, e.toString()),
          );
          return;
        }
      }
    } catch (e) {
      _operationsController.add(FilepondOperation.failed(file, index));
    }
  }

  /// Uploads all files that have not been uploaded yet.
  ///
  /// Calls [uploadFile] for each file whose [filepond] property is null.
  /// Waits for all uploads to complete.
  Future<void> uploadAll() async {
    final filesToUpload = files.where((f) => f.filepond == null).toList();
    for (final file in filesToUpload) {
      await uploadFile(file);
    }
  }

  /// Removes the given [file] from the controller.
  ///
  /// Emits a [FilepondOperation.removed] event on success.
  void removeFile(FilepondFile file) {
    final int index = files.indexOf(file);
    if (index != -1) {
      files.removeAt(index);
      _operationsController.add(FilepondOperation.remove(file, index));
    }
  }
}
