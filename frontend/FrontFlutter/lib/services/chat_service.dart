import '../models/message.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  /// Récupère toutes les conversations de l'utilisateur connecté
  static Future<List<Conversation>> getConversations() async {
    final response = await ApiService.get('/chat/conversations');

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  /// Récupère les messages d'une conversation spécifique
  static Future<List<Message>> getMessages(String bookingId) async {
    final response = await ApiService.get('/chat/conversations/$bookingId/messages');

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  /// Envoie un message dans une conversation via REST
  static Future<Message> sendMessage({
    required String bookingId,
    required String receiverId,
    required String content,
    required String senderType,
    required String senderId,
  }) async {
    final body = {
      'booking_id': bookingId,
      'sender_id': senderId,
      'sender_type': senderType,
      'receiver_id': receiverId,
      'content': content,
      'message_type': 'text',
    };

    final response = await ApiService.post('/chat/conversations/$bookingId/messages', body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Message.fromJson(data);
      }
    }

    throw Exception('Erreur lors de l\'envoi du message');
  }

  /// Marque les messages d'une conversation comme lus
  static Future<void> markAsRead(String bookingId) async {
    final response = await ApiService.post('/chat/conversations/$bookingId/read');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors du marquage des messages comme lus');
    }
  }

  /// Récupère les statistiques de chat
  static Future<ChatStats> getStats() async {
    final response = await ApiService.get('/chat/stats');

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return ChatStats.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la récupération des statistiques');
  }

  static Future<WebSocketChannel> connectWebSocket() async {
    final token = await StorageService.getToken();
    final baseUri = Uri.parse('${ApiService.baseUrl}/chat/ws/chat');
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final queryParams = Map<String, String>.from(baseUri.queryParameters);
    if (token != null) {
      queryParams['token'] = token;
    }
    final wsUri = baseUri.replace(
      scheme: scheme,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return WebSocketChannel.connect(wsUri);
  }
}

