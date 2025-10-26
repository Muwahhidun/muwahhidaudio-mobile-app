import 'package:json_annotation/json_annotation.dart';

part 'teacher.g.dart';

@JsonSerializable()
class TeacherModel {
  final int id;
  final String name;
  final String? biography;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  TeacherModel({
    required this.id,
    required this.name,
    this.biography,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) => _$TeacherModelFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherModelToJson(this);
}
