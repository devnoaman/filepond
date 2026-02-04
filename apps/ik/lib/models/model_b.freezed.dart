// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_b.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ModelB _$ModelBFromJson(Map<String, dynamic> json) {
  return _ModelB.fromJson(json);
}

/// @nodoc
mixin _$ModelB {
  ModelA get modelA => throw _privateConstructorUsedError;

  /// Serializes this ModelB to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelB
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelBCopyWith<ModelB> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelBCopyWith<$Res> {
  factory $ModelBCopyWith(ModelB value, $Res Function(ModelB) then) =
      _$ModelBCopyWithImpl<$Res, ModelB>;
  @useResult
  $Res call({ModelA modelA});

  $ModelACopyWith<$Res> get modelA;
}

/// @nodoc
class _$ModelBCopyWithImpl<$Res, $Val extends ModelB>
    implements $ModelBCopyWith<$Res> {
  _$ModelBCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelB
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? modelA = null}) {
    return _then(
      _value.copyWith(
            modelA: null == modelA
                ? _value.modelA
                : modelA // ignore: cast_nullable_to_non_nullable
                      as ModelA,
          )
          as $Val,
    );
  }

  /// Create a copy of ModelB
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelACopyWith<$Res> get modelA {
    return $ModelACopyWith<$Res>(_value.modelA, (value) {
      return _then(_value.copyWith(modelA: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ModelBImplCopyWith<$Res> implements $ModelBCopyWith<$Res> {
  factory _$$ModelBImplCopyWith(
    _$ModelBImpl value,
    $Res Function(_$ModelBImpl) then,
  ) = __$$ModelBImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ModelA modelA});

  @override
  $ModelACopyWith<$Res> get modelA;
}

/// @nodoc
class __$$ModelBImplCopyWithImpl<$Res>
    extends _$ModelBCopyWithImpl<$Res, _$ModelBImpl>
    implements _$$ModelBImplCopyWith<$Res> {
  __$$ModelBImplCopyWithImpl(
    _$ModelBImpl _value,
    $Res Function(_$ModelBImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModelB
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? modelA = null}) {
    return _then(
      _$ModelBImpl(
        modelA: null == modelA
            ? _value.modelA
            : modelA // ignore: cast_nullable_to_non_nullable
                  as ModelA,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelBImpl extends _ModelB {
  const _$ModelBImpl({required this.modelA}) : super._();

  factory _$ModelBImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelBImplFromJson(json);

  @override
  final ModelA modelA;

  @override
  String toString() {
    return 'ModelB(modelA: $modelA)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelBImpl &&
            (identical(other.modelA, modelA) || other.modelA == modelA));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, modelA);

  /// Create a copy of ModelB
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelBImplCopyWith<_$ModelBImpl> get copyWith =>
      __$$ModelBImplCopyWithImpl<_$ModelBImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelBImplToJson(this);
  }
}

abstract class _ModelB extends ModelB {
  const factory _ModelB({required final ModelA modelA}) = _$ModelBImpl;
  const _ModelB._() : super._();

  factory _ModelB.fromJson(Map<String, dynamic> json) = _$ModelBImpl.fromJson;

  @override
  ModelA get modelA;

  /// Create a copy of ModelB
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelBImplCopyWith<_$ModelBImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
