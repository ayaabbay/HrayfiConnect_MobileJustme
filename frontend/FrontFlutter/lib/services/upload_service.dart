import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class UploadService {
  // Fonction helper pour déterminer le MediaType depuis le nom de fichier
  static MediaType _getMediaTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'bmp':
        return MediaType('image', 'bmp');
      case 'webp':
        return MediaType('image', 'webp');
      case 'svg':
        return MediaType('image', 'svg+xml');
      default:
        return MediaType('image', 'jpeg'); // Par défaut
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(dynamic file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/profile-picture'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Gérer le cas web et mobile différemment
    if (kIsWeb) {
      // Pour Flutter Web, file est un XFile
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        final contentType = _getMediaTypeFromFileName(fileName);
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: contentType,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté pour le web');
      }
    } else {
      // Pour mobile, file est un File
      if (file is File) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      } else if (file is XFile) {
        // Fallback pour XFile sur mobile
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        final contentType = _getMediaTypeFromFileName(fileName);
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: contentType,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté');
      }
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

    throw Exception('Erreur lors de l\'upload de la photo de profil');
  }
  static Future<String> uploadImage(
    dynamic file, {
    String folder = 'uploads',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/image'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Ajouter le dossier si spécifié
    if (folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    // Gérer le cas web et mobile différemment
    if (kIsWeb) {
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté pour le web');
      }
    } else {
      if (file is File) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      } else if (file is XFile) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté');
      }
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
      if (data != null && data['url'] != null) {
        return data['url'] as String;
      }
    }

    throw Exception('Erreur lors de l\'upload de l\'image');
  }
  static Future<Map<String, dynamic>> uploadIdentityDocument(
    dynamic file,
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

    // Gérer le cas web et mobile différemment
    if (kIsWeb) {
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté pour le web');
      }
    } else {
      if (file is File) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      } else if (file is XFile) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté');
      }
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

    throw Exception('Erreur lors de l\'upload du document');
  }

  static Future<Map<String, dynamic>> uploadPortfolioImage(dynamic file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload/artisans/portfolio'),
    );

    final token = await StorageService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Gérer le cas web et mobile différemment
    if (kIsWeb) {
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté pour le web');
      }
    } else {
      if (file is File) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );
      } else if (file is XFile) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('Format de fichier non supporté');
      }
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

    throw Exception('Erreur lors de l\'upload de l\'image du portfolio');
  }

  static Future<Map<String, dynamic>> uploadMultiplePortfolioImages(
    List<dynamic> files,
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
      if (kIsWeb) {
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          final fileName = file.name;
          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              bytes,
              filename: fileName,
            ),
          );
        }
      } else {
        if (file is File) {
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path),
          );
        } else if (file is XFile) {
          final bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              bytes,
              filename: file.name,
            ),
          );
        }
      }
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

