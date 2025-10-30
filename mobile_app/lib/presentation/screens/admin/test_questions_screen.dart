import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/test.dart';
import '../../../data/api/dio_provider.dart';
import '../../../core/constants/app_icons.dart';
import 'test_question_form_screen.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class TestQuestionsScreen extends ConsumerStatefulWidget {
  final Test test;

  const TestQuestionsScreen({super.key, required this.test});

  @override
  ConsumerState<TestQuestionsScreen> createState() =>
      _TestQuestionsScreenState();
}

class _TestQuestionsScreenState extends ConsumerState<TestQuestionsScreen> {
  List<TestQuestion> _questions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get(
        '/tests/${widget.test.id}/questions',
        queryParameters: {
          'limit': 1000, // Load all questions
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _questions = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuestion(int questionId) async {
    try {
      final dio = DioProvider.getDio();
      await dio.delete('/tests/${widget.test.id}/questions/$questionId');
      _loadQuestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вопрос удален')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  // Group questions by lesson
  Map<int, List<TestQuestion>> get _groupedQuestions {
    final Map<int, List<TestQuestion>> grouped = {};
    for (final question in _questions) {
      grouped.putIfAbsent(question.lessonId, () => []).add(question);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedQuestions = _groupedQuestions;
    final lessonIds = groupedQuestions.keys.toList()..sort();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Вопросы теста'),
              Text(
                widget.test.title,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Добавить вопрос',
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestQuestionFormScreen(
                      testId: widget.test.id,
                      seriesId: widget.test.seriesId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadQuestions();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
          // Test info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(AppIcons.test, color: AppIcons.testColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Серия: ${widget.test.series?.displayName ?? "N/A"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Преподаватель: ${widget.test.teacher?.name ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Всего вопросов: ${_questions.length} | Проходной балл: ${widget.test.passingScore}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Questions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ошибка: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadQuestions,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _questions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Вопросы не найдены',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TestQuestionFormScreen(
                                          testId: widget.test.id,
                                          seriesId: widget.test.seriesId,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadQuestions();
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Добавить первый вопрос'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: lessonIds.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, groupIndex) {
                              final lessonId = lessonIds[groupIndex];
                              final questions = groupedQuestions[lessonId]!;
                              final lesson = questions.first.lesson;

                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Lesson header
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppIcons.lessonColor.withAlpha(25),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            AppIcons.lesson,
                                            size: 20,
                                            color: AppIcons.lessonColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              lesson?.displayTitle ??
                                                  lesson?.title ??
                                                  'Урок #$lessonId',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${questions.length} вопр.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Questions in this lesson
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: questions.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final question = questions[index];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.withAlpha(50),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            question.questionText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            'Вариантов: ${question.options.length} | Баллов: ${question.points}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 20),
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push<
                                                          bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TestQuestionFormScreen(
                                                        testId: widget.test.id,
                                                        seriesId:
                                                            widget.test.seriesId,
                                                        question: question,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    _loadQuestions();
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 20),
                                                color: Colors.red,
                                                onPressed: () async {
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          'Подтверждение'),
                                                      content: const Text(
                                                          'Удалить этот вопрос?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              'Отмена'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context, true),
                                                          child: const Text(
                                                              'Удалить'),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    _deleteQuestion(
                                                        question.id);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      ),
    );
  }
}
