import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/admin_service.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;

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
      final bookings = await AdminService.getAllBookings(
        status: _selectedStatus,
        limit: 1000, // Récupérer toutes les bookings
      );
      setState(() {
        _bookings = bookings;
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
        // Filtres
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par statut',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                    const DropdownMenuItem(value: 'pending', child: Text('En attente')),
                    const DropdownMenuItem(value: 'confirmed', child: Text('Confirmé')),
                    const DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                    const DropdownMenuItem(value: 'completed', child: Text('Terminé')),
                    const DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _loadBookings();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadBookings,
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
        // Liste des bookings
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
                            onPressed: _loadBookings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : _bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune réservation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            return Card(
                              child: InkWell(
                                onTap: () => _showBookingDetails(context, booking),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Réservation #${booking.id.substring(0, 8)}',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDate(booking.scheduledDate),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey.shade600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          _buildStatusChip(booking.status),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (booking.clientName != null || booking.artisanName != null)
                                        Row(
                                          children: [
                                            if (booking.clientName != null) ...[
                                              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Client: ${booking.clientName}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                            if (booking.clientName != null && booking.artisanName != null)
                                              const SizedBox(width: 16),
                                            if (booking.artisanName != null) ...[
                                              Icon(Icons.home_repair_service_outlined, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Artisan: ${booking.artisanName}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ],
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        booking.description,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (booking.urgency) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.priority_high, size: 14, color: Colors.red.shade700),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Urgent',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'En attente';
        break;
      case BookingStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmé';
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        text = 'En cours';
        break;
      case BookingStatus.completed:
        color = Colors.green;
        text = 'Terminé';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Annulé';
        break;
      case BookingStatus.rejected:
        color = Colors.grey;
        text = 'Rejeté';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réservation #${booking.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Statut', _getStatusText(booking.status)),
              const SizedBox(height: 12),
              _buildDetailRow('Date prévue', _formatDate(booking.scheduledDate)),
              const SizedBox(height: 12),
              if (booking.clientName != null)
                _buildDetailRow('Client', booking.clientName!),
              if (booking.clientName != null) const SizedBox(height: 12),
              if (booking.clientPhone != null)
                _buildDetailRow('Téléphone client', booking.clientPhone!),
              if (booking.clientPhone != null) const SizedBox(height: 12),
              if (booking.artisanName != null)
                _buildDetailRow('Artisan', booking.artisanName!),
              if (booking.artisanName != null) const SizedBox(height: 12),
              if (booking.artisanPhone != null)
                _buildDetailRow('Téléphone artisan', booking.artisanPhone!),
              if (booking.artisanPhone != null) const SizedBox(height: 12),
              if (booking.address != null)
                _buildDetailRow('Adresse', booking.address!),
              if (booking.address != null) const SizedBox(height: 12),
              _buildDetailRow('Urgence', booking.urgency ? 'Oui' : 'Non'),
              const SizedBox(height: 12),
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(booking.description),
              const SizedBox(height: 12),
              Text(
                'Créé le:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_formatDate(booking.createdAt)),
              const SizedBox(height: 12),
              Text(
                'Modifié le:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_formatDate(booking.updatedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmé';
      case BookingStatus.inProgress:
        return 'En cours';
      case BookingStatus.completed:
        return 'Terminé';
      case BookingStatus.cancelled:
        return 'Annulé';
      case BookingStatus.rejected:
        return 'Rejeté';
    }
  }
}

