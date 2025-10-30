import 'package:flutter/material.dart';
import '../../../data/models/test_attempt.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/breadcrumbs.dart';

/// Screen showing test results after completion
class TestResultScreen extends StatelessWidget {
  final TestAttempt result;
  final List<String> breadcrumbs;

  const TestResultScreen({
    super.key,
    required this.result,
    required this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    final isPassed = result.passed;
    final scorePercent = result.scorePercent;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Breadcrumbs
              Breadcrumbs(path: [...breadcrumbs, 'Результат']),

              // Results content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: GlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Result icon
                            Icon(
                              isPassed ? Icons.celebration : Icons.close_rounded,
                              size: 100,
                              color: isPassed ? Colors.green : Colors.red,
                            ),
                            const SizedBox(height: 24),

                            // Result text
                            Text(
                              isPassed ? 'Поздравляем!' : 'Попробуйте еще раз',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPassed
                                  ? 'Вы успешно прошли тест'
                                  : 'К сожалению, тест не пройден',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // Score display
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPassed
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.red.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${scorePercent.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: isPassed ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ваш результат',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Details
                            _buildDetailRow(
                              Icons.check_circle_outline,
                              'Правильных ответов',
                              '${result.score} из ${result.maxScore}',
                            ),
                            const SizedBox(height: 16),
                            if (result.timeSpentSeconds != null)
                              _buildDetailRow(
                                Icons.access_time,
                                'Затрачено времени',
                                _formatDuration(result.timeSpentSeconds!),
                              ),
                            const SizedBox(height: 40),

                            // Action buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Try again button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Pop twice to go back to lessons/series screen
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Попробовать снова',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Back button
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // Pop twice to go back to lessons/series screen
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text(
                                    'Вернуться к урокам',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes мин $secs сек';
    }
    return '$secs сек';
  }
}
