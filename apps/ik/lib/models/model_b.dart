import 'package:freezed_annotation/freezed_annotation.dart';
import 'model_a.dart';

part 'model_b.freezed.dart';
part 'model_b.g.dart';

@freezed
 class ModelB with _$ModelB {
  const ModelB._();
  const factory ModelB({required ModelA modelA}) = _ModelB;

  factory ModelB.fromJson(Map<String, dynamic> json) => _$ModelBFromJson(json);
}
// toJ(ModelA j){
//   return j.toJson();
// }
// {@JsonKey(includeToJson: true,toJson:toJ ) 