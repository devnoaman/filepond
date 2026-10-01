import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'filepond_file_status.dart';

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

/// A file managed by a `FilepondController`.
///
/// [status] is the single source of truth for the upload state:
/// `pending → uploading → uploaded | failed`. A failed file can be retried
/// (`FilepondController.retryUpload`) or removed.
@freezed
abstract class FilepondFile with _$FilepondFile {
  const FilepondFile._();

  const factory FilepondFile({
    required String id,
    @Uint8ListConverter() required Uint8List file,

    /// The pond id returned by the server once the upload succeeded.
    String? filepond,
    String? fileName,
    String? uploadName,

    /// Kept for backward compatibility; always mirrors
    /// `status == FilepondFileStatus.uploading`.
    @Deprecated('Use status (or isUploading) instead.')
    @Default(false)
    bool uploading,

    /// Upload status of this file.
    @Default(FilepondFileStatus.pending) FilepondFileStatus status,

    /// Last upload failure message; `null` unless [status] is `failed`.
    String? error,
  }) = _FilepondFile;

  /// Deserialises a file.
  ///
  /// JSON written before `status` existed has no `status` key: it is read as
  /// [FilepondFileStatus.uploaded] when `filepond` is set, otherwise
  /// [FilepondFileStatus.pending].
  factory FilepondFile.fromJson(Map<String, dynamic> json) =>
      _$FilepondFileFromJson(_migrateLegacyJson(json));

  /// Upload not started yet.
  bool get isPending => status == FilepondFileStatus.pending;

  /// Upload request in flight.
  bool get isUploading => status == FilepondFileStatus.uploading;

  /// Server returned a pond id.
  bool get isUploaded => status == FilepondFileStatus.uploaded;

  /// Last upload attempt failed; see [error].
  bool get isFailed => status == FilepondFileStatus.failed;
}

Map<String, dynamic> _migrateLegacyJson(Map<String, dynamic> json) {
  if (json['status'] != null) return json;
  return <String, dynamic>{
    ...json,
    'status': json['filepond'] != null
        ? FilepondFileStatus.uploaded.name
        : FilepondFileStatus.pending.name,
    // A legacy in-flight upload can't be resumed after deserialisation.
    'uploading': false,
  };
}
