import 'package:json_annotation/json_annotation.dart';
import 'lesson.dart';

part 'bookmark.g.dart';

/// Bookmark model
@JsonSerializable()
class Bookmark {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'lesson_id')
  final int lessonId;
  @JsonKey(name: 'custom_name')
  final String? customName;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final Lesson? lesson;

  Bookmark({
    required this.id,
    required this.userId,
    required this.lessonId,
    this.customName,
    required this.createdAt,
    required this.updatedAt,
    this.lesson,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) =>
      _$BookmarkFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkToJson(this);
}

/// Series with bookmarks count
@JsonSerializable()
class SeriesWithBookmarks {
  final int id;
  final String name;
  final int year;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'teacher_id')
  final int teacherId;
  @JsonKey(name: 'book_id')
  final int? bookId;
  @JsonKey(name: 'theme_id')
  final int? themeId;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  final String? description;
  final int order;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final TeacherNested? teacher;
  final BookNested? book;
  @JsonKey(name: 'bookmarks_count')
  final int bookmarksCount;

  SeriesWithBookmarks({
    required this.id,
    required this.name,
    required this.year,
    required this.displayName,
    required this.teacherId,
    this.bookId,
    this.themeId,
    required this.isActive,
    required this.isCompleted,
    this.description,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.teacher,
    this.book,
    required this.bookmarksCount,
  });

  factory SeriesWithBookmarks.fromJson(Map<String, dynamic> json) =>
      _$SeriesWithBookmarksFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesWithBookmarksToJson(this);
}

/// Request for creating bookmark
@JsonSerializable()
class BookmarkCreateRequest {
  @JsonKey(name: 'lesson_id')
  final int lessonId;
  @JsonKey(name: 'custom_name')
  final String? customName;

  BookmarkCreateRequest({
    required this.lessonId,
    this.customName,
  });

  factory BookmarkCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$BookmarkCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkCreateRequestToJson(this);
}

/// Request for updating bookmark
@JsonSerializable()
class BookmarkUpdateRequest {
  @JsonKey(name: 'custom_name')
  final String? customName;

  BookmarkUpdateRequest({
    this.customName,
  });

  factory BookmarkUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$BookmarkUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkUpdateRequestToJson(this);
}

/// Toggle bookmark response
@JsonSerializable()
class BookmarkToggleResponse {
  final String action; // "added" or "removed"
  final Bookmark? bookmark;

  BookmarkToggleResponse({
    required this.action,
    this.bookmark,
  });

  factory BookmarkToggleResponse.fromJson(Map<String, dynamic> json) =>
      _$BookmarkToggleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkToggleResponseToJson(this);
}
