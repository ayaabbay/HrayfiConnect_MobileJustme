import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class UploadService {
  static Future<Map<String, dynamic>> uploadProfilePicture(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/profile-picture'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        response: response,
      );
    }

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de l\'upload de la photo de profil');
  }

  static Future<Map<String, dynamic>> uploadIdentityDocument(
    File file,
    String documentType, // 'cin_recto' | 'cin_verso' | 'photo'
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/artisans/identity-documents/$documentType'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        response: response,
      );
    }

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de l\'upload du document');
  }

  static Future<Map<String, dynamic>> uploadPortfolioImage(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/artisans/portfolio'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        response: response,
      );
    }

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de l\'upload de l\'image du portfolio');
  }

  static Future<Map<String, dynamic>> uploadMultiplePortfolioImages(
    List<File> files,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/artisans/portfolio/multiple'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    for (var file in files) {
      request.files.add(
        await http.MultipartFile.fromPath('files', file.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        response: response,
      );
    }

    if (response.statusCode == 200) {
      final data = ApiService.parseResponse(response);
      if (data != null) {
        return data;
      }
    }

    throw Exception('Erreur lors de l\'upload des images du portfolio');
  }
}

