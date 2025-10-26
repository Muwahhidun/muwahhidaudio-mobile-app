import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'feedback.g.dart';

/// Feedback message model (individual message in conversation)
@JsonSerializable()
class FeedbackMessage {
  final int id;
  @JsonKey(name: 'feedback_id')
  final int feedbackId;
  @JsonKey(name: 'author_id')
  final int authorId;
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @JsonKey(name: 'message_text')
  final String messageText;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final User? author; // Author information

  FeedbackMessage({
    required this.id,
    required this.feedbackId,
    required this.authorId,
    required this.isAdmin,
    required this.messageText,
    required this.createdAt,
    this.author,
  });

  factory FeedbackMessage.fromJson(Map<String, dynamic> json) =>
      _$FeedbackMessageFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackMessageToJson(this);
}

/// Feedback message create request model
@JsonSerializable()
class FeedbackMessageCreate {
  @JsonKey(name: 'message_text')
  final String messageText;
  @JsonKey(name: 'send_as_admin')
  final bool? sendAsAdmin;

  FeedbackMessageCreate({
    required this.messageText,
    this.sendAsAdmin,
  });

  factory FeedbackMessageCreate.fromJson(Map<String, dynamic> json) =>
      _$FeedbackMessageCreateFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackMessageCreateToJson(this);
}

/// Feedback model
@JsonSerializable()
class Feedback {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String subject;
  @JsonKey(name: 'message_text')
  final String messageText;
  @JsonKey(name: 'admin_reply')
  final String? adminReply;
  final String status; // 'new', 'replied', 'closed'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'replied_at')
  final DateTime? repliedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  final User? user; // For admin view
  final List<FeedbackMessage> messages; // Conversation history

  Feedback({
    required this.id,
    required this.userId,
    required this.subject,
    required this.messageText,
    this.adminReply,
    required this.status,
    required this.createdAt,
    this.repliedAt,
    this.closedAt,
    this.user,
    this.messages = const [],
  });

  factory Feedback.fromJson(Map<String, dynamic> json) => _$FeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackToJson(this);

  /// Get status display name in Russian
  String get statusDisplayName {
    switch (status) {
      case 'new':
        return 'Новый';
      case 'replied':
        return 'Отвечен';
      case 'closed':
        return 'Закрыт';
      default:
        return status;
    }
  }

  /// Get status color
  int get statusColor {
    switch (status) {
      case 'new':
        return 0xFF2196F3; // Blue
      case 'replied':
        return 0xFF4CAF50; // Green
      case 'closed':
        return 0xFF9E9E9E; // Gray
      default:
        return 0xFF9E9E9E;
    }
  }

  /// Check if feedback is closed
  bool get isClosed => status == 'closed';

  /// Check if admin has replied
  bool get hasReply => adminReply != null && adminReply!.isNotEmpty;
}

/// Feedback create request model
@JsonSerializable()
class FeedbackCreate {
  final String subject;
  @JsonKey(name: 'message_text')
  final String messageText;

  FeedbackCreate({
    required this.subject,
    required this.messageText,
  });

  factory FeedbackCreate.fromJson(Map<String, dynamic> json) =>
      _$FeedbackCreateFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackCreateToJson(this);
}

/// Feedback admin update model
@JsonSerializable()
class FeedbackAdminUpdate {
  @JsonKey(name: 'admin_reply')
  final String? adminReply;
  final String? status;

  FeedbackAdminUpdate({
    this.adminReply,
    this.status,
  });

  factory FeedbackAdminUpdate.fromJson(Map<String, dynamic> json) =>
      _$FeedbackAdminUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackAdminUpdateToJson(this);
}

/// Paginated feedbacks response
@JsonSerializable()
class PaginatedFeedbacksResponse {
  final List<Feedback> items;
  final int total;
  final int skip;
  final int limit;

  PaginatedFeedbacksResponse({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory PaginatedFeedbacksResponse.fromJson(Map<String, dynamic> json) =>
      _$PaginatedFeedbacksResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedFeedbacksResponseToJson(this);

  /// Calculate total number of pages
  int get totalPages => (total / limit).ceil();

  /// Check if there are more items
  bool get hasMore => skip + items.length < total;
}
