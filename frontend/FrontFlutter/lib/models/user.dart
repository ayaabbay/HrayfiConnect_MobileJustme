class User {
  final String id;
  final String email;
  final String phone;
  final String userType;
  final String? profilePicture;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.userType,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      userType: json['user_type'] as String,
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

class Client extends User {
  final String firstName;
  final String lastName;
  final String? address;

  Client({
    required super.id,
    required super.email,
    required super.phone,
    required this.firstName,
    required this.lastName,
    this.address,
    super.profilePicture,
  }) : super(userType: 'client');

  String get fullName => '$firstName $lastName';

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      address: json['address'] as String?,
      profilePicture: json['profile_picture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
      'profile_picture': profilePicture,
    };
  }
}

// Modèle pour les éléments du portfolio
class PortfolioItem {
  final String url;
  final String publicId;
  final String uploadedAt;

  PortfolioItem({
    required this.url,
    required this.publicId,
    required this.uploadedAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      url: json['url'] as String,
      publicId: json['public_id'] as String,
      uploadedAt: json['uploaded_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'public_id': publicId,
      'uploaded_at': uploadedAt,
    };
  }
}

class Artisan extends User {
  final String firstName;
  final String lastName;
  final String? companyName;
  final String trade;
  final String? description;
  final int? yearsOfExperience;
  final bool isVerified;
  final List<String> certifications;
  final List<PortfolioItem> portfolio; // Changé de List<String> à List<PortfolioItem>
  final String? address;
  final double? averageRating;
  final int? totalReviews;

  Artisan({
    required super.id,
    required super.email,
    required super.phone,
    required this.firstName,
    required this.lastName,
    this.companyName,
    required this.trade,
    this.description,
    this.yearsOfExperience,
    this.isVerified = false,
    this.certifications = const [],
    this.portfolio = const [],
    this.address,
    this.averageRating,
    this.totalReviews,
    super.profilePicture,
  }) : super(userType: 'artisan');

  String get fullName => '$firstName $lastName';

  factory Artisan.fromJson(Map<String, dynamic> json) {
    // Gérer le portfolio qui peut être List<String> (ancien format) ou List<Map> (nouveau format)
    List<PortfolioItem> portfolioList = [];
    final portfolioData = json['portfolio'];
    if (portfolioData != null) {
      if (portfolioData is List) {
        portfolioList = portfolioData.map((item) {
          if (item is String) {
            // Ancien format: juste l'URL
            return PortfolioItem(
              url: item,
              publicId: '',
              uploadedAt: DateTime.now().toIso8601String(),
            );
          } else if (item is Map<String, dynamic>) {
            // Nouveau format: objet avec url, public_id, uploaded_at
            return PortfolioItem.fromJson(item);
          }
          return PortfolioItem(
            url: item.toString(),
            publicId: '',
            uploadedAt: DateTime.now().toIso8601String(),
          );
        }).toList();
      }
    }

    return Artisan(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      companyName: json['company_name'] as String?,
      trade: json['trade'] as String,
      description: json['description'] as String?,
      yearsOfExperience: json['years_of_experience'] as int?,
      isVerified: json['is_verified'] as bool? ?? false,
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      portfolio: portfolioList,
      address: json['address'] as String?,
      averageRating: json['average_rating'] != null 
          ? (json['average_rating'] as num).toDouble()
          : null,
      totalReviews: json['total_reviews'] as int?,
      profilePicture: json['profile_picture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'trade': trade,
      'description': description,
      'years_of_experience': yearsOfExperience,
      'certifications': certifications,
      'address': address,
    };
  }
  
  // Helper pour obtenir les URLs du portfolio (pour compatibilité)
  List<String> get portfolioUrls => portfolio.map((item) => item.url).toList();
}

class Admin extends User {
  final String firstName;
  final String lastName;
  final String role;
  final List<String> permissions;

  Admin({
    required super.id,
    required super.email,
    required super.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.permissions = const [],
    super.profilePicture,
  }) : super(userType: 'admin');

  String get fullName => '$firstName $lastName';

  factory Admin.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile_data'] as Map<String, dynamic>? ?? {};
    return Admin(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      firstName: profileData['first_name'] as String? ?? '',
      lastName: profileData['last_name'] as String? ?? '',
      role: profileData['role'] as String? ?? '',
      permissions: (profileData['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

