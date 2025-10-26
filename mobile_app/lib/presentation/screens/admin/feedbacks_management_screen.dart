import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/feedback.dart' as model;
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import 'feedback_admin_edit_screen.dart';

class FeedbacksManagementScreen extends ConsumerStatefulWidget {
  const FeedbacksManagementScreen({super.key});

  @override
  ConsumerState<FeedbacksManagementScreen> createState() =>
      _FeedbacksManagementScreenState();
}

class _FeedbacksManagementScreenState
    extends ConsumerState<FeedbacksManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<model.Feedback> _feedbacks = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedStatus;
  int? _selectedUserId;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbacks({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final response = await apiClient.getAllFeedbacks(
        statusFilter: _selectedStatus,
        userId: _selectedUserId,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        skip: _currentPage * _itemsPerPage,
        limit: _itemsPerPage,
      );

      setState(() {
        _feedbacks = response.items;
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
      _loadFeedbacks();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadFeedbacks();
    }
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  Future<void> _navigateToEdit(model.Feedback feedback) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackAdminEditScreen(feedback: feedback),
      ),
    );

    if (result == true) {
      _loadFeedbacks();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedUserId = null;
    });
    _loadFeedbacks(resetPage: true);
  }

  Future<void> _deleteFeedback(model.Feedback feedback) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить обращение'),
        content: Text(
            'Вы уверены, что хотите удалить обращение "${feedback.subject}"?\n\nВсе сообщения также будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteFeedback(feedback.id);

      await _loadFeedbacks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Обращение удалено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление обращениями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFeedbacks(resetPage: true),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Поиск',
                      hintText: 'Поиск по теме или тексту',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadFeedbacks(resetPage: true);
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _loadFeedbacks(resetPage: true),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Сброс фильтров',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Все')),
                DropdownMenuItem(value: 'new', child: Text('Новые')),
                DropdownMenuItem(
                    value: 'replied', child: Text('Отвеченные')),
                DropdownMenuItem(
                    value: 'closed', child: Text('Закрытые')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                _loadFeedbacks(resetPage: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadFeedbacks(resetPage: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_feedbacks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет обращений',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = _feedbacks[index];
              return _buildFeedbackCard(feedback);
            },
          ),
        ),
        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildFeedbackCard(model.Feedback feedback) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEdit(feedback),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.subject,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (feedback.user != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'От: ${feedback.user!.displayName} (${feedback.user!.email})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(feedback),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.red[400],
                    tooltip: 'Удалить обращение',
                    onPressed: () => _deleteFeedback(feedback),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                feedback.messageText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(feedback.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (feedback.hasReply) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.reply, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Отвечен',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(model.Feedback feedback) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(feedback.statusColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(feedback.statusColor)),
      ),
      child: Text(
        feedback.statusDisplayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(feedback.statusColor),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Назад'),
          ),
          Text(
            'Страница ${_currentPage + 1} из $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          ElevatedButton.icon(
            onPressed: (_currentPage + 1) < _totalPages ? _nextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Вперёд'),
            style: ElevatedButton.styleFrom(
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}
