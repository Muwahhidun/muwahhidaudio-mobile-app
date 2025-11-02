import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lesson.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/series_provider.dart';
import '../../providers/teachers_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/themes_provider.dart';
import 'lesson_form_screen.dart';

class LessonsManagementScreen extends ConsumerStatefulWidget {
  const LessonsManagementScreen({super.key});

  @override
  ConsumerState<LessonsManagementScreen> createState() =>
      _LessonsManagementScreenState();
}

class _LessonsManagementScreenState
    extends ConsumerState<LessonsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Lesson> _lessons = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedSeriesId;
  int? _selectedTeacherId;
  int? _selectedBookId;
  int? _selectedThemeId;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get(
        '/lessons',
        queryParameters: {
          if (_searchController.text.isNotEmpty) 'search': _searchController.text,
          if (_selectedSeriesId != null) 'series_id': _selectedSeriesId,
          if (_selectedTeacherId != null) 'teacher_id': _selectedTeacherId,
          if (_selectedBookId != null) 'book_id': _selectedBookId,
          if (_selectedThemeId != null) 'theme_id': _selectedThemeId,
          'include_inactive': true,
          'skip': _currentPage * _itemsPerPage,
          'limit': _itemsPerPage,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List).map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
      final total = data['total'] as int;

      setState(() {
        _lessons = items;
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
      _loadLessons();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadLessons();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  Future<void> _deleteLesson(int id) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteLesson(id);
      _loadLessons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Урок удален')),
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

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesProvider);
    final teachersState = ref.watch(teachersProvider);
    final booksState = ref.watch(booksProvider);
    final themesState = ref.watch(themesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление уроками'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const LessonFormScreen(),
                ),
              );
              if (result == true) {
                _loadLessons();
              }
            },
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
                          labelText: 'Поиск по названию или тегам',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    _loadLessons(resetPage: true);
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to show/hide X button
                          _loadLessons(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedSeriesId = null;
                          _selectedTeacherId = null;
                          _selectedBookId = null;
                          _selectedThemeId = null;
                        });
                        _loadLessons(resetPage: true);
                      },
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

                // Filters row 1: Series and Teacher
                Row(
                  children: [
                    // Series filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSeriesId,
                        decoration: const InputDecoration(
                          labelText: 'Серия',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Все'),
                          ),
                          ...seriesState.series.map((series) {
                            return DropdownMenuItem<int>(
                              value: series.id,
                              child: Text(series.displayName ?? series.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSeriesId = value;
                          });
                          _loadLessons(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          ...teachersState.teachers.map((teacher) {
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
                          _loadLessons(resetPage: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filters row 2: Book and Theme
                Row(
                  children: [
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
                          ...booksState.books.map((book) {
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
                          _loadLessons(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          ...themesState.themes.map((theme) {
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
                          _loadLessons(resetPage: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lessons list with pagination
          Expanded(
            child: Column(
              children: [
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
                                    onPressed: _loadLessons,
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            )
                          : _lessons.isEmpty
                              ? const Center(
                                  child: Text('Уроки не найдены'),
                                )
                              : ListView.builder(
                                  itemCount: _lessons.length,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, index) {
                              final lesson = _lessons[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppIcons.lessonColor
                                          .withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      AppIcons.lesson,
                                      color: AppIcons.lessonColor,
                                    ),
                                  ),
                                  title: Text(
                                    lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (lesson.series != null)
                                        Text(
                                          'Серия: ${lesson.series!.displayName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      if (lesson.teacher != null)
                                        Text(
                                          'Преподаватель: ${lesson.teacher!.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      if (lesson.book != null)
                                        Text(
                                          'Книга: ${lesson.book!.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      if (lesson.formattedDuration != null)
                                        Text(
                                          'Длительность: ${lesson.formattedDuration}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          // Load full lesson data before editing
                                          try {
                                            final dio = DioProvider.getDio();
                                            final apiClient = ApiClient(dio);
                                            final fullLesson = await apiClient.getLesson(lesson.id);

                                            if (!mounted) return;

                                            final result = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LessonFormScreen(lesson: fullLesson),
                                              ),
                                            );

                                            if (result == true) {
                                              _loadLessons();
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Ошибка загрузки урока: $e')),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Подтверждение'),
                                              content: const Text(
                                                  'Удалить этот урок?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Отмена'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Удалить'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            _deleteLesson(lesson.id);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
          ),
        ],
      ),
    );
  }
}
