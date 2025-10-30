import 'package:json_annotation/json_annotation.dart';

part 'test_attempt.g.dart';

/// Test attempt model - user's attempt at taking a test
@JsonSerializable()
class TestAttempt {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'test_id')
  final int testId;
  @JsonKey(name: 'lesson_id')
  final int? lessonId;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final int score;
  @JsonKey(name: 'max_score')
  final int maxScore;
  final bool passed;
  final Map<String, dynamic>? answers;
  @JsonKey(name: 'time_spent_seconds')
  final int? timeSpentSeconds;

  TestAttempt({
    required this.id,
    required this.userId,
    required this.testId,
    this.lessonId,
    required this.startedAt,
    this.completedAt,
    required this.score,
    required this.maxScore,
    required this.passed,
    this.answers,
    this.timeSpentSeconds,
  });

  /// Calculate score percentage
  double get scorePercent => maxScore > 0 ? (score / maxScore * 100) : 0.0;

  /// Check if attempt is completed
  bool get isCompleted => completedAt != null;

  factory TestAttempt.fromJson(Map<String, dynamic> json) => _$TestAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$TestAttemptToJson(this);
}


/// Test attempt submission model
@JsonSerializable()
class TestAttemptSubmit {
  final Map<String, int> answers; // question_id -> answer_index
  @JsonKey(name: 'time_spent_seconds')
  final int timeSpentSeconds;

  TestAttemptSubmit({
    required this.answers,
    required this.timeSpentSeconds,
  });

  factory TestAttemptSubmit.fromJson(Map<String, dynamic> json) =>
      _$TestAttemptSubmitFromJson(json);

  Map<String, dynamic> toJson() => _$TestAttemptSubmitToJson(this);
}
