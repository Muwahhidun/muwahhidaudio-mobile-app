// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeriesStatistics _$SeriesStatisticsFromJson(Map<String, dynamic> json) =>
    SeriesStatistics(
      seriesId: (json['series_id'] as num).toInt(),
      totalAudioDuration: (json['total_audio_duration'] as num).toInt(),
      totalQuestions: (json['total_questions'] as num).toInt(),
      bestScorePercent: (json['best_score_percent'] as num?)?.toDouble(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
      passedCount: (json['passed_count'] as num).toInt(),
      lastAttemptDate: json['last_attempt_date'] == null
          ? null
          : DateTime.parse(json['last_attempt_date'] as String),
      hasAttempts: json['has_attempts'] as bool,
    );

Map<String, dynamic> _$SeriesStatisticsToJson(SeriesStatistics instance) =>
    <String, dynamic>{
      'series_id': instance.seriesId,
      'total_audio_duration': instance.totalAudioDuration,
      'total_questions': instance.totalQuestions,
      'best_score_percent': instance.bestScorePercent,
      'total_attempts': instance.totalAttempts,
      'passed_count': instance.passedCount,
      'last_attempt_date': instance.lastAttemptDate?.toIso8601String(),
      'has_attempts': instance.hasAttempts,
    };

SeriesStatisticsDetailed _$SeriesStatisticsDetailedFromJson(
        Map<String, dynamic> json) =>
    SeriesStatisticsDetailed(
      seriesId: (json['series_id'] as num).toInt(),
      seriesName: json['series_name'] as String,
      seriesYear: (json['series_year'] as num).toInt(),
      bookName: json['book_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      totalAudioDuration: (json['total_audio_duration'] as num).toInt(),
      totalQuestions: (json['total_questions'] as num).toInt(),
      bestScorePercent: (json['best_score_percent'] as num?)?.toDouble(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
      passedCount: (json['passed_count'] as num).toInt(),
      lastAttemptDate: json['last_attempt_date'] == null
          ? null
          : DateTime.parse(json['last_attempt_date'] as String),
      hasAttempts: json['has_attempts'] as bool,
    );

Map<String, dynamic> _$SeriesStatisticsDetailedToJson(
        SeriesStatisticsDetailed instance) =>
    <String, dynamic>{
      'series_id': instance.seriesId,
      'series_name': instance.seriesName,
      'series_year': instance.seriesYear,
      'book_name': instance.bookName,
      'teacher_name': instance.teacherName,
      'total_audio_duration': instance.totalAudioDuration,
      'total_questions': instance.totalQuestions,
      'best_score_percent': instance.bestScorePercent,
      'total_attempts': instance.totalAttempts,
      'passed_count': instance.passedCount,
      'last_attempt_date': instance.lastAttemptDate?.toIso8601String(),
      'has_attempts': instance.hasAttempts,
    };
