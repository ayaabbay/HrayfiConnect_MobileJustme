import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/artisan_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';

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
  List<String> _services = [];
  List<String> _portfolioImages = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _userId;

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
      _userId = userInfo['userId']!;
      
      final profile = await UserService.getUserProfile();
      final profileData = profile['profile_data'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        _firstNameController.text = profileData['first_name'] ?? '';
        _lastNameController.text = profileData['last_name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _descriptionController.text = profileData['description'] ?? '';
        _companyController.text = profileData['company_name'] ?? '';
        _tradeController.text = profileData['trade'] ?? '';
        _certifications = List<String>.from(profileData['certifications'] ?? []);
        // Services n'est pas stocké dans le profil, on peut le garder localement
        _portfolioImages = []; // Sera chargé depuis portfolio
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addCertification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter une certification'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Nom de la certification'),
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
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _addService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un service'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Nom du service'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _services.add(value);
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mon Portfolio',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Photo de profil
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop"),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Changer la photo'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Informations personnelles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations Personnelles',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    _buildFormField('Prénom', _firstNameController),
                    _buildFormField('Nom', _lastNameController),
                    _buildFormField('Email', _emailController),
                    _buildFormField('Entreprise', _companyController),
                    _buildFormField('Métier', _tradeController),
                    _buildFormField('Description', _descriptionController, maxLines: 3),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Certifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Certifications',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _addCertification,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _certifications.map((cert) => Chip(
                        label: Text(cert),
                        onDeleted: () {
                          setState(() {
                            _certifications.remove(cert);
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Services
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Services',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _addService,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _services.map((service) => Chip(
                        label: Text(service),
                        onDeleted: () {
                          setState(() {
                            _services.remove(service);
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Portfolio Photos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _portfolioImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _portfolioImages.length) {
                          return GestureDetector(
                            onTap: () {
                              // Ajouter une photo
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, size: 40, color: Colors.grey),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _portfolioImages[index],
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: Icon(Icons.close, size: 12, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _portfolioImages.removeAt(index);
                                    });
                                  },
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
            ),
            
            SizedBox(height: 16),
            
            // Bouton Sauvegarder
            Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sauvegarder le Profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}