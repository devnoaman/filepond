// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

class FilepondFile {
  final String id;
  final File file;
  final String? filepond;

  FilepondFile({required this.id, required this.file, this.filepond});

  FilepondFile copyWith({String? id, File? file, String? filepond}) {
    return FilepondFile(
      id: id ?? this.id,
      file: file ?? this.file,
      filepond: filepond ?? this.filepond,
    );
  }
}
