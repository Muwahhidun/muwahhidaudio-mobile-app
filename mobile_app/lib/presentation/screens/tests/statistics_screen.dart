import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';

/// Screen showing overall test statistics for all series
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(allStatisticsProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Breadcrumbs
              const Breadcrumbs(path: ['Главная', 'Статистика']),

              // Statistics content
              Expanded(
                child: statisticsAsync.when(
                  data: (stats) => _buildStatisticsList(stats),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (error, stack) => Center(
                    child: GlassCard(
                      margin: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Ошибка загрузки',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(allStatisticsProvider);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Повторить'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildStatisticsList(List stats) {
    if (stats.isEmpty) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assessment_outlined, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Нет статистики',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Пройдите хотя бы один тест,\nчтобы увидеть статистику',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh statistics
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Series name and year
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.seriesName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (stat.bookName != null)
                            Text(
                              stat.bookName!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${stat.seriesYear} г. • ${stat.teacherName ?? ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pass/fail indicator
                    Icon(
                      stat.hasPassed ? Icons.check_circle : Icons.cancel,
                      color: stat.hasPassed ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Statistics grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        Icons.access_time,
                        stat.formattedDuration,
                        'Длительность',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        Icons.quiz,
                        '${stat.totalQuestions}',
                        'Вопросов',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        Icons.star,
                        stat.hasAttempts
                            ? '${stat.bestScorePercent?.toStringAsFixed(0) ?? 0}%'
                            : '—',
                        'Лучший результат',
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        Icons.replay,
                        '${stat.totalAttempts}',
                        'Попыток',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),

                // Last attempt date
                if (stat.lastAttemptDate != null) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Последняя попытка: ${_formatDate(stat.lastAttemptDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}
