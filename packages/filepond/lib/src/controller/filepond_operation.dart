// import 'package:filepond/src/models/filepond_file.dart';
part of 'controller.dart';

/// Enum representing the type of operation performed on the file list.
enum UploadOperationType {
  ///indicate that file inserted successfully
  insert,

  ///indicate that the file has been uploaded to the server and pond location added
  uploaded,

  update,

  ///indicate fail in the attach or upload operation
  failed,

  ///indicate that the file removed successfully
  remove,
  uploading,

  /// indicate that the file is a dublicate from other file
  dublicate,
}

/// Represents a single operation performed on the file list managed by a [FilepondController].
///
/// Instances of this class are emitted by the [FilepondController.operationsStream]
/// to notify listeners about changes.
class FilepondOperation {
  final String? message;

  /// The type of operation performed.
  final UploadOperationType type;

  /// The file before an update operation. Null for other types.
  final FilepondFile? oldFile;

  /// The affected file (inserted, updated, removed). Null for `set`.
  final FilepondFile? file;

  /// The index where the file was inserted or removed. Null for `update` and `set`.
  final int? index;

  FilepondOperation._(
    this.type, {
    this.oldFile,
    this.file,
    this.index,
    String? errorMessage,
  }) : message = errorMessage;

  /// Creates an insert operation.
  factory FilepondOperation.insert(FilepondFile file, int index) =>
      FilepondOperation._(UploadOperationType.insert, file: file, index: index);
  factory FilepondOperation.uploaded(FilepondFile file, int index) {
    Logger.warn(message: 'attempt to insert at index $index');
    return FilepondOperation._(
      UploadOperationType.uploaded,
      file: file,
      index: index,
    );
  }

  /// Creates an update operation.
  factory FilepondOperation.update(FilepondFile oldFile, FilepondFile file) =>
      FilepondOperation._(
        UploadOperationType.update,
        oldFile: oldFile,
        file: file,
      );

  /// Creates a remove operation.
  factory FilepondOperation.remove(FilepondFile file, int index) =>
      FilepondOperation._(UploadOperationType.remove, file: file, index: index);
  factory FilepondOperation.uploading(FilepondFile file, int index) =>
      FilepondOperation._(UploadOperationType.remove, file: file, index: index);
  factory FilepondOperation.failed(
    FilepondFile file,
    int index, [
    String? message,
  ]) => FilepondOperation._(
    UploadOperationType.failed,
    file: file,
    index: index,
    errorMessage: message,
  );

  factory FilepondOperation.dublicate(
    FilepondFile file,
    int index, [
    String? message,
  ]) => FilepondOperation._(
    UploadOperationType.dublicate,
    file: file,
    index: index,
    errorMessage: message,
  );
}
