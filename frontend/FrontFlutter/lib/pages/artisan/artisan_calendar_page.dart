import 'package:flutter/material.dart';
import '../../models/artisan_model.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/api_service.dart';

class ArtisanCalendarPage extends StatefulWidget {
  const ArtisanCalendarPage({Key? key}) : super(key: key);

  @override
  State<ArtisanCalendarPage> createState() => _ArtisanCalendarPageState();
}

class _ArtisanCalendarPageState extends State<ArtisanCalendarPage> {
  List<ArtisanAppointment> _appointments = [];
  DateTime _selectedDate = DateTime.now();
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
      // Récupérer tous les bookings de l'artisan
      final bookings = await BookingService.getMyBookings();
      
      // Convertir les bookings en ArtisanAppointment
      _appointments = bookings.map((booking) {
        final clientName = booking.clientName ?? 'Client inconnu';
        
        return ArtisanAppointment(
          id: booking.id,
          clientId: booking.clientId,
          clientName: clientName,
          dateTime: booking.scheduledDate,
          type: booking.urgency ? "urgent" : "normal",
          status: booking.status.name,
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
              : Column(
                  children: [
                    // Header Calendrier
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Calendrier',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadBookings,
                          ),
                        ],
                      ),
                    ),
          
                    // Vue Mois
                    Container(
                      padding: EdgeInsets.all(16),
                      child: _buildMonthView(),
                    ),
          
                    // Rendez-vous du jour
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rendez-vous du ${_selectedDate.day}/${_selectedDate.month}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Expanded(
                              child: _buildAppointmentsList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMonthView() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête jours
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map((day) => Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: 35, // 5 semaines
            itemBuilder: (context, index) {
              final day = index - 2; // Ajuster pour commencer au bon jour
              final currentDay = DateTime.now();
              final displayDate = DateTime(currentDay.year, currentDay.month, currentDay.day + day);
              
              final hasAppointment = _appointments.any((apt) =>
                  apt.dateTime.year == displayDate.year &&
                  apt.dateTime.month == displayDate.month &&
                  apt.dateTime.day == displayDate.day);
              
              // Récupérer les rendez-vous de ce jour
              final dayAppointments = _appointments.where((apt) =>
                  apt.dateTime.year == displayDate.year &&
                  apt.dateTime.month == displayDate.month &&
                  apt.dateTime.day == displayDate.day).toList();
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = displayDate;
                  });
                  
                  // Si la date a des rendez-vous, afficher la modale
                  if (hasAppointment && dayAppointments.isNotEmpty) {
                    _showReservationDetails(context, displayDate, dayAppointments);
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _selectedDate.day == displayDate.day && 
                           _selectedDate.month == displayDate.month
                        ? Colors.blue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayDate.day.toString(),
                        style: TextStyle(
                          color: _selectedDate.day == displayDate.day && 
                                 _selectedDate.month == displayDate.month
                              ? Colors.white
                              : Colors.black,
                          fontWeight: hasAppointment ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (hasAppointment)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _selectedDate.day == displayDate.day && 
                                   _selectedDate.month == displayDate.month
                                ? Colors.white
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final dayAppointments = _appointments.where((apt) =>
        apt.dateTime.year == _selectedDate.year &&
        apt.dateTime.month == _selectedDate.month &&
        apt.dateTime.day == _selectedDate.day).toList();
    
    if (dayAppointments.isEmpty) {
      return Center(
        child: Text(
          'Aucun rendez-vous ce jour',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    return FutureBuilder<List<Booking>>(
      future: BookingService.getMyBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Aucun rendez-vous ce jour',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        final bookings = snapshot.data!;
        
        return ListView.builder(
          shrinkWrap: true,
          itemCount: dayAppointments.length,
          itemBuilder: (context, index) {
            final apt = dayAppointments[index];
            final booking = bookings.firstWhere(
              (b) => b.id == apt.id,
              orElse: () => bookings.first,
            );
            
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: apt.type == "urgent" ? Colors.red : Colors.blue,
                  child: Icon(
                    apt.type == "urgent" ? Icons.warning : Icons.schedule,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  apt.clientName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${apt.dateTime.hour}h${apt.dateTime.minute.toString().padLeft(2, '0')} - ${apt.type == "urgent" ? "Urgent" : "Normal"}'),
                trailing: Chip(
                  label: Text(
                    _getStatusText(apt.status),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(apt.status),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Informations du client:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(child: Text('Nom: ${apt.clientName}')),
                          ],
                        ),
                        if (booking.clientName != null && booking.clientName!.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(child: Text('Nom complet: ${booking.clientName}')),
                            ],
                          ),
                        ],
                        if (booking.client != null) ...[
                          if (booking.client!['phone'] != null && booking.client!['phone'].toString().isNotEmpty) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(child: Text('Téléphone: ${booking.client!['phone']}')),
                              ],
                            ),
                          ],
                          if (booking.client!['email'] != null && booking.client!['email'].toString().isNotEmpty) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(child: Text('Email: ${booking.client!['email']}')),
                              ],
                            ),
                          ],
                        ],
                        // Afficher l'adresse de la réservation (qui est l'adresse où l'artisan doit se rendre)
                        if (booking.address != null && booking.address!.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(child: Text('Adresse de la réservation: ${booking.address}')),
                            ],
                          ),
                        ] else if (booking.client != null && booking.client!['address'] != null && booking.client!['address'].toString().isNotEmpty) ...[
                          // Fallback sur l'adresse du client si l'adresse de réservation n'est pas disponible
                          SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(child: Text('Adresse: ${booking.client!['address']}')),
                            ],
                          ),
                        ],
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                        Text(
                          'Détails de la réservation:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Date: ${apt.dateTime.day}/${apt.dateTime.month}/${apt.dateTime.year}'),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Heure: ${apt.dateTime.hour}h${apt.dateTime.minute.toString().padLeft(2, '0')}'),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(apt.type == "urgent" ? Icons.warning : Icons.info, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(child: Text('Type: ${apt.type == "urgent" ? "Urgent" : "Normal"}')),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(child: Text('Statut: ${_getStatusText(apt.status)}')),
                          ],
                        ),
                        if (booking.description.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Divider(),
                          SizedBox(height: 8),
                          Text(
                            'Description:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(booking.description),
                          ),
                        ],
                        if (booking.address != null && booking.address!.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Divider(),
                          SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 20, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Adresse de la réservation:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(booking.address!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      case 'rejected':
        return 'Refusé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // NOUVELLE MÉTHODE: Afficher les détails de réservation dans une modale
  Future<void> _showReservationDetails(
    BuildContext context,
    DateTime date,
    List<ArtisanAppointment> appointments,
  ) async {
    // Charger les détails complets des bookings
    try {
      final bookings = await BookingService.getMyBookings();
      final dayBookings = bookings.where((booking) {
        final bookingDate = booking.scheduledDate;
        return bookingDate.year == date.year &&
               bookingDate.month == date.month &&
               bookingDate.day == date.day;
      }).toList();

      if (dayBookings.isEmpty) {
        return;
      }

      // Afficher la modale avec les détails
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Réservations du ${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                
                // Liste des réservations
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dayBookings.length,
                    itemBuilder: (context, index) {
                      final booking = dayBookings[index];
                      final appointment = appointments.firstWhere(
                        (apt) => apt.id == booking.id,
                        orElse: () => appointments.first,
                      );
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: appointment.type == "urgent" ? Colors.red : Colors.blue,
                            child: Icon(
                              appointment.type == "urgent" ? Icons.warning : Icons.schedule,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            appointment.clientName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${booking.scheduledDate.hour}h${booking.scheduledDate.minute.toString().padLeft(2, '0')} - ${_getStatusText(appointment.status)}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Informations du client
                                  Text(
                                    'Informations du client:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  if (booking.clientName != null && booking.clientName!.isNotEmpty) ...[
                                    _buildInfoRow(Icons.person, 'Nom:', booking.clientName!),
                                    SizedBox(height: 8),
                                  ],
                                  if (booking.client != null) ...[
                                    if (booking.client!['phone'] != null && booking.client!['phone'].toString().isNotEmpty) ...[
                                      _buildInfoRow(Icons.phone, 'Téléphone:', booking.client!['phone'].toString()),
                                      SizedBox(height: 8),
                                    ],
                                    if (booking.client!['email'] != null && booking.client!['email'].toString().isNotEmpty) ...[
                                      _buildInfoRow(Icons.email, 'Email:', booking.client!['email'].toString()),
                                      SizedBox(height: 8),
                                    ],
                                  ],
                                  if (booking.address != null && booking.address!.isNotEmpty) ...[
                                    _buildInfoRow(Icons.location_on, 'Adresse:', booking.address!),
                                    SizedBox(height: 8),
                                  ],
                                  SizedBox(height: 16),
                                  Divider(),
                                  SizedBox(height: 8),
                                  
                                  // Détails de la réservation
                                  Text(
                                    'Détails de la réservation:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Date:',
                                    '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                                  ),
                                  SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'Heure:',
                                    '${booking.scheduledDate.hour}h${booking.scheduledDate.minute.toString().padLeft(2, '0')}',
                                  ),
                                  SizedBox(height: 8),
                                  _buildInfoRow(
                                    appointment.type == "urgent" ? Icons.warning : Icons.info,
                                    'Type:',
                                    appointment.type == "urgent" ? "Urgent" : "Normal",
                                  ),
                                  SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.check_circle_outline,
                                    'Statut:',
                                    _getStatusText(appointment.status),
                                  ),
                                  if (booking.description.isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    Divider(),
                                    SizedBox(height: 8),
                                    Text(
                                      'Description:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(booking.description),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des détails: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}