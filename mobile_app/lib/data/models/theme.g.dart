// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppThemeModel _$AppThemeModelFromJson(Map<String, dynamic> json) =>
    AppThemeModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool?,
      booksCount: (json['books_count'] as num?)?.toInt(),
      seriesCount: (json['series_count'] as num?)?.toInt(),
      lessonsCount: (json['lessons_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppThemeModelToJson(AppThemeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_active': instance.isActive,
      'books_count': instance.booksCount,
      'series_count': instance.seriesCount,
      'lessons_count': instance.lessonsCount,
    };
