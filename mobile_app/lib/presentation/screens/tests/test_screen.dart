import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/test_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/circular_timer.dart';
import '../../widgets/test_question_card.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import 'test_result_screen.dart';

/// Screen for taking a test
/// Shows one question at a time with timer and progress
class TestScreen extends ConsumerStatefulWidget {
  final int seriesId;
  final int? lessonId; // null for series test, set for lesson test
  final List<String> breadcrumbs;
  final String testTitle;

  const TestScreen({
    super.key,
    required this.seriesId,
    this.lessonId,
    required this.breadcrumbs,
    required this.testTitle,
  });

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  @override
  void initState() {
    super.initState();
    // Load and start test
    Future.microtask(() async {
      final testNotifier = ref.read(testProvider.notifier);

      // Load test (lesson or series)
      if (widget.lessonId != null) {
        await testNotifier.loadLessonTest(widget.lessonId!);
      } else {
        await testNotifier.loadSeriesTest(widget.seriesId);
      }

      // Start test attempt
      await testNotifier.startTest(lessonId: widget.lessonId);
    });
  }

  @override
  void dispose() {
    // Don't use ref in dispose - Riverpod doesn't allow it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(testProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Breadcrumbs
              Breadcrumbs(path: [...widget.breadcrumbs, widget.testTitle]),

              // Main content
              Expanded(
                child: _buildContent(testState),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildContent(TestState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Загрузка теста...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.test == null || state.currentQuestion == null) {
      return const Center(
        child: Text(
          'Тест не найден',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Show question with timer and progress
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timer
          if (state.remainingSeconds != null)
            CircularTimer(
              totalSeconds: state.test!.timePerQuestionSeconds ?? 30,
              remainingSeconds: state.remainingSeconds!,
            ),
          const SizedBox(height: 24),

          // Progress indicator
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Вопрос ${state.currentQuestionIndex + 1} из ${state.totalQuestions}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${((state.currentQuestionIndex + 1) / state.totalQuestions * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (state.currentQuestionIndex + 1) / state.totalQuestions,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          const SizedBox(height: 32),

          // Question card
          TestQuestionCard(
            question: state.currentQuestion!,
            selectedAnswer: state.selectedAnswers[state.currentQuestion!.id.toString()],
            onAnswerSelected: (index) {
              ref.read(testProvider.notifier).selectAnswer(index);
            },
            enabled: !state.isSubmitting,
          ),
          const SizedBox(height: 24),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.selectedAnswers.containsKey(state.currentQuestion!.id.toString()) &&
                      !state.isSubmitting
                  ? () async {
                      final testNotifier = ref.read(testProvider.notifier);

                      if (state.isLastQuestion) {
                        // Submit test and navigate to results
                        final result = await testNotifier.submitTest();
                        if (result != null && mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => TestResultScreen(
                                result: result,
                                breadcrumbs: widget.breadcrumbs,
                              ),
                            ),
                          );
                        }
                      } else {
                        // Move to next question
                        testNotifier.nextQuestion();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      state.isLastQuestion ? 'Завершить тест' : 'Следующий вопрос',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
