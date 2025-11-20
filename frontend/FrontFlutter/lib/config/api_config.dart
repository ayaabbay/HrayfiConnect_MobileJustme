import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Détection automatique de l'URL selon la plateforme
  static String get baseUrl {
    // Pour le web, utiliser localhost
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    
    // Pour les plateformes mobiles, vérifier l'OS
    try {
      // Pour Android emulator, utiliser 10.0.2.2 au lieu de localhost
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
      // Pour iOS simulator ou autres plateformes
      return 'http://localhost:8000';
    } catch (e) {
      // En cas d'erreur (ex: Platform non disponible), utiliser localhost
      return 'http://localhost:8000';
    }
  }
  
  // Préfixe API versionné
  static const String apiPrefix = '/api/v1';
  
  // URL complète de l'API
  static String get apiBaseUrl => '$baseUrl$apiPrefix';
}

