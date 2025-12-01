import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/artisan_service.dart';
import 'admin_user_details_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Client> _clients = [];
  List<Artisan> _artisans = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clients = await UserService.getClients();
      final artisans = await UserService.getArtisans();
      setState(() {
        _clients = clients;
        _artisans = artisans;
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Remplacement du TabBar par un Row avec des ChoiceChips
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 4),
                      Text('Clients'),
                    ],
                  ),
                  selected: _selectedTab == 0,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTab = 0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_repair_service_outlined, size: 18),
                      SizedBox(width: 4),
                      Text('Artisans'),
                    ],
                  ),
                  selected: _selectedTab == 1,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTab = 1);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
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
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : _selectedTab == 0
                      ? _buildClientsList()
                      : _buildArtisansList(),
        ),
      ],
    );
  }

  Widget _buildClientsList() {
    if (_clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun client',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final client = _clients[index];
        // Récupérer la photo de profil depuis profilePicture ou profileData
        final profilePicture = client.profilePicture ?? 
                              (client.profileData['profile_picture'] as String?);
        final hasProfilePicture = profilePicture != null && profilePicture.isNotEmpty;
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.1),
              foregroundColor: Colors.indigo,
              backgroundImage: hasProfilePicture ? NetworkImage(profilePicture!) : null,
              child: !hasProfilePicture ? const Icon(Icons.person_outline) : null,
            ),
            title: Text(client.fullName),
            subtitle: Text('${client.email} • ${client.phone}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUserDetailsPage(client: client),
                    ),
                  );
                } else if (value == 'disable') {
                  // TODO: Implémenter la désactivation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Voir'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'disable',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Désactiver'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtisansList() {
    if (_artisans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_repair_service_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun artisan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _artisans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final artisan = _artisans[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.1),
              foregroundColor: Colors.teal,
              backgroundImage: artisan.profilePicture != null ? NetworkImage(artisan.profilePicture!) : null,
              child: artisan.profilePicture == null ? const Icon(Icons.home_repair_service_outlined) : null,
            ),
            title: Row(
              children: [
                Expanded(child: Text(artisan.fullName)),
                if (artisan.isVerified)
                  Icon(Icons.verified, size: 18, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            subtitle: Text('${artisan.trade} • ${artisan.email}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                try {
                  if (value == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserDetailsPage(artisan: artisan),
                      ),
                    );
                  } else if (value == 'verify' && !artisan.isVerified) {
                    await ArtisanService.verifyArtisan(artisan.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Artisan vérifié avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else if (value == 'disable') {
                    // Demander confirmation avant de désactiver
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Désactiver l\'artisan'),
                        content: Text('Êtes-vous sûr de vouloir désactiver ${artisan.fullName} ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                            child: const Text('Désactiver'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await ArtisanService.disableArtisan(artisan.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Artisan désactivé avec succès'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } else if (value == 'enable') {
                    await ArtisanService.enableArtisan(artisan.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Artisan réactivé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    // Demander confirmation avant de supprimer
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer l\'artisan'),
                        content: Text(
                          'Êtes-vous sûr de vouloir supprimer définitivement ${artisan.fullName} ?\n\nCette action est irréversible.',
                          style: const TextStyle(color: Colors.red),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await ArtisanService.deleteArtisan(artisan.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Artisan supprimé avec succès'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                  
                  // Recharger la liste après toute action
                  _loadUsers();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                if (!artisan.isVerified)
                  const PopupMenuItem(
                    value: 'verify',
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 18),
                        SizedBox(width: 8),
                        Text('Vérifier'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Voir'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: artisan.isActive ?? true ? 'disable' : 'enable',
                  child: Row(
                    children: [
                      Icon(
                        artisan.isActive ?? true ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: artisan.isActive ?? true ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(artisan.isActive ?? true ? 'Désactiver' : 'Réactiver'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


