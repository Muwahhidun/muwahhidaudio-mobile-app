import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/test.dart';
import '../../../data/models/lesson.dart';
import '../../../data/api/dio_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class TestQuestionFormScreen extends ConsumerStatefulWidget {
  final int testId;
  final int seriesId;
  final TestQuestion? question;

  const TestQuestionFormScreen({
    super.key,
    required this.testId,
    required this.seriesId,
    this.question,
  });

  @override
  ConsumerState<TestQuestionFormScreen> createState() =>
      _TestQuestionFormScreenState();
}

class _TestQuestionFormScreenState
    extends ConsumerState<TestQuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;

  int? _selectedLessonId;
  int _correctAnswerIndex = 0;
  int _points = 1;

  List<Lesson> _lessons = [];
  bool _isLoadingLessons = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.question?.questionText ?? '');
    _explanationController =
        TextEditingController(text: widget.question?.explanation ?? '');

    // Initialize option controllers
    if (widget.question != null) {
      _optionControllers = widget.question!.options
          .map((option) => TextEditingController(text: option))
          .toList();
      _correctAnswerIndex = widget.question!.correctAnswerIndex ?? 0;
      _points = widget.question!.points;
      _selectedLessonId = widget.question!.lessonId;
    } else {
      // Default: 4 empty options
      _optionControllers = List.generate(
        4,
        (_) => TextEditingController(),
      );
    }

    _loadLessons();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoadingLessons = true;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get(
        '/lessons',
        queryParameters: {
          'series_id': widget.seriesId,
          'limit': 1000,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _lessons = items;
        _isLoadingLessons = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLessons = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки уроков: ${e.toString()}')),
        );
      }
    }
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        // Adjust correct answer index if needed
        if (_correctAnswerIndex >= _optionControllers.length) {
          _correctAnswerIndex = _optionControllers.length - 1;
        }
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLessonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите урок')),
      );
      return;
    }

    // Validate that all options are filled
    final options =
        _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните минимум 2 варианта ответа')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioProvider.getDio();

      final data = {
        'test_id': widget.testId,
        'lesson_id': _selectedLessonId,
        'question_text': _questionController.text.trim(),
        'options': options,
        'correct_answer_index': _correctAnswerIndex,
        'explanation': _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        'order': widget.question?.order ?? 0,
        'points': _points,
      };

      if (widget.question == null) {
        // Create new question
        await dio.post('/tests/${widget.testId}/questions', data: data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вопрос создан')),
          );
        }
      } else {
        // Update existing question
        await dio.put(
          '/tests/${widget.testId}/questions/${widget.question!.id}',
          data: data,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вопрос обновлен')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.question == null
              ? 'Новый вопрос'
              : 'Редактировать вопрос'),
          actions: [
            if (!_isLoading)
              TextButton(
                onPressed: _saveQuestion,
                child: const Text('Сохранить'),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Lesson selector
              _isLoadingLessons
                  ? const LinearProgressIndicator()
                  : GlassCard(
                      padding: EdgeInsets.zero,
                      child: DropdownButtonFormField<int>(
                        value: _selectedLessonId,
                        decoration: const InputDecoration(
                          labelText: 'Урок *',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          helperText: 'Обязательное поле',
                        ),
                        items: _lessons.map((lesson) {
                          return DropdownMenuItem<int>(
                            value: lesson.id,
                            child: Text(lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLessonId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Выберите урок';
                          }
                          return null;
                        },
                      ),
                    ),
              const SizedBox(height: 16),

              // Question text
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Текст вопроса *',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    helperText: 'Обязательное поле',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите текст вопроса';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

            // Options section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Варианты ответов',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Options list
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Radio button for correct answer
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (value) {
                        setState(() {
                          _correctAnswerIndex = value!;
                        });
                      },
                    ),
                    // Option text field
                    Expanded(
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Вариант ${index + 1}',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            filled: _correctAnswerIndex == index,
                            fillColor: _correctAnswerIndex == index
                                ? Colors.green.withAlpha(25)
                                : null,
                          ),
                          validator: (value) {
                            // At least first 2 options must be filled
                            if (index < 2 &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Обязательное поле';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    // Delete button (disabled if less than 3 options)
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeOption(index),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            Text(
              'Выберите правильный ответ, нажав на круг слева',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Explanation (optional)
            GlassCard(
              padding: EdgeInsets.zero,
              child: TextFormField(
                controller: _explanationController,
                decoration: const InputDecoration(
                  labelText: 'Пояснение (необязательно)',
                  hintText:
                      'Объяснение правильного ответа (показывается после теста)',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),

            // Points
            GlassCard(
              padding: EdgeInsets.zero,
              child: TextFormField(
                initialValue: _points.toString(),
                decoration: const InputDecoration(
                  labelText: 'Баллы за вопрос',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final points = int.tryParse(value);
                  if (points != null && points > 0) {
                    _points = points;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество баллов';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points < 1) {
                    return 'Введите число больше 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save button (duplicate at bottom for convenience)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveQuestion,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(widget.question == null
                  ? 'Создать вопрос'
                  : 'Сохранить изменения'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
