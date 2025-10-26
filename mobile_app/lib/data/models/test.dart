import 'package:json_annotation/json_annotation.dart';
import 'lesson.dart'; // For nested models

part 'test.g.dart';

/// Test model - linked to series
@JsonSerializable()
class Test {
  final int id;
  final String title;
  final String? description;
  @JsonKey(name: 'series_id')
  final int seriesId;
  @JsonKey(name: 'teacher_id')
  final int teacherId;
  @JsonKey(name: 'passing_score')
  final int passingScore;
  @JsonKey(name: 'time_per_question_seconds')
  final int timePerQuestionSeconds;
  @JsonKey(name: 'questions_count')
  final int questionsCount;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final int order;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Nested relationships
  final LessonSeriesNested? series;
  final TeacherNested? teacher;

  Test({
    required this.id,
    required this.title,
    this.description,
    required this.seriesId,
    required this.teacherId,
    required this.passingScore,
    required this.timePerQuestionSeconds,
    required this.questionsCount,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.series,
    this.teacher,
  });

  factory Test.fromJson(Map<String, dynamic> json) => _$TestFromJson(json);

  Map<String, dynamic> toJson() => _$TestToJson(this);
}

/// Test question model
@JsonSerializable()
class TestQuestion {
  final int id;
  @JsonKey(name: 'test_id')
  final int testId;
  @JsonKey(name: 'lesson_id')
  final int lessonId;
  @JsonKey(name: 'question_text')
  final String questionText;
  final List<String> options;
  @JsonKey(name: 'correct_answer_index')
  final int correctAnswerIndex;
  final String? explanation;
  final int order;
  final int points;

  // Nested lesson data
  final LessonNested? lesson;

  TestQuestion({
    required this.id,
    required this.testId,
    required this.lessonId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    required this.order,
    required this.points,
    this.lesson,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) =>
      _$TestQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$TestQuestionToJson(this);
}

/// Test create/update model for forms
@JsonSerializable()
class TestFormData {
  final String? title;
  final String? description;
  @JsonKey(name: 'series_id')
  final int seriesId;
  @JsonKey(name: 'teacher_id')
  final int teacherId;
  @JsonKey(name: 'passing_score')
  final int passingScore;
  @JsonKey(name: 'time_per_question_seconds')
  final int timePerQuestionSeconds;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final int order;

  TestFormData({
    this.title,
    this.description,
    required this.seriesId,
    required this.teacherId,
    this.passingScore = 80,
    this.timePerQuestionSeconds = 30,
    this.isActive = true,
    this.order = 0,
  });

  factory TestFormData.fromJson(Map<String, dynamic> json) =>
      _$TestFormDataFromJson(json);

  Map<String, dynamic> toJson() => _$TestFormDataToJson(this);
}

/// Test question create/update model for forms
@JsonSerializable()
class TestQuestionFormData {
  @JsonKey(name: 'test_id')
  final int testId;
  @JsonKey(name: 'lesson_id')
  final int lessonId;
  @JsonKey(name: 'question_text')
  final String questionText;
  final List<String> options;
  @JsonKey(name: 'correct_answer_index')
  final int correctAnswerIndex;
  final String? explanation;
  final int order;
  final int points;

  TestQuestionFormData({
    required this.testId,
    required this.lessonId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.order = 0,
    this.points = 1,
  });

  factory TestQuestionFormData.fromJson(Map<String, dynamic> json) =>
      _$TestQuestionFormDataFromJson(json);

  Map<String, dynamic> toJson() => _$TestQuestionFormDataToJson(this);
}
