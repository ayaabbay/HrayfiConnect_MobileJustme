import 'package:flutter/material.dart';
import '../../models/artisan_model.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/api_service.dart';
import 'widgets/client_card.dart';

class ArtisanUrgentDashboardPage extends StatefulWidget {
  final Function(String) onAcceptUrgent;
  final Function(String) onDeclineUrgent;

  const ArtisanUrgentDashboardPage({
    Key? key,
    required this.onAcceptUrgent,
    required this.onDeclineUrgent,
  }) : super(key: key);

  @override
  State<ArtisanUrgentDashboardPage> createState() => _ArtisanUrgentDashboardPageState();
}

class _ArtisanUrgentDashboardPageState extends State<ArtisanUrgentDashboardPage> {
  List<ArtisanClient> _clients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer tous les bookings en attente de l'artisan
      final bookings = await BookingService.getMyBookings(status: 'pending');
      
      // Convertir les bookings en ArtisanClient
      _clients = bookings.map((booking) {
        final clientName = booking.clientName ?? 'Client inconnu';
        final description = booking.description;
        
        return ArtisanClient(
          id: booking.id,
          name: clientName,
          avatar: booking.client?['profile_picture'] as String? ?? 'https://ui-avatars.com/api/?name=$clientName&background=random',
          lastMessage: description,
          timestamp: _formatTimestamp(booking.createdAt),
          unread: 0,
          status: booking.status.name,
          project: description.length > 30 ? '${description.substring(0, 30)}...' : description,
          isUrgent: booking.urgency,
        );
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  void _handleClientTap(ArtisanClient client) {
    // Navigation vers les messages avec ce client
    print('Client tapped: ${client.id}');
    // TODO: Navigate to chat page
  }

  Future<void> _handleAccept(ArtisanClient client) async {
    try {
      await BookingService.updateStatus(client.id, BookingStatus.confirmed);
      widget.onAcceptUrgent(client.id);
      setState(() {
        _clients.removeWhere((c) => c.id == client.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande acceptée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'acceptation';
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

  Future<void> _handleDecline(ArtisanClient client) async {
    try {
      await BookingService.updateStatus(client.id, BookingStatus.rejected);
      widget.onDeclineUrgent(client.id);
      setState(() {
        _clients.removeWhere((c) => c.id == client.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors du refus';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
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
                        onPressed: _loadBookings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tableau de Bord',
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Gérez vos demandes clients',
                                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadBookings,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                        // Section Demandes Urgentes
                        if (_clients.any((client) => client.isUrgent))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Demandes Urgentes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ..._clients.where((client) => client.isUrgent).map((client) => ClientCard(
                                  client: client,
                                  onTap: () => _handleClientTap(client),
                                  onAccept: () => _handleAccept(client),
                                  onDecline: () => _handleDecline(client),
                                )),
                              ],
                            ),
                          ),
                      
                        // Section Autres Clients
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16),
                              Text(
                                _clients.any((client) => !client.isUrgent) 
                                    ? 'Autres Demandes' 
                                    : _clients.isEmpty 
                                        ? 'Aucune demande' 
                                        : 'Toutes les Demandes',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              if (_clients.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                                        SizedBox(height: 16),
                                        Text(
                                          'Aucune demande en attente',
                                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ..._clients.where((client) => !client.isUrgent).map((client) => ClientCard(
                                  client: client,
                                  onTap: () => _handleClientTap(client),
                                  onAccept: () => _handleAccept(client),
                                  onDecline: () => _handleDecline(client),
                                )),
                            ],
                          ),
                        ),
                        SizedBox(height: 16), // Espace en bas pour éviter le débordement
                      ],
                    ),
                  ),
                ),
    );
  }
}