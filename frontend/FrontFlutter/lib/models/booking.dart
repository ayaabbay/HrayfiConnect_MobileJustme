enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected;

  String get value => name;
  
  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

class Booking {
  final String id;
  final String clientId;
  final String artisanId;
  final DateTime scheduledDate;
  final String description;
  final bool urgency; // Changé de UrgencyLevel à bool
  final String? address;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Informations détaillées du client et artisan (depuis BookingDetailedResponse)
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? artisan;

  Booking({
    required this.id,
    required this.clientId,
    required this.artisanId,
    required this.scheduledDate,
    required this.description,
    required this.urgency,
    this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.client,
    this.artisan,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      artisanId: json['artisan_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      description: json['description'] as String,
      urgency: json['urgency'] is bool 
          ? json['urgency'] as bool
          : (json['urgency'] == true || json['urgency'] == 'true'),
      address: json['address'] as String?,
      status: BookingStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      client: json['client'] as Map<String, dynamic>?,
      artisan: json['artisan'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'artisan_id': artisanId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'description': description,
      'urgency': urgency,
      'address': address,
    };
  }
  
  // Helpers pour accéder aux informations détaillées
  String? get clientName {
    if (client != null) {
      final firstName = client!['first_name'] ?? '';
      final lastName = client!['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return null;
  }
  
  String? get artisanName {
    if (artisan != null) {
      final firstName = artisan!['first_name'] ?? '';
      final lastName = artisan!['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return null;
  }
  
  String? get clientPhone => client?['phone'] as String?;
  String? get artisanPhone => artisan?['phone'] as String?;
}

class BookingStats {
  final int total;
  final int pending;
  final int confirmed;
  final int inProgress;
  final int completed;
  final int cancelled;

  BookingStats({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      total: json['total'] as int,
      pending: json['pending'] as int,
      confirmed: json['confirmed'] as int,
      inProgress: json['in_progress'] as int,
      completed: json['completed'] as int,
      cancelled: json['cancelled'] as int,
    );
  }
}

