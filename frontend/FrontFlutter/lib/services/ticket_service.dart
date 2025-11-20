import '../models/ticket.dart';
import 'api_service.dart';

class TicketService {
  static Future<Ticket> createTicket({
    required String userId,
    required TicketCategory category,
    required TicketPriority priority,
    required String subject,
    required String description,
  }) async {
    final body = {
      'user_id': userId,
      'category': category.name,
      'priority': priority.name,
      'subject': subject,
      'description': description,
    };

    final response = await ApiService.post('/tickets/', body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Ticket.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la création du ticket');
  }

  static Future<List<Ticket>> getMyTickets({
    int skip = 0,
    int limit = 100,
    String? status,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (status != null) {
      queryParams['status'] = status;
    }
    if (category != null) {
      queryParams['category'] = category;
    }

    final response = await ApiService.get(
      '/tickets/my-tickets',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<List<Ticket>> getAllTickets({
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    final response = await ApiService.get(
      '/tickets/',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<Ticket> updateTicketStatus(
    String ticketId, {
    required TicketStatus status,
    String? adminNotes,
  }) async {
    final body = <String, dynamic>{
      'status': status.name,
    };
    if (adminNotes != null) {
      body['admin_notes'] = adminNotes;
    }

    final response = await ApiService.put('/tickets/$ticketId/status', body: body);

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Ticket.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la mise à jour du ticket');
  }

  static Future<void> addTicketResponse(String ticketId, String message) async {
    final response = await ApiService.post(
      '/tickets/$ticketId/responses',
      body: {'message': message},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'ajout de la réponse');
    }
  }
}

