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
    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      clientId: json['client_id'] as String,
      artisanId: json['artisan_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      clientName: json['client_name'] as String?,
      artisanName: json['artisan_name'] as String?,
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
    return ReviewStats(
      artisanId: json['artisan_id'] as String,
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: json['total_reviews'] as int,
      ratingDistribution: Map<String, int>.from(
        json['rating_distribution'] as Map,
      ),
    );
  }
}

