import 'api_service.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/review.dart';
import 'ticket_service.dart';
import 'user_service.dart';
import 'review_service.dart';
import 'artisan_service.dart';
import 'auth_service.dart';
import 'booking_service.dart';

class AdminService {
  /// Récupère les statistiques globales du dashboard admin
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Récupérer les statistiques de tickets
      final ticketStatsResponse = await ApiService.get('/tickets/stats/overview');
      Map<String, dynamic> ticketStats = {};
      if (ticketStatsResponse.statusCode == 200) {
        final data = ApiService.parseResponse(ticketStatsResponse);
        if (data != null) {
          ticketStats = data;
        }
      }

      // Récupérer les utilisateurs (clients et artisans)
      final clientsResponse = await ApiService.get('/users/clients/', queryParams: {'skip': '0', 'limit': '1'});
      final artisansResponse = await ApiService.get('/users/artisans/', queryParams: {'skip': '0', 'limit': '1'});

      // Compter le total (approximation basée sur les réponses paginées)
      // Note: Pour un vrai comptage, il faudrait un endpoint dédié
      int totalUsers = 0;
      int totalArtisans = 0;
      int totalClients = 0;

      if (clientsResponse.statusCode == 200) {
        final clientsData = ApiService.parseListResponse(clientsResponse);
        if (clientsData != null) {
          // Si on a des résultats, on peut estimer qu'il y en a plus
          // Pour l'instant, on utilise un comptage approximatif
          totalClients = clientsData.length; // Approximation
        }
      }

      if (artisansResponse.statusCode == 200) {
        final artisansData = ApiService.parseListResponse(artisansResponse);
        if (artisansData != null) {
          totalArtisans = artisansData.length; // Approximation
        }
      }

      totalUsers = totalClients + totalArtisans;

      // Récupérer les statistiques de bookings (pour l'admin, on ne peut que les estimer)
      // Note: Il faudrait un endpoint admin dédié pour les stats de bookings
      int totalBookings = 0; // Approximation

      return {
        'total_users': totalUsers,
        'total_clients': totalClients,
        'total_artisans': totalArtisans,
        'total_bookings': totalBookings,
        'tickets_open': ticketStats['open'] ?? 0,
        'tickets_total': ticketStats['total'] ?? 0,
      };
    } catch (e) {
      // En cas d'erreur, retourner des valeurs par défaut
      return {
        'total_users': 0,
        'total_clients': 0,
        'total_artisans': 0,
        'total_bookings': 0,
        'tickets_open': 0,
        'tickets_total': 0,
      };
    }
  }

  // ========== USER MANAGEMENT ==========

  /// Récupère tous les clients (Admin seulement)
  static Future<List<Client>> getClients({
    int skip = 0,
    int limit = 100,
  }) async {
    return await UserService.getClients(skip: skip, limit: limit);
  }

  /// Récupère tous les artisans (Admin seulement)
  static Future<List<Artisan>> getArtisans({
    int skip = 0,
    int limit = 100,
    String? trade,
    bool? verified,
  }) async {
    return await UserService.getArtisans(
      skip: skip,
      limit: limit,
      trade: trade,
      verified: verified,
    );
  }

  /// Recherche d'artisans (Admin seulement)
  static Future<List<Artisan>> searchArtisans({
    String? trade,
    String? location,
    int skip = 0,
    int limit = 100,
  }) async {
    return await ArtisanService.searchArtisans(
      trade: trade,
      location: location,
      skip: skip,
      limit: limit,
    );
  }

  /// Récupère les artisans en attente de vérification (Admin seulement)
  static Future<List<Artisan>> getPendingVerificationArtisans({
    int skip = 0,
    int limit = 100,
  }) async {
    return await UserService.getArtisans(
      skip: skip,
      limit: limit,
      verified: false,
    );
  }

  /// Vérifie un artisan (Admin seulement)
  static Future<void> verifyArtisan(String artisanId) async {
    final response = await ApiService.put('/users/artisans/$artisanId/verify', body: {});
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la vérification de l\'artisan');
    }
  }

  /// Supprime un client (Admin seulement)
  static Future<void> deleteClient(String clientId) async {
    await UserService.deleteClient(clientId);
  }

  /// Supprime un artisan (Admin seulement)
  static Future<void> deleteArtisan(String artisanId) async {
    final response = await ApiService.delete('/users/artisans/$artisanId');
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'artisan');
    }
  }

  // ========== TICKET MANAGEMENT ==========

  /// Récupère tous les tickets (Admin seulement)
  static Future<List<Ticket>> getAllTickets({
    int skip = 0,
    int limit = 100,
    String? status,
    String? category,
    String? priority,
  }) async {
    return await TicketService.getAllTickets(
      skip: skip,
      limit: limit,
      status: status,
      category: category,
      priority: priority,
    );
  }

  /// Récupère les statistiques des tickets (Admin seulement)
  static Future<Map<String, dynamic>> getTicketStatsOverview() async {
    return await TicketService.getTicketStatsOverview();
  }

  /// Récupère un ticket spécifique (Admin seulement)
  static Future<Ticket> getTicket(String ticketId) async {
    return await TicketService.getTicket(ticketId);
  }

  /// Met à jour le statut d'un ticket (Admin seulement)
  static Future<Ticket> updateTicketStatus(
    String ticketId, {
    required TicketStatus status,
    String? adminNotes,
  }) async {
    return await TicketService.updateTicketStatus(
      ticketId,
      status: status,
      adminNotes: adminNotes,
    );
  }

  /// Ajoute une réponse à un ticket (Admin seulement)
  static Future<void> addTicketResponse(String ticketId, String message) async {
    await TicketService.addTicketResponse(ticketId, message);
  }

  /// Supprime un ticket (Admin seulement)
  static Future<void> deleteTicket(String ticketId) async {
    await TicketService.deleteTicket(ticketId);
  }

  // ========== BOOKING MANAGEMENT ==========

  /// Récupère toutes les réservations (Admin seulement)
  static Future<List<Booking>> getAllBookings({
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
      '/bookings/',
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

  /// Récupère une réservation spécifique (Admin seulement)
  static Future<Booking> getBooking(String bookingId) async {
    return await BookingService.getBooking(bookingId);
  }

  /// Met à jour une réservation (Admin seulement)
  static Future<Booking> updateBooking(
    String bookingId, {
    DateTime? scheduledDate,
    String? description,
    bool? urgency,
    String? address,
    BookingStatus? status,
  }) async {
    return await BookingService.updateBookingAsAdmin(
      bookingId,
      scheduledDate: scheduledDate,
      description: description,
      urgency: urgency,
      address: address,
      status: status,
    );
  }

  /// Supprime une réservation (Admin seulement)
  static Future<void> deleteBooking(String bookingId) async {
    await BookingService.deleteBookingAsAdmin(bookingId);
  }

  // ========== REVIEW MANAGEMENT ==========
  // Note: Le backend n'a pas d'endpoint GET /api/v1/reviews/ pour admin
  // Seuls /artisans/{id} et /my-reviews existent

  /// Récupère un avis spécifique (Admin seulement)
  static Future<Review> getReview(String reviewId) async {
    return await ReviewService.getReview(reviewId);
  }

  /// Supprime un avis (Admin seulement)
  static Future<void> deleteReview(String reviewId) async {
    await ReviewService.deleteReview(reviewId);
  }

  /// Récupère les statistiques de notation d'un artisan (Admin seulement)
  static Future<ReviewStats> getArtisanReviewStats(String artisanId) async {
    return await ReviewService.getArtisanStats(artisanId);
  }

  // ========== IDENTITY DOCUMENTS ==========

  /// Récupère les documents d'identité d'un artisan (Admin seulement)
  static Future<Map<String, dynamic>> getArtisanIdentityDocuments(String artisanId) async {
    final response = await ApiService.get('/upload/artisans/$artisanId/identity-documents');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }
    throw Exception('Erreur lors de la récupération des documents d\'identité');
  }

  // ========== UTILITY METHODS ==========

  /// Vérifie la disponibilité d'un email (Admin seulement)
  static Future<bool> checkEmailAvailability(String email) async {
    return await AuthService.checkEmailAvailability(email);
  }

  /// Récupère les routes de debug (Admin seulement)
  /// Note: Endpoint de debug, peut ne pas être disponible en production
  static Future<Map<String, dynamic>> getDebugRoutes() async {
    final response = await ApiService.get('/bookings/debug/routes');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }
    throw Exception('Erreur lors de la récupération des routes de debug');
  }
}

