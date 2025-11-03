import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/theme.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/logger.dart';

/// Themes state with filters
class ThemesState {
  final List<AppThemeModel> themes;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int? teacherId;
  final bool isOfflineMode; // True if showing cached data due to network error

  ThemesState({
    this.themes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.teacherId,
    this.isOfflineMode = false,
  });

  ThemesState copyWith({
    List<AppThemeModel>? themes,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? teacherId,
    bool? isOfflineMode,
  }) {
    return ThemesState(
      themes: themes ?? this.themes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      teacherId: teacherId ?? this.teacherId,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Themes notifier
class ThemesNotifier extends StateNotifier<ThemesState> {
  final ApiClient _apiClient;
  final DatabaseHelper _db;

  ThemesNotifier(this._apiClient, this._db) : super(ThemesState()) {
    loadThemes();
  }

  /// Load themes with optional filters
  /// Implements offline-first: tries API first, falls back to cache on network error
  Future<void> loadThemes({
    String? search,
    int? teacherId,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: search,
        teacherId: teacherId,
      );

      // Try to fetch from API
      final response = await _apiClient.getThemes(
        search: search,
        teacherId: teacherId,
        hasSeries: true,
        includeInactive: false,
        limit: 1000,
      );

      state = state.copyWith(
        themes: response.items,
        isLoading: false,
        isOfflineMode: false,
      );
    } on DioException catch (e) {
      // Network error - try to load from cache
      logger.w('Network error loading themes, falling back to cache: ${e.message}');
      await _loadFromCache();
    } catch (e) {
      logger.e('Error loading themes', error: e);

      // Try cache fallback for any error
      final cached = await _loadFromCache();
      if (!cached) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Load themes from cache (all cached themes)
  Future<bool> _loadFromCache() async {
    try {
      final cachedData = await _db.getAllCachedThemes();

      if (cachedData.isEmpty) {
        logger.i('No cached themes found');
        state = state.copyWith(
          isLoading: false,
          error: 'Нет подключения к интернету и нет сохраненных данных',
          isOfflineMode: true,
        );
        return false;
      }

      // Convert cached data to AppThemeModel objects
      final themes = cachedData.map<AppThemeModel>((data) {
        return AppThemeModel(
          id: data['id'] as int,
          name: data['name'] as String,
          description: data['description'] as String?,
          isActive: (data['is_active'] as int?) == 1,
          seriesCount: null, // Series count not available in cache
        );
      }).toList();

      logger.i('Loaded ${themes.length} themes from cache (offline mode)');
      state = state.copyWith(
        themes: themes,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load from cache', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
    }
  }

  /// Search themes with current filters
  Future<void> search(String query) async {
    await loadThemes(
      search: query.isEmpty ? null : query,
      teacherId: state.teacherId,
    );
  }

  /// Clear search and reload with current filters
  Future<void> clearSearch() async {
    await loadThemes(
      teacherId: state.teacherId,
    );
  }

  /// Refresh themes with current filters and search
  Future<void> refresh() async {
    await loadThemes(
      search: state.searchQuery,
      teacherId: state.teacherId,
    );
  }

  /// Set filters and load
  Future<void> setFilters({
    int? teacherId,
  }) async {
    await loadThemes(
      teacherId: teacherId,
    );
  }
}

/// Themes provider
final themesProvider = StateNotifierProvider<ThemesNotifier, ThemesState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  final db = DatabaseHelper();
  return ThemesNotifier(apiClient, db);
});
