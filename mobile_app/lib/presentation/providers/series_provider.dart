import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/series.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/logger.dart';

/// Series state with filters
class SeriesState {
  final List<SeriesModel> series;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int? themeId;
  final int? bookId;
  final int? teacherId;
  final bool isOfflineMode; // True if showing cached data due to network error

  SeriesState({
    this.series = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.themeId,
    this.bookId,
    this.teacherId,
    this.isOfflineMode = false,
  });

  SeriesState copyWith({
    List<SeriesModel>? series,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? themeId,
    int? bookId,
    int? teacherId,
    bool? isOfflineMode,
  }) {
    return SeriesState(
      series: series ?? this.series,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      themeId: themeId ?? this.themeId,
      bookId: bookId ?? this.bookId,
      teacherId: teacherId ?? this.teacherId,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Series notifier with filter support
class SeriesNotifier extends StateNotifier<SeriesState> {
  final ApiClient _apiClient;
  final DatabaseHelper _db;

  SeriesNotifier(this._apiClient, this._db) : super(SeriesState());

  /// Load series with optional filters
  /// Implements offline-first: tries API first, falls back to cache on network error
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

      // Try to fetch from API
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
        isOfflineMode: false,
      );
    } on DioException catch (e) {
      // Network error - try to load from cache
      logger.w('Network error loading series, falling back to cache: ${e.message}');
      await _loadFromCache(
        themeId: themeId,
        bookId: bookId,
        teacherId: teacherId,
      );
    } catch (e) {
      logger.e('Error loading series', error: e);

      // Try cache fallback for any error
      final cached = await _loadFromCache(
        themeId: themeId,
        bookId: bookId,
        teacherId: teacherId,
      );
      if (!cached) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Load series from cache (all cached series)
  Future<bool> _loadFromCache({
    int? themeId,
    int? bookId,
    int? teacherId,
  }) async {
    try {
      final cachedData = await _db.getAllCachedSeries(
        themeId: themeId,
        bookId: bookId,
        teacherId: teacherId,
      );

      if (cachedData.isEmpty) {
        logger.i('No cached series found');
        state = state.copyWith(
          isLoading: false,
          error: 'Нет подключения к интернету и нет сохраненных данных',
          isOfflineMode: true,
        );
        return false;
      }

      // Convert cached data to SeriesModel objects
      final series = cachedData.map((data) {
        return SeriesModel(
          id: data['id'] as int,
          name: data['name'] as String,
          year: data['year'] as int,
          description: data['description'] as String?,
          teacherId: data['teacher_id'] as int,
          bookId: data['book_id'] as int?,
          themeId: data['theme_id'] as int?,
          isCompleted: (data['is_completed'] as int?) == 1,
          order: data['order'] as int? ?? 0,
          isActive: (data['is_active'] as int?) == 1,
          createdAt: data['created_at'] as String? ?? DateTime.now().toIso8601String(),
          updatedAt: data['updated_at'] as String? ?? DateTime.now().toIso8601String(),
          displayName: data['display_name'] as String?,
        );
      }).toList();

      logger.i('Loaded ${series.length} series from cache (offline mode)');
      state = state.copyWith(
        series: series,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load series from cache', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
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
  final db = DatabaseHelper();
  return SeriesNotifier(apiClient, db);
});
