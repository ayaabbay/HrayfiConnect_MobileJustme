enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  /// Convertit le statut en format backend (snake_case)
  String get backendValue {
    switch (this) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  /// Convertit le format backend (snake_case) vers l'enum
  static TicketStatus fromBackendValue(String value) {
    switch (value) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

enum TicketCategory {
  technical,
  billing,
  account,
  booking,
  other,
}

class Ticket {
  final String id;
  final String userId;
  final TicketCategory category;
  final TicketPriority priority;
  final String subject;
  final String description;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? attachments;
  final String? adminNotes;

  Ticket({
    required this.id,
    required this.userId,
    required this.category,
    required this.priority,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attachments,
    this.adminNotes,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: TicketCategory.values.firstWhere(
        (e) => e.name == json['category'] as String,
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == json['priority'] as String,
        orElse: () => TicketPriority.medium,
      ),
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: TicketStatus.fromBackendValue(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      adminNotes: json['admin_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category': category.name,
      'priority': priority.name,
      'subject': subject,
      'description': description,
    };
  }
}

class TicketResponse {
  final String message;

  TicketResponse({required this.message});

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(message: json['message'] as String);
  }
}

