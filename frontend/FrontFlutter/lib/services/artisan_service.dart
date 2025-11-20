import '../models/user.dart';
import 'api_service.dart';

class ArtisanService {
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

  static Future<List<Artisan>> searchArtisans({
    String? trade,
    String? location,
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (trade != null) {
      queryParams['trade'] = trade;
    }
    if (location != null) {
      queryParams['location'] = location;
    }

    final response = await ApiService.get(
      '/users/artisans/search',
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

  static Future<void> verifyArtisan(String artisanId) async {
    final response = await ApiService.put('/users/artisans/$artisanId/verify');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la vérification');
    }
  }

  static Future<Artisan> updateArtisan({
    required String artisanId,
    String? firstName,
    String? lastName,
    String? companyName,
    String? trade,
    String? description,
    int? yearsOfExperience,
    List<String>? certifications,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (companyName != null) body['company_name'] = companyName;
    if (trade != null) body['trade'] = trade;
    if (description != null) body['description'] = description;
    if (yearsOfExperience != null) body['years_of_experience'] = yearsOfExperience;
    if (certifications != null) body['certifications'] = certifications;

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

