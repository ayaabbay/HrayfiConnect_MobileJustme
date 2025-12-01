class Review {
  final String id;
  final String bookingId;
  final String clientId;
  final String artisanId;
  final int rating;
  final String comment;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? clientName;
  final String? artisanName;

  Review({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.artisanId,
    required this.rating,
    required this.comment,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.clientName,
    this.artisanName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Gérer les valeurs null avec des valeurs par défaut
    final id = json['id'] ?? json['_id'] ?? '';
    final bookingId = json['booking_id']?.toString() ?? '';
    final clientId = json['client_id']?.toString() ?? '';
    final artisanId = json['artisan_id']?.toString() ?? '';
    final rating = (json['rating'] as num?)?.toInt() ?? 0;
    final comment = json['comment']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    
    // Gérer les dates avec des valeurs par défaut
    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    try {
      updatedAt = json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now();
    } catch (e) {
      updatedAt = DateTime.now();
    }
    
    return Review(
      id: id.toString(),
      bookingId: bookingId,
      clientId: clientId,
      artisanId: artisanId,
      rating: rating,
      comment: comment,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      clientName: json['client_name']?.toString(),
      artisanName: json['artisan_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'client_id': clientId,
      'artisan_id': artisanId,
      'rating': rating,
      'comment': comment,
      'title': title,
    };
  }
}

class ReviewStats {
  final String artisanId;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingDistribution;

  ReviewStats({
    required this.artisanId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    // Gérer les valeurs null avec des valeurs par défaut
    final artisanId = json['artisan_id']?.toString() ?? '';
    final averageRating = (json['average_rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = (json['total_reviews'] as num?)?.toInt() ?? 0;
    
    // Gérer la distribution des notes
    Map<String, int> ratingDistribution = {};
    if (json['rating_distribution'] != null && json['rating_distribution'] is Map) {
      try {
        ratingDistribution = Map<String, int>.from(
          (json['rating_distribution'] as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toInt() ?? 0,
            ),
          ),
        );
      } catch (e) {
        ratingDistribution = {};
      }
    }
    
    return ReviewStats(
      artisanId: artisanId,
      averageRating: averageRating,
      totalReviews: totalReviews,
      ratingDistribution: ratingDistribution,
    );
  }
}

