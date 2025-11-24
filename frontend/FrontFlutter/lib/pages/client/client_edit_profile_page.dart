import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:typed_data';
import '../../services/user_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';
import '../../models/user.dart';

class ClientEditProfilePage extends StatefulWidget {
  const ClientEditProfilePage({super.key});

  @override
  State<ClientEditProfilePage> createState() => _ClientEditProfilePageState();
}

class _ClientEditProfilePageState extends State<ClientEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _languageController = TextEditingController(text: 'Français');
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _profilePictureUrl;
  String? _userId;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () async {
                  final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, pickedImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Caméra'),
                onTap: () async {
                  final XFile? pickedImage = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, pickedImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _isSaving = true;
        _selectedImageBytes = bytes;
      });

      try {
        // Passer directement XFile au lieu de File pour compatibilité web
        final result = await UploadService.uploadProfilePicture(image);
        setState(() {
          _profilePictureUrl = result['url'] as String?;
          _isSaving = false;
        });
        
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger le profil pour mettre à jour l'avatar
        _loadProfile();
      }
      } catch (e) {
        setState(() {
          _isSaving = false;
          _selectedImage = null;
        });
        
        if (mounted) {
          String errorMessage = 'Erreur lors de l\'upload';
          if (e is ApiException) {
            errorMessage = e.message;
          } else {
            errorMessage = e.toString();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await UserService.getUserProfile();
      final profileData = profile['profile_data'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        _userId = profile['id'] as String?;
        _firstNameController.text = profileData['first_name'] ?? '';
        _lastNameController.text = profileData['last_name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _addressController.text = profileData['address'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (_userId == null) {
        throw Exception('Impossible de déterminer l\'identifiant utilisateur');
      }

      await UserService.updateClient(
        _userId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la sauvegarde';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          errorMessage = e.toString();
        }
        setState(() {
          _error = errorMessage;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !_isSaving
              ? Center(
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
                )
              : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo de profil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                        ? NetworkImage(_profilePictureUrl!)
                        : (_selectedImageBytes != null
                            ? MemoryImage(_selectedImageBytes!)
                            : null) as ImageProvider?,
                    child: _profilePictureUrl == null && _selectedImage == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
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
                        onPressed: _pickProfilePicture,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Prénom
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Nom
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Email (readonly)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                helperText: 'L\'email ne peut pas être modifié',
              ),
            ),
            const SizedBox(height: 16),
            // Téléphone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Adresse
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre adresse';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Langue
            DropdownButtonFormField<String>(
              initialValue: _languageController.text,
              decoration: const InputDecoration(
                labelText: 'Langue',
                prefixIcon: Icon(Icons.language_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Français', child: Text('Français')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Español', child: Text('Español')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _languageController.text = value;
                }
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}