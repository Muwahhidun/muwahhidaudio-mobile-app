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
  final int? birthYearFrom;
  final int? birthYearTo;
  final int? deathYearFrom;
  final int? deathYearTo;

  BookAuthorsState({
    this.authors = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.birthYearFrom,
    this.birthYearTo,
    this.deathYearFrom,
    this.deathYearTo,
  });

  BookAuthorsState copyWith({
    List<BookAuthorModel>? authors,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? birthYearFrom,
    int? birthYearTo,
    int? deathYearFrom,
    int? deathYearTo,
    bool clearFilters = false,
  }) {
    return BookAuthorsState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
      birthYearFrom: clearFilters ? null : (birthYearFrom ?? this.birthYearFrom),
      birthYearTo: clearFilters ? null : (birthYearTo ?? this.birthYearTo),
      deathYearFrom: clearFilters ? null : (deathYearFrom ?? this.deathYearFrom),
      deathYearTo: clearFilters ? null : (deathYearTo ?? this.deathYearTo),
    );
  }
}

/// Book Authors notifier
class BookAuthorsNotifier extends StateNotifier<BookAuthorsState> {
  final ApiClient _apiClient;

  BookAuthorsNotifier(this._apiClient) : super(BookAuthorsState()) {
    loadAuthors();
  }

  /// Load all book authors with current filters
  Future<void> loadAuthors({
    String? search,
    int? birthYearFrom,
    int? birthYearTo,
    int? deathYearFrom,
    int? deathYearTo,
    bool clearFilters = false,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: search,
        birthYearFrom: birthYearFrom,
        birthYearTo: birthYearTo,
        deathYearFrom: deathYearFrom,
        deathYearTo: deathYearTo,
        clearFilters: clearFilters,
      );

      final response = await _apiClient.getBookAuthors(
        search: search,
        birthYearFrom: birthYearFrom,
        birthYearTo: birthYearTo,
        deathYearFrom: deathYearFrom,
        deathYearTo: deathYearTo,
        includeInactive: true, // Include inactive for admin management
        limit: 1000, // Load all authors
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

  /// Search authors
  Future<void> search(String query) async {
    await loadAuthors(
      search: query.isEmpty ? null : query,
      birthYearFrom: state.birthYearFrom,
      birthYearTo: state.birthYearTo,
      deathYearFrom: state.deathYearFrom,
      deathYearTo: state.deathYearTo,
    );
  }

  /// Filter by birth year range
  Future<void> filterByBirthYear(int? from, int? to) async {
    await loadAuthors(
      search: state.searchQuery,
      birthYearFrom: from,
      birthYearTo: to,
      deathYearFrom: state.deathYearFrom,
      deathYearTo: state.deathYearTo,
    );
  }

  /// Filter by death year range
  Future<void> filterByDeathYear(int? from, int? to) async {
    await loadAuthors(
      search: state.searchQuery,
      birthYearFrom: state.birthYearFrom,
      birthYearTo: state.birthYearTo,
      deathYearFrom: from,
      deathYearTo: to,
    );
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await loadAuthors(clearFilters: true);
  }

  /// Refresh authors with current filters
  Future<void> refresh() async {
    await loadAuthors(
      search: state.searchQuery,
      birthYearFrom: state.birthYearFrom,
      birthYearTo: state.birthYearTo,
      deathYearFrom: state.deathYearFrom,
      deathYearTo: state.deathYearTo,
    );
  }
}

/// Book Authors provider
final bookAuthorsProvider =
    StateNotifierProvider<BookAuthorsNotifier, BookAuthorsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return BookAuthorsNotifier(apiClient);
});
