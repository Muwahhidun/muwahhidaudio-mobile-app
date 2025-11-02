import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/dio_provider.dart';
import '../../../data/models/bookmark.dart';
import '../../../core/audio/audio_service_web.dart';
import '../../../core/audio/audio_handler_mobile.dart';
import '../../../config/api_config.dart';
import '../../providers/lessons_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../player/player_screen.dart';
import '../tests/test_screen.dart';
import '../../../main.dart' as app;
import '../../../core/logger.dart';

/// Universal screen for showing lessons in a series
class LessonsScreen extends ConsumerStatefulWidget {
  final List<String> breadcrumbs;
  final int seriesId;

  const LessonsScreen({
    super.key,
    required this.breadcrumbs,
    required this.seriesId,
  });

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> with RouteAware {
  // Map of lesson_id -> bookmark for quick lookup
  Map<int, Bookmark> _bookmarksMap = {};

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
    app.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    app.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
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
      });
    } catch (e) {
      logger.e('Error loading bookmarks: $e');
      // Silently fail - bookmarks are not critical
    }
  }

  Future<void> _toggleBookmark(lesson) async {
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
            // Breadcrumbs
            GlassCard(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Breadcrumbs(
                path: widget.breadcrumbs,
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
    if (state.isLoading) {
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
        itemCount: state.lessons.length + 1, // +1 for series test button
        itemBuilder: (context, index) {
          // Show series test button as last item
          if (index == state.lessons.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Итоговый тест по серии',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Проверьте свои знания по всем урокам',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to series test screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TestScreen(
                              seriesId: widget.seriesId,
                              lessonId: null, // null for series test
                              breadcrumbs: widget.breadcrumbs,
                              testTitle: 'Итоговый тест',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Начать тест'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final lesson = state.lessons[index];
          final isBookmarked = _bookmarksMap.containsKey(lesson.id);
          final bookmark = _bookmarksMap[lesson.id];

          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.zero,
            onTap: () {
              // Navigate to player with full playlist
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    lesson: lesson,
                    playlist: state.lessons, // Pass all lessons as playlist
                    breadcrumbs: [...widget.breadcrumbs, lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}'],
                  ),
                ),
              ).then((_) {
                // Reload bookmarks when returning
                _loadBookmarks();
              });
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.8),
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
                ],
              ),
              subtitle: lesson.formattedDuration != null
                  ? Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.formattedDuration!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Test button (graduation cap)
                  IconButton(
                    icon: const Icon(
                      Icons.school,
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                    onPressed: () {
                      // Navigate to lesson test screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TestScreen(
                            seriesId: widget.seriesId,
                            lessonId: lesson.id, // specific lesson test
                            breadcrumbs: [...widget.breadcrumbs, lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}'],
                            testTitle: 'Тест по уроку',
                          ),
                        ),
                      );
                    },
                  ),
                  // Bookmark star button
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.star : Icons.star_border,
                      color: isBookmarked ? Colors.amber : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      size: 28,
                    ),
                    onPressed: () => _toggleBookmark(lesson),
                  ),
                  // Play/Pause button with StreamBuilder
                  if (kIsWeb)
                    StreamBuilder<bool>(
                      stream: AudioServiceWeb().player.playingStream,
                      builder: (context, playingSnapshot) {
                        final isPlaying = playingSnapshot.data ?? false;
                        final audioService = AudioServiceWeb();
                        final isCurrentLesson = audioService.currentLesson?.id == lesson.id;
                        final showPause = isCurrentLesson && isPlaying;

                        return IconButton(
                          icon: Icon(
                            showPause ? Icons.pause : Icons.play_arrow,
                            size: 32,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            if (isCurrentLesson && isPlaying) {
                              // Pause current lesson
                              await audioService.player.pause();
                            } else if (isCurrentLesson && !isPlaying) {
                              // Resume current lesson
                              await audioService.player.play();
                            } else {
                              // Start new lesson
                              await audioService.playLesson(
                                lesson: lesson,
                                playlist: state.lessons,
                              );
                            }
                            setState(() {}); // Refresh UI
                          },
                        );
                      },
                    )
                  else
                    StreamBuilder<bool>(
                      stream: (app.audioHandler as LessonAudioHandler).player.playingStream,
                      builder: (context, playingSnapshot) {
                        final isPlaying = playingSnapshot.data ?? false;
                        final handler = app.audioHandler as LessonAudioHandler;
                        final isCurrentLesson = handler.currentLesson?.id == lesson.id;
                        final showPause = isCurrentLesson && isPlaying;

                        return IconButton(
                          icon: Icon(
                            showPause ? Icons.pause : Icons.play_arrow,
                            size: 32,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            if (isCurrentLesson && isPlaying) {
                              // Pause current lesson
                              await handler.pause();
                            } else if (isCurrentLesson && !isPlaying) {
                              // Resume current lesson
                              await handler.play();
                            } else {
                              // Start new lesson
                              await handler.playLesson(
                                lesson: lesson,
                                playlist: state.lessons,
                                baseUrl: ApiConfig.baseUrl,
                              );
                            }
                            setState(() {}); // Refresh UI
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
