// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_author.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookAuthorModel _$BookAuthorModelFromJson(Map<String, dynamic> json) =>
    BookAuthorModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      biography: json['biography'] as String?,
      birthYear: (json['birth_year'] as num?)?.toInt(),
      deathYear: (json['death_year'] as num?)?.toInt(),
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$BookAuthorModelToJson(BookAuthorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'biography': instance.biography,
      'birth_year': instance.birthYear,
      'death_year': instance.deathYear,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
