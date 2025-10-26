// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Test _$TestFromJson(Map<String, dynamic> json) => Test(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      seriesId: (json['series_id'] as num).toInt(),
      teacherId: (json['teacher_id'] as num).toInt(),
      passingScore: (json['passing_score'] as num).toInt(),
      timePerQuestionSeconds:
          (json['time_per_question_seconds'] as num).toInt(),
      questionsCount: (json['questions_count'] as num).toInt(),
      isActive: json['is_active'] as bool,
      order: (json['order'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      series: json['series'] == null
          ? null
          : LessonSeriesNested.fromJson(json['series'] as Map<String, dynamic>),
      teacher: json['teacher'] == null
          ? null
          : TeacherNested.fromJson(json['teacher'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TestToJson(Test instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'series_id': instance.seriesId,
      'teacher_id': instance.teacherId,
      'passing_score': instance.passingScore,
      'time_per_question_seconds': instance.timePerQuestionSeconds,
      'questions_count': instance.questionsCount,
      'is_active': instance.isActive,
      'order': instance.order,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'series': instance.series,
      'teacher': instance.teacher,
    };

TestQuestion _$TestQuestionFromJson(Map<String, dynamic> json) => TestQuestion(
      id: (json['id'] as num).toInt(),
      testId: (json['test_id'] as num).toInt(),
      lessonId: (json['lesson_id'] as num).toInt(),
      questionText: json['question_text'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswerIndex: (json['correct_answer_index'] as num).toInt(),
      explanation: json['explanation'] as String?,
      order: (json['order'] as num).toInt(),
      points: (json['points'] as num).toInt(),
      lesson: json['lesson'] == null
          ? null
          : LessonNested.fromJson(json['lesson'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TestQuestionToJson(TestQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'test_id': instance.testId,
      'lesson_id': instance.lessonId,
      'question_text': instance.questionText,
      'options': instance.options,
      'correct_answer_index': instance.correctAnswerIndex,
      'explanation': instance.explanation,
      'order': instance.order,
      'points': instance.points,
      'lesson': instance.lesson,
    };

TestFormData _$TestFormDataFromJson(Map<String, dynamic> json) => TestFormData(
      title: json['title'] as String?,
      description: json['description'] as String?,
      seriesId: (json['series_id'] as num).toInt(),
      teacherId: (json['teacher_id'] as num).toInt(),
      passingScore: (json['passing_score'] as num?)?.toInt() ?? 80,
      timePerQuestionSeconds:
          (json['time_per_question_seconds'] as num?)?.toInt() ?? 30,
      isActive: json['is_active'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TestFormDataToJson(TestFormData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'series_id': instance.seriesId,
      'teacher_id': instance.teacherId,
      'passing_score': instance.passingScore,
      'time_per_question_seconds': instance.timePerQuestionSeconds,
      'is_active': instance.isActive,
      'order': instance.order,
    };

TestQuestionFormData _$TestQuestionFormDataFromJson(
        Map<String, dynamic> json) =>
    TestQuestionFormData(
      testId: (json['test_id'] as num).toInt(),
      lessonId: (json['lesson_id'] as num).toInt(),
      questionText: json['question_text'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswerIndex: (json['correct_answer_index'] as num).toInt(),
      explanation: json['explanation'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$TestQuestionFormDataToJson(
        TestQuestionFormData instance) =>
    <String, dynamic>{
      'test_id': instance.testId,
      'lesson_id': instance.lessonId,
      'question_text': instance.questionText,
      'options': instance.options,
      'correct_answer_index': instance.correctAnswerIndex,
      'explanation': instance.explanation,
      'order': instance.order,
      'points': instance.points,
    };
