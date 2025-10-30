import 'package:json_annotation/json_annotation.dart';

part 'series_statistics.g.dart';

/// Statistics for a series
@JsonSerializable()
class SeriesStatistics {
  @JsonKey(name: 'series_id')
  final int seriesId;
  @JsonKey(name: 'total_audio_duration')
  final int totalAudioDuration; // in seconds
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'best_score_percent')
  final double? bestScorePercent;
  @JsonKey(name: 'total_attempts')
  final int totalAttempts;
  @JsonKey(name: 'passed_count')
  final int passedCount;
  @JsonKey(name: 'last_attempt_date')
  final DateTime? lastAttemptDate;
  @JsonKey(name: 'has_attempts')
  final bool hasAttempts;

  SeriesStatistics({
    required this.seriesId,
    required this.totalAudioDuration,
    required this.totalQuestions,
    this.bestScorePercent,
    required this.totalAttempts,
    required this.passedCount,
    this.lastAttemptDate,
    required this.hasAttempts,
  });

  /// Format audio duration as "XЧ YМ"
  String get formattedDuration {
    final hours = totalAudioDuration ~/ 3600;
    final minutes = (totalAudioDuration % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}ч ${minutes}м';
    } else if (hours > 0) {
      return '${hours}ч';
    } else {
      return '${minutes}м';
    }
  }

  /// Check if user has passed at least one test
  bool get hasPassed => passedCount > 0;

  factory SeriesStatistics.fromJson(Map<String, dynamic> json) =>
      _$SeriesStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesStatisticsToJson(this);
}


/// Detailed statistics for a series with series info
@JsonSerializable()
class SeriesStatisticsDetailed {
  @JsonKey(name: 'series_id')
  final int seriesId;
  @JsonKey(name: 'series_name')
  final String seriesName;
  @JsonKey(name: 'series_year')
  final int seriesYear;
  @JsonKey(name: 'book_name')
  final String? bookName;
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  @JsonKey(name: 'total_audio_duration')
  final int totalAudioDuration; // in seconds
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'best_score_percent')
  final double? bestScorePercent;
  @JsonKey(name: 'total_attempts')
  final int totalAttempts;
  @JsonKey(name: 'passed_count')
  final int passedCount;
  @JsonKey(name: 'last_attempt_date')
  final DateTime? lastAttemptDate;
  @JsonKey(name: 'has_attempts')
  final bool hasAttempts;

  SeriesStatisticsDetailed({
    required this.seriesId,
    required this.seriesName,
    required this.seriesYear,
    this.bookName,
    this.teacherName,
    required this.totalAudioDuration,
    required this.totalQuestions,
    this.bestScorePercent,
    required this.totalAttempts,
    required this.passedCount,
    this.lastAttemptDate,
    required this.hasAttempts,
  });

  /// Format audio duration as "XЧ YМ"
  String get formattedDuration {
    final hours = totalAudioDuration ~/ 3600;
    final minutes = (totalAudioDuration % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}ч ${minutes}м';
    } else if (hours > 0) {
      return '${hours}ч';
    } else {
      return '${minutes}м';
    }
  }

  /// Check if user has passed at least one test
  bool get hasPassed => passedCount > 0;

  /// Full display name with year
  String get fullName => '$seriesName ($seriesYear)';

  factory SeriesStatisticsDetailed.fromJson(Map<String, dynamic> json) =>
      _$SeriesStatisticsDetailedFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesStatisticsDetailedToJson(this);
}
