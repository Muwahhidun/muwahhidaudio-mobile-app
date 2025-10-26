import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Books state
class BooksState {
  final List<BookModel> books;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  BooksState({
    this.books = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  BooksState copyWith({
    List<BookModel>? books,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return BooksState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Books notifier
class BooksNotifier extends StateNotifier<BooksState> {
  final ApiClient _apiClient;

  BooksNotifier(this._apiClient) : super(BooksState()) {
    loadBooks();
  }

  /// Load all books with optional search and filters
  Future<void> loadBooks({
    String? search,
    int? themeId,
    int? authorId,
    int? teacherId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);
      final response = await _apiClient.getBooks(
        search: search,
        themeId: themeId,
        authorId: authorId,
        includeInactive: false,
        limit: 1000,
      );
      state = state.copyWith(
        books: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
}

/// Books provider
final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return BooksNotifier(apiClient);
});
