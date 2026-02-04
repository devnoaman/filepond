// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filepond_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FilepondFile {

 String get id;@Uint8ListConverter() Uint8List get file; String? get filepond; String? get fileName; String? get uploadName; bool get uploading;
/// Create a copy of FilepondFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilepondFileCopyWith<FilepondFile> get copyWith => _$FilepondFileCopyWithImpl<FilepondFile>(this as FilepondFile, _$identity);

  /// Serializes this FilepondFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilepondFile&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.file, file)&&(identical(other.filepond, filepond) || other.filepond == filepond)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.uploadName, uploadName) || other.uploadName == uploadName)&&(identical(other.uploading, uploading) || other.uploading == uploading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(file),filepond,fileName,uploadName,uploading);

@override
String toString() {
  return 'FilepondFile(id: $id, file: $file, filepond: $filepond, fileName: $fileName, uploadName: $uploadName, uploading: $uploading)';
}


}

/// @nodoc
abstract mixin class $FilepondFileCopyWith<$Res>  {
  factory $FilepondFileCopyWith(FilepondFile value, $Res Function(FilepondFile) _then) = _$FilepondFileCopyWithImpl;
@useResult
$Res call({
 String id,@Uint8ListConverter() Uint8List file, String? filepond, String? fileName, String? uploadName, bool uploading
});




}
/// @nodoc
class _$FilepondFileCopyWithImpl<$Res>
    implements $FilepondFileCopyWith<$Res> {
  _$FilepondFileCopyWithImpl(this._self, this._then);

  final FilepondFile _self;
  final $Res Function(FilepondFile) _then;

/// Create a copy of FilepondFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? file = null,Object? filepond = freezed,Object? fileName = freezed,Object? uploadName = freezed,Object? uploading = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as Uint8List,filepond: freezed == filepond ? _self.filepond : filepond // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,uploadName: freezed == uploadName ? _self.uploadName : uploadName // ignore: cast_nullable_to_non_nullable
as String?,uploading: null == uploading ? _self.uploading : uploading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _FilepondFile implements FilepondFile {
  const _FilepondFile({required this.id, @Uint8ListConverter() required this.file, this.filepond, this.fileName, this.uploadName, this.uploading = false});
  factory _FilepondFile.fromJson(Map<String, dynamic> json) => _$FilepondFileFromJson(json);

@override final  String id;
@override@Uint8ListConverter() final  Uint8List file;
@override final  String? filepond;
@override final  String? fileName;
@override final  String? uploadName;
@override@JsonKey() final  bool uploading;

/// Create a copy of FilepondFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilepondFileCopyWith<_FilepondFile> get copyWith => __$FilepondFileCopyWithImpl<_FilepondFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilepondFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FilepondFile&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.file, file)&&(identical(other.filepond, filepond) || other.filepond == filepond)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.uploadName, uploadName) || other.uploadName == uploadName)&&(identical(other.uploading, uploading) || other.uploading == uploading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(file),filepond,fileName,uploadName,uploading);

@override
String toString() {
  return 'FilepondFile(id: $id, file: $file, filepond: $filepond, fileName: $fileName, uploadName: $uploadName, uploading: $uploading)';
}


}

/// @nodoc
abstract mixin class _$FilepondFileCopyWith<$Res> implements $FilepondFileCopyWith<$Res> {
  factory _$FilepondFileCopyWith(_FilepondFile value, $Res Function(_FilepondFile) _then) = __$FilepondFileCopyWithImpl;
@override @useResult
$Res call({
 String id,@Uint8ListConverter() Uint8List file, String? filepond, String? fileName, String? uploadName, bool uploading
});




}
/// @nodoc
class __$FilepondFileCopyWithImpl<$Res>
    implements _$FilepondFileCopyWith<$Res> {
  __$FilepondFileCopyWithImpl(this._self, this._then);

  final _FilepondFile _self;
  final $Res Function(_FilepondFile) _then;

/// Create a copy of FilepondFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? file = null,Object? filepond = freezed,Object? fileName = freezed,Object? uploadName = freezed,Object? uploading = null,}) {
  return _then(_FilepondFile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as Uint8List,filepond: freezed == filepond ? _self.filepond : filepond // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,uploadName: freezed == uploadName ? _self.uploadName : uploadName // ignore: cast_nullable_to_non_nullable
as String?,uploading: null == uploading ? _self.uploading : uploading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
