import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/dio_provider.dart';
import '../../data/api/api_client.dart';
import '../../data/models/test.dart';
import '../../data/models/test_attempt.dart';
import '../../core/logger.dart';

/// State for test taking
class TestState {
  final Test? test;
  final TestAttempt? currentAttempt;
  final int currentQuestionIndex;
  final Map<String, int> selectedAnswers; // question_id -> answer_index
  final int? remainingSeconds;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;

  TestState({
    this.test,
    this.currentAttempt,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.remainingSeconds,
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
  });

  TestState copyWith({
    Test? test,
    TestAttempt? currentAttempt,
    int? currentQuestionIndex,
    Map<String, int>? selectedAnswers,
    int? remainingSeconds,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
  }) {
    return TestState(
      test: test ?? this.test,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  TestQuestion? get currentQuestion {
    if (test == null || test!.questions == null || test!.questions!.isEmpty) return null;
    if (currentQuestionIndex >= test!.questions!.length) return null;
    return test!.questions![currentQuestionIndex];
  }

  bool get isLastQuestion {
    if (test == null || test!.questions == null) return false;
    return currentQuestionIndex >= test!.questions!.length - 1;
  }

  int get totalQuestions => test?.questions?.length ?? 0;
}

/// Notifier for managing test state
class TestNotifier extends StateNotifier<TestState> {
  final ApiClient _apiClient;
  Timer? _timer;
  DateTime? _startTime;

  TestNotifier(this._apiClient) : super(TestState());

  /// Load test for a series
  Future<void> loadSeriesTest(int seriesId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final test = await _apiClient.getSeriesTest(seriesId);
      state = state.copyWith(
        test: test,
        isLoading: false,
        currentQuestionIndex: 0,
        selectedAnswers: {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load test for a specific lesson
  Future<void> loadLessonTest(int lessonId) async {
    logger.d('[TEST_PROVIDER] Loading test for lesson $lessonId');
    state = state.copyWith(isLoading: true, error: null);
    try {
      logger.d('[TEST_PROVIDER] Calling API...');
      final test = await _apiClient.getLessonTest(lessonId);
      logger.d('[TEST_PROVIDER] API response received');
      logger.d('[TEST_PROVIDER] Test ID: ${test.id}, Title: ${test.title}');
      logger.d('[TEST_PROVIDER] timePerQuestionSeconds: ${test.timePerQuestionSeconds}');
      logger.d('[TEST_PROVIDER] passingScore: ${test.passingScore}');
      logger.d('[TEST_PROVIDER] Questions count: ${test.questions?.length}');

      logger.d('[TEST_PROVIDER] Updating state...');
      state = state.copyWith(
        test: test,
        isLoading: false,
        currentQuestionIndex: 0,
        selectedAnswers: {},
      );
      logger.d('[TEST_PROVIDER] State updated successfully');
    } catch (e, stackTrace) {
      logger.e('[TEST_PROVIDER] Error loading test: $e');
      logger.e('[TEST_PROVIDER] Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start a test attempt
  Future<void> startTest({int? lessonId}) async {
    if (state.test == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final attempt = await _apiClient.startTest(state.test!.id, lessonId);
      _startTime = DateTime.now();
      state = state.copyWith(
        currentAttempt: attempt,
        isLoading: false,
        currentQuestionIndex: 0,
        selectedAnswers: {},
      );
      _startQuestionTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start timer for current question
  void _startQuestionTimer() {
    _timer?.cancel();

    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null || state.test == null) return;

    state = state.copyWith(
      remainingSeconds: state.test!.timePerQuestionSeconds ?? 30,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.remainingSeconds;
      if (remaining == null || remaining <= 0) {
        timer.cancel();
        // Time's up - treat as wrong answer and move to next
        nextQuestion();
      } else {
        state = state.copyWith(remainingSeconds: remaining - 1);
      }
    });
  }

  /// Select an answer for the current question
  void selectAnswer(int answerIndex) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    final newAnswers = Map<String, int>.from(state.selectedAnswers);
    newAnswers[currentQuestion.id.toString()] = answerIndex;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  /// Move to next question
  void nextQuestion() {
    _timer?.cancel();

    if (state.isLastQuestion) {
      // This was the last question, submit the test
      submitTest();
    } else {
      // Move to next question
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
      _startQuestionTimer();
    }
  }

  /// Submit the test
  Future<TestAttempt?> submitTest() async {
    _timer?.cancel();

    if (state.currentAttempt == null) return null;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final timeSpent = _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds
          : 0;

      final submission = TestAttemptSubmit(
        answers: state.selectedAnswers,
        timeSpentSeconds: timeSpent,
      );

      final result = await _apiClient.submitTestAttempt(
        state.currentAttempt!.id,
        submission,
      );

      state = state.copyWith(isSubmitting: false);
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  /// Reset test state
  void reset() {
    _timer?.cancel();
    _startTime = null;
    state = TestState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for test state
final testProvider = StateNotifierProvider<TestNotifier, TestState>((ref) {
  final dio = DioProvider.getDio();
  final apiClient = ApiClient(dio);
  return TestNotifier(apiClient);
});
