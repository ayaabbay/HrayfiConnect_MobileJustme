class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final String userType;
  final String userId;
  final String email;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userType,
    required this.userId,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      userType: json['user_type'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
    );
  }
}

class RegisterClientRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String address;

  RegisterClientRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'address': address,
    };
  }
}

class RegisterArtisanRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String companyName;
  final String trade;
  final String description;
  final int yearsOfExperience;
  final List<String> certifications;

  RegisterArtisanRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.companyName,
    required this.trade,
    required this.description,
    required this.yearsOfExperience,
    required this.certifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'company_name': companyName,
      'trade': trade,
      'description': description,
      'years_of_experience': yearsOfExperience,
      'certifications': certifications,
    };
  }
}

