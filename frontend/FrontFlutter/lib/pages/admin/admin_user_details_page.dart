import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';

class AdminUserDetailsPage extends StatefulWidget {
  final Client? client;
  final Artisan? artisan;

  const AdminUserDetailsPage({
    super.key,
    this.client,
    this.artisan,
  }) : assert(client != null || artisan != null, 'Either client or artisan must be provided');

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  Map<String, dynamic>? _identityDocuments;
  bool _isLoadingDocuments = false;

  @override
  void initState() {
    super.initState();
    if (widget.artisan != null) {
      _loadIdentityDocuments();
    }
  }

  Future<void> _loadIdentityDocuments() async {
    if (widget.artisan == null) return;
    
    setState(() {
      _isLoadingDocuments = true;
    });

    try {
      final documents = await AdminService.getArtisanIdentityDocuments(widget.artisan!.id);
      setState(() {
        _identityDocuments = documents;
        _isLoadingDocuments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDocuments = false;
      });
      // Ne pas afficher d'erreur si les documents n'existent pas encore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.client != null;
    final user = isClient ? widget.client! : widget.artisan!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isClient ? 'Détails du client' : 'Détails de l\'artisan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo de profil
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                foregroundColor: Colors.indigo,
                backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null || user.profilePicture!.isEmpty
                    ? Icon(
                        isClient ? Icons.person : Icons.home_repair_service,
                        size: 60,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Informations de base
            _buildSection(
              context,
              'Informations personnelles',
              [
                _buildInfoRow('Nom complet', widget.client?.fullName ?? widget.artisan?.fullName ?? ''),
                _buildInfoRow('Email', user.email),
                _buildInfoRow('Téléphone', user.phone),
                if (isClient && widget.client!.address != null)
                  _buildInfoRow('Adresse', widget.client!.address!),
              ],
            ),

            // Informations spécifiques à l'artisan
            if (!isClient && widget.artisan != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Informations professionnelles',
                [
                  if (widget.artisan!.companyName != null)
                    _buildInfoRow('Entreprise', widget.artisan!.companyName!),
                  _buildInfoRow('Métier', widget.artisan!.trade),
                  _buildInfoRow(
                    'Années d\'expérience',
                    widget.artisan!.yearsOfExperience?.toString() ?? 'Non spécifié',
                  ),
                  _buildInfoRow(
                    'Statut de vérification',
                    widget.artisan!.isVerified ? 'Vérifié' : 'Non vérifié',
                    valueColor: widget.artisan!.isVerified ? Colors.green : Colors.orange,
                  ),
                  _buildInfoRow(
                    'Statut',
                    widget.artisan!.isActive ?? true ? 'Actif' : 'Inactif',
                    valueColor: widget.artisan!.isActive ?? true ? Colors.green : Colors.red,
                  ),
                ],
              ),
              if (widget.artisan!.description != null && widget.artisan!.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoRow('Description', widget.artisan!.description!, isMultiline: true),
              ],
              if (widget.artisan!.certifications.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Certifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.artisan!.certifications
                      .map((cert) => Chip(
                            label: Text(cert),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                          ))
                      .toList(),
                ),
              ],
              // Documents d'identité
              const SizedBox(height: 24),
              _buildIdentityDocumentsSection(context),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isMultiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIdentityDocumentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carte d\'Identité',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingDocuments
                ? const Center(child: CircularProgressIndicator())
                : _identityDocuments == null ||
                        (_identityDocuments!['cin_recto'] == null &&
                            _identityDocuments!['cin_verso'] == null)
                    ? const Text(
                        'Aucun document d\'identité uploadé',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Row(
                        children: [
                          // Recto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_identityDocuments!['cin_recto'] != null)
                                  GestureDetector(
                                    onTap: () => _showImageDialog(
                                      context,
                                      _identityDocuments!['cin_recto'] as String,
                                      'Recto',
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _identityDocuments!['cin_recto'] as String,
                                        fit: BoxFit.cover,
                                        height: 150,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 150,
                                            color: Colors.grey.shade300,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Non disponible',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Verso
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Verso',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_identityDocuments!['cin_verso'] != null)
                                  GestureDetector(
                                    onTap: () => _showImageDialog(
                                      context,
                                      _identityDocuments!['cin_verso'] as String,
                                      'Verso',
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _identityDocuments!['cin_verso'] as String,
                                        fit: BoxFit.cover,
                                        height: 150,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 150,
                                            color: Colors.grey.shade300,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Non disponible',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

