import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lesson.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Lessons state
class LessonsState {
  final List<Lesson> lessons;
  final bool isLoading;
  final String? error;
  final int? seriesId;

  LessonsState({
    this.lessons = const [],
    this.isLoading = false,
    this.error,
    this.seriesId,
  });

  LessonsState copyWith({
    List<Lesson>? lessons,
    bool? isLoading,
    String? error,
    int? seriesId,
  }) {
    return LessonsState(
      lessons: lessons ?? this.lessons,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      seriesId: seriesId ?? this.seriesId,
    );
  }
}

/// Lessons notifier
class LessonsNotifier extends StateNotifier<LessonsState> {
  final ApiClient _apiClient;

  LessonsNotifier(this._apiClient) : super(LessonsState());

  /// Load lessons for a series
  Future<void> loadLessons(int seriesId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        seriesId: seriesId,
      );

      final lessons = await _apiClient.getSeriesLessons(seriesId);

      state = state.copyWith(
        lessons: lessons,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh lessons
  Future<void> refresh() async {
    if (state.seriesId != null) {
      await loadLessons(state.seriesId!);
    }
  }
}

/// Lessons provider
final lessonsProvider = StateNotifierProvider<LessonsNotifier, LessonsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return LessonsNotifier(apiClient);
});
