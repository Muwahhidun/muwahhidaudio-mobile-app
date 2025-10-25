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
  final int? themeFilter;
  final int? authorFilter;

  BooksState({
    this.books = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.themeFilter,
    this.authorFilter,
  });

  BooksState copyWith({
    List<BookModel>? books,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? themeFilter,
    int? authorFilter,
    bool clearFilters = false,
  }) {
    return BooksState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
      themeFilter: clearFilters ? null : (themeFilter ?? this.themeFilter),
      authorFilter: clearFilters ? null : (authorFilter ?? this.authorFilter),
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
    bool clearFilters = false,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: search,
        themeFilter: themeId,
        authorFilter: authorId,
        clearFilters: clearFilters,
      );
      final books = await _apiClient.getBooks(
        search: search,
        themeId: themeId,
        authorId: authorId,
        includeInactive: true, // Include inactive for admin management
      );
      state = state.copyWith(
        books: books,
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
    await loadBooks(
      search: query.isEmpty ? null : query,
      themeId: state.themeFilter,
      authorId: state.authorFilter,
    );
  }

  /// Filter by theme
  Future<void> filterByTheme(int? themeId) async {
    await loadBooks(
      search: state.searchQuery,
      themeId: themeId,
      authorId: state.authorFilter,
    );
  }

  /// Filter by author
  Future<void> filterByAuthor(int? authorId) async {
    await loadBooks(
      search: state.searchQuery,
      themeId: state.themeFilter,
      authorId: authorId,
    );
  }

  /// Clear all filters and search
  Future<void> clearFilters() async {
    await loadBooks(clearFilters: true);
  }

  /// Refresh books with current filters
  Future<void> refresh() async {
    await loadBooks(
      search: state.searchQuery,
      themeId: state.themeFilter,
      authorId: state.authorFilter,
    );
  }
}

/// Books provider
final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return BooksNotifier(apiClient);
});
