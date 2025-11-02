import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import 'user_edit_screen.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() =>
      _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedRoleId;
  bool? _selectedIsActive;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final response = await apiClient.getUsers(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        roleId: _selectedRoleId,
        isActive: _selectedIsActive,
        skip: _currentPage * _itemsPerPage,
        limit: _itemsPerPage,
      );

      setState(() {
        _users = response.items;
        _totalItems = response.total;
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
      _loadUsers();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadUsers();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  Future<void> _deleteUser(int id) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteUser(id);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь удален')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями'),
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
                          labelText: 'Поиск по email или логину',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    _loadUsers(resetPage: true);
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to show/hide X button
                          _loadUsers(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedRoleId = null;
                          _selectedIsActive = null;
                        });
                        _loadUsers(resetPage: true);
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

                // Filters row: Role and Status
                Row(
                  children: [
                    // Role filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Роль',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text('Все'),
                          ),
                          DropdownMenuItem<int>(
                            value: 1,
                            child: Text('User'),
                          ),
                          DropdownMenuItem<int>(
                            value: 2,
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleId = value;
                          });
                          _loadUsers(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Active status filter
                    Expanded(
                      child: DropdownButtonFormField<bool>(
                        value: _selectedIsActive,
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
                            child: Text('Активные'),
                          ),
                          DropdownMenuItem<bool>(
                            value: false,
                            child: Text('Заблокированные'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedIsActive = value;
                          });
                          _loadUsers(resetPage: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users list with pagination
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
                                    onPressed: _loadUsers,
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            )
                          : _users.isEmpty
                              ? const Center(
                                  child: Text('Пользователи не найдены'),
                                )
                              : ListView.builder(
                                  itemCount: _users.length,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        title: Text(
                                          user.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                            Text(
                                              'Роль: ${user.role.name} | ${user.isActive ? "Активен" : "Заблокирован"} | Email: ${user.emailVerified ? "✓" : "✗"}',
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
                                                final result = await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserEditScreen(user: user),
                                                  ),
                                                );
                                                if (result == true) {
                                                  _loadUsers();
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
                                                    title: const Text('Подтверждение'),
                                                    content: const Text(
                                                        'Удалить этого пользователя?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(context, false),
                                                        child: const Text('Отмена'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(context, true),
                                                        child: const Text('Удалить'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  _deleteUser(user.id);
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
