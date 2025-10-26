import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/test.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/teachers_provider.dart';
import '../../providers/books_provider.dart';

class TestFormScreen extends ConsumerStatefulWidget {
  final Test? test;

  const TestFormScreen({super.key, this.test});

  @override
  ConsumerState<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends ConsumerState<TestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _passingScoreController;
  late TextEditingController _timePerQuestionController;

  int? _selectedSeriesId;
  int? _selectedTeacherId;
  int? _selectedBookId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.test?.title ?? '');
    _descriptionController = TextEditingController(text: widget.test?.description ?? '');
    _passingScoreController = TextEditingController(
      text: widget.test?.passingScore.toString() ?? '80',
    );
    _timePerQuestionController = TextEditingController(
      text: widget.test?.timePerQuestionSeconds.toString() ?? '30',
    );

    _selectedSeriesId = widget.test?.seriesId;
    _selectedTeacherId = widget.test?.teacherId;
    _isActive = widget.test?.isActive ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize book_id from series when editing
    if (!_isInitialized && widget.test != null && _selectedSeriesId != null) {
      final seriesState = ref.read(seriesProvider);
      final series = seriesState.series.firstWhere(
        (s) => s.id == _selectedSeriesId,
        orElse: () => seriesState.series.first,
      );
      _selectedBookId = series.bookId;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingScoreController.dispose();
    _timePerQuestionController.dispose();
    super.dispose();
  }

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите преподавателя')),
      );
      return;
    }

    if (_selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите книгу')),
      );
      return;
    }

    if (_selectedSeriesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите серию')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioProvider.getDio();

      final data = {
        'title': _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'series_id': _selectedSeriesId,
        'teacher_id': _selectedTeacherId,
        'passing_score': int.parse(_passingScoreController.text),
        'time_per_question_seconds': int.parse(_timePerQuestionController.text),
        'is_active': _isActive,
        'order': widget.test?.order ?? 0,
      };

      if (widget.test == null) {
        // Create new test
        await dio.post('/tests', data: data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Тест создан')),
          );
        }
      } else {
        // Update existing test
        await dio.put('/tests/${widget.test!.id}', data: data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Тест обновлен')),
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
    final seriesState = ref.watch(seriesProvider);
    final teachersState = ref.watch(teachersProvider);
    final booksState = ref.watch(booksProvider);

    // Filter books by selected teacher
    final availableBooks = _selectedTeacherId == null
        ? <dynamic>[]
        : seriesState.series
            .where((s) => s.teacherId == _selectedTeacherId)
            .map((s) => s.bookId)
            .toSet()
            .map((bookId) => booksState.books.firstWhere((b) => b.id == bookId))
            .toList();

    // Filter series by selected teacher and book
    final availableSeries = (_selectedTeacherId == null || _selectedBookId == null)
        ? <dynamic>[]
        : seriesState.series
            .where((s) => s.teacherId == _selectedTeacherId && s.bookId == _selectedBookId)
            .toList();

    // Calculate safe values for dropdowns
    final safeBookId = _selectedBookId != null && availableBooks.any((b) => b.id == _selectedBookId)
        ? _selectedBookId
        : null;

    final safeSeriesId = _selectedSeriesId != null && availableSeries.any((s) => s.id == _selectedSeriesId)
        ? _selectedSeriesId
        : null;

    // Reset invalid values after build
    if (safeBookId != _selectedBookId || safeSeriesId != _selectedSeriesId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            if (safeBookId != _selectedBookId) {
              _selectedBookId = safeBookId;
              _selectedSeriesId = null;
            } else if (safeSeriesId != _selectedSeriesId) {
              _selectedSeriesId = safeSeriesId;
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test == null ? 'Новый тест' : 'Редактировать тест'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveTest,
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
            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Оставьте название пустым для автогенерации из серии и книги',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Teacher selector (always enabled)
            DropdownButtonFormField<int>(
              value: _selectedTeacherId,
              decoration: const InputDecoration(
                labelText: 'Преподаватель *',
                border: OutlineInputBorder(),
                helperText: 'Обязательное поле',
              ),
              items: teachersState.teachers.map((teacher) {
                return DropdownMenuItem<int>(
                  value: teacher.id,
                  child: Text(teacher.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTeacherId = value;
                  // Reset dependent fields
                  _selectedBookId = null;
                  _selectedSeriesId = null;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Выберите преподавателя';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Book selector (disabled until teacher is selected)
            DropdownButtonFormField<int>(
              value: safeBookId,
              decoration: InputDecoration(
                labelText: 'Книга *',
                border: const OutlineInputBorder(),
                helperText: 'Обязательное поле',
                enabled: _selectedTeacherId != null,
              ),
              items: availableBooks.map((book) {
                return DropdownMenuItem<int>(
                  value: book.id,
                  child: Text(book.name),
                );
              }).toList(),
              onChanged: _selectedTeacherId == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedBookId = value;
                        // Reset series when book changes
                        _selectedSeriesId = null;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Выберите книгу';
                }
                return null;
              },
              disabledHint: const Text('Сначала выберите преподавателя'),
            ),
            const SizedBox(height: 16),

            // Series selector (disabled until teacher and book are selected)
            DropdownButtonFormField<int>(
              value: safeSeriesId,
              decoration: InputDecoration(
                labelText: 'Серия *',
                border: const OutlineInputBorder(),
                helperText: 'Обязательное поле',
                enabled: _selectedTeacherId != null && _selectedBookId != null,
              ),
              items: availableSeries.map((series) {
                return DropdownMenuItem<int>(
                  value: series.id,
                  child: Text(series.displayName ?? series.name),
                );
              }).toList(),
              onChanged: (_selectedTeacherId == null || _selectedBookId == null)
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSeriesId = value;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Выберите серию';
                }
                return null;
              },
              disabledHint: const Text('Сначала выберите преподавателя и книгу'),
            ),
            const SizedBox(height: 16),

            // Title (optional - auto-generated if empty)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название теста',
                hintText: 'Авто: "Тест по \'{книга}\' - {серия}"',
                border: OutlineInputBorder(),
                helperText: 'Необязательно - будет сгенерировано автоматически',
              ),
              maxLines: 2,
              maxLength: 255,
            ),
            const SizedBox(height: 16),

            // Description (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Дополнительная информация о тесте',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Passing score
            TextFormField(
              controller: _passingScoreController,
              decoration: const InputDecoration(
                labelText: 'Проходной балл (%)',
                border: OutlineInputBorder(),
                helperText: 'Минимальный процент правильных ответов для прохождения',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите проходной балл';
                }
                final score = int.tryParse(value);
                if (score == null || score < 0 || score > 100) {
                  return 'Введите число от 0 до 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Time per question
            TextFormField(
              controller: _timePerQuestionController,
              decoration: const InputDecoration(
                labelText: 'Время на вопрос (секунды)',
                border: OutlineInputBorder(),
                helperText: 'Время, отведенное на каждый вопрос',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите время на вопрос';
                }
                final time = int.tryParse(value);
                if (time == null || time < 1) {
                  return 'Введите число больше 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Active status
            SwitchListTile(
              title: const Text('Активен'),
              subtitle: const Text('Тест доступен пользователям'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Save button (duplicate at bottom for convenience)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveTest,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(widget.test == null ? 'Создать тест' : 'Сохранить изменения'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
