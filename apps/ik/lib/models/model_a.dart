import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_a.freezed.dart';
part 'model_a.g.dart';

@freezed
abstract class ModelA with _$ModelA {
  const factory ModelA({required double latitude, required double longitude}) =
      _ModelA;

  factory ModelA.fromJson(Map<String, dynamic> json) => _$ModelAFromJson(json);
}
