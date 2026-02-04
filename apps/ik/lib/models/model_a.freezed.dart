// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_a.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ModelA _$ModelAFromJson(Map<String, dynamic> json) {
  return _ModelA.fromJson(json);
}

/// @nodoc
mixin _$ModelA {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this ModelA to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelA
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelACopyWith<ModelA> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelACopyWith<$Res> {
  factory $ModelACopyWith(ModelA value, $Res Function(ModelA) then) =
      _$ModelACopyWithImpl<$Res, ModelA>;
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class _$ModelACopyWithImpl<$Res, $Val extends ModelA>
    implements $ModelACopyWith<$Res> {
  _$ModelACopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelA
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? latitude = null, Object? longitude = null}) {
    return _then(
      _value.copyWith(
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModelAImplCopyWith<$Res> implements $ModelACopyWith<$Res> {
  factory _$$ModelAImplCopyWith(
    _$ModelAImpl value,
    $Res Function(_$ModelAImpl) then,
  ) = __$$ModelAImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class __$$ModelAImplCopyWithImpl<$Res>
    extends _$ModelACopyWithImpl<$Res, _$ModelAImpl>
    implements _$$ModelAImplCopyWith<$Res> {
  __$$ModelAImplCopyWithImpl(
    _$ModelAImpl _value,
    $Res Function(_$ModelAImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModelA
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? latitude = null, Object? longitude = null}) {
    return _then(
      _$ModelAImpl(
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelAImpl implements _ModelA {
  const _$ModelAImpl({required this.latitude, required this.longitude});

  factory _$ModelAImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelAImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'ModelA(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelAImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

  /// Create a copy of ModelA
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelAImplCopyWith<_$ModelAImpl> get copyWith =>
      __$$ModelAImplCopyWithImpl<_$ModelAImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelAImplToJson(this);
  }
}

abstract class _ModelA implements ModelA {
  const factory _ModelA({
    required final double latitude,
    required final double longitude,
  }) = _$ModelAImpl;

  factory _ModelA.fromJson(Map<String, dynamic> json) = _$ModelAImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of ModelA
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelAImplCopyWith<_$ModelAImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
