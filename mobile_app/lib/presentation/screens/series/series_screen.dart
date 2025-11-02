import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/series_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../lessons/lessons_screen.dart';

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
  @override
  void initState() {
    super.initState();
    // Load series with filters
    Future.microtask(() {
      ref
          .read(seriesProvider.notifier)
          .setFilters(
            themeId: widget.themeId,
            bookId: widget.bookId,
            teacherId: widget.teacherId,
          );
    });
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
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
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
                            if (stats.hasAttempts) ...[
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
                            ] else
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
}
