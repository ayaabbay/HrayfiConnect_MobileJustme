import 'package:flutter/material.dart';
import 'client_edit_profile_page.dart';
import 'client_history_page.dart';
import 'client_review_page.dart';
import 'client_ticket_page.dart';
import '../role_selector_page.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  Client? _client;
  bool _isLoading = true;
  String? _error;

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
      final profile = await UserService.getUserProfile();
      final profileData = profile['profile_data'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        _client = Client(
          id: profile['id'] as String,
          email: profile['email'] as String,
          phone: profile['phone'] as String,
          firstName: profileData['first_name'] ?? '',
          lastName: profileData['last_name'] ?? '',
          address: profileData['address'],
          profilePicture: profileData['profile_picture'] as String?,
          profileData: profileData,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      if (!mounted) return;

      // Rediriger proprement vers la page de connexion et
      // vider toute la pile de navigation pour empêcher le retour au dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
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
            : RefreshIndicator( // ICI - la parenthèse ouvrante
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête profil
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: _client?.profilePicture != null
                                ? NetworkImage(_client!.profilePicture!)
                                : null,
                            child: _client?.profilePicture == null
                                ? const Icon(Icons.person, size: 32)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _client?.fullName ?? 'Client',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(_client?.email ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                  
                      const SizedBox(height: 24),
                      // Actions rapides
                      Text(
                        'Actions rapides',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ProfileActionCard(
                            icon: Icons.edit_note,
                            color: Colors.indigo,
                            title: 'Modifier profil',
                            subtitle: 'Nom, adresse, préférences',
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ClientEditProfilePage()),
                              );
                              // Recharger le profil après modification
                              _loadProfile();
                            },
                          ),
                          _ProfileActionCard(
                            icon: Icons.history,
                            color: Colors.teal,
                            title: 'Historique',
                            subtitle: 'Mes réservations',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ClientHistoryPage()),
                              );
                            },
                          ),
                          _ProfileActionCard(
                            icon: Icons.star_rate_rounded,
                            color: Colors.amber.shade700,
                            title: 'Écrire un avis',
                            subtitle: 'Noter un artisan',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ClientReviewPage()),
                              );
                            },
                          ),
                          _ProfileActionCard(
                            icon: Icons.support_agent,
                            color: Colors.deepOrange,
                            title: 'Ticket support',
                            subtitle: 'Signaler un problème',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ClientTicketPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Paramètres
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: const Text('Adresse'),
                              subtitle: Text(_client?.address ?? 'Aucune adresse'),
                              trailing: IconButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ClientEditProfilePage()),
                                  );
                                  _loadProfile(); // Recharger le profil après modification
                                },
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.notifications_outlined),
                              title: const Text('Notifications'),
                              subtitle: const Text('Urgent, réservations, messages'),
                              trailing: Switch(value: true, onChanged: (_) {}),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Déconnexion'),
                                    content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Annuler'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _logout();
                                        },
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Déconnexion'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ), // ICI - la parenthèse fermante manquante pour le SingleChildScrollView
              ); // ICI - la parenthèse fermante pour le RefreshIndicator
  }
}

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}