import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../../data/models/theme.dart';
import '../../../data/models/book_author.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class BooksManagementScreen extends ConsumerStatefulWidget {
  const BooksManagementScreen({super.key});

  @override
  ConsumerState<BooksManagementScreen> createState() =>
      _BooksManagementScreenState();
}

class _BooksManagementScreenState extends ConsumerState<BooksManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookModel> _books = [];
  List<AppThemeModel> _themes = [];
  List<BookAuthorModel> _authors = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedThemeId;
  int? _selectedAuthorId;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks({bool resetPage = false}) async {
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
        '/books',
        queryParameters: {
          if (_searchController.text.isNotEmpty) 'search': _searchController.text,
          if (_selectedThemeId != null) 'theme_id': _selectedThemeId,
          if (_selectedAuthorId != null) 'author_id': _selectedAuthorId,
          'include_inactive': true,
          'skip': _currentPage * _itemsPerPage,
          'limit': _itemsPerPage,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      setState(() {
        _books = items;
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

  Future<void> _loadFilters() async {
    try {
      final dio = DioProvider.getDio();

      // Load themes
      final themesResponse = await dio.get(
        '/themes',
        queryParameters: {
          'include_inactive': true,
          'limit': 1000,
        },
      );
      final themesData = themesResponse.data as Map<String, dynamic>;
      final themes = (themesData['items'] as List)
          .map((e) => AppThemeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load authors
      final authorsResponse = await dio.get(
        '/book-authors',
        queryParameters: {
          'include_inactive': true,
          'limit': 1000,
        },
      );
      final authorsData = authorsResponse.data as Map<String, dynamic>;
      final authors = (authorsData['items'] as List)
          .map((e) => BookAuthorModel.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _themes = themes;
        _authors = authors;
      });
    } catch (e) {
      // Silently fail for filters, main list is more important
      debugPrint('Error loading filters: $e');
    }
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _totalItems) {
      setState(() {
        _currentPage++;
      });
      _loadBooks();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadBooks();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Управление книгами'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showBookDialog(context),
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
                  child: GlassCard(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Поиск по названию или описанию',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                  _loadBooks(resetPage: true);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {}); // Update to show/hide clear button
                      },
                      onSubmitted: (_) {
                        _loadBooks(resetPage: true);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedThemeId = null;
                      _selectedAuthorId = null;
                    });
                    _loadBooks(resetPage: true);
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
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Theme filter
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedThemeId,
                    decoration: const InputDecoration(
                      labelText: 'Фильтр по теме',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все темы'),
                      ),
                      ..._themes.map((theme) {
                        return DropdownMenuItem<int?>(
                          value: theme.id,
                          child: Text(theme.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedThemeId = value;
                      });
                      _loadBooks(resetPage: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Author filter
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedAuthorId,
                    decoration: const InputDecoration(
                      labelText: 'Фильтр по автору',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все авторы'),
                      ),
                      ..._authors.map((author) {
                        return DropdownMenuItem<int?>(
                          value: author.id,
                          child: Text(author.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAuthorId = value;
                      });
                      _loadBooks(resetPage: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: _isLoading && _books.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ошибка: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadBooks(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _books.isEmpty
                        ? const Center(child: Text('Нет книг'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _books.length,
                            itemBuilder: (context, index) {
                              final book = _books[index];
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  title: Text(
                                    book.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (book.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          book.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (book.theme != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Тема: ${book.theme!.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                      if (book.author != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Автор: ${book.author!.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        'Активна: ${(book.isActive ?? false) ? "Да" : "Нет"}',
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
                                        onPressed: () => _showBookDialog(context, book: book),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, book),
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
            GlassCard(
              margin: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
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
    );
  }

  Future<void> _showBookDialog(BuildContext context, {BookModel? book}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookFormDialog(book: book),
    );

    // Refresh list if book was created or updated
    if (result == true) {
      await _loadBooks();
      await _loadFilters(); // Refresh filters in case new theme/author was added
    }
  }

  void _confirmDelete(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('Вы уверены, что хотите удалить "${book.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBook(book.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteBook(bookId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Книга удалена')));
        await _loadBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}

/// Book form dialog
class BookFormDialog extends StatefulWidget {
  final BookModel? book;

  const BookFormDialog({super.key, this.book});

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  int? _selectedThemeId;
  int? _selectedAuthorId;
  bool _isLoading = false;
  List<AppThemeModel> _themes = [];
  List<BookAuthorModel> _authors = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.book?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.book?.description ?? '',
    );
    _isActive = widget.book?.isActive ?? true;
    _selectedThemeId = widget.book?.themeId;
    _selectedAuthorId = widget.book?.authorId;

    _loadFilters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final dio = DioProvider.getDio();

      // Load themes
      final themesResponse = await dio.get(
        '/themes',
        queryParameters: {
          'include_inactive': true,
          'limit': 1000,
        },
      );
      final themesData = themesResponse.data as Map<String, dynamic>;
      final themes = (themesData['items'] as List)
          .map((e) => AppThemeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load authors
      final authorsResponse = await dio.get(
        '/book-authors',
        queryParameters: {
          'include_inactive': true,
          'limit': 1000,
        },
      );
      final authorsData = authorsResponse.data as Map<String, dynamic>;
      final authors = (authorsData['items'] as List)
          .map((e) => BookAuthorModel.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _themes = themes;
        _authors = authors;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.book == null ? 'Новая книга' : 'Редактировать книгу'),
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
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название';
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

                // Theme dropdown
                DropdownButtonFormField<int>(
                  value: _themes.any((t) => t.id == _selectedThemeId)
                      ? _selectedThemeId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Тема',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Без темы'),
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
                  },
                ),
                const SizedBox(height: 16),

                // Author dropdown
                DropdownButtonFormField<int>(
                  value: _authors.any((a) => a.id == _selectedAuthorId)
                      ? _selectedAuthorId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Автор',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Без автора'),
                    ),
                    ..._authors.map((author) {
                      return DropdownMenuItem<int>(
                        value: author.id,
                        child: Text(author.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAuthorId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Active switch
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
              : Text(widget.book == null ? 'Создать' : 'Сохранить'),
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

      final bookData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'theme_id': _selectedThemeId,
        'author_id': _selectedAuthorId,
        'is_active': _isActive,
        'sort_order': 0,
      };

      if (widget.book != null) {
        // Update existing book
        await apiClient.updateBook(widget.book!.id, bookData);
      } else {
        // Create new book
        await apiClient.createBook(bookData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.book != null ? 'Книга обновлена' : 'Книга создана',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
