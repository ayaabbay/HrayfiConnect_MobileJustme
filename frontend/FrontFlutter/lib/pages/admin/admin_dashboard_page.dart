import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer les statistiques de tickets
      final ticketStatsResponse = await ApiService.get('/tickets/stats/overview');
      Map<String, dynamic> ticketStats = {};
      if (ticketStatsResponse.statusCode == 200) {
        final data = ApiService.parseResponse(ticketStatsResponse);
        if (data != null) {
          ticketStats = data;
        }
      }

      // Récupérer les utilisateurs
      final clients = await UserService.getClients(limit: 1000);
      final artisans = await UserService.getArtisans(limit: 1000);

      // Récupérer les bookings
      int totalBookings = 0;
      try {
        final bookings = await AdminService.getAllBookings(limit: 1000);
        totalBookings = bookings.length;
      } catch (e) {
        print('Erreur récupération bookings: $e');
        // Continuer même si les bookings ne peuvent pas être récupérés
      }

      setState(() {
        _stats = {
          'total_users': clients.length + artisans.length,
          'total_clients': clients.length,
          'total_artisans': artisans.length,
          'total_bookings': totalBookings,
          'tickets_open': ticketStats['open'] ?? 0,
          'tickets_total': ticketStats['total'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
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
                      onPressed: _loadStats,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatCard(
                          title: 'Utilisateurs',
                          value: _formatNumber(_stats['total_users'] ?? 0),
                          icon: Icons.people_outline,
                          color: Colors.indigo,
                        ),
                        _StatCard(
                          title: 'Artisans',
                          value: _formatNumber(_stats['total_artisans'] ?? 0),
                          icon: Icons.home_repair_service_outlined,
                          color: Colors.teal,
                        ),
                        _StatCard(
                          title: 'Clients',
                          value: _formatNumber(_stats['total_clients'] ?? 0),
                          icon: Icons.person_outline,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          title: 'Réservations',
                          value: _formatNumber(_stats['total_bookings'] ?? 0),
                          icon: Icons.calendar_today_outlined,
                          color: Colors.purple,
                        ),
                        _StatCard(
                          title: 'Tickets ouverts',
                          value: _formatNumber(_stats['tickets_open'] ?? 0),
                          icon: Icons.support_agent,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Activité récente'),
                            trailing: IconButton(
                              onPressed: _loadStats,
                              icon: const Icon(Icons.refresh),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.circle, size: 10, color: Colors.green),
                            title: Text('Total tickets: ${_stats['tickets_total'] ?? 0}'),
                            subtitle: const Text('Statistiques du système'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: color.withOpacity(0.07),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


