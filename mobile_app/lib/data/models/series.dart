import 'package:json_annotation/json_annotation.dart';
import 'teacher.dart';
import 'book.dart';
import 'theme.dart';

part 'series.g.dart';

@JsonSerializable()
class SeriesModel {
  final int id;
  final String name;
  final int year;
  final String? description;
  @JsonKey(name: 'teacher_id')
  final int teacherId;
  @JsonKey(name: 'book_id')
  final int? bookId;
  @JsonKey(name: 'theme_id')
  final int? themeId;
  @JsonKey(name: 'is_completed')
  final bool? isCompleted;
  final int order;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  final TeacherModel? teacher;
  final BookModel? book;
  final AppThemeModel? theme;
  @JsonKey(name: 'display_name')
  final String? displayName;

  SeriesModel({
    required this.id,
    required this.name,
    required this.year,
    this.description,
    required this.teacherId,
    this.bookId,
    this.themeId,
    this.isCompleted,
    required this.order,
    this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.teacher,
    this.book,
    this.theme,
    this.displayName,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) => _$SeriesModelFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesModelToJson(this);
}
