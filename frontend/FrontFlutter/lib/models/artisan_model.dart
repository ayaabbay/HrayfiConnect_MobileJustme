class Artisan {
  final String id;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String companyName;
  final String trade;
  final String description;
  final int yearsOfExperience;
  final String? profilePicture;
  final List<Map<String, dynamic>> portfolio;
  final Map<String, dynamic>? identityDocument;
  final bool isVerified;
  final List<String> certifications;
  final String userType;
  final DateTime createdAt;

  Artisan({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.companyName,
    required this.trade,
    required this.description,
    required this.yearsOfExperience,
    this.profilePicture,
    required this.portfolio,
    this.identityDocument,
    required this.isVerified,
    required this.certifications,
    required this.userType,
    required this.createdAt,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      companyName: json['company_name'] ?? '',
      trade: json['trade'] ?? '',
      description: json['description'] ?? '',
      yearsOfExperience: json['years_of_experience'] ?? 0,
      profilePicture: json['profile_picture'],
      portfolio: List<Map<String, dynamic>>.from(json['portfolio'] ?? []),
      identityDocument: json['identity_document'],
      isVerified: json['is_verified'] ?? false,
      certifications: List<String>.from(json['certifications'] ?? []),
      userType: json['user_type'] ?? 'artisan',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'trade': trade,
      'description': description,
      'years_of_experience': yearsOfExperience,
      'profile_picture': profilePicture,
      'portfolio': portfolio,
      'identity_document': identityDocument,
      'is_verified': isVerified,
      'certifications': certifications,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Extension pour copier l'objet Artisan
extension ArtisanCopyWith on Artisan {
  Artisan copyWith({
    String? firstName,
    String? lastName,
    String? companyName,
    String? trade,
    String? description,
    int? yearsOfExperience,
    String? profilePicture,
    List<Map<String, dynamic>>? portfolio,
    List<String>? certifications,
    bool? isVerified,
  }) {
    return Artisan(
      id: id,
      email: email,
      phone: phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      trade: trade ?? this.trade,
      description: description ?? this.description,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      profilePicture: profilePicture ?? this.profilePicture,
      portfolio: portfolio ?? this.portfolio,
      identityDocument: identityDocument,
      isVerified: isVerified ?? this.isVerified,
      certifications: certifications ?? this.certifications,
      userType: userType,
      createdAt: createdAt,
    );
  }
}

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