import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/teacher.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';

class TeachersManagementScreen extends ConsumerStatefulWidget {
  const TeachersManagementScreen({super.key});

  @override
  ConsumerState<TeachersManagementScreen> createState() =>
      _TeachersManagementScreenState();
}

class _TeachersManagementScreenState
    extends ConsumerState<TeachersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TeacherModel> _teachers = [];
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers({bool resetPage = false}) async {
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
        '/teachers',
        queryParameters: {
          if (_searchController.text.isNotEmpty) 'search': _searchController.text,
          'include_inactive': true,
          'skip': _currentPage * _itemsPerPage,
          'limit': _itemsPerPage,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => TeacherModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      setState(() {
        _teachers = items;
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
      _loadTeachers();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadTeachers();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление преподавателями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeacherDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск по имени или биографии',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadTeachers(resetPage: true);
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Update to show/hide clear button
              },
              onSubmitted: (_) {
                _loadTeachers(resetPage: true);
              },
            ),
          ),
          // List
          Expanded(
            child: _isLoading && _teachers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ошибка: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadTeachers(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _teachers.isEmpty
                        ? const Center(child: Text('Нет преподавателей'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _teachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _teachers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    teacher.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (teacher.biography != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          teacher.biography!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        'Активен: ${(teacher.isActive ?? false) ? "Да" : "Нет"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showTeacherDialog(context, teacher: teacher),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, teacher),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: teacher.biography != null,
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

  Future<void> _showTeacherDialog(BuildContext context, {TeacherModel? teacher}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TeacherFormDialog(teacher: teacher),
    );

    // Refresh list if teacher was created or updated
    if (result == true) {
      await _loadTeachers();
    }
  }

  void _confirmDelete(BuildContext context, TeacherModel teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить преподавателя?'),
        content: Text('Вы уверены, что хотите удалить "${teacher.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTeacher(teacher.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeacher(int teacherId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteTeacher(teacherId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Преподаватель удалён')),
        );
        await _loadTeachers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

/// Teacher form dialog
class TeacherFormDialog extends ConsumerStatefulWidget {
  final TeacherModel? teacher;

  const TeacherFormDialog({super.key, this.teacher});

  @override
  ConsumerState<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _biographyController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher?.name ?? '');
    _biographyController =
        TextEditingController(text: widget.teacher?.biography ?? '');
    _isActive = widget.teacher?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Новый преподаватель' : 'Редактировать преподавателя'),
      content: SizedBox(
        width: 500,
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
                    labelText: 'Имя преподавателя',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите имя преподавателя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Biography field
                TextFormField(
                  controller: _biographyController,
                  decoration: const InputDecoration(
                    labelText: 'Биография (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Active switch
                SwitchListTile(
                  title: const Text('Активен'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
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
              : Text(widget.teacher == null ? 'Создать' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());

      final teacherData = {
        'name': _nameController.text,
        'biography': _biographyController.text.isEmpty
            ? null
            : _biographyController.text,
        'is_active': _isActive,
      };

      if (widget.teacher != null) {
        // Update existing teacher
        await apiClient.updateTeacher(widget.teacher!.id, teacherData);
      } else {
        // Create new teacher
        await apiClient.createTeacher(teacherData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.teacher != null ? 'Преподаватель обновлён' : 'Преподаватель создан'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
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
}
