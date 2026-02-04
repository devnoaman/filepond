// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filepond_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FilepondFile _$FilepondFileFromJson(Map<String, dynamic> json) =>
    _FilepondFile(
      id: json['id'] as String,
      file: const Uint8ListConverter().fromJson(json['file']),
      filepond: json['filepond'] as String?,
      fileName: json['fileName'] as String?,
      uploadName: json['uploadName'] as String?,
      uploading: json['uploading'] as bool? ?? false,
    );

Map<String, dynamic> _$FilepondFileToJson(_FilepondFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file': const Uint8ListConverter().toJson(instance.file),
      'filepond': instance.filepond,
      'fileName': instance.fileName,
      'uploadName': instance.uploadName,
      'uploading': instance.uploading,
    };
