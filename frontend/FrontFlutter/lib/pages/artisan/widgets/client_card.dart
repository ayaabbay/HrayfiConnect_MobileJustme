import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../../models/artisan_model.dart';
import '../../../models/booking.dart';
import 'urgent_badge.dart';

class ClientCard extends StatelessWidget {
  final ArtisanClient client;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final BookingStatus? currentStatus;
  final ValueChanged<BookingStatus>? onStatusChanged;
  final List<BookingStatus>? statusOptions;
  final bool isStatusUpdating;

  const ClientCard({
    Key? key,
    required this.client,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
    this.currentStatus,
    this.onStatusChanged,
    this.statusOptions,
    this.isStatusUpdating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec photo et infos
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(client.avatar),
                    radius: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          client.project,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (client.isUrgent) UrgentBadge(),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Message
              Text(
                client.lastMessage,
                style: TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Actions pour demandes urgentes
              if (client.isUrgent && client.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Accepter'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: Text('Refuser'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      client.timestamp,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (client.unread > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          client.unread.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),

              if (!client.isUrgent && currentStatus != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Statut de la demande',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(_statusLabel(currentStatus!)),
                      backgroundColor: _statusColor(currentStatus!).withOpacity(0.15),
                      labelStyle: TextStyle(color: _statusColor(currentStatus!), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<BookingStatus>(
                        value: currentStatus,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Mettre à jour',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: (statusOptions ?? BookingStatus.values)
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(_statusLabel(status)),
                              ),
                            )
                            .toList(),
                        onChanged: isStatusUpdating || onStatusChanged == null
                            ? null
                            : (value) {
                                if (value != null) {
                                  onStatusChanged!(value);
                                }
                              },
                      ),
                    ),
                    if (isStatusUpdating) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmée';
      case BookingStatus.inProgress:
        return 'En cours';
      case BookingStatus.completed:
        return 'Complétée';
      case BookingStatus.cancelled:
        return 'Annulée';
      case BookingStatus.rejected:
        return 'Refusée';
    }
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.indigo;
      case BookingStatus.completed:
        return Colors.teal;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.grey;
    }
  }
}