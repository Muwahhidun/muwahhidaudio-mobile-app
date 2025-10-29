import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/teacher.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Teachers state
class TeachersState {
  final List<TeacherModel> teachers;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  TeachersState({
    this.teachers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  TeachersState copyWith({
    List<TeacherModel>? teachers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return TeachersState(
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Teachers notifier
class TeachersNotifier extends StateNotifier<TeachersState> {
  final ApiClient _apiClient;

  TeachersNotifier(this._apiClient) : super(TeachersState()) {
    loadTeachers();
  }

  /// Load all teachers with optional search and filters
  Future<void> loadTeachers({
    String? search,
    int? bookId,
    int? themeId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);
      final response = await _apiClient.getTeachers(
        search: search,
        bookId: bookId,
        themeId: themeId,
        hasSeries: true,
        includeInactive: false,
        limit: 1000,
      );
      state = state.copyWith(
        teachers: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search teachers
  Future<void> search(String query) async {
    await loadTeachers(search: query.isEmpty ? null : query);
  }

  /// Clear search and reload all teachers
  Future<void> clearSearch() async {
    await loadTeachers();
  }

  /// Refresh teachers
  Future<void> refresh() async {
    await loadTeachers(search: state.searchQuery);
  }
}

/// Teachers provider
final teachersProvider = StateNotifierProvider<TeachersNotifier, TeachersState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return TeachersNotifier(apiClient);
});
