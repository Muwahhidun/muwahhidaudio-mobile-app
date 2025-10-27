import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/feedback.dart' as model;
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../widgets/mini_player.dart';
import 'feedback_create_screen.dart';
import 'feedback_detail_screen.dart';

class FeedbackListScreen extends ConsumerStatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  ConsumerState<FeedbackListScreen> createState() =>
      _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  List<model.Feedback> _feedbacks = [];
  bool _isLoading = false;
  String? _error;

  // Pagination
  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final response = await apiClient.getMyFeedbacks(
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

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackCreateScreen()),
    );

    if (result == true) {
      // Reload feedbacks after creating new one
      _currentPage = 0;
      _loadFeedbacks();
    }
  }

  Future<void> _navigateToDetail(model.Feedback feedback) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackDetailScreen(feedback: feedback),
      ),
    );

    if (result == true) {
      // Reload feedbacks if details changed
      _loadFeedbacks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обратная связь'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbacks,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Новое обращение'),
      ),
      bottomNavigationBar: const MiniPlayer(),
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
              onPressed: _loadFeedbacks,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет обращений',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте первое обращение, нажав на кнопку ниже',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
        onTap: () => _navigateToDetail(feedback),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feedback.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(feedback),
                ],
              ),
              const SizedBox(height: 8),
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
                      'Получен ответ',
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
        color: Color(feedback.statusColor).withOpacity(0.1),
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
