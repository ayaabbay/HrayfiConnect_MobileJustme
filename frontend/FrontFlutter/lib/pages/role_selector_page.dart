import 'package:flutter/material.dart';

class RoleSelectorPage extends StatelessWidget {
  static const routeName = '/';
  const RoleSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un rôle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _RoleCard(
              title: 'Client',
              description: 'Rechercher des artisans, réserver (urgent/normal), chatter, profil',
              icon: Icons.search,
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              title: 'Artisan',
              description: 'Demandes urgentes, calendrier, portfolio, messagerie',
              icon: Icons.home_repair_service_outlined,
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              title: 'Admin',
              description: 'Gérer utilisateurs, services, tickets support',
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.deepOrange,
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}


