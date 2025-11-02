import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../data/models/lesson.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/teachers_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class LessonFormScreen extends ConsumerStatefulWidget {
  final Lesson? lesson; // If null, create mode; if not null, edit mode

  const LessonFormScreen({super.key, this.lesson});

  @override
  ConsumerState<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends ConsumerState<LessonFormScreen> {
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
  bool _isDurationManuallyEdited = false;

  // Audio upload state
  PlatformFile? _selectedAudioFile;
  bool _isUploadingAudio = false;
  double _uploadProgress = 0.0;
  String? _currentAudioPath;
  int? _currentDuration;
  CancelToken? _uploadCancelToken;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _lessonNumberController = TextEditingController(
      text: widget.lesson?.lessonNumber.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.lesson?.durationSeconds?.toString() ?? '',
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
      // По умолчанию заблокировано даже для существующих уроков

      // Initialize audio data if exists
      _currentAudioPath = widget.lesson!.audioFilePath;
      _currentDuration = widget.lesson!.durationSeconds;
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Урок создан')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Edit mode
        await apiClient.updateLesson(widget.lesson!.id, lessonData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Урок обновлен')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
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

  // ============================================
  // Audio Upload Functions
  // ============================================

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size (200 MB max)
        const maxSize = 200 * 1024 * 1024; // 200 MB
        if (file.size > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Файл слишком большой. Максимум 200 МБ'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedAudioFile = file;
        });

        // Show confirmation dialog
        if (mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Загрузить аудио?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Файл: ${file.name}'),
                  Text('Размер: ${(file.size / 1024 / 1024).toStringAsFixed(2)} МБ'),
                  const SizedBox(height: 16),
                  const Text(
                    'Файл будет обработан:\n'
                    '• Конвертация в MP3\n'
                    '• Mono, 64 kbps\n'
                    '• Нормализация громкости',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Загрузить'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _uploadAudio();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файла: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    if (_selectedAudioFile == null) return;
    if (widget.lesson == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сначала сохраните урок, затем загрузите аудио'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploadingAudio = true;
      _uploadProgress = 0.0;
      _uploadCancelToken = CancelToken();
    });

    try {
      final dio = DioProvider.getDio();

      // Get file bytes
      final bytes = _selectedAudioFile!.bytes;
      if (bytes == null) {
        throw Exception('Не удалось прочитать файл');
      }

      // Create multipart file
      final formData = FormData.fromMap({
        'audio_file': MultipartFile.fromBytes(
          bytes,
          filename: _selectedAudioFile!.name,
        ),
      });

      // Upload with progress tracking
      final response = await dio.post(
        '/lessons/${widget.lesson!.id}/audio',
        data: formData,
        cancelToken: _uploadCancelToken,
        onSendProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        setState(() {
          _currentAudioPath = data['processed_path'] as String?;
          _currentDuration = data['duration_seconds'] as int?;
          _selectedAudioFile = null;
          _isUploadingAudio = false;
          _uploadProgress = 0.0;

          // Update duration field only if not manually edited
          if (_currentDuration != null && !_isDurationManuallyEdited) {
            _durationController.text = _currentDuration.toString();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Аудио успешно загружено и обработано'),
              backgroundColor: Colors.green,
            ),
          );

          // Auto-save the lesson after successful audio upload
          await _saveLesson();
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingAudio = false;
        _uploadProgress = 0.0;
        _uploadCancelToken = null;
      });

      if (mounted) {
        // Check if upload was cancelled
        if (e is DioException && e.type == DioExceptionType.cancel) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Загрузка отменена'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadCancelToken = null;
        });
      }
    }
  }

  Future<void> _deleteAudio() async {
    if (widget.lesson == null || _currentAudioPath == null) return;

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аудио?'),
        content: const Text(
          'Это действие нельзя отменить.\n'
          'Будут удалены оригинальный и обработанный файлы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = DioProvider.getDio();
      await dio.delete('/lessons/${widget.lesson!.id}/audio');

      setState(() {
        _currentAudioPath = null;
        _currentDuration = null;
        // Clear duration only if not manually edited
        if (!_isDurationManuallyEdited) {
          _durationController.clear();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аудио удалено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    // If audio upload is in progress, show confirmation dialog
    if (_isUploadingAudio) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Идет загрузка аудио'),
          content: const Text('Прервать загрузку и выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Остаться'),
            ),
            TextButton(
              onPressed: () {
                // Cancel the upload
                _uploadCancelToken?.cancel('Пользователь отменил загрузку');
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Выйти'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesProvider);
    final teachersState = ref.watch(teachersProvider);
    final booksState = ref.watch(booksProvider);
    final themesState = ref.watch(themesProvider);

    return PopScope(
      canPop: !_isUploadingAudio,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(widget.lesson == null ? 'Создать урок' : 'Редактировать урок'),
            actions: [
              if (!_isLoading && !_isUploadingAudio)
                TextButton(
                  onPressed: _saveLesson,
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              if (_isLoading || _isUploadingAudio)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(height: 16),

              // Duration field (seconds) - auto-detected from audio
              GlassCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _durationController,
                  enabled: _isDurationManuallyEdited,
                  decoration: InputDecoration(
                    labelText: 'Длительность (секунды)',
                    hintText: _isDurationManuallyEdited ? 'Введите длительность' : 'Авто-определение из аудио',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    filled: !_isDurationManuallyEdited,
                    fillColor: !_isDurationManuallyEdited ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isDurationManuallyEdited ? Icons.lock_open : Icons.edit,
                        color: _isDurationManuallyEdited ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isDurationManuallyEdited = !_isDurationManuallyEdited;
                        });
                      },
                      tooltip: _isDurationManuallyEdited
                          ? 'Вернуться к авто-определению'
                          : 'Редактировать вручную',
                    ),
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
                  maxLines: 5,
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

              // Active switch
              SwitchListTile(
                title: const Text('Активно'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              // Audio Upload Section
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.audio_file, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Аудио файл',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Show upload button if no audio
                      if (_currentAudioPath == null && !_isUploadingAudio)
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: widget.lesson != null ? _pickAudioFile : null,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Выбрать аудио файл'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            if (widget.lesson == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Сначала сохраните урок',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Поддерживаемые форматы: MP3, WAV, M4A, OGG, FLAC\n'
                              'Максимальный размер: 200 МБ\n'
                              'Обработка: MP3, Mono, 64 kbps, нормализация громкости',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                      // Show upload progress
                      if (_isUploadingAudio)
                        Column(
                          children: [
                            const Text('Загрузка и обработка...'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 8,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),

                      // Show audio info if exists
                      if (_currentAudioPath != null && !_isUploadingAudio)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Аудио загружено',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Длительность: ${_formatDuration(_currentDuration)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.music_note, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('Формат: MP3, Mono, 64 kbps'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _pickAudioFile,
                                      icon: const Icon(Icons.sync, size: 18),
                                      label: const Text('Заменить'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _deleteAudio,
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Удалить'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
