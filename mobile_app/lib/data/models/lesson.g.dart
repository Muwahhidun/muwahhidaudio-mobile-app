// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookAuthorNested _$BookAuthorNestedFromJson(Map<String, dynamic> json) =>
    BookAuthorNested(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$BookAuthorNestedToJson(BookAuthorNested instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

BookNested _$BookNestedFromJson(Map<String, dynamic> json) => BookNested(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  author: json['author'] == null
      ? null
      : BookAuthorNested.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BookNestedToJson(BookNested instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
    };

TeacherNested _$TeacherNestedFromJson(Map<String, dynamic> json) =>
    TeacherNested(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$TeacherNestedToJson(TeacherNested instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LessonSeries _$LessonSeriesFromJson(Map<String, dynamic> json) => LessonSeries(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  year: (json['year'] as num).toInt(),
  displayName: json['display_name'] as String,
  teacherId: (json['teacher_id'] as num).toInt(),
  bookId: (json['book_id'] as num?)?.toInt(),
  themeId: (json['theme_id'] as num?)?.toInt(),
  isActive: json['is_active'] as bool,
  lessonsCount: (json['lessons_count'] as num?)?.toInt(),
  teacher: json['teacher'] == null
      ? null
      : TeacherNested.fromJson(json['teacher'] as Map<String, dynamic>),
  book: json['book'] == null
      ? null
      : BookNested.fromJson(json['book'] as Map<String, dynamic>),
  theme: json['theme'] == null
      ? null
      : AppThemeModel.fromJson(json['theme'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LessonSeriesToJson(LessonSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'year': instance.year,
      'display_name': instance.displayName,
      'teacher_id': instance.teacherId,
      'book_id': instance.bookId,
      'theme_id': instance.themeId,
      'is_active': instance.isActive,
      'lessons_count': instance.lessonsCount,
      'teacher': instance.teacher,
      'book': instance.book,
      'theme': instance.theme,
    };

LessonSeriesNested _$LessonSeriesNestedFromJson(Map<String, dynamic> json) =>
    LessonSeriesNested(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      year: (json['year'] as num).toInt(),
      displayName: json['display_name'] as String,
    );

Map<String, dynamic> _$LessonSeriesNestedToJson(LessonSeriesNested instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'year': instance.year,
      'display_name': instance.displayName,
    };

ThemeNested _$ThemeNestedFromJson(Map<String, dynamic> json) =>
    ThemeNested(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$ThemeNestedToJson(ThemeNested instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LessonNested _$LessonNestedFromJson(Map<String, dynamic> json) => LessonNested(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String?,
  lessonNumber: (json['lesson_number'] as num).toInt(),
  displayTitle: json['display_title'] as String?,
);

Map<String, dynamic> _$LessonNestedToJson(LessonNested instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'lesson_number': instance.lessonNumber,
      'display_title': instance.displayTitle,
    };

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String?,
  displayTitle: json['display_title'] as String?,
  lessonNumber: (json['lesson_number'] as num).toInt(),
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  formattedDuration: json['formatted_duration'] as String?,
  audioUrl: json['audio_url'] as String?,
  audioFilePath: json['audio_file_path'] as String?,
  description: json['description'] as String?,
  tags: json['tags'] as String?,
  tagsList: (json['tags_list'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  waveformData: json['waveform_data'] as String?,
  isActive: json['is_active'] as bool?,
  seriesId: (json['series_id'] as num?)?.toInt(),
  teacherId: (json['teacher_id'] as num?)?.toInt(),
  bookId: (json['book_id'] as num?)?.toInt(),
  themeId: (json['theme_id'] as num?)?.toInt(),
  series: json['series'] == null
      ? null
      : LessonSeriesNested.fromJson(json['series'] as Map<String, dynamic>),
  teacher: json['teacher'] == null
      ? null
      : TeacherNested.fromJson(json['teacher'] as Map<String, dynamic>),
  book: json['book'] == null
      ? null
      : BookNested.fromJson(json['book'] as Map<String, dynamic>),
  theme: json['theme'] == null
      ? null
      : ThemeNested.fromJson(json['theme'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'display_title': instance.displayTitle,
  'lesson_number': instance.lessonNumber,
  'duration_seconds': instance.durationSeconds,
  'formatted_duration': instance.formattedDuration,
  'audio_url': instance.audioUrl,
  'audio_file_path': instance.audioFilePath,
  'description': instance.description,
  'tags': instance.tags,
  'tags_list': instance.tagsList,
  'waveform_data': instance.waveformData,
  'is_active': instance.isActive,
  'series_id': instance.seriesId,
  'teacher_id': instance.teacherId,
  'book_id': instance.bookId,
  'theme_id': instance.themeId,
  'series': instance.series,
  'teacher': instance.teacher,
  'book': instance.book,
  'theme': instance.theme,
};
