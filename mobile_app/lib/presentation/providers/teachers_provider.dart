import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/teacher.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/logger.dart';

/// Teachers state
class TeachersState {
  final List<TeacherModel> teachers;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final bool isOfflineMode; // True if showing cached data due to network error

  TeachersState({
    this.teachers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.isOfflineMode = false,
  });

  TeachersState copyWith({
    List<TeacherModel>? teachers,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? isOfflineMode,
  }) {
    return TeachersState(
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Teachers notifier
class TeachersNotifier extends StateNotifier<TeachersState> {
  final ApiClient _apiClient;
  final DatabaseHelper _db;

  TeachersNotifier(this._apiClient, this._db) : super(TeachersState());
  // Don't auto-load - wait for explicit call from UI

  /// Load all teachers with optional search and filters
  /// Implements offline-first: tries API first, falls back to cache on network error
  Future<void> loadTeachers({
    String? search,
    int? bookId,
    int? themeId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);

      // Try to fetch from API
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
        isOfflineMode: false,
      );
    } on DioException catch (e) {
      // Network error - try to load from cache
      logger.w('Network error loading teachers, falling back to cache: ${e.message}');
      await _loadFromCache();
    } catch (e) {
      logger.e('Error loading teachers', error: e);

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

  /// Load teachers from cache (all cached teachers)
  Future<bool> _loadFromCache() async {
    try {
      final cachedData = await _db.getAllCachedTeachers();

      if (cachedData.isEmpty) {
        logger.i('No cached teachers found');
        state = state.copyWith(
          isLoading: false,
          error: 'Нет подключения к интернету и нет сохраненных лекторов',
          isOfflineMode: true,
        );
        return false;
      }

      // Convert cached data to TeacherModel objects
      final teachers = cachedData.map<TeacherModel>((data) {
        return TeacherModel(
          id: data['id'] as int,
          name: data['name'] as String,
          biography: data['biography'] as String?,
          isActive: (data['is_active'] as int?) == 1,
        );
      }).toList();

      logger.i('Loaded ${teachers.length} teachers from cache (offline mode)');
      state = state.copyWith(
        teachers: teachers,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load teachers from cache', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
    }
  }
}

/// Teachers provider
final teachersProvider = StateNotifierProvider<TeachersNotifier, TeachersState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  final db = DatabaseHelper();
  return TeachersNotifier(apiClient, db);
});
