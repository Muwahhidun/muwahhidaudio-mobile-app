import 'package:json_annotation/json_annotation.dart';

part 'theme.g.dart';

/// Theme model
@JsonSerializable()
class AppThemeModel {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'books_count')
  final int? booksCount;
  @JsonKey(name: 'series_count')
  final int? seriesCount;
  @JsonKey(name: 'lessons_count')
  final int? lessonsCount;

  AppThemeModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive,
    this.booksCount,
    this.seriesCount,
    this.lessonsCount,
  });

  factory AppThemeModel.fromJson(Map<String, dynamic> json) =>
      _$AppThemeModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppThemeModelToJson(this);
}
