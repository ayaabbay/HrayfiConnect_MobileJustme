class User {
  final String id;
  final String email;
  final String phone;
  final String userType;
  final String? profilePicture;
  final Map<String, dynamic> profileData;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.userType,
    this.profilePicture,
    required this.profileData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile_data'] as Map<String, dynamic>? ?? {};
    
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      userType: json['user_type'] as String,
      profilePicture: profileData['profile_picture'],
      profileData: profileData,
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
    required super.profileData, // ✅ AJOUTÉ
  }) : super(userType: 'client');

  String get fullName => '$firstName $lastName';

  factory Client.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile_data'] as Map<String, dynamic>? ?? {};
    
    // Gérer profile_picture depuis profile_data ou directement depuis json
    final profilePicture = profileData['profile_picture'] as String? ?? 
                          json['profile_picture'] as String?;
    
    return Client(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      firstName: profileData['first_name'] as String? ?? '',
      lastName: profileData['last_name'] as String? ?? '',
      address: profileData['address'] as String?,
      profilePicture: profilePicture,
      profileData: profileData,
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
  final List<PortfolioItem> portfolio;
  final String? address;
  final double? averageRating;
  final int? totalReviews;
  final bool? isActive;

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
    this.isActive = true,
    super.profilePicture,
    required super.profileData,
  }) : super(userType: 'artisan');

  String get fullName => '$firstName $lastName';

  factory Artisan.fromJson(Map<String, dynamic> json) {
    final profileData = Map<String, dynamic>.from(json['profile_data'] as Map<String, dynamic>? ?? {});

    dynamic resolveValue(String key) {
      if (profileData.containsKey(key) && profileData[key] != null) {
        return profileData[key];
      }
      return json[key];
    }

    List<PortfolioItem> _parsePortfolio(dynamic source) {
      if (source is List) {
        return source.map((item) {
          if (item is String) {
            return PortfolioItem(
              url: item,
              publicId: '',
              uploadedAt: DateTime.now().toIso8601String(),
            );
          } else if (item is Map<String, dynamic>) {
            return PortfolioItem.fromJson(item);
          }
          return PortfolioItem(
            url: item.toString(),
            publicId: '',
            uploadedAt: DateTime.now().toIso8601String(),
          );
        }).toList();
      }
      return [];
    }

    final portfolioSource = resolveValue('portfolio');

    String _resolveId() {
      final String? id = json['id'] as String?;
      if (id != null) return id;
      final dynamic rawObjectId = json['_id'];
      if (rawObjectId is String) return rawObjectId;
      if (rawObjectId is Map<String, dynamic>) {
        final oid = rawObjectId[r'$oid'];
        if (oid is String) return oid;
      }
      return '';
    }

    return Artisan(
      id: _resolveId(),
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      firstName: (resolveValue('first_name') as String?) ?? '',
      lastName: (resolveValue('last_name') as String?) ?? '',
      companyName: resolveValue('company_name') as String?,
      trade: (resolveValue('trade') as String?) ?? '',
      description: resolveValue('description') as String?,
      yearsOfExperience: (resolveValue('years_of_experience') as num?)?.toInt(),
      isVerified: (resolveValue('is_verified') as bool?) ?? false,
      isActive: (resolveValue('is_active') as bool?) ?? (json['is_active'] as bool? ?? true),
      certifications: (resolveValue('certifications') as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      portfolio: _parsePortfolio(portfolioSource),
      address: resolveValue('address') as String?,
      averageRating: (resolveValue('average_rating') as num?)?.toDouble(),
      totalReviews: (resolveValue('total_reviews') as num?)?.toInt(),
      profilePicture: (resolveValue('profile_picture') as String?) ?? json['profile_picture'] as String?,
      profileData: profileData,
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
    required super.profileData, // ✅ AJOUTÉ
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
      profilePicture: profileData['profile_picture'],
      profileData: profileData, // ✅ AJOUTÉ
    );
  }
}