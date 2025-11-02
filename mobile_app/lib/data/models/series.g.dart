// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeriesModel _$SeriesModelFromJson(Map<String, dynamic> json) => SeriesModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  year: (json['year'] as num).toInt(),
  description: json['description'] as String?,
  teacherId: (json['teacher_id'] as num).toInt(),
  bookId: (json['book_id'] as num?)?.toInt(),
  themeId: (json['theme_id'] as num?)?.toInt(),
  isCompleted: json['is_completed'] as bool?,
  order: (json['order'] as num).toInt(),
  isActive: json['is_active'] as bool?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  teacher: json['teacher'] == null
      ? null
      : TeacherModel.fromJson(json['teacher'] as Map<String, dynamic>),
  book: json['book'] == null
      ? null
      : BookModel.fromJson(json['book'] as Map<String, dynamic>),
  theme: json['theme'] == null
      ? null
      : AppThemeModel.fromJson(json['theme'] as Map<String, dynamic>),
  displayName: json['display_name'] as String?,
);

Map<String, dynamic> _$SeriesModelToJson(SeriesModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'year': instance.year,
      'description': instance.description,
      'teacher_id': instance.teacherId,
      'book_id': instance.bookId,
      'theme_id': instance.themeId,
      'is_completed': instance.isCompleted,
      'order': instance.order,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'teacher': instance.teacher,
      'book': instance.book,
      'theme': instance.theme,
      'display_name': instance.displayName,
    };
