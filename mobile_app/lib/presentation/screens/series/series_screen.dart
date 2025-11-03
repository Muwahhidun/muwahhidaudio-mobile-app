import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/series_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/lessons_provider.dart';
import '../../providers/download_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../lessons/lessons_screen.dart';
import '../../../core/logger.dart';

/// Universal screen for showing lesson series
/// Works for all navigation paths
class SeriesScreen extends ConsumerStatefulWidget {
  final List<String> breadcrumbs;
  final int? themeId;
  final int? bookId;
  final int? teacherId;

  const SeriesScreen({
    super.key,
    required this.breadcrumbs,
    this.themeId,
    this.bookId,
    this.teacherId,
  });

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  // Track download state for each series
  final Map<int, bool> _downloadingSeriesMap = {};
  // Track lesson IDs for each series to check download status
  final Map<int, List<int>> _seriesLessonIds = {};

  @override
  void initState() {
    super.initState();
    // Load series with filters
    Future.microtask(() async {
      await ref
          .read(seriesProvider.notifier)
          .setFilters(
            themeId: widget.themeId,
            bookId: widget.bookId,
            teacherId: widget.teacherId,
          );

      // Load lesson IDs for all series to show correct download status
      await _loadSeriesLessonIds();
    });
  }

  /// Load lesson IDs for all series to check download status
  Future<void> _loadSeriesLessonIds() async {
    final seriesState = ref.read(seriesProvider);

    for (final series in seriesState.series) {
      try {
        // Load lessons for this series
        await ref.read(lessonsProvider.notifier).loadLessons(series.id);
        final lessonsState = ref.read(lessonsProvider);

        if (lessonsState.lessons.isNotEmpty) {
          _seriesLessonIds[series.id] = lessonsState.lessons.map((l) => l.id).toList();
        }
      } catch (e) {
        logger.e('Failed to load lesson IDs for series ${series.id}', error: e);
      }
    }

    // Trigger UI rebuild to show correct download status
    if (mounted) {
      setState(() {});
    }
  }

  /// Download entire series
  Future<void> _downloadSeries(int seriesId) async {
    try {
      setState(() {
        _downloadingSeriesMap[seriesId] = true;
      });

      logger.i('Loading lessons for series $seriesId');

      // Get series model from state
      final seriesState = ref.read(seriesProvider);
      final series = seriesState.series.firstWhere(
        (s) => s.id == seriesId,
        orElse: () => throw Exception('Series not found in state'),
      );

      // First, load lessons for this series
      await ref.read(lessonsProvider.notifier).loadLessons(seriesId);
      final lessonsState = ref.read(lessonsProvider);

      if (lessonsState.lessons.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет уроков для скачивания')),
          );
        }
        return;
      }

      // Save lesson IDs for this series to track download status
      _seriesLessonIds[seriesId] = lessonsState.lessons.map((l) => l.id).toList();

      logger.i('Starting download for ${lessonsState.lessons.length} lessons');

      // Download all lessons with series metadata
      await ref.read(downloadProvider.notifier).downloadSeries(lessonsState.lessons, series);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Серия скачана (${lessonsState.lessons.length} уроков)')),
        );
      }
    } catch (e) {
      logger.e('Failed to download series', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingSeriesMap[seriesId] = false;
        });
      }
    }
  }

  /// Delete series downloads
  Future<void> _deleteSeriesDownloads(int seriesId) async {
    try {
      logger.i('Deleting downloads for series $seriesId');

      // Use saved lesson IDs if available, otherwise load lessons
      List<int> lessonIds = _seriesLessonIds[seriesId] ?? [];

      if (lessonIds.isEmpty) {
        // Load lessons for this series
        await ref.read(lessonsProvider.notifier).loadLessons(seriesId);
        final lessonsState = ref.read(lessonsProvider);

        if (lessonsState.lessons.isEmpty) {
          return;
        }

        lessonIds = lessonsState.lessons.map((l) => l.id).toList();
        _seriesLessonIds[seriesId] = lessonIds;
      }

      // Delete all lesson downloads
      final downloadNotifier = ref.read(downloadProvider.notifier);
      for (final lessonId in lessonIds) {
        if (downloadNotifier.isLessonDownloaded(lessonId)) {
          await downloadNotifier.deleteDownload(lessonId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Загрузки удалены')),
        );

        // Refresh UI
        setState(() {});
      }
    } catch (e) {
      logger.e('Failed to delete series downloads', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Серии уроков'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Breadcrumbs
            GlassCard(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Breadcrumbs(path: widget.breadcrumbs),
            ),

            // Series list
            Expanded(child: _buildSeriesList(seriesState)),
          ],
        ),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }

  Widget _buildSeriesList(SeriesState state) {
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
                ref.read(seriesProvider.notifier).refresh();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.series.isEmpty) {
      return const Center(child: Text('Серий не найдено'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(seriesProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: state.series.length,
        itemBuilder: (context, index) {
          final series = state.series[index];

          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.zero,
            onTap: () {
              // Navigate to lessons
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonsScreen(
                    breadcrumbs: [
                      ...widget.breadcrumbs,
                      series.displayName ?? series.name,
                    ],
                    seriesId: series.id,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.library_books, color: Colors.blue, size: 32),
                  ),
                  title: Text(
                    series.displayName ?? series.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (series.teacher != null)
                        Text(
                          'Лектор: ${series.teacher!.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (series.book != null)
                        Text(
                          'Книга: ${series.book!.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSeriesDownloadButton(series.id),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),

                // Statistics row
                Consumer(
                  builder: (context, ref, child) {
                    final statsAsync = ref.watch(seriesStatisticsProvider(series.id));

                    return statsAsync.when(
                      data: (stats) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.access_time,
                              stats.formattedDuration,
                              Colors.blue,
                            ),
                            _buildStatItem(
                              Icons.quiz,
                              '${stats.totalQuestions} вопр.',
                              Colors.orange,
                            ),
                            if (stats.hasAttempts) ...{
                              _buildStatItem(
                                Icons.star,
                                '${stats.bestScorePercent?.toStringAsFixed(0) ?? 0}%',
                                Colors.amber,
                              ),
                              Icon(
                                stats.hasPassed ? Icons.check_circle : Icons.cancel,
                                color: stats.hasPassed ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            } else
                              _buildStatItem(
                                Icons.pending,
                                'Не пройдено',
                                Colors.grey,
                              ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build download button for series
  Widget _buildSeriesDownloadButton(int seriesId) {
    return Consumer(
      builder: (context, ref, child) {
        // Check if series is being downloaded
        final isDownloading = _downloadingSeriesMap[seriesId] ?? false;

        if (isDownloading) {
          // Show loading indicator
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // Check download status if we have lesson IDs for this series
        final lessonIds = _seriesLessonIds[seriesId];
        if (lessonIds != null && lessonIds.isNotEmpty) {
          final downloadState = ref.watch(downloadProvider);
          final downloadedCount = lessonIds.where((id) =>
            downloadState.downloadedLessons[id] == true
          ).length;

          if (downloadedCount == lessonIds.length) {
            // All lessons downloaded - show done icon
            return IconButton(
              icon: const Icon(
                Icons.download_done,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () => _showDeleteSeriesDialog(seriesId),
            );
          } else if (downloadedCount > 0) {
            // Partially downloaded - show badge with count
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () => _downloadSeries(seriesId),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$downloadedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }
        }

        // Not downloaded - show download button
        return IconButton(
          icon: Icon(
            Icons.download,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
            size: 20,
          ),
          onPressed: () => _downloadSeries(seriesId),
        );
      },
    );
  }

  /// Show dialog to confirm series deletion
  Future<void> _showDeleteSeriesDialog(int seriesId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить загрузки'),
        content: const Text('Удалить все скачанные уроки этой серии?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSeriesDownloads(seriesId);
    }
  }
}
