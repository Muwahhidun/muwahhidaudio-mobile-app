import 'package:flutter/material.dart';
import '../../../data/models/series.dart';
import '../../../data/models/teacher.dart';
import '../../../data/models/book.dart';
import '../../../data/models/theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';

class SeriesManagementScreen extends StatefulWidget {
  const SeriesManagementScreen({super.key});

  @override
  State<SeriesManagementScreen> createState() => _SeriesManagementScreenState();
}

class _SeriesManagementScreenState extends State<SeriesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // Data lists
  List<SeriesModel> _series = [];
  List<TeacherModel> _teachers = [];
  List<BookModel> _books = [];
  List<AppThemeModel> _themes = [];

  // State
  bool _isLoading = false;
  String? _error;

  // Filters
  int? _selectedTeacherId;
  int? _selectedBookId;
  int? _selectedThemeId;
  int? _selectedYear;
  bool? _selectedIsCompleted;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTeachers(),
      _loadBooks(),
      _loadThemes(),
    ]);
    await _loadSeries();
  }

  Future<void> _loadTeachers() async {
    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/teachers', queryParameters: {
        'include_inactive': true,
        'limit': 1000,
      });
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _teachers = (data['items'] as List)
            .map((e) => TeacherModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  Future<void> _loadBooks() async {
    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/books', queryParameters: {
        'include_inactive': true,
        'limit': 1000,
      });
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _books = (data['items'] as List)
            .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  Future<void> _loadThemes() async {
    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/themes', queryParameters: {
        'include_inactive': true,
        'limit': 1000,
      });
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _themes = (data['items'] as List)
            .map((e) => AppThemeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading themes: $e');
    }
  }

  Future<void> _loadSeries({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/series', queryParameters: {
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
        if (_selectedTeacherId != null) 'teacher_id': _selectedTeacherId,
        if (_selectedBookId != null) 'book_id': _selectedBookId,
        if (_selectedThemeId != null) 'theme_id': _selectedThemeId,
        if (_selectedYear != null) 'year': _selectedYear,
        if (_selectedIsCompleted != null) 'is_completed': _selectedIsCompleted,
        'include_inactive': true,
        'skip': _currentPage * _itemsPerPage,
        'limit': _itemsPerPage,
      });

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => SeriesModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      setState(() {
        _series = items;
        _totalItems = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _totalItems) {
      setState(() {
        _currentPage++;
      });
      _loadSeries();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadSeries();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _yearController.clear();
      _selectedTeacherId = null;
      _selectedBookId = null;
      _selectedThemeId = null;
      _selectedYear = null;
      _selectedIsCompleted = null;
    });
    _loadSeries(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление сериями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSeriesDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field with clear filters button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Поиск по названию или описанию',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                    _loadSeries(resetPage: true);
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (_) {
                          _loadSeries(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Сброс'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filters row
                Row(
                  children: [
                    // Teacher filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Преподаватель',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Все'),
                          ),
                          ..._teachers.map((teacher) {
                            return DropdownMenuItem<int>(
                              value: teacher.id,
                              child: Text(teacher.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTeacherId = value;
                          });
                          _loadSeries(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Book filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedBookId,
                        decoration: const InputDecoration(
                          labelText: 'Книга',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Все'),
                          ),
                          ..._books.map((book) {
                            return DropdownMenuItem<int>(
                              value: book.id,
                              child: Text(book.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBookId = value;
                          });
                          _loadSeries(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Theme filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedThemeId,
                        decoration: const InputDecoration(
                          labelText: 'Тема',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Все'),
                          ),
                          ..._themes.map((theme) {
                            return DropdownMenuItem<int>(
                              value: theme.id,
                              child: Text(theme.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedThemeId = value;
                          });
                          _loadSeries(resetPage: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Year and completion filter row
                Row(
                  children: [
                    // Year filter
                    Expanded(
                      child: TextField(
                        controller: _yearController,
                        decoration: InputDecoration(
                          labelText: 'Год',
                          border: const OutlineInputBorder(),
                          suffixIcon: _yearController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _yearController.clear();
                                    setState(() {
                                      _selectedYear = null;
                                    });
                                    _loadSeries(resetPage: true);
                                  },
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              _selectedYear = null;
                            } else {
                              final year = int.tryParse(value);
                              if (year != null) {
                                _selectedYear = year;
                              }
                            }
                          });
                        },
                        onSubmitted: (_) {
                          _loadSeries(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Completion filter
                    Expanded(
                      child: DropdownButtonFormField<bool>(
                        value: _selectedIsCompleted,
                        decoration: const InputDecoration(
                          labelText: 'Статус',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<bool>(
                            value: null,
                            child: Text('Все'),
                          ),
                          DropdownMenuItem<bool>(
                            value: true,
                            child: Text('Завершённые'),
                          ),
                          DropdownMenuItem<bool>(
                            value: false,
                            child: Text('Незавершённые'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedIsCompleted = value;
                          });
                          _loadSeries(resetPage: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Series list
          Expanded(
            child: _isLoading && _series.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ошибка: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadSeries(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _series.isEmpty
                        ? const Center(child: Text('Нет серий'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _series.length,
                            itemBuilder: (context, index) {
                              final series = _series[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    series.displayName ??
                                        '${series.year} - ${series.name}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (series.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          series.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      if (series.teacher != null)
                                        Text(
                                            'Преподаватель: ${series.teacher!.name}'),
                                      if (series.book != null)
                                        Text('Книга: ${series.book!.name}'),
                                      if (series.theme != null)
                                        Text('Тема: ${series.theme!.name}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showSeriesDialog(
                                            context,
                                            series: series),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _confirmDelete(context, series),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
          ),

          // Pagination controls
          if (_totalItems > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Всего: $_totalItems | Страница ${_currentPage + 1} из $_totalPages',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0 ? _previousPage : null,
                        tooltip: 'Предыдущая страница',
                      ),
                      Text(
                        '${_currentPage + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: (_currentPage + 1) < _totalPages
                            ? _nextPage
                            : null,
                        tooltip: 'Следующая страница',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSeriesDialog(
    BuildContext context, {
    SeriesModel? series,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SeriesFormDialog(
        series: series,
        teachers: _teachers,
        books: _books,
        themes: _themes,
      ),
    );

    // Refresh list if series was created or updated
    if (result == true) {
      await _loadSeries();
    }
  }

  void _confirmDelete(BuildContext context, SeriesModel series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить серию?'),
        content: Text('Вы уверены, что хотите удалить "${series.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSeries(series.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSeries(int seriesId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteSeries(seriesId);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Серия удалена')));
        await _loadSeries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}

/// Series form dialog
class SeriesFormDialog extends StatefulWidget {
  final SeriesModel? series;
  final List<TeacherModel> teachers;
  final List<BookModel> books;
  final List<AppThemeModel> themes;

  const SeriesFormDialog({
    super.key,
    this.series,
    required this.teachers,
    required this.books,
    required this.themes,
  });

  @override
  State<SeriesFormDialog> createState() => _SeriesFormDialogState();
}

class _SeriesFormDialogState extends State<SeriesFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;
  int? _selectedTeacherId;
  int? _selectedBookId;
  int? _selectedThemeId;
  late bool _isCompleted;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.series?.name ?? '');
    _yearController = TextEditingController(
      text: widget.series?.year.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.series?.description ?? '',
    );
    _orderController = TextEditingController(
      text: widget.series?.order.toString() ?? '0',
    );
    _selectedTeacherId = widget.series?.teacherId;
    _selectedBookId = widget.series?.bookId;
    _selectedThemeId = widget.series?.themeId;
    _isCompleted = widget.series?.isCompleted ?? false;
    _isActive = widget.series?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.series == null ? 'Новая серия' : 'Редактировать серию',
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название серии *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название серии';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Year field
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Год *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите год';
                    }
                    final year = int.tryParse(value);
                    if (year == null) {
                      return 'Введите корректный год';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Teacher dropdown
                DropdownButtonFormField<int>(
                  value: _selectedTeacherId,
                  decoration: const InputDecoration(
                    labelText: 'Преподаватель *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.teachers.map((teacher) {
                    return DropdownMenuItem<int>(
                      value: teacher.id,
                      child: Text(teacher.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTeacherId = value;
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

                // Book dropdown
                DropdownButtonFormField<int>(
                  value: _selectedBookId != null &&
                          widget.books.any((book) => book.id == _selectedBookId)
                      ? _selectedBookId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Книга (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Не выбрано'),
                    ),
                    ...widget.books.map((book) {
                      return DropdownMenuItem<int>(
                        value: book.id,
                        child: Text(book.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBookId = value;

                      // Если выбрана книга, автоматически установить её тему
                      if (value != null) {
                        final selectedBook = widget.books.firstWhere(
                          (book) => book.id == value,
                        );
                        _selectedThemeId = selectedBook.themeId;
                      }
                      // Если "Не выбрано", тема остается как есть (можно выбрать вручную)
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Theme dropdown
                DropdownButtonFormField<int>(
                  value: _selectedThemeId != null &&
                          widget.themes
                              .any((theme) => theme.id == _selectedThemeId)
                      ? _selectedThemeId
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Тема (опционально)',
                    border: const OutlineInputBorder(),
                    // Показываем подсказку если тема берется из книги
                    helperText: _selectedBookId != null
                        ? 'Тема автоматически берётся из книги'
                        : null,
                    helperStyle: const TextStyle(color: Colors.blue),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Не выбрано'),
                    ),
                    ...widget.themes.map((theme) {
                      return DropdownMenuItem<int>(
                        value: theme.id,
                        child: Text(theme.name),
                      );
                    }),
                  ],
                  // Если выбрана книга - dropdown неактивен (серый)
                  onChanged: _selectedBookId != null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedThemeId = value;
                          });
                        },
                  // Серый цвет когда disabled
                  disabledHint: _selectedThemeId != null &&
                          widget.themes
                              .any((theme) => theme.id == _selectedThemeId)
                      ? Text(
                          widget.themes
                              .firstWhere(
                                  (theme) => theme.id == _selectedThemeId)
                              .name,
                          style: const TextStyle(color: Colors.grey),
                        )
                      : const Text(
                          'Не выбрано',
                          style: TextStyle(color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 16),

                // Order field
                TextFormField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    labelText: 'Порядок',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final order = int.tryParse(value);
                      if (order == null) {
                        return 'Введите корректное число';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ВРЕМЕННО ЗАКОММЕНТИРОВАНО для отладки
                // // Is completed switch
                // SwitchListTile(
                //   title: const Text('Серия завершена'),
                //   value: _isCompleted,
                //   onChanged: (value) {
                //     setState(() {
                //       _isCompleted = value;
                //     });
                //   },
                // ),

                // // Is active switch
                // SwitchListTile(
                //   title: const Text('Активна'),
                //   value: _isActive,
                //   onChanged: (value) {
                //     setState(() {
                //       _isActive = value;
                //     });
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.series == null ? 'Создать' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent double submission
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());

      final seriesData = {
        'name': _nameController.text,
        'year': int.parse(_yearController.text),
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'teacher_id': _selectedTeacherId!,
        'book_id': _selectedBookId,
        'theme_id': _selectedThemeId,
        'order': int.parse(_orderController.text),
        'is_completed': _isCompleted,
        'is_active': _isActive,
      };

      if (widget.series != null) {
        // Update existing series
        await apiClient.updateSeries(widget.series!.id, seriesData);
      } else {
        // Create new series
        await apiClient.createSeries(seriesData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.series != null ? 'Серия обновлена' : 'Серия создана',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
