import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/theme.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Themes state
class ThemesState {
  final List<AppThemeModel> themes;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  ThemesState({
    this.themes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  ThemesState copyWith({
    List<AppThemeModel>? themes,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ThemesState(
      themes: themes ?? this.themes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Themes notifier
class ThemesNotifier extends StateNotifier<ThemesState> {
  final ApiClient _apiClient;

  ThemesNotifier(this._apiClient) : super(ThemesState()) {
    loadThemes();
  }

  /// Load all themes with optional search
  Future<void> loadThemes({String? search}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);
      final themes = await _apiClient.getThemes(
        search: search,
        includeInactive: true, // Include inactive for admin management
      );
      state = state.copyWith(
        themes: themes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search themes
  Future<void> search(String query) async {
    await loadThemes(search: query.isEmpty ? null : query);
  }

  /// Clear search and reload all themes
  Future<void> clearSearch() async {
    await loadThemes();
  }

  /// Refresh themes
  Future<void> refresh() async {
    await loadThemes(search: state.searchQuery);
  }
}

/// Themes provider
final themesProvider = StateNotifierProvider<ThemesNotifier, ThemesState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return ThemesNotifier(apiClient);
});
