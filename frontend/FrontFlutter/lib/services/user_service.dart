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
}

