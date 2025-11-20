import '../config/api_config.dart';
import '../models/auth.dart'; // IMPORT AJOUTÉ
import '../models/user.dart';
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
      await StorageService.clearAll(); // CORRIGÉ : clear() → clearAll()
    }
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

  // Ajout des méthodes d'inscription manquantes
  static Future<void> registerClient(RegisterClientRequest request) async {
    final response = await ApiService.post(
      '/auth/register/client',
      body: request.toJson(),
      includeAuth: false,
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l\'inscription client');
    }
  }

  static Future<void> registerArtisan(RegisterArtisanRequest request) async {
    final response = await ApiService.post(
      '/auth/register/artisan',
      body: request.toJson(),
      includeAuth: false,
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l\'inscription artisan');
    }
  }
}