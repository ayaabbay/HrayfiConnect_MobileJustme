import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  static Future<Booking> createBooking({
    required String clientId,
    required String artisanId,
    required DateTime scheduledDate,
    required String description,
    required bool urgency, // Changé de UrgencyLevel à bool
    String? address,
  }) async {
    // Convertir la date en UTC pour correspondre au backend
    final utcDate = scheduledDate.isUtc ? scheduledDate : scheduledDate.toUtc();
    
    final body = {
      'client_id': clientId,
      'artisan_id': artisanId,
      'scheduled_date': utcDate.toIso8601String(),
      'description': description,
      'urgency': urgency,
      if (address != null && address.isNotEmpty) 'address': address,
    };

    try {
      final response = await ApiService.post('/bookings/', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.parseResponse(response);
        if (data != null) {
          return Booking.fromJson(data);
        }
      }
      throw Exception('Erreur lors de la création de la réservation');
    } catch (e) {
      if (e is ApiException) {
        throw e;
      }
      rethrow;
    }
  }

  static Future<List<Booking>> getMyBookings({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await ApiService.get(
      '/bookings/my-bookings',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<void> updateSchedule(String bookingId, DateTime scheduledDate) async {
    // Convertir la date en UTC pour correspondre au backend
    final utcDate = scheduledDate.isUtc ? scheduledDate : scheduledDate.toUtc();
    
    final response = await ApiService.put(
      '/bookings/$bookingId/schedule',
      body: {'scheduled_date': utcDate.toIso8601String()},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour de la date');
    }
  }

  static Future<void> updateStatus(String bookingId, BookingStatus status) async {
    final response = await ApiService.put(
      '/bookings/$bookingId/status',
      body: {'status': status.name},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour du statut');
    }
  }

  static Future<BookingStats> getStats() async {
    final response = await ApiService.get('/bookings/stats/me');

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return BookingStats.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la récupération des statistiques');
  }
}

