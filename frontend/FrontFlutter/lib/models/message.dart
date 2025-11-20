class Conversation {
  final String bookingId;
  final Map<String, dynamic> otherUser;
  final Map<String, dynamic>? lastMessage;
  final int unreadCount;

  Conversation({
    required this.bookingId,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      bookingId: json['booking_id'] as String,
      otherUser: json['other_user'] as Map<String, dynamic>,
      lastMessage: json['last_message'] as Map<String, dynamic>?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  String get otherUserName {
    final firstName = otherUser['first_name'] ?? '';
    final lastName = otherUser['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  String? get otherUserAvatar => otherUser['profile_picture'] as String?;
}

class Message {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderType;
  final String receiverId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
    this.isRead = false,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'sender_id': senderId,
      'sender_type': senderType,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
    };
  }
}

class ChatStats {
  final int totalMessages;
  final int unreadMessages;
  final int activeConversations;

  ChatStats({
    required this.totalMessages,
    required this.unreadMessages,
    required this.activeConversations,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    return ChatStats(
      totalMessages: json['total_messages'] as int? ?? 0,
      unreadMessages: json['unread_messages'] as int? ?? 0,
      activeConversations: json['active_conversations'] as int? ?? 0,
    );
  }
}

