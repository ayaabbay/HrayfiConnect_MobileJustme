// MODÈLES SPÉCIFIQUES PARTIE ARTISAN
class ArtisanClient {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String timestamp;
  final int unread;
  final String status; // 'urgent', 'pending', 'completed'
  final String project;
  final bool isUrgent;

  ArtisanClient({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
    required this.status,
    required this.project,
    this.isUrgent = false,
  });
}

class ArtisanMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isUrgent;

  ArtisanMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isUrgent = false,
  });
}

class ArtisanAppointment {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime dateTime;
  final String type; // 'urgent', 'normal'
  final String status; // 'pending', 'confirmed', 'completed'

  ArtisanAppointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.dateTime,
    required this.type,
    required this.status,
  });
}

// Données d'exemple pour tests PARTIE ARTISAN
List<ArtisanClient> mockArtisanClients = [
  ArtisanClient(
    id: "1",
    name: "Sarah Alami",
    avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop",
    lastMessage: "Merci pour votre travail, c'est parfait!",
    timestamp: "10:30",
    unread: 2,
    status: "completed",
    project: "Installation électrique",
    isUrgent: false,
  ),
  ArtisanClient(
    id: "2", 
    name: "Hassan Tazi",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop",
    lastMessage: "Pouvez-vous venir demain matin? C'est urgent!",
    timestamp: "09:15",
    unread: 0,
    status: "pending",
    project: "Réparation urgente",
    isUrgent: true,
  ),
];