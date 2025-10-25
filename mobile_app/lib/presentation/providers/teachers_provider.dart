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
    bool clearFilters = false,
  }) {
    return TeachersState(
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Teachers notifier
class TeachersNotifier extends StateNotifier<TeachersState> {
  final ApiClient _apiClient;

  TeachersNotifier(this._apiClient) : super(TeachersState()) {
    loadTeachers();
  }

  /// Load all teachers with optional search
  Future<void> loadTeachers({
    String? search,
    bool clearFilters = false,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: search,
        clearFilters: clearFilters,
      );
      final teachers = await _apiClient.getTeachers(
        search: search,
        includeInactive: true, // Include inactive for admin management
      );
      state = state.copyWith(
        teachers: teachers,
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

  /// Clear all filters and search
  Future<void> clearFilters() async {
    await loadTeachers(clearFilters: true);
  }

  /// Refresh teachers with current filters
  Future<void> refresh() async {
    await loadTeachers(search: state.searchQuery);
  }
}

/// Teachers provider
final teachersProvider =
    StateNotifierProvider<TeachersNotifier, TeachersState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return TeachersNotifier(apiClient);
});
