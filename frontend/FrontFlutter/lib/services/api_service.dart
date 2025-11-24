import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.apiBaseUrl;
  
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(includeAuth: includeAuth),
      );
      
      // Gestion des erreurs HTTP
      _handleHttpError(response);
      
      return response;
    } catch (e) {
      // Gérer les erreurs de connexion (ClientException)
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('Connection refused')) {
        throw ApiException(
          statusCode: 0,
          message: 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur $baseUrl',
        );
      }
      rethrow;
    }
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    
    // Gestion des erreurs HTTP
    _handleHttpError(response);
    
    return response;
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    
    // Gestion des erreurs HTTP
    _handleHttpError(response);
    
    return response;
  }

  static Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
    );
    
    // Gestion des erreurs HTTP
    _handleHttpError(response);
    
    return response;
  }
  
  static void _handleHttpError(http.Response response) {
    if (response.statusCode >= 400) {
      final errorMessage = extractErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        response: response,
      );
    }
  }
  
  static String extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        return json['detail'] ?? json['message'] ?? 'Une erreur est survenue';
      }
    } catch (e) {
      // Ignorer si le parsing échoue
    }
    return 'Une erreur est survenue (${response.statusCode})';
  }

  static Future<http.StreamedResponse> postMultipart(
    String endpoint, {
    required http.MultipartRequest request,
    bool includeAuth = true,
  }) async {
    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    request.headers['Content-Type'] = 'multipart/form-data';
    
    final response = await request.send();
    return response;
  }

  static Map<String, dynamic>? parseResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static List<dynamic>? parseListResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }
}

// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final http.Response? response;

  ApiException({
    required this.statusCode,
    required this.message,
    this.response,
  });

  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}

