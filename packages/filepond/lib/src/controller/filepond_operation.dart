import 'package:filepond/src/models/filepond_file.dart';

/// Enum representing the type of operation performed on the chat file list.
enum UploadOperationType { insert, uploaded, update, failed, remove }

/// Represents a single operation performed on the file list managed by a [ChatController].
///
/// Instances of this class are emitted by the [ChatController.operationsStream]
/// to notify listeners about changes.
class FilepondOperation {
  /// The type of operation performed.
  final UploadOperationType type;

  /// The file before an update operation. Null for other types.
  final FilepondFile? oldFile;

  /// The affected file (inserted, updated, removed). Null for `set`.
  final FilepondFile? file;

  /// The index where the file was inserted or removed. Null for `update` and `set`.
  final int? index;

  FilepondOperation._(this.type, {this.oldFile, this.file, this.index});

  /// Creates an insert operation.
  factory FilepondOperation.insert(FilepondFile file, int index) =>
      FilepondOperation._(UploadOperationType.insert, file: file, index: index);
  factory FilepondOperation.uploaded(FilepondFile file, int index) =>
      FilepondOperation._(
        UploadOperationType.uploaded,
        file: file,
        index: index,
      );

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

  /// Creates a set operation (signifying a full list replacement).
  // factory ChatOperation.set() => ChatOperation._(UploadOperationType.set);
}
