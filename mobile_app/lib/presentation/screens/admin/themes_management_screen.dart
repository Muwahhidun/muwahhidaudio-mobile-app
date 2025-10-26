import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';

class ThemesManagementScreen extends ConsumerStatefulWidget {
  const ThemesManagementScreen({super.key});

  @override
  ConsumerState<ThemesManagementScreen> createState() =>
      _ThemesManagementScreenState();
}

class _ThemesManagementScreenState
    extends ConsumerState<ThemesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppThemeModel> _themes = [];
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadThemes({bool resetPage = false}) async {
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
        '/themes',
        queryParameters: {
          if (_searchController.text.isNotEmpty) 'search': _searchController.text,
          'include_inactive': true,
          'skip': _currentPage * _itemsPerPage,
          'limit': _itemsPerPage,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => AppThemeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      setState(() {
        _themes = items;
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
      _loadThemes();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadThemes();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление темами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showThemeDialog(context),
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
                labelText: 'Поиск по названию или описанию',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadThemes(resetPage: true);
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Update to show/hide clear button
              },
              onSubmitted: (_) {
                _loadThemes(resetPage: true);
              },
            ),
          ),
          // List
          Expanded(
            child: _isLoading && _themes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ошибка: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadThemes(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _themes.isEmpty
                        ? const Center(child: Text('Нет тем'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _themes.length,
                            itemBuilder: (context, index) {
                              final theme = _themes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    theme.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (theme.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          theme.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        'Активна: ${(theme.isActive ?? false) ? "Да" : "Нет"}',
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
                                        onPressed: () => _showThemeDialog(context, theme: theme),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, theme),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: theme.description != null,
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

  Future<void> _showThemeDialog(BuildContext context, {AppThemeModel? theme}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ThemeFormDialog(theme: theme),
    );

    // Refresh list if theme was created or updated
    if (result == true) {
      await _loadThemes();
    }
  }

  void _confirmDelete(BuildContext context, AppThemeModel theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тему?'),
        content: Text('Вы уверены, что хотите удалить тему "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTheme(theme.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTheme(int themeId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteTheme(themeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тема удалена')),
        );
        await _loadThemes();
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

class ThemeFormDialog extends StatefulWidget {
  final AppThemeModel? theme;

  const ThemeFormDialog({super.key, this.theme});

  @override
  State<ThemeFormDialog> createState() => _ThemeFormDialogState();
}

class _ThemeFormDialogState extends State<ThemeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.theme?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.theme?.description ?? '');
    _isActive = widget.theme?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.theme != null;

    return AlertDialog(
      title: Text(isEdit ? 'Редактировать тему' : 'Создать тему'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Активна'),
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Сохранить' : 'Создать'),
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

      final themeData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'is_active': _isActive,
        'sort_order': 0,
      };

      if (widget.theme != null) {
        // Update existing theme
        await apiClient.updateTheme(widget.theme!.id, themeData);
      } else {
        // Create new theme
        await apiClient.createTheme(themeData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.theme != null ? 'Тема обновлена' : 'Тема создана',
            ),
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
