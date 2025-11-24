import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  static Future<Review> createReview({
    required String bookingId,
    required String clientId,
    required String artisanId,
    required int rating,
    required String comment,
    required String title,
  }) async {
    final body = {
      'booking_id': bookingId,
      'client_id': clientId,
      'artisan_id': artisanId,
      'rating': rating,
      'comment': comment,
      'title': title,
    };

    final response = await ApiService.post('/reviews', body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Review.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la création de l\'avis');
  }

  static Future<List<Review>> getArtisanReviews(
    String artisanId, {
    int skip = 0,
    int limit = 100,
    int? minRating,
    int? maxRating,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (minRating != null) {
      queryParams['min_rating'] = minRating.toString();
    }
    if (maxRating != null) {
      queryParams['max_rating'] = maxRating.toString();
    }

    final response = await ApiService.get(
      '/reviews/artisans/$artisanId',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<List<Review>> getMyReviews() async {
    final response = await ApiService.get('/reviews/my-reviews');

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<Review> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
    String? title,
  }) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;
    if (title != null) body['title'] = title;

    final response = await ApiService.put('/reviews/$reviewId', body: body);

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Review.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la mise à jour de l\'avis');
  }

  static Future<ReviewStats> getArtisanStats(String artisanId) async {
    final response = await ApiService.get('/reviews/artisans/$artisanId/stats');

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return ReviewStats.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la récupération des statistiques');
  }
}

