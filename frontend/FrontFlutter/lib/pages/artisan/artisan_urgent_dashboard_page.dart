import 'package:flutter/material.dart';
import '../../models/artisan_model.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/api_service.dart';
import 'widgets/client_card.dart';

class ArtisanUrgentDashboardPage extends StatefulWidget {
  final Function(String) onAcceptUrgent;
  final Function(String) onDeclineUrgent;
  final ValueChanged<int>? onUrgentCountChanged;

  const ArtisanUrgentDashboardPage({
    Key? key,
    required this.onAcceptUrgent,
    required this.onDeclineUrgent,
    this.onUrgentCountChanged,
  }) : super(key: key);

  @override
  State<ArtisanUrgentDashboardPage> createState() => _ArtisanUrgentDashboardPageState();
}

class _ArtisanUrgentDashboardPageState extends State<ArtisanUrgentDashboardPage> {
  List<ArtisanClient> _clients = [];
  List<Booking> _acceptedBookings = [];
  bool _isLoading = true;
  bool _isLoadingAccepted = false;
  String? _error;
  final Set<String> _statusUpdating = {};
  final List<BookingStatus> _statusChoices = const [
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.inProgress,
    BookingStatus.completed,
    BookingStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadAcceptedBookings();
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
      final urgentPending = _clients.where((client) => client.isUrgent && client.status == 'pending').length;
      widget.onUrgentCountChanged?.call(urgentPending);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // NOUVELLE MÉTHODE: Charger les réservations acceptées
  Future<void> _loadAcceptedBookings() async {
    setState(() {
      _isLoadingAccepted = true;
    });

    try {
      // Récupérer les réservations confirmées et en cours
      final confirmedBookings = await BookingService.getMyBookings(status: 'confirmed');
      final inProgressBookings = await BookingService.getMyBookings(status: 'in_progress');
      
      // Combiner les deux listes
      final allAccepted = [...confirmedBookings, ...inProgressBookings];
      
      setState(() {
        _acceptedBookings = allAccepted;
        _isLoadingAccepted = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAccepted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des réservations acceptées: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NOUVELLE MÉTHODE: Changer le statut d'une réservation
  Future<void> _updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    try {
      await BookingService.updateStatus(bookingId, newStatus);
      
      // Recharger les réservations acceptées
      await _loadAcceptedBookings();
      
      if (mounted) {
        final statusText = newStatus == BookingStatus.completed ? 'complétée' : 'en cours';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation marquée comme $statusText avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la mise à jour du statut';
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
      await _loadBookings();
      await _loadAcceptedBookings();
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
      await _loadBookings();
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

  Future<void> _handleStandardStatusChange(String bookingId, BookingStatus newStatus) async {
    setState(() {
      _statusUpdating.add(bookingId);
    });
    try {
      await BookingService.updateStatus(bookingId, newStatus);
      await _loadBookings();
      await _loadAcceptedBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${newStatus.name}'),
            backgroundColor: Colors.blueGrey.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la mise à jour du statut';
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
    } finally {
      if (mounted) {
        setState(() {
          _statusUpdating.remove(bookingId);
        });
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
                  onRefresh: () async {
                    await _loadBookings();
                    await _loadAcceptedBookings();
                  },
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
                                    onPressed: () async {
                                      await _loadBookings();
                                      await _loadAcceptedBookings();
                                    },
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
                                ..._clients.where((client) => !client.isUrgent).map((client) {
                                  final currentStatus = BookingStatus.fromString(client.status);
                                  return ClientCard(
                                    client: client,
                                    onTap: () => _handleClientTap(client),
                                    onAccept: () => _handleAccept(client),
                                    onDecline: () => _handleDecline(client),
                                    currentStatus: currentStatus,
                                    statusOptions: _statusChoices,
                                    onStatusChanged: (status) => _handleStandardStatusChange(client.id, status),
                                    isStatusUpdating: _statusUpdating.contains(client.id),
                                  );
                                }),
                            ],
                          ),
                        ),
                        
                        // NOUVELLE SECTION: Réservations Acceptées
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 24),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Réservations Acceptées',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (_isLoadingAccepted)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_acceptedBookings.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                                        SizedBox(height: 16),
                                        Text(
                                          'Aucune réservation acceptée',
                                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ..._acceptedBookings.map((booking) => _buildAcceptedBookingCard(booking)),
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

  // NOUVELLE MÉTHODE: Construire une carte pour une réservation acceptée
  Widget _buildAcceptedBookingCard(Booking booking) {
    final clientName = booking.clientName ?? 'Client inconnu';
    final isCompleted = booking.status == BookingStatus.completed;
    final isInProgress = booking.status == BookingStatus.inProgress;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: booking.client?['profile_picture'] != null
                      ? NetworkImage(booking.client!['profile_picture'] as String)
                      : null,
                  child: booking.client?['profile_picture'] == null
                      ? Text(
                          clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            '${booking.scheduledDate.hour}h${booking.scheduledDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    isCompleted ? 'Complétée' : isInProgress ? 'En cours' : booking.status.name,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: isCompleted ? Colors.teal : Colors.blue,
                ),
              ],
            ),
            if (booking.description.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Text(
                booking.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            // Boutons pour changer le statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isInProgress)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateBookingStatus(booking.id, BookingStatus.inProgress),
                      icon: Icon(Icons.play_arrow, size: 18),
                      label: Text('En cours'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                if (!isInProgress) SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isCompleted
                        ? null
                        : () => _updateBookingStatus(booking.id, BookingStatus.completed),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('Compléter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.teal.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le client peut maintenant noter cette réservation',
                        style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}