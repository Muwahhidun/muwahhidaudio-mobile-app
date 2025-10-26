import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book_author.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Book Authors state
class BookAuthorsState {
  final List<BookAuthorModel> authors;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  BookAuthorsState({
    this.authors = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  BookAuthorsState copyWith({
    List<BookAuthorModel>? authors,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return BookAuthorsState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Book Authors notifier
class BookAuthorsNotifier extends StateNotifier<BookAuthorsState> {
  final ApiClient _apiClient;

  BookAuthorsNotifier(this._apiClient) : super(BookAuthorsState()) {
    loadAuthors();
  }

  /// Load all book authors with optional search
  Future<void> loadAuthors({String? search}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, searchQuery: search);
      final response = await _apiClient.getBookAuthors(
        search: search,
        includeInactive: false,
        limit: 1000,
      );
      state = state.copyWith(
        authors: response.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
}

/// Book Authors provider
final bookAuthorsProvider = StateNotifierProvider<BookAuthorsNotifier, BookAuthorsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return BookAuthorsNotifier(apiClient);
});
