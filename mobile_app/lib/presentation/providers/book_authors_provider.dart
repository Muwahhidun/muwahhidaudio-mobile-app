import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/book_author.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/logger.dart';

/// Book Authors state
class BookAuthorsState {
  final List<BookAuthorModel> authors;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final bool isOfflineMode; // True if showing cached data due to network error

  BookAuthorsState({
    this.authors = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.isOfflineMode = false,
  });

  BookAuthorsState copyWith({
    List<BookAuthorModel>? authors,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? isOfflineMode,
  }) {
    return BookAuthorsState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Book Authors notifier
class BookAuthorsNotifier extends StateNotifier<BookAuthorsState> {
  final ApiClient _apiClient;
  final DatabaseHelper _db;

  BookAuthorsNotifier(this._apiClient, this._db) : super(BookAuthorsState());
  // Don't auto-load - wait for explicit call from UI

  /// Load all book authors with optional search
  /// Implements offline-first: tries API first, falls back to cache on network error
  Future<void> loadAuthors({String? search}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);

      // Try to fetch from API
      final response = await _apiClient.getBookAuthors(
        search: search,
        hasSeries: true,
        includeInactive: false,
        limit: 1000,
      );

      state = state.copyWith(
        authors: response.items,
        isLoading: false,
        isOfflineMode: false,
      );
    } on DioException catch (e) {
      // Network error - try to load from cache
      logger.w('Network error loading book authors, falling back to cache: ${e.message}');
      await _loadFromCache();
    } catch (e) {
      logger.e('Error loading book authors', error: e);

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

  /// Search book authors
  Future<void> search(String query) async {
    await loadAuthors(search: query.isEmpty ? null : query);
  }

  /// Clear search and reload all book authors
  Future<void> clearSearch() async {
    await loadAuthors();
  }

  /// Refresh book authors
  Future<void> refresh() async {
    await loadAuthors(search: state.searchQuery);
  }

  /// Load book authors from cache (all cached authors)
  Future<bool> _loadFromCache() async {
    try {
      final cachedData = await _db.getAllCachedBookAuthors();

      if (cachedData.isEmpty) {
        logger.i('No cached book authors found');
        state = state.copyWith(
          isLoading: false,
          error: 'Нет подключения к интернету и нет сохраненных авторов',
          isOfflineMode: true,
        );
        return false;
      }

      // Convert cached data to BookAuthorModel objects
      final authors = cachedData.map<BookAuthorModel>((data) {
        return BookAuthorModel(
          id: data['id'] as int,
          name: data['name'] as String,
          biography: data['biography'] as String?,
          birthYear: data['birth_year'] as int?,
          deathYear: data['death_year'] as int?,
          isActive: (data['is_active'] as int?) == 1,
        );
      }).toList();

      logger.i('Loaded ${authors.length} book authors from cache (offline mode)');
      state = state.copyWith(
        authors: authors,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load book authors from cache', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
    }
  }
}

/// Book Authors provider
final bookAuthorsProvider = StateNotifierProvider<BookAuthorsNotifier, BookAuthorsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  final db = DatabaseHelper();
  return BookAuthorsNotifier(apiClient, db);
});
