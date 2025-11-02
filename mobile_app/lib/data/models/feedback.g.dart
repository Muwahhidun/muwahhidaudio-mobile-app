// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackMessage _$FeedbackMessageFromJson(Map<String, dynamic> json) =>
    FeedbackMessage(
      id: (json['id'] as num).toInt(),
      feedbackId: (json['feedback_id'] as num).toInt(),
      authorId: (json['author_id'] as num).toInt(),
      isAdmin: json['is_admin'] as bool,
      messageText: json['message_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeedbackMessageToJson(FeedbackMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'feedback_id': instance.feedbackId,
      'author_id': instance.authorId,
      'is_admin': instance.isAdmin,
      'message_text': instance.messageText,
      'created_at': instance.createdAt.toIso8601String(),
      'author': instance.author,
    };

FeedbackMessageCreate _$FeedbackMessageCreateFromJson(
  Map<String, dynamic> json,
) => FeedbackMessageCreate(
  messageText: json['message_text'] as String,
  sendAsAdmin: json['send_as_admin'] as bool?,
);

Map<String, dynamic> _$FeedbackMessageCreateToJson(
  FeedbackMessageCreate instance,
) => <String, dynamic>{
  'message_text': instance.messageText,
  'send_as_admin': instance.sendAsAdmin,
};

Feedback _$FeedbackFromJson(Map<String, dynamic> json) => Feedback(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  subject: json['subject'] as String,
  messageText: json['message_text'] as String,
  adminReply: json['admin_reply'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  repliedAt: json['replied_at'] == null
      ? null
      : DateTime.parse(json['replied_at'] as String),
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => FeedbackMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$FeedbackToJson(Feedback instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'subject': instance.subject,
  'message_text': instance.messageText,
  'admin_reply': instance.adminReply,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'replied_at': instance.repliedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'user': instance.user,
  'messages': instance.messages,
};

FeedbackCreate _$FeedbackCreateFromJson(Map<String, dynamic> json) =>
    FeedbackCreate(
      subject: json['subject'] as String,
      messageText: json['message_text'] as String,
    );

Map<String, dynamic> _$FeedbackCreateToJson(FeedbackCreate instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'message_text': instance.messageText,
    };

FeedbackAdminUpdate _$FeedbackAdminUpdateFromJson(Map<String, dynamic> json) =>
    FeedbackAdminUpdate(
      adminReply: json['admin_reply'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$FeedbackAdminUpdateToJson(
  FeedbackAdminUpdate instance,
) => <String, dynamic>{
  'admin_reply': instance.adminReply,
  'status': instance.status,
};

PaginatedFeedbacksResponse _$PaginatedFeedbacksResponseFromJson(
  Map<String, dynamic> json,
) => PaginatedFeedbacksResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => Feedback.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  skip: (json['skip'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$PaginatedFeedbacksResponseToJson(
  PaginatedFeedbacksResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'skip': instance.skip,
  'limit': instance.limit,
};
