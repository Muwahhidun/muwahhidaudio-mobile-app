// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestAttempt _$TestAttemptFromJson(Map<String, dynamic> json) => TestAttempt(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  testId: (json['test_id'] as num).toInt(),
  lessonId: (json['lesson_id'] as num?)?.toInt(),
  startedAt: DateTime.parse(json['started_at'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  score: (json['score'] as num).toInt(),
  maxScore: (json['max_score'] as num).toInt(),
  passed: json['passed'] as bool,
  answers: json['answers'] as Map<String, dynamic>?,
  timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$TestAttemptToJson(TestAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'test_id': instance.testId,
      'lesson_id': instance.lessonId,
      'started_at': instance.startedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'score': instance.score,
      'max_score': instance.maxScore,
      'passed': instance.passed,
      'answers': instance.answers,
      'time_spent_seconds': instance.timeSpentSeconds,
    };

TestAttemptSubmit _$TestAttemptSubmitFromJson(Map<String, dynamic> json) =>
    TestAttemptSubmit(
      answers: Map<String, int>.from(json['answers'] as Map),
      timeSpentSeconds: (json['time_spent_seconds'] as num).toInt(),
    );

Map<String, dynamic> _$TestAttemptSubmitToJson(TestAttemptSubmit instance) =>
    <String, dynamic>{
      'answers': instance.answers,
      'time_spent_seconds': instance.timeSpentSeconds,
    };
