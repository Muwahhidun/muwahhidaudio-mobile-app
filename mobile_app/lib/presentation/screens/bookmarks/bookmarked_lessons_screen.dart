import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/dio_provider.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/lesson.dart';
import '../../providers/lessons_provider.dart';
import '../../widgets/mini_player.dart';
import '../player/player_screen.dart';
import '../../../main.dart';

/// Screen showing all lessons in a series with bookmark indicators
class BookmarkedLessonsScreen extends ConsumerStatefulWidget {
  final int seriesId;
  final String seriesName;

  const BookmarkedLessonsScreen({
    super.key,
    required this.seriesId,
    required this.seriesName,
  });

  @override
  ConsumerState<BookmarkedLessonsScreen> createState() =>
      _BookmarkedLessonsScreenState();
}

class _BookmarkedLessonsScreenState
    extends ConsumerState<BookmarkedLessonsScreen> with RouteAware {
  // Map of lesson_id -> bookmark for quick lookup
  Map<int, Bookmark> _bookmarksMap = {};
  bool _loadingBookmarks = false;

  @override
  void initState() {
    super.initState();
    // Load lessons for this series
    Future.microtask(() {
      ref.read(lessonsProvider.notifier).loadLessons(widget.seriesId);
      _loadBookmarks();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loadingBookmarks = true;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/bookmarks/series/${widget.seriesId}');

      final bookmarks = (response.data as List).map((e) {
        final data = e as Map<String, dynamic>;
        // Remove the nested lesson object to avoid parsing issues
        data.remove('lesson');
        return Bookmark.fromJson(data);
      }).toList();

      setState(() {
        _bookmarksMap = {for (var b in bookmarks) b.lessonId: b};
        _loadingBookmarks = false;
      });
    } catch (e) {
      print('Error loading bookmarks: $e');
      setState(() {
        _loadingBookmarks = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки закладок: $e')),
        );
      }
    }
  }

  Future<void> _toggleBookmark(Lesson lesson) async {
    try {
      final dio = DioProvider.getDio();
      final response = await dio.post(
        '/bookmarks/toggle',
        data: {
          'lesson_id': lesson.id,
          'custom_name': null,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final action = data['action'] as String;

      setState(() {
        if (action == 'added') {
          final bookmark = Bookmark.fromJson(data['bookmark'] as Map<String, dynamic>);
          _bookmarksMap[lesson.id] = bookmark;
        } else {
          _bookmarksMap.remove(lesson.id);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'added'
                  ? 'Добавлено в закладки'
                  : 'Удалено из закладок',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsState = ref.watch(lessonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уроки'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.seriesName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Нажмите на звездочку чтобы добавить/удалить из закладок',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // Lessons list
          Expanded(
            child: _buildLessonsList(lessonsState),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildLessonsList(LessonsState state) {
    if (state.isLoading || _loadingBookmarks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(lessonsProvider.notifier).refresh();
                _loadBookmarks();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.lessons.isEmpty) {
      return const Center(
        child: Text('Уроков не найдено'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(lessonsProvider.notifier).refresh();
        await _loadBookmarks();
      },
      child: ListView.builder(
        itemCount: state.lessons.length,
        itemBuilder: (context, index) {
          final lesson = state.lessons[index];
          final isBookmarked = _bookmarksMap.containsKey(lesson.id);
          final bookmark = _bookmarksMap[lesson.id];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  '${lesson.lessonNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Show custom note if exists
                  if (bookmark?.customName != null && bookmark!.customName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '"${bookmark.customName}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: lesson.formattedDuration != null
                  ? Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(lesson.formattedDuration!),
                      ],
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bookmark star button
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.star : Icons.star_border,
                      color: isBookmarked ? Colors.amber : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => _toggleBookmark(lesson),
                  ),
                  // Play button
                  const Icon(Icons.play_arrow, size: 32, color: Colors.green),
                ],
              ),
              onTap: () {
                // Navigate to player with full playlist
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      lesson: lesson,
                      playlist: state.lessons,
                      breadcrumbs: [
                        'Закладки',
                        widget.seriesName,
                        lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}',
                      ],
                    ),
                  ),
                ).then((_) {
                  // Reload bookmarks when returning (might have changed)
                  _loadBookmarks();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
