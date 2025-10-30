import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lesson.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/teachers_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/glass_card.dart';

class LessonFormDialog extends ConsumerStatefulWidget {
  final Lesson? lesson; // If null, create mode; if not null, edit mode

  const LessonFormDialog({super.key, this.lesson});

  @override
  ConsumerState<LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends ConsumerState<LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _lessonNumberController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  int? _selectedSeriesId;
  int? _selectedTeacherId;
  int? _selectedBookId;
  int? _selectedThemeId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isTitleManuallyEdited = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _lessonNumberController = TextEditingController(
      text: widget.lesson?.lessonNumber.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.lesson?.durationSeconds.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.lesson?.description ?? '',
    );
    _tagsController = TextEditingController(text: widget.lesson?.tags ?? '');

    // Initialize selections
    if (widget.lesson != null) {
      _selectedSeriesId = widget.lesson!.seriesId;
      _selectedTeacherId = widget.lesson!.teacherId;
      _selectedBookId = widget.lesson!.bookId;
      _selectedThemeId = widget.lesson!.themeId;
      _isActive = widget.lesson!.isActive ?? true;
      _isTitleManuallyEdited = true; // Existing lesson has manual title
    }

    // Add listener to lesson number field to regenerate title
    _lessonNumberController.addListener(() {
      if (!_isTitleManuallyEdited && _selectedSeriesId != null) {
        _generateTitle();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lessonNumberController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _updateFieldsFromSeries(int? seriesId) {
    if (seriesId == null) {
      setState(() {
        _selectedBookId = null;
        _selectedThemeId = null;
      });
      return;
    }

    final seriesState = ref.read(seriesProvider);
    final selectedSeries = seriesState.series.firstWhere(
      (s) => s.id == seriesId,
      orElse: () => seriesState.series.first,
    );

    setState(() {
      _selectedSeriesId = seriesId;
      _selectedTeacherId = selectedSeries.teacherId;
      _selectedBookId = selectedSeries.bookId;
      _selectedThemeId = selectedSeries.themeId;
    });

    // Auto-generate title if not manually edited
    if (!_isTitleManuallyEdited) {
      _generateTitle();
    }
  }

  void _generateTitle() {
    if (_selectedSeriesId == null) return;

    final seriesState = ref.read(seriesProvider);
    final teachersState = ref.read(teachersProvider);
    final booksState = ref.read(booksProvider);

    final series = seriesState.series.firstWhere(
      (s) => s.id == _selectedSeriesId,
      orElse: () => seriesState.series.first,
    );

    final teacher = teachersState.teachers.firstWhere(
      (t) => t.id == _selectedTeacherId,
      orElse: () => teachersState.teachers.first,
    );

    final book = _selectedBookId != null
        ? booksState.books.firstWhere(
            (b) => b.id == _selectedBookId,
            orElse: () => booksState.books.first,
          )
        : null;

    final lessonNumber = _lessonNumberController.text.isEmpty
        ? 'урок'
        : 'урок_${_lessonNumberController.text}';

    // Format: Преподаватель_Книга_Год_Серия_урок_N
    final parts = [
      teacher.name.replaceAll(' ', '_'),
      if (book != null) book.name.replaceAll(' ', '_'),
      series.year.toString(),
      series.name.replaceAll(' ', '_'),
      lessonNumber,
    ];

    _titleController.text = parts.join('_');
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSeriesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите серию')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());

      final lessonData = {
        'title': _titleController.text.trim(),
        'lesson_number': _lessonNumberController.text.isEmpty
            ? null
            : int.parse(_lessonNumberController.text),
        'duration_seconds': _durationController.text.isEmpty
            ? null
            : int.parse(_durationController.text),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'tags': _tagsController.text.trim().isEmpty
            ? null
            : _tagsController.text.trim(),
        'series_id': _selectedSeriesId,
        'teacher_id': _selectedTeacherId,
        'book_id': _selectedBookId,
        'theme_id': _selectedThemeId,
        'is_active': _isActive,
      };

      if (widget.lesson == null) {
        // Create mode
        await apiClient.createLesson(lessonData);
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Урок создан')),
          );
        }
      } else {
        // Edit mode
        await apiClient.updateLesson(widget.lesson!.id, lessonData);
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Урок обновлен')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesProvider);
    final teachersState = ref.watch(teachersProvider);
    final booksState = ref.watch(booksProvider);
    final themesState = ref.watch(themesProvider);

    return AlertDialog(
      title: Text(widget.lesson == null ? 'Создать урок' : 'Редактировать урок'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title field (auto-generated with manual edit option)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _titleController,
                    readOnly: !_isTitleManuallyEdited,
                    decoration: InputDecoration(
                      labelText: 'Название * (авто)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: _isTitleManuallyEdited ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isTitleManuallyEdited ? Icons.lock_open : Icons.edit,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isTitleManuallyEdited = !_isTitleManuallyEdited;
                            // Regenerate title when switching back to auto mode
                            if (!_isTitleManuallyEdited && _selectedSeriesId != null) {
                              _generateTitle();
                            }
                          });
                        },
                        tooltip: _isTitleManuallyEdited
                            ? 'Использовать автогенерацию'
                            : 'Редактировать вручную',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите название';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Lesson number field
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _lessonNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Номер урока',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(height: 16),

                // Duration field (seconds)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Длительность (секунды)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),

                // Tags field
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Теги (через запятую)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      helperText: 'Пример: акыда, таухид, основы',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Series dropdown (required)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: DropdownButtonFormField<int>(
                    value: _selectedSeriesId,
                    decoration: const InputDecoration(
                      labelText: 'Серия *',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    items: seriesState.series.map((series) {
                      return DropdownMenuItem<int>(
                        value: series.id,
                        child: Text(series.displayName ?? series.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _updateFieldsFromSeries(value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Пожалуйста, выберите серию';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Teacher dropdown (read-only, inherited from Series)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: DropdownButtonFormField<int>(
                    value: _selectedTeacherId,
                    decoration: InputDecoration(
                      labelText: 'Преподаватель (из серии)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Не выбрано'),
                      ),
                      ...teachersState.teachers.map((teacher) {
                        return DropdownMenuItem<int>(
                          value: teacher.id,
                          child: Text(teacher.name),
                        );
                      }),
                    ],
                    onChanged: null, // Disabled
                    disabledHint: Text(
                      _selectedTeacherId != null
                          ? teachersState.teachers
                              .firstWhere((t) => t.id == _selectedTeacherId,
                                  orElse: () => teachersState.teachers.first)
                              .name
                          : 'Не выбрано',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Book dropdown (read-only, inherited from Series)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: DropdownButtonFormField<int>(
                    value: _selectedBookId,
                    decoration: InputDecoration(
                      labelText: 'Книга (из серии)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Не выбрано'),
                      ),
                      ...booksState.books.map((book) {
                        return DropdownMenuItem<int>(
                          value: book.id,
                          child: Text(book.name),
                        );
                      }),
                    ],
                    onChanged: null, // Disabled
                    disabledHint: Text(
                      _selectedBookId != null
                          ? booksState.books
                              .firstWhere((b) => b.id == _selectedBookId,
                                  orElse: () => booksState.books.first)
                              .name
                          : 'Не выбрано',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Theme dropdown (read-only, inherited from Series)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: DropdownButtonFormField<int>(
                    value: _selectedThemeId,
                    decoration: InputDecoration(
                      labelText: 'Тема (из серии)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Не выбрано'),
                      ),
                      ...themesState.themes.map((theme) {
                        return DropdownMenuItem<int>(
                          value: theme.id,
                          child: Text(theme.name),
                        );
                      }),
                    ],
                    onChanged: null, // Disabled
                    disabledHint: Text(
                      _selectedThemeId != null
                          ? themesState.themes
                              .firstWhere((t) => t.id == _selectedThemeId,
                                  orElse: () => themesState.themes.first)
                              .name
                          : 'Не выбрано',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active checkbox
                CheckboxListTile(
                  title: const Text('Активно'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveLesson,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.lesson == null ? 'Создать' : 'Сохранить'),
        ),
      ],
    );
  }
}
