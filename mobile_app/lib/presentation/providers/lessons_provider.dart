import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../data/models/lesson.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/logger.dart';

/// Lessons state
class LessonsState {
  final List<Lesson> lessons;
  final bool isLoading;
  final String? error;
  final int? seriesId;
  final bool isOfflineMode; // True if showing cached data due to network error

  LessonsState({
    this.lessons = const [],
    this.isLoading = false,
    this.error,
    this.seriesId,
    this.isOfflineMode = false,
  });

  LessonsState copyWith({
    List<Lesson>? lessons,
    bool? isLoading,
    String? error,
    int? seriesId,
    bool? isOfflineMode,
  }) {
    return LessonsState(
      lessons: lessons ?? this.lessons,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      seriesId: seriesId ?? this.seriesId,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Lessons notifier
class LessonsNotifier extends StateNotifier<LessonsState> {
  final ApiClient _apiClient;
  final DatabaseHelper _db;

  LessonsNotifier(this._apiClient, this._db) : super(LessonsState());

  /// Load lessons for a series
  /// Implements offline-first: tries API first, falls back to DOWNLOADED lessons only on network error
  Future<void> loadLessons(int seriesId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        seriesId: seriesId,
      );

      // Try to fetch from API
      final lessons = await _apiClient.getSeriesLessons(seriesId);

      state = state.copyWith(
        lessons: lessons,
        isLoading: false,
        isOfflineMode: false,
      );
    } on DioException catch (e) {
      // Network error - load ALL cached lessons for this series
      logger.w('Network error loading lessons, loading from cache: ${e.message}');
      await _loadCachedLessons(seriesId);
    } catch (e) {
      logger.e('Error loading lessons', error: e);

      // Try to load cached lessons as fallback
      final cached = await _loadCachedLessons(seriesId);
      if (!cached) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Refresh lessons
  Future<void> refresh() async {
    if (state.seriesId != null) {
      await loadLessons(state.seriesId!);
    }
  }

  /// Load ALL cached lessons for a series (including non-downloaded)
  Future<bool> _loadCachedLessons(int seriesId) async {
    try {
      final cachedData = await _db.getCachedLessonsForSeries(seriesId);

      if (cachedData.isEmpty) {
        logger.i('No cached lessons found for series $seriesId');
        state = state.copyWith(
          lessons: [],
          isLoading: false,
          error: 'Нет подключения к интернету и нет сохраненных данных',
          isOfflineMode: true,
        );
        return false;
      }

      // Convert cached data to Lesson objects
      final lessons = cachedData.map<Lesson>((data) {
        return Lesson(
          id: data['id'] as int,
          title: data['title'] as String?,
          displayTitle: data['display_title'] as String?,
          lessonNumber: data['lesson_number'] as int,
          durationSeconds: data['duration_seconds'] as int?,
          formattedDuration: data['formatted_duration'] as String?,
          audioUrl: data['audio_url'] as String?,
          audioFilePath: data['audio_file_path'] as String?,
          description: data['description'] as String?,
          tags: data['tags'] as String?,
          waveformData: data['waveform_data'] as String?,
          isActive: (data['is_active'] as int?) == 1,
          seriesId: data['series_id'] as int?,
          teacherId: data['teacher_id'] as int?,
          bookId: data['book_id'] as int?,
          themeId: data['theme_id'] as int?,
        );
      }).toList();

      // Sort lessons by lesson number
      lessons.sort((a, b) => (a.lessonNumber).compareTo(b.lessonNumber));

      logger.i('Loaded ${lessons.length} cached lessons (offline mode)');
      state = state.copyWith(
        lessons: lessons,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load cached lessons', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
    }
  }

  /// Load ONLY downloaded lessons for a series from database
  Future<bool> _loadDownloadedLessons(int seriesId) async {
    try {
      // Get downloaded lessons for this series
      final downloadedData = await _db.getDownloadedLessonsForSeries(seriesId);

      if (downloadedData.isEmpty) {
        logger.i('No downloaded lessons found for series $seriesId');
        state = state.copyWith(
          lessons: [],
          isLoading: false,
          error: 'Нет подключения к интернету и нет скачанных уроков',
          isOfflineMode: true,
        );
        return false;
      }

      // Parse lesson_data JSON from each downloaded lesson
      final lessons = <Lesson>[];
      for (final data in downloadedData) {
        try {
          final lessonJson = data['lesson_data'] as String?;
          if (lessonJson != null) {
            final lessonMap = jsonDecode(lessonJson) as Map<String, dynamic>;
            final lesson = Lesson.fromJson(lessonMap);
            lessons.add(lesson);
          }
        } catch (e) {
          logger.e('Failed to parse lesson data for lesson ${data['lesson_id']}', error: e);
        }
      }

      if (lessons.isEmpty) {
        logger.w('No valid lesson data found in downloaded lessons');
        state = state.copyWith(
          lessons: [],
          isLoading: false,
          error: 'Ошибка загрузки данных уроков',
          isOfflineMode: true,
        );
        return false;
      }

      // Sort lessons by lesson number
      lessons.sort((a, b) => (a.lessonNumber ?? 0).compareTo(b.lessonNumber ?? 0));

      logger.i('Loaded ${lessons.length} downloaded lessons from cache (offline mode)');
      state = state.copyWith(
        lessons: lessons,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load downloaded lessons', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
    }
  }
}

/// Lessons provider
final lessonsProvider = StateNotifierProvider<LessonsNotifier, LessonsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  final db = DatabaseHelper();
  return LessonsNotifier(apiClient, db);
});
