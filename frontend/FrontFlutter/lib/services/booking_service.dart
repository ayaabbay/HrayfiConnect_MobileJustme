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

  static Future<Booking> getBooking(String bookingId) async {
    final response = await ApiService.get('/bookings/$bookingId');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Booking.fromJson(data);
      }
    }
    throw Exception('Réservation introuvable');
  }

  static Future<Booking> updateBooking(
    String bookingId, {
    DateTime? scheduledDate,
    String? description,
    bool? urgency,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (scheduledDate != null) {
      final utcDate = scheduledDate.isUtc ? scheduledDate : scheduledDate.toUtc();
      body['scheduled_date'] = utcDate.toIso8601String();
    }
    if (description != null) body['description'] = description;
    if (urgency != null) body['urgency'] = urgency;
    if (address != null) body['address'] = address;

    final response = await ApiService.put('/bookings/$bookingId', body: body);
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Booking.fromJson(data);
      }
    }
    throw Exception('Erreur lors de la mise à jour de la réservation');
  }

  static Future<void> deleteBooking(String bookingId) async {
    final response = await ApiService.delete('/bookings/$bookingId');
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de la réservation');
    }
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
      body: {'status': status.value},
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

  // ========== ADMIN METHODS ==========
  // Note: Le backend n'a pas d'endpoint admin dédié pour les bookings
  // Les admins peuvent utiliser les mêmes endpoints que les utilisateurs normaux
  // Pour obtenir toutes les bookings, un admin devrait utiliser getMyBookings
  // mais cela ne fonctionnera que si l'admin a des bookings personnelles
  
  /// Met à jour une réservation (Admin peut tout modifier)
  static Future<Booking> updateBookingAsAdmin(
    String bookingId, {
    DateTime? scheduledDate,
    String? description,
    bool? urgency,
    String? address,
    BookingStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (scheduledDate != null) {
      final utcDate = scheduledDate.isUtc ? scheduledDate : scheduledDate.toUtc();
      body['scheduled_date'] = utcDate.toIso8601String();
    }
    if (description != null) body['description'] = description;
    if (urgency != null) body['urgency'] = urgency;
    if (address != null) body['address'] = address;
    if (status != null) body['status'] = status.value;

    final response = await ApiService.put('/bookings/$bookingId', body: body);
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Booking.fromJson(data);
      }
    }
    throw Exception('Erreur lors de la mise à jour de la réservation');
  }

  /// Supprime une réservation (Admin seulement)
  static Future<void> deleteBookingAsAdmin(String bookingId) async {
    await deleteBooking(bookingId);
  }
}

