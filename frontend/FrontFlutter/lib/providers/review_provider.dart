import 'package:flutter/foundation.dart';

import '../models/review.dart';
import '../repositories/review_repository.dart';

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewRepository? repository})
      : _repository = repository ?? const ReviewRepository();

  final ReviewRepository _repository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  List<Review> _artisanReviews = [];
  List<Review> _myReviews = [];
  ReviewStats? _stats;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<Review> get artisanReviews => _artisanReviews;
  List<Review> get myReviews => _myReviews;
  ReviewStats? get stats => _stats;

  Future<void> loadArtisanReviews(
    String artisanId, {
    int? minRating,
    int? maxRating,
  }) async {
    _setLoading(true);
    try {
      _error = null;
      final reviews = await _repository.getArtisanReviews(
        artisanId,
        minRating: minRating,
        maxRating: maxRating,
      );
      _artisanReviews = reviews;
      try {
        _stats = await _repository.getArtisanStats(artisanId);
      } catch (statsError) {
        _stats = null;
        _error = statsError.toString();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyReviews() async {
    _setLoading(true);
    try {
      _myReviews = await _repository.getMyReviews();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Review?> submitReview({
    required String bookingId,
    required String clientId,
    required String artisanId,
    required int rating,
    required String comment,
    required String title,
  }) async {
    _setSubmitting(true);
    try {
      final review = await _repository.createReview(
        bookingId: bookingId,
        clientId: clientId,
        artisanId: artisanId,
        rating: rating,
        comment: comment,
        title: title,
      );
      await loadMyReviews();
      await loadArtisanReviews(artisanId);
      _error = null;
      return review;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<Review?> updateReview(
    String reviewId, {
    required String artisanId,
    int? rating,
    String? comment,
    String? title,
  }) async {
    _setSubmitting(true);
    try {
      final review = await _repository.updateReview(
        reviewId,
        rating: rating,
        comment: comment,
        title: title,
      );
      await loadMyReviews();
      await loadArtisanReviews(artisanId);
      _error = null;
      return review;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deleteReview(String reviewId, String artisanId) async {
    _setSubmitting(true);
    try {
      await _repository.deleteReview(reviewId);
      await loadMyReviews();
      await loadArtisanReviews(artisanId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Review? findMyReviewForBooking(String bookingId) {
    try {
      return _myReviews.firstWhere((review) => review.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}


