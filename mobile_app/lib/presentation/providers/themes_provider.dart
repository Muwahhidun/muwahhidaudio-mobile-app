import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/theme.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Themes state with filters
class ThemesState {
  final List<AppThemeModel> themes;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int? teacherId;

  ThemesState({
    this.themes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.teacherId,
  });

  ThemesState copyWith({
    List<AppThemeModel>? themes,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? teacherId,
  }) {
    return ThemesState(
      themes: themes ?? this.themes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}

/// Themes notifier
class ThemesNotifier extends StateNotifier<ThemesState> {
  final ApiClient _apiClient;

  ThemesNotifier(this._apiClient) : super(ThemesState()) {
    loadThemes();
  }

  /// Load themes with optional filters
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
      final response = await _apiClient.getThemes(
        search: search,
        teacherId: teacherId,
        includeInactive: false,
        limit: 1000,
      );
      state = state.copyWith(
        themes: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
  return ThemesNotifier(apiClient);
});
