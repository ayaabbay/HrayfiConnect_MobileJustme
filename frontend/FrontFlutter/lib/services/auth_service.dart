import '../config/api_config.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        final token = data['access_token'] as String;
        final userType = data['user_type'] as String;
        final userId = data['user_id'] as String;
        final email = data['email'] as String;

        // Sauvegarder le token et les infos utilisateur
        await StorageService.saveToken(token);
        await StorageService.saveUserInfo(
          userId: userId,
          userType: userType,
          email: email,
        );

        return {
          'token': token,
          'userType': userType,
          'userId': userId,
          'email': email,
        };
      }
    }

    throw Exception('Erreur lors de la connexion');
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout');
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    } finally {
      await StorageService.clearAll();
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiService.get('/auth/me');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }
    throw Exception('Erreur lors de la récupération de l\'utilisateur connecté');
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await ApiService.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        final token = data['access_token'] as String?;
        if (token != null) {
          await StorageService.saveToken(token);
        }
        return data;
      }
    }

    throw Exception('Impossible de rafraîchir le token');
  }

  /// Demande de réinitialisation de mot de passe - Envoie un code par email
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiService.post(
      '/auth/forgot-password',
      body: {'email': email},
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de la demande de réinitialisation');
  }

  /// Vérifie le code de réinitialisation et obtient un token temporaire
  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    final response = await ApiService.post(
      '/auth/verify-reset-code',
      body: {
        'email': email,
        'code': code,
      },
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Code invalide ou expiré');
  }

  /// Réinitialise le mot de passe avec le token temporaire
  static Future<Map<String, dynamic>> resetPassword(String resetToken, String newPassword) async {
    final response = await ApiService.post(
      '/auth/reset-password',
      body: {
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de la réinitialisation du mot de passe');
  }

  static Future<bool> checkEmailAvailability(String email) async {
    final response = await ApiService.get(
      '/auth/check-email/$email',
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data['available'] as bool? ?? true;
      }
      return true;
    }

    throw Exception('Erreur lors de la vérification de l\'email');
  }

  static Future<Map<String, dynamic>> testEndpoint() async {
    final response = await ApiService.get('/auth/test');
    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }
    throw Exception('Erreur lors de l\'appel du endpoint de test');
  }

  // NOUVELLES MÉTHODES D'INSCRIPTION CORRIGÉES
  static Future<Map<String, dynamic>> registerClient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    String? address,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      };
      
      if (address != null && address.isNotEmpty) {
        body['address'] = address;
      }

      // DEBUG
      print('🎯 REGISTER CLIENT - Données envoyées: $body');

      final response = await ApiService.post(
        '/auth/register/client',
        body: body,
        includeAuth: false,
      );

      // CORRECTION: L'API retourne 200, pas 201
      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        print('✅ INSCRIPTION CLIENT RÉUSSIE: $data');
        return data ?? {};
      } else {
        final errorData = ApiService.parseResponse(response);
        print('❌ ERREUR INSCRIPTION CLIENT: $errorData');
        throw Exception(errorData?['detail'] ?? 'Erreur lors de l\'inscription client');
      }
    } catch (e) {
      print('❌ ERREUR CATCH INSCRIPTION CLIENT: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> registerArtisan({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String companyName,
    required String trade,
    required String description,
    int yearsOfExperience = 0,
    List<String> certifications = const [],
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'company_name': companyName,
        'trade': trade,
        'description': description,
        'years_of_experience': yearsOfExperience,
        'certifications': certifications,
      };

      print('🎯 REGISTER ARTISAN - Données envoyées: $body');

      final response = await ApiService.post(
        '/auth/register/artisan',
        body: body,
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        print('✅ INSCRIPTION ARTISAN RÉUSSIE: $data');
        return data ?? {};
      } else {
        final errorData = ApiService.parseResponse(response);
        print('❌ ERREUR INSCRIPTION ARTISAN: $errorData');
        throw Exception(errorData?['detail'] ?? 'Erreur lors de l\'inscription artisan');
      }
    } catch (e) {
      print('❌ ERREUR INSCRIPTION ARTISAN: $e');
      rethrow;
    }
  }
}