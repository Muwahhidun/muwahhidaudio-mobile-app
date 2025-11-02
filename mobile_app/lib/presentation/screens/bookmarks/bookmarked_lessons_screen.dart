import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/dio_provider.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/lesson.dart';
import '../../providers/lessons_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../player/player_screen.dart';
import '../../../main.dart';
import '../../../core/logger.dart';

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
      logger.e('Error loading bookmarks: $e');
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

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Уроки'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
        children: [
          // Header
          GlassCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.library_books, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.seriesName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Нажмите на звездочку чтобы добавить/удалить из закладок',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
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
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.lessons.length,
        itemBuilder: (context, index) {
          final lesson = state.lessons[index];
          final isBookmarked = _bookmarksMap.containsKey(lesson.id);
          final bookmark = _bookmarksMap[lesson.id];

          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(16),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Lesson number avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${lesson.lessonNumber}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        // Show custom note if exists
                        if (bookmark?.customName != null && bookmark!.customName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '"${bookmark.customName}"',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (lesson.formattedDuration != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  lesson.formattedDuration!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
            ),
          );
        },
      ),
    );
  }
}
