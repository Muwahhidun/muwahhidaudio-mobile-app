import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book_author.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';

class BookAuthorsManagementScreen extends ConsumerStatefulWidget {
  const BookAuthorsManagementScreen({super.key});

  @override
  ConsumerState<BookAuthorsManagementScreen> createState() =>
      _BookAuthorsManagementScreenState();
}

class _BookAuthorsManagementScreenState
    extends ConsumerState<BookAuthorsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _birthYearFromController = TextEditingController();
  final TextEditingController _birthYearToController = TextEditingController();
  final TextEditingController _deathYearFromController = TextEditingController();
  final TextEditingController _deathYearToController = TextEditingController();

  List<BookAuthorModel> _authors = [];
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _birthYearFromController.dispose();
    _birthYearToController.dispose();
    _deathYearFromController.dispose();
    _deathYearToController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthors({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioProvider.getDio();
      final queryParams = <String, dynamic>{
        'include_inactive': true,
        'skip': _currentPage * _itemsPerPage,
        'limit': _itemsPerPage,
      };

      // Add search parameter
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }

      // Add birth year filters
      if (_birthYearFromController.text.isNotEmpty) {
        queryParams['birth_year_from'] = int.parse(_birthYearFromController.text);
      }
      if (_birthYearToController.text.isNotEmpty) {
        queryParams['birth_year_to'] = int.parse(_birthYearToController.text);
      }

      // Add death year filters
      if (_deathYearFromController.text.isNotEmpty) {
        queryParams['death_year_from'] = int.parse(_deathYearFromController.text);
      }
      if (_deathYearToController.text.isNotEmpty) {
        queryParams['death_year_to'] = int.parse(_deathYearToController.text);
      }

      final response = await dio.get(
        '/book-authors',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => BookAuthorModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      setState(() {
        _authors = items;
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
      _loadAuthors();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadAuthors();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _birthYearFromController.clear();
      _birthYearToController.clear();
      _deathYearFromController.clear();
      _deathYearToController.clear();
    });
    _loadAuthors(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление авторами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAuthorDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field with clear filters button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Поиск по имени или биографии',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                _loadAuthors(resetPage: true);
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Update to show/hide clear button
                    },
                    onSubmitted: (_) {
                      _loadAuthors(resetPage: true);
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
          ),
          // Year filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Birth year filters
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Год рождения',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _birthYearFromController,
                              decoration: const InputDecoration(
                                labelText: 'От',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (value) {
                                setState(() {}); // Update UI
                              },
                              onSubmitted: (_) {
                                _loadAuthors(resetPage: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _birthYearToController,
                              decoration: const InputDecoration(
                                labelText: 'До',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (value) {
                                setState(() {}); // Update UI
                              },
                              onSubmitted: (_) {
                                _loadAuthors(resetPage: true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Death year filters
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Год смерти',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _deathYearFromController,
                              decoration: const InputDecoration(
                                labelText: 'От',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (value) {
                                setState(() {}); // Update UI
                              },
                              onSubmitted: (_) {
                                _loadAuthors(resetPage: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _deathYearToController,
                              decoration: const InputDecoration(
                                labelText: 'До',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (value) {
                                setState(() {}); // Update UI
                              },
                              onSubmitted: (_) {
                                _loadAuthors(resetPage: true);
                              },
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
          const SizedBox(height: 16),
          // List
          Expanded(
            child: _isLoading && _authors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ошибка: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadAuthors(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _authors.isEmpty
                        ? const Center(child: Text('Нет авторов'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _authors.length,
                            itemBuilder: (context, index) {
                              final author = _authors[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    author.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (author.biography != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          author.biography!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${author.birthYear != null ? "${author.birthYear}" : "?"} - ${author.deathYear != null ? "${author.deathYear}" : "?"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Активен: ${(author.isActive ?? false) ? "Да" : "Нет"}',
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
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showAuthorDialog(
                                            context,
                                            author: author),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _confirmDelete(context, author),
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

  Future<void> _showAuthorDialog(BuildContext context,
      {BookAuthorModel? author}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AuthorFormDialog(author: author),
    );

    // Refresh list if author was created or updated
    if (result == true) {
      await _loadAuthors();
    }
  }

  void _confirmDelete(BuildContext context, BookAuthorModel author) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора?'),
        content: Text('Вы уверены, что хотите удалить "${author.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAuthor(author.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAuthor(int authorId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteBookAuthor(authorId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Автор удалён')),
        );
        await _loadAuthors();
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

/// Author form dialog
class AuthorFormDialog extends ConsumerStatefulWidget {
  final BookAuthorModel? author;

  const AuthorFormDialog({super.key, this.author});

  @override
  ConsumerState<AuthorFormDialog> createState() => _AuthorFormDialogState();
}

class _AuthorFormDialogState extends ConsumerState<AuthorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _biographyController;
  late final TextEditingController _birthYearController;
  late final TextEditingController _deathYearController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.author?.name ?? '');
    _biographyController =
        TextEditingController(text: widget.author?.biography ?? '');
    _birthYearController = TextEditingController(
        text: widget.author?.birthYear?.toString() ?? '');
    _deathYearController = TextEditingController(
        text: widget.author?.deathYear?.toString() ?? '');
    _isActive = widget.author?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    _birthYearController.dispose();
    _deathYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.author == null ? 'Новый автор' : 'Редактировать автора'),
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
                    labelText: 'Имя автора',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите имя автора';
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

                // Birth year field
                TextFormField(
                  controller: _birthYearController,
                  decoration: const InputDecoration(
                    labelText: 'Год рождения (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null || year < 0 || year > 2100) {
                        return 'Введите корректный год';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Death year field
                TextFormField(
                  controller: _deathYearController,
                  decoration: const InputDecoration(
                    labelText: 'Год смерти (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null || year < 0 || year > 2100) {
                        return 'Введите корректный год';
                      }
                      // Check death year is after birth year
                      final birthYear = int.tryParse(_birthYearController.text);
                      if (birthYear != null && year < birthYear) {
                        return 'Год смерти не может быть раньше года рождения';
                      }
                    }
                    return null;
                  },
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
              : Text(widget.author == null ? 'Создать' : 'Сохранить'),
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

      final authorData = {
        'name': _nameController.text,
        'biography': _biographyController.text.isEmpty
            ? null
            : _biographyController.text,
        'birth_year': _birthYearController.text.isEmpty
            ? null
            : int.parse(_birthYearController.text),
        'death_year': _deathYearController.text.isEmpty
            ? null
            : int.parse(_deathYearController.text),
        'is_active': _isActive,
      };

      if (widget.author != null) {
        // Update existing author
        await apiClient.updateBookAuthor(widget.author!.id, authorData);
      } else {
        // Create new author
        await apiClient.createBookAuthor(authorData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.author != null ? 'Автор обновлён' : 'Автор создан'),
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
