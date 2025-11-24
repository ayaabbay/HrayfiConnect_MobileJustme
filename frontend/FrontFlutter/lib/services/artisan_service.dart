import '../models/user.dart';
import 'api_service.dart';

class ArtisanService {
  static Future<List<Artisan>> getArtisans({
    int skip = 0,
    int limit = 100,
    String? trade,
    bool? verified,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (trade != null && trade.isNotEmpty) {
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
        if (data != null && data.isNotEmpty) {
          try {
            return data.map((json) {
              try {
                return Artisan.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('Erreur lors du parsing d\'un artisan: $e');
                print('Données JSON: $json');
                rethrow;
              }
            }).toList();
          } catch (e) {
            print('Erreur lors de la conversion des artisans: $e');
            throw Exception('Erreur lors de la conversion des données des artisans: $e');
          }
        }
      }

      return [];
    } catch (e) {
      print('Erreur dans getArtisans: $e');
      rethrow;
    }
  }
  static Future<void> updatePortfolio(String artisanId, List<String> portfolioImages) async {
  final response = await ApiService.put(
    '/users/artisans/$artisanId/portfolio',
    body: {'portfolio': portfolioImages},
  );

  if (response.statusCode != 200) {
    throw Exception('Erreur lors de la mise à jour du portfolio');
  }
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

  static Future<void> disableArtisan(String artisanId) async {
    final response = await ApiService.put('/users/artisans/$artisanId/disable');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la désactivation');
    }
  }

  static Future<void> enableArtisan(String artisanId) async {
    final response = await ApiService.put('/users/artisans/$artisanId/enable');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la réactivation');
    }
  }

  static Future<void> deleteArtisan(String artisanId) async {
    final response = await ApiService.delete('/users/artisans/$artisanId');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression');
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

