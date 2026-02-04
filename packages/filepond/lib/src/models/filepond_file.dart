// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:io';

// class FilepondFile {
//   final String id;
//   final File file;
//   final String? filepond;

//   FilepondFile({required this.id, required this.file, this.filepond});

//   FilepondFile copyWith({String? id, File? file, String? filepond}) {
//     return FilepondFile(
//       id: id ?? this.id,
//       file: file ?? this.file,
//       filepond: filepond ?? this.filepond,
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filepond_file.freezed.dart';
part 'filepond_file.g.dart';

class Uint8ListConverter implements JsonConverter<Uint8List, dynamic> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(dynamic json) {
    return base64Decode(json.toString());
  }

  @override
  String toJson(Uint8List object) {
    return base64Encode(object);
  }
}

@freezed
abstract class FilepondFile with _$FilepondFile {
  const factory FilepondFile({
    required String id,
    @Uint8ListConverter() required Uint8List file,
    String? filepond,
    String? fileName,
    String? uploadName,
    @Default(false) bool uploading,
  }) = _FilepondFile;

  factory FilepondFile.fromJson(Map<String, dynamic> json) =>
      _$FilepondFileFromJson(json);
}

// // Helper methods
// File _fileFromJson(String path) => File(path);
// String _fileToJson(File file) => file.path;
