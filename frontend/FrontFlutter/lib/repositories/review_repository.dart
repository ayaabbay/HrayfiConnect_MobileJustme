import '../models/review.dart';
import '../services/review_service.dart';

class ReviewRepository {
  const ReviewRepository();

  Future<Review> createReview({
    required String bookingId,
    required String clientId,
    required String artisanId,
    required int rating,
    required String comment,
    required String title,
  }) {
    return ReviewService.createReview(
      bookingId: bookingId,
      clientId: clientId,
      artisanId: artisanId,
      rating: rating,
      comment: comment,
      title: title,
    );
  }

  Future<List<Review>> getArtisanReviews(
    String artisanId, {
    int skip = 0,
    int limit = 100,
    int? minRating,
    int? maxRating,
  }) {
    return ReviewService.getArtisanReviews(
      artisanId,
      skip: skip,
      limit: limit,
      minRating: minRating,
      maxRating: maxRating,
    );
  }

  Future<List<Review>> getMyReviews() {
    return ReviewService.getMyReviews();
  }

  Future<Review> getReview(String reviewId) {
    return ReviewService.getReview(reviewId);
  }

  Future<Review> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
    String? title,
  }) {
    return ReviewService.updateReview(
      reviewId,
      rating: rating,
      comment: comment,
      title: title,
    );
  }

  Future<void> deleteReview(String reviewId) {
    return ReviewService.deleteReview(reviewId);
  }

  Future<ReviewStats> getArtisanStats(String artisanId) {
    return ReviewService.getArtisanStats(artisanId);
  }
}


