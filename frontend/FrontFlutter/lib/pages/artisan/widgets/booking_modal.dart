import 'package:flutter/material.dart';

class BookingModal extends StatelessWidget {
  final TextEditingController messageController;
  final bool isUrgent;
  final Function(bool) onUrgentChanged;
  final VoidCallback onBook;
  final VoidCallback onCancel;

  const BookingModal({
    Key? key,
    required this.messageController,
    required this.isUrgent,
    required this.onUrgentChanged,
    required this.onBook,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle Réservation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 16),
            
            // Switch Urgent
            Row(
              children: [
                Icon(Icons.warning, color: isUrgent ? Colors.red : Colors.grey),
                SizedBox(width: 8),
                Text('Travail urgent', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Switch(
                  value: isUrgent,
                  onChanged: onUrgentChanged,
                  activeThumbColor: Colors.red,
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Message
            Text('Message à l\'artisan:'),
            SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Décrivez votre besoin...',
              ),
            ),
            
            SizedBox(height: 24),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text('Annuler'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUrgent ? Colors.red : Colors.blue,
                    ),
                    child: Text('Réserver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}