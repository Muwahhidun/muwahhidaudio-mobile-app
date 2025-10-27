import 'package:flutter/material.dart';
import '../../../data/api/dio_provider.dart';
import '../../../data/models/bookmark.dart';
import '../../widgets/mini_player.dart';
import 'bookmarked_lessons_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<SeriesWithBookmarks> _series = [];
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedSeries();
  }

  Future<void> _loadBookmarkedSeries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/bookmarks/series', queryParameters: {
        'skip': _currentPage * _itemsPerPage,
        'limit': _itemsPerPage,
      });

      final data = response.data as Map<String, dynamic>;
      setState(() {
        _series = (data['items'] as List)
            .map((e) => SeriesWithBookmarks.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalItems = data['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _totalItems) {
      setState(() {
        _currentPage++;
      });
      _loadBookmarkedSeries();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadBookmarkedSeries();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Закладки'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              'Серии с закладками',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // Series list
          Expanded(
            child: _buildSeriesList(),
          ),

          // Pagination controls
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Страница ${_currentPage + 1} из $_totalPages',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: (_currentPage + 1) * _itemsPerPage < _totalItems
                        ? _nextPage
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildSeriesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookmarkedSeries,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_series.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет закладок',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте уроки из плеера или библиотеки',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadBookmarkedSeries();
      },
      child: ListView.builder(
        itemCount: _series.length,
        itemBuilder: (context, index) {
          final series = _series[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.library_books, color: Colors.blue, size: 32),
              title: Text(
                series.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (series.teacher != null)
                    Text('Лектор: ${series.teacher!.name}'),
                  if (series.book != null)
                    Text('Книга: ${series.book!.name}'),
                  const SizedBox(height: 4),
                  Text(
                    '${series.bookmarksCount} ${_pluralUrok(series.bookmarksCount)} в закладках',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to bookmarked lessons
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookmarkedLessonsScreen(
                      seriesId: series.id,
                      seriesName: series.displayName,
                    ),
                  ),
                ).then((_) {
                  // Reload when returning (in case bookmarks were changed)
                  _loadBookmarkedSeries();
                });
              },
            ),
          );
        },
      ),
    );
  }

  String _pluralUrok(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'урок';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'урока';
    } else {
      return 'уроков';
    }
  }
}
