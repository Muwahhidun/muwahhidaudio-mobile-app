import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/series.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Series state with filters
class SeriesState {
  final List<SeriesModel> series;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int? themeId;
  final int? bookId;
  final int? teacherId;

  SeriesState({
    this.series = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.themeId,
    this.bookId,
    this.teacherId,
  });

  SeriesState copyWith({
    List<SeriesModel>? series,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? themeId,
    int? bookId,
    int? teacherId,
  }) {
    return SeriesState(
      series: series ?? this.series,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      themeId: themeId ?? this.themeId,
      bookId: bookId ?? this.bookId,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}

/// Series notifier with filter support
class SeriesNotifier extends StateNotifier<SeriesState> {
  final ApiClient _apiClient;

  SeriesNotifier(this._apiClient) : super(SeriesState());

  /// Load series with optional filters
  Future<void> loadSeries({
    String? search,
    int? themeId,
    int? bookId,
    int? teacherId,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: search,
        themeId: themeId,
        bookId: bookId,
        teacherId: teacherId,
      );

      final response = await _apiClient.getSeries(
        search: search,
        themeId: themeId,
        bookId: bookId,
        teacherId: teacherId,
        includeInactive: false,
        limit: 1000,
      );

      state = state.copyWith(
        series: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search series with current filters
  Future<void> search(String query) async {
    await loadSeries(
      search: query.isEmpty ? null : query,
      themeId: state.themeId,
      bookId: state.bookId,
      teacherId: state.teacherId,
    );
  }

  /// Clear search and reload with current filters
  Future<void> clearSearch() async {
    await loadSeries(
      themeId: state.themeId,
      bookId: state.bookId,
      teacherId: state.teacherId,
    );
  }

  /// Refresh series with current filters and search
  Future<void> refresh() async {
    await loadSeries(
      search: state.searchQuery,
      themeId: state.themeId,
      bookId: state.bookId,
      teacherId: state.teacherId,
    );
  }

  /// Set filters and load
  Future<void> setFilters({
    int? themeId,
    int? bookId,
    int? teacherId,
  }) async {
    await loadSeries(
      themeId: themeId,
      bookId: bookId,
      teacherId: teacherId,
    );
  }
}

/// Series provider
final seriesProvider = StateNotifierProvider<SeriesNotifier, SeriesState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return SeriesNotifier(apiClient);
});
