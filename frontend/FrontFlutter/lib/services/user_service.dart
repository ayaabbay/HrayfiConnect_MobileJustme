import '../models/user.dart';
import 'api_service.dart';

class UserService {
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await ApiService.get('/users/profile');

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de la récupération du profil');
  }

  static Future<Client> getClient(String clientId) async {
    final response = await ApiService.get('/users/clients/$clientId');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Client.fromJson(data);
      }
    }
    throw Exception('Client introuvable');
  }
  static Future<List<Client>> getClients({
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    final response = await ApiService.get(
      '/users/clients/',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Client.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<Client> updateClient(
    String clientId, {
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? profilePicture,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (profilePicture != null) body['profile_picture'] = profilePicture;

    final response = await ApiService.put('/users/clients/$clientId', body: body);

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Client.fromJson(data);
      }
    }

    throw Exception('Erreur lors de la mise à jour du client');
  }

  static Future<void> deleteClient(String clientId) async {
    final response = await ApiService.delete('/users/clients/$clientId');
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du client');
    }
  }

  static Future<List<Artisan>> getArtisans({
    int skip = 0,
    int limit = 100,
    String? trade,
    bool? verified,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (trade != null) {
      queryParams['trade'] = trade;
    }
    if (verified != null) {
      queryParams['verified'] = verified.toString();
    }

    final response = await ApiService.get(
      '/users/artisans/',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseListResponse(response);
      if (data != null) {
        return data.map((json) => Artisan.fromJson(json as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  static Future<Artisan> getArtisan(String artisanId) async {
    final response = await ApiService.get('/users/artisans/$artisanId');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Artisan.fromJson(data);
      }
    }
    throw Exception('Artisan introuvable');
  }

  /// Récupère les artisans en attente de vérification (Admin seulement)
  /// Utilise l'endpoint /users/artisans/ avec verified=false
  static Future<List<Artisan>> getPendingVerificationArtisans({
    int skip = 0,
    int limit = 100,
  }) async {
    return await getArtisans(
      skip: skip,
      limit: limit,
      verified: false,
    );
  }

  /// Met à jour un artisan (Admin ou propriétaire)
  static Future<Artisan> updateArtisan(
    String artisanId, {
    String? firstName,
    String? lastName,
    String? companyName,
    String? trade,
    String? description,
    int? yearsOfExperience,
    List<String>? certifications,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (companyName != null) body['company_name'] = companyName;
    if (trade != null) body['trade'] = trade;
    if (description != null) body['description'] = description;
    if (yearsOfExperience != null) body['years_of_experience'] = yearsOfExperience;
    if (certifications != null) body['certifications'] = certifications;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;

    final response = await ApiService.put('/users/artisans/$artisanId', body: body);
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return Artisan.fromJson(data);
      }
    }
    throw Exception('Erreur lors de la mise à jour de l\'artisan');
  }
}

