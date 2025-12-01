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
  DateTime _currentMonth = DateTime.now(); // Mois actuellement affiché
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Calendrier',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: _loadBookings,
                            tooltip: 'Actualiser',
                          ),
                        ],
                      ),
                    ),
          
                    // Vue Mois avec navigation
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: _buildMonthView(),
                        ),
                      ),
                    ),
          
                    // Rendez-vous du jour
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rendez-vous du ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildAppointmentsList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMonthView() {
    // Obtenir le premier jour du mois et le nombre de jours dans le mois
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Obtenir le jour de la semaine du premier jour (1 = lundi, 7 = dimanche)
    int firstWeekday = firstDayOfMonth.weekday;
    
    // Obtenir le dernier jour du mois précédent pour afficher les jours précédents
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 0);
    final daysInPreviousMonth = previousMonth.day;
    
    // Calculer le nombre total de cellules nécessaires (jours du mois + jours précédents + jours suivants)
    final totalCells = ((firstWeekday - 1) + daysInMonth + (7 - lastDayOfMonth.weekday));
    final weeksCount = (totalCells / 7).ceil();
    
    // Noms des mois en français
    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête avec navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                    });
                  },
                  tooltip: 'Mois précédent',
                ),
                Column(
                  children: [
                    Text(
                      '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime.now();
                          _selectedDate = DateTime.now();
                        });
                      },
                      child: const Text('Aujourd\'hui', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  },
                  tooltip: 'Mois suivant',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // En-tête jours de la semaine
            Row(
              children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                  .map((day) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            
            // Grille des jours du mois complet
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: weeksCount * 7,
              itemBuilder: (context, index) {
                DateTime displayDate;
                bool isCurrentMonth = false;
                bool isToday = false;
                
                if (index < firstWeekday - 1) {
                  // Jours du mois précédent
                  final day = daysInPreviousMonth - (firstWeekday - 2 - index);
                  displayDate = DateTime(_currentMonth.year, _currentMonth.month - 1, day);
                } else if (index < firstWeekday - 1 + daysInMonth) {
                  // Jours du mois actuel
                  final day = index - (firstWeekday - 1) + 1;
                  displayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                  isCurrentMonth = true;
                } else {
                  // Jours du mois suivant
                  final day = index - (firstWeekday - 1 + daysInMonth) + 1;
                  displayDate = DateTime(_currentMonth.year, _currentMonth.month + 1, day);
                }
                
                // Vérifier si c'est aujourd'hui
                final now = DateTime.now();
                isToday = displayDate.year == now.year &&
                         displayDate.month == now.month &&
                         displayDate.day == now.day;
                
                // Vérifier si la date est sélectionnée
                final isSelected = _selectedDate.year == displayDate.year &&
                                  _selectedDate.month == displayDate.month &&
                                  _selectedDate.day == displayDate.day;
                
                // Vérifier s'il y a des rendez-vous
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
                      // Si on clique sur un jour d'un autre mois, changer de mois
                      if (!isCurrentMonth) {
                        _currentMonth = DateTime(displayDate.year, displayDate.month);
                      }
                    });
                    
                    // Si la date a des rendez-vous, afficher la modale
                    if (hasAppointment && dayAppointments.isNotEmpty) {
                      _showReservationDetails(context, displayDate, dayAppointments);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isToday
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayDate.day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                            fontWeight: isSelected || hasAppointment
                                ? FontWeight.w600
                                : isToday
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                            fontSize: isToday ? 16 : 14,
                          ),
                        ),
                        if (hasAppointment)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.error,
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