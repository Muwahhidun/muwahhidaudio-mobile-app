// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookModel _$BookModelFromJson(Map<String, dynamic> json) => BookModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
  isActive: json['is_active'] as bool?,
  themeId: (json['theme_id'] as num?)?.toInt(),
  authorId: (json['author_id'] as num?)?.toInt(),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  theme: json['theme'] == null
      ? null
      : AppThemeModel.fromJson(json['theme'] as Map<String, dynamic>),
  author: json['author'] == null
      ? null
      : BookAuthorModel.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BookModelToJson(BookModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'sort_order': instance.sortOrder,
  'is_active': instance.isActive,
  'theme_id': instance.themeId,
  'author_id': instance.authorId,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'theme': instance.theme,
  'author': instance.author,
};
