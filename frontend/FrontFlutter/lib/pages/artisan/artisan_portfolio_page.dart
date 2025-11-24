import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/user_service.dart';
import '../../services/artisan_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';

class ArtisanPortfolioPage extends StatefulWidget {
  const ArtisanPortfolioPage({Key? key}) : super(key: key);

  @override
  State<ArtisanPortfolioPage> createState() => _ArtisanPortfolioPageState();
}

class _ArtisanPortfolioPageState extends State<ArtisanPortfolioPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _tradeController = TextEditingController();
  
  List<String> _certifications = [];
  List<Map<String, dynamic>> _portfolioImages = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _userId;
  String? _userType;
  String? _profilePictureUrl;
  XFile? _selectedProfileImage;
  Uint8List? _selectedProfileImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userInfo = await StorageService.getUserInfo();
      _userId = userInfo['userId'];
      _userType = userInfo['userType'];
      
      if (_userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final profile = await UserService.getUserProfile();
      final profileData = Map<String, dynamic>.from(
        profile['profile_data'] as Map<String, dynamic>? ?? {},
      );
      final rawPortfolio = profileData['portfolio'];
      List<Map<String, dynamic>> portfolioItems = [];
      if (rawPortfolio is List) {
        portfolioItems = rawPortfolio.map<Map<String, dynamic>>((item) {
          if (item is Map<String, dynamic>) {
            return Map<String, dynamic>.from(item);
          } else if (item is Map) {
            return Map<String, dynamic>.from(item.map((key, value) => MapEntry(key.toString(), value)));
          }
          return {
            'url': item.toString(),
          };
        }).toList();
      }
      
      setState(() {
        _firstNameController.text = profileData['first_name'] ?? '';
        _lastNameController.text = profileData['last_name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _descriptionController.text = profileData['description'] ?? '';
        _companyController.text = profileData['company_name'] ?? '';
        _tradeController.text = profileData['trade'] ?? '';
        _certifications = List<String>.from(profileData['certifications'] ?? []);
        _profilePictureUrl = profileData['profile_picture'] ?? profile['profile_picture'];
        _portfolioImages = portfolioItems;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // MÉTHODE CORRIGÉE : Sélectionner une photo de profil
  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedProfileImage = image;
          _selectedProfileImageBytes = bytes;
        });
        
        // Uploader l'image immédiatement
        await _uploadProfilePicture();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: ${e.toString()}');
    }
  }

  // MÉTHODE CORRIGÉE : Uploader la photo de profil
  Future<void> _uploadProfilePicture() async {
    if (_selectedProfileImage == null) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final uploadResult = await UploadService.uploadProfilePicture(_selectedProfileImage!);
      final uploadedUrl = uploadResult['url'] as String;

      setState(() {
        _profilePictureUrl = uploadedUrl;
        _selectedProfileImage = null;
        _selectedProfileImageBytes = null;
      });

      await _loadProfile();
      _showSuccessSnackBar('Photo de profil mise à jour avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'upload: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // MÉTHODE CORRIGÉE : Sélectionner une image pour le portfolio
  Future<void> _pickPortfolioImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadPortfolioImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: ${e.toString()}');
    }
  }

  // MÉTHODE CORRIGÉE : Uploader une image de portfolio
  Future<void> _uploadPortfolioImage(XFile imageFile) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final uploadResult = await UploadService.uploadPortfolioImage(imageFile);
      final uploadedUrl = uploadResult['url'] as String;
      final publicId = uploadResult['public_id'] as String;

      // Créer l'objet portfolio
      final portfolioItem = {
        'url': uploadedUrl,
        'public_id': publicId,
        'uploaded_at': DateTime.now().toIso8601String(),
      };

      setState(() {
        _portfolioImages.add(portfolioItem);
      });

      await _loadProfile();

      _showSuccessSnackBar('Image ajoutée au portfolio avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'upload: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // MÉTHODE CORRIGÉE : Supprimer une image du portfolio
  Future<void> _removePortfolioImage(int index) async {
    if (index < 0 || index >= _portfolioImages.length) return;

    try {
      setState(() {
        _isSaving = true;
      });

      // Supprimer de la liste locale
      final removedImage = _portfolioImages.removeAt(index);

      // Mettre à jour le profil
      await ArtisanService.updateArtisan(
        artisanId: _userId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        companyName: _companyController.text.trim(),
        trade: _tradeController.text.trim(),
        description: _descriptionController.text.trim(),
        certifications: _certifications,
      );

      _showSuccessSnackBar('Image supprimée du portfolio');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression: ${e.toString()}');
      // Re-ajouter l'image en cas d'erreur
      setState(() {
        // Note: On ne re-ajoute pas car l'index est perdu, on recharge plutôt
        _loadProfile();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _addCertification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une certification'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Nom de la certification'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _certifications.add(value);
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ArtisanService.updateArtisan(
        artisanId: _userId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        companyName: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        trade: _tradeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        certifications: _certifications,
      );

      _showSuccessSnackBar('Profil mis à jour avec succès');
    } catch (e) {
      String errorMessage = 'Erreur lors de la sauvegarde';
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      setState(() {
        _error = errorMessage;
      });
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Portfolio Artisan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !_isSaving
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo de profil
          _buildProfilePictureSection(),
          const SizedBox(height: 24),
          
          // Informations personnelles
          _buildPersonalInfoSection(),
          const SizedBox(height: 24),
          
          // Certifications
          _buildCertificationsSection(),
          const SizedBox(height: 24),
          
          // Portfolio Photos
          _buildPortfolioSection(),
          const SizedBox(height: 24),
          
          // Bouton Sauvegarder
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Photo de Profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      onPressed: _isSaving ? null : _pickProfilePicture,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _pickProfilePicture,
              child: const Text('Changer la photo'),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
      return NetworkImage(_profilePictureUrl!);
    } else if (_selectedProfileImageBytes != null) {
      return MemoryImage(_selectedProfileImageBytes!);
    }
    return null;
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations Personnelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFormField('Prénom', _firstNameController),
            _buildFormField('Nom', _lastNameController),
            _buildFormField('Email', _emailController, enabled: false),
            _buildFormField('Entreprise', _companyController),
            _buildFormField('Métier', _tradeController),
            _buildFormField('Description', _descriptionController, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Certifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _isSaving ? null : _addCertification,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _certifications.map((cert) => Chip(
                label: Text(cert),
                onDeleted: _isSaving ? null : () {
                  setState(() {
                    _certifications.remove(cert);
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _pickPortfolioImage,
              child: const Text('Ajouter une image au portfolio'),
            ),
            const SizedBox(height: 16),
            _portfolioImages.isEmpty
                ? const Text(
                    'Aucune image dans le portfolio',
                    style: TextStyle(color: Colors.grey),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _portfolioImages.length,
                    itemBuilder: (context, index) {
                      final image = _portfolioImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image['url'] ?? '',
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                onPressed: _isSaving ? null : () => _removePortfolioImage(index),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Sauvegarder le Profil'),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {
    int maxLines = 1, 
    bool enabled = true
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled && !_isSaving,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _companyController.dispose();
    _tradeController.dispose();
    super.dispose();
  }
}