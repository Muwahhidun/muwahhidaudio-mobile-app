import 'package:json_annotation/json_annotation.dart';
import 'theme.dart';

part 'lesson.g.dart';

/// Book Author nested model
@JsonSerializable()
class BookAuthorNested {
  final int id;
  final String name;

  BookAuthorNested({
    required this.id,
    required this.name,
  });

  factory BookAuthorNested.fromJson(Map<String, dynamic> json) =>
      _$BookAuthorNestedFromJson(json);

  Map<String, dynamic> toJson() => _$BookAuthorNestedToJson(this);
}

/// Book nested model
@JsonSerializable()
class BookNested {
  final int id;
  final String name;
  final BookAuthorNested? author;

  BookNested({
    required this.id,
    required this.name,
    this.author,
  });

  factory BookNested.fromJson(Map<String, dynamic> json) =>
      _$BookNestedFromJson(json);

  Map<String, dynamic> toJson() => _$BookNestedToJson(this);
}

/// Teacher nested model
@JsonSerializable()
class TeacherNested {
  final int id;
  final String name;

  TeacherNested({
    required this.id,
    required this.name,
  });

  factory TeacherNested.fromJson(Map<String, dynamic> json) =>
      _$TeacherNestedFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherNestedToJson(this);
}

/// Lesson Series model
@JsonSerializable()
class LessonSeries {
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
  @JsonKey(name: 'lessons_count')
  final int? lessonsCount;
  final TeacherNested? teacher;
  final BookNested? book;
  final AppThemeModel? theme;

  LessonSeries({
    required this.id,
    required this.name,
    required this.year,
    required this.displayName,
    required this.teacherId,
    this.bookId,
    this.themeId,
    required this.isActive,
    this.lessonsCount,
    this.teacher,
    this.book,
    this.theme,
  });

  factory LessonSeries.fromJson(Map<String, dynamic> json) =>
      _$LessonSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$LessonSeriesToJson(this);
}

/// Lesson Series nested (simplified)
@JsonSerializable()
class LessonSeriesNested {
  final int id;
  final String name;
  final int year;
  @JsonKey(name: 'display_name')
  final String displayName;

  LessonSeriesNested({
    required this.id,
    required this.name,
    required this.year,
    required this.displayName,
  });

  factory LessonSeriesNested.fromJson(Map<String, dynamic> json) =>
      _$LessonSeriesNestedFromJson(json);

  Map<String, dynamic> toJson() => _$LessonSeriesNestedToJson(this);
}

/// Theme nested (simplified)
@JsonSerializable()
class ThemeNested {
  final int id;
  final String name;

  ThemeNested({
    required this.id,
    required this.name,
  });

  factory ThemeNested.fromJson(Map<String, dynamic> json) =>
      _$ThemeNestedFromJson(json);

  Map<String, dynamic> toJson() => _$ThemeNestedToJson(this);
}

/// Lesson nested (simplified) - for test questions
@JsonSerializable()
class LessonNested {
  final int id;
  final String? title;
  @JsonKey(name: 'lesson_number')
  final int lessonNumber;
  @JsonKey(name: 'display_title')
  final String? displayTitle;

  LessonNested({
    required this.id,
    this.title,
    required this.lessonNumber,
    this.displayTitle,
  });

  factory LessonNested.fromJson(Map<String, dynamic> json) =>
      _$LessonNestedFromJson(json);

  Map<String, dynamic> toJson() => _$LessonNestedToJson(this);
}

/// Lesson model
@JsonSerializable()
class Lesson {
  final int id;
  final String? title;
  @JsonKey(name: 'display_title')
  final String? displayTitle;
  @JsonKey(name: 'lesson_number')
  final int lessonNumber;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 'formatted_duration')
  final String? formattedDuration;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'audio_file_path')
  final String? audioFilePath;
  final String? description;
  final String? tags;
  @JsonKey(name: 'tags_list')
  final List<String>? tagsList;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'series_id')
  final int? seriesId;
  @JsonKey(name: 'teacher_id')
  final int? teacherId;
  @JsonKey(name: 'book_id')
  final int? bookId;
  @JsonKey(name: 'theme_id')
  final int? themeId;
  final LessonSeriesNested? series;
  final TeacherNested? teacher;
  final BookNested? book;
  final ThemeNested? theme;

  Lesson({
    required this.id,
    this.title,
    this.displayTitle,
    required this.lessonNumber,
    this.durationSeconds,
    this.formattedDuration,
    this.audioUrl,
    this.audioFilePath,
    this.description,
    this.tags,
    this.tagsList,
    this.isActive,
    this.seriesId,
    this.teacherId,
    this.bookId,
    this.themeId,
    this.series,
    this.teacher,
    this.book,
    this.theme,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) =>
      _$LessonFromJson(json);

  Map<String, dynamic> toJson() => _$LessonToJson(this);
}
