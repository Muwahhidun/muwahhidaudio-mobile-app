import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/book.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/logger.dart';

/// Books state
class BooksState {
  final List<BookModel> books;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final bool isOfflineMode; // True if showing cached data due to network error

  BooksState({
    this.books = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.isOfflineMode = false,
  });

  BooksState copyWith({
    List<BookModel>? books,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? isOfflineMode,
  }) {
    return BooksState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Books notifier
class BooksNotifier extends StateNotifier<BooksState> {
  final ApiClient _apiClient;
  final DatabaseHelper _db;

  BooksNotifier(this._apiClient, this._db) : super(BooksState());
  // Don't auto-load books - always needs themeId/authorId filter

  /// Load all books with optional search and filters
  /// Implements offline-first: tries API first, falls back to cache on network error
  Future<void> loadBooks({
    String? search,
    int? themeId,
    int? authorId,
    int? teacherId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);

      // Try to fetch from API
      final response = await _apiClient.getBooks(
        search: search,
        themeId: themeId,
        authorId: authorId,
        hasSeries: true,
        includeInactive: false,
        limit: 1000,
      );

      state = state.copyWith(
        books: response.items,
        isLoading: false,
        isOfflineMode: false,
      );
    } on DioException catch (e) {
      // Network error - try to load from cache
      logger.w('Network error loading books, falling back to cache: ${e.message}');
      await _loadFromCache(themeId: themeId, authorId: authorId);
    } catch (e) {
      logger.e('Error loading books', error: e);

      // Try cache fallback for any error
      final cached = await _loadFromCache(themeId: themeId, authorId: authorId);
      if (!cached) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Search books
  Future<void> search(String query) async {
    await loadBooks(search: query.isEmpty ? null : query);
  }

  /// Clear search and reload all books
  Future<void> clearSearch() async {
    await loadBooks();
  }

  /// Refresh books
  Future<void> refresh() async {
    await loadBooks(search: state.searchQuery);
  }

  /// Load books from cache (all cached books)
  /// Can load all books or filter by themeId
  Future<bool> _loadFromCache({
    int? themeId,
    int? authorId,
  }) async {
    try {
      final cachedData = await _db.getAllCachedBooks(themeId: themeId);

      if (cachedData.isEmpty) {
        final message = themeId != null
            ? 'No cached books found for theme $themeId'
            : 'No cached books found';
        logger.i(message);
        state = state.copyWith(
          isLoading: false,
          error: 'Нет подключения к интернету и нет сохраненных данных',
          isOfflineMode: true,
        );
        return false;
      }

      // Convert cached data to BookModel objects
      final books = cachedData.map<BookModel>((data) {
        return BookModel(
          id: data['id'] as int,
          name: data['name'] as String,
          description: data['description'] as String?,
          authorId: data['author_id'] as int?,
          themeId: data['theme_id'] as int?,
          isActive: (data['is_active'] as int?) == 1,
        );
      }).toList();

      logger.i('Loaded ${books.length} books from cache (offline mode)');
      state = state.copyWith(
        books: books,
        isLoading: false,
        isOfflineMode: true,
        error: null, // Clear error on successful cache load
      );

      return true;
    } catch (e) {
      logger.e('Failed to load books from cache', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки кэша: ${e.toString()}',
      );
      return false;
    }
  }
}

/// Books provider
final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  final db = DatabaseHelper();
  return BooksNotifier(apiClient, db);
});
