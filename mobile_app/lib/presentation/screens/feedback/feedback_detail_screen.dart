import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/feedback.dart' as model;
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../../data/models/user.dart';
import '../../providers/auth_provider.dart';

class FeedbackDetailScreen extends ConsumerStatefulWidget {
  final model.Feedback feedback;

  const FeedbackDetailScreen({
    super.key,
    required this.feedback,
  });

  @override
  ConsumerState<FeedbackDetailScreen> createState() =>
      _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends ConsumerState<FeedbackDetailScreen> {
  late model.Feedback _feedback;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination for messages
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _feedback = widget.feedback;
    _refreshFeedback();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final updated = await apiClient.getFeedback(_feedback.id);

      setState(() {
        _feedback = updated;
        _isLoading = false;
      });

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    if (_feedback.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нельзя добавлять сообщения в закрытое обращение'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final messageCreate = model.FeedbackMessageCreate(
        messageText: messageText,
        sendAsAdmin: false, // Always send as regular user from user screen
      );

      await apiClient.createFeedbackMessage(_feedback.id, messageCreate);

      _messageController.clear();
      await _refreshFeedback();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сообщение отправлено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обращение'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFeedback,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          _buildSubjectHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading && _feedback == widget.feedback
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _buildMessagesList(currentUser),
          ),
          if (!_feedback.isClosed) _buildMessageInput(),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'replied':
        return Icons.reply;
      case 'closed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return const Color(0xFF2196F3); // Blue
      case 'replied':
        return const Color(0xFF4CAF50); // Green
      case 'closed':
        return const Color(0xFF9E9E9E); // Gray
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_feedback.status),
            color: _getStatusColor(_feedback.status),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Статус:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _feedback.statusDisplayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(_feedback.status),
            ),
          ),
          if (_isLoading) ...[
            const Spacer(),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.subject, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _feedback.subject,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Ошибка: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshFeedback,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(User? currentUser) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    // Combine initial message and conversation messages
    final totalMessages = 1 + _feedback.messages.length; // 1 for initial message
    final totalPages = (totalMessages / _itemsPerPage).ceil();

    // Calculate pagination
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalMessages);

    final paginatedMessages = <Widget>[];

    // Add initial message if in first page range
    if (startIndex == 0) {
      paginatedMessages.add(_buildInitialMessage(dateFormat));
    }

    // Calculate message indices (account for initial message)
    final messageStartIndex = (startIndex - 1).clamp(0, _feedback.messages.length);
    final messageEndIndex = (endIndex - 1).clamp(0, _feedback.messages.length);

    // Add conversation messages for current page
    for (int i = messageStartIndex; i < messageEndIndex; i++) {
      if (i >= 0 && i < _feedback.messages.length) {
        paginatedMessages.add(
          _buildMessageBubble(_feedback.messages[i], currentUser, dateFormat),
        );
      }
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshFeedback,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: paginatedMessages.length,
              itemBuilder: (context, index) => paginatedMessages[index],
            ),
          ),
        ),
        if (totalPages > 1) _buildMessagesPagination(totalPages),
      ],
    );
  }

  Widget _buildMessagesPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Страница ${_currentPage + 1} из $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          IconButton(
            onPressed: (_currentPage + 1) < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialMessage(DateFormat dateFormat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.person, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _feedback.user?.displayName ?? 'Пользователь',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(_feedback.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _feedback.messageText,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    model.FeedbackMessage message,
    User? currentUser,
    DateFormat dateFormat,
  ) {
    final isAdmin = message.isAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isAdmin ? Colors.green[100] : Colors.blue[100],
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? Colors.green[700] : Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.author?.displayName ??
                          (isAdmin ? 'Администратор' : 'Пользователь'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isAdmin ? Colors.green[700] : Colors.black,
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Админ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(message.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.green[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.messageText,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Напишите сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isSending,
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const CircularProgressIndicator()
                : IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    iconSize: 28,
                  ),
          ],
        ),
      ),
    );
  }
}
