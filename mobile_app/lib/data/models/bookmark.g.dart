// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bookmark _$BookmarkFromJson(Map<String, dynamic> json) => Bookmark(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      lessonId: (json['lesson_id'] as num).toInt(),
      customName: json['custom_name'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      lesson: json['lesson'] == null
          ? null
          : Lesson.fromJson(json['lesson'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BookmarkToJson(Bookmark instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'lesson_id': instance.lessonId,
      'custom_name': instance.customName,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'lesson': instance.lesson,
    };

SeriesWithBookmarks _$SeriesWithBookmarksFromJson(Map<String, dynamic> json) =>
    SeriesWithBookmarks(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      year: (json['year'] as num).toInt(),
      displayName: json['display_name'] as String,
      teacherId: (json['teacher_id'] as num).toInt(),
      bookId: (json['book_id'] as num?)?.toInt(),
      themeId: (json['theme_id'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      isCompleted: json['is_completed'] as bool,
      description: json['description'] as String?,
      order: (json['order'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      teacher: json['teacher'] == null
          ? null
          : TeacherNested.fromJson(json['teacher'] as Map<String, dynamic>),
      book: json['book'] == null
          ? null
          : BookNested.fromJson(json['book'] as Map<String, dynamic>),
      bookmarksCount: (json['bookmarks_count'] as num).toInt(),
    );

Map<String, dynamic> _$SeriesWithBookmarksToJson(
        SeriesWithBookmarks instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'year': instance.year,
      'display_name': instance.displayName,
      'teacher_id': instance.teacherId,
      'book_id': instance.bookId,
      'theme_id': instance.themeId,
      'is_active': instance.isActive,
      'is_completed': instance.isCompleted,
      'description': instance.description,
      'order': instance.order,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'teacher': instance.teacher,
      'book': instance.book,
      'bookmarks_count': instance.bookmarksCount,
    };

BookmarkCreateRequest _$BookmarkCreateRequestFromJson(
        Map<String, dynamic> json) =>
    BookmarkCreateRequest(
      lessonId: (json['lesson_id'] as num).toInt(),
      customName: json['custom_name'] as String?,
    );

Map<String, dynamic> _$BookmarkCreateRequestToJson(
        BookmarkCreateRequest instance) =>
    <String, dynamic>{
      'lesson_id': instance.lessonId,
      'custom_name': instance.customName,
    };

BookmarkUpdateRequest _$BookmarkUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    BookmarkUpdateRequest(
      customName: json['custom_name'] as String?,
    );

Map<String, dynamic> _$BookmarkUpdateRequestToJson(
        BookmarkUpdateRequest instance) =>
    <String, dynamic>{
      'custom_name': instance.customName,
    };

BookmarkToggleResponse _$BookmarkToggleResponseFromJson(
        Map<String, dynamic> json) =>
    BookmarkToggleResponse(
      action: json['action'] as String,
      bookmark: json['bookmark'] == null
          ? null
          : Bookmark.fromJson(json['bookmark'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BookmarkToggleResponseToJson(
        BookmarkToggleResponse instance) =>
    <String, dynamic>{
      'action': instance.action,
      'bookmark': instance.bookmark,
    };
