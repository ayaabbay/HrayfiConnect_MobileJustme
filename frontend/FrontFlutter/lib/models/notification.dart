class Notification {
  final String id;
  final String userId;
  final String type;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

