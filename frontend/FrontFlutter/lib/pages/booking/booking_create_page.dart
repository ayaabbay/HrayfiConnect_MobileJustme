import 'package:flutter/material.dart';

class BookingCreatePage extends StatefulWidget {
  const BookingCreatePage({super.key});

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  bool isUrgent = false;
  DateTime? selectedDate;
  TimeOfDay? selectedStart;
  final TextEditingController notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle réservation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: isUrgent,
              onChanged: (v) => setState(() => isUrgent = v),
              title: const Text('Demande urgente'),
              subtitle: const Text("Notification immédiate à l'artisan (acceptation/refus)"),
            ),
            const SizedBox(height: 8),
            if (!isUrgent) ...[
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(selectedDate == null
                    ? 'Sélectionner une date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                    initialDate: selectedDate ?? now,
                  );
                  if (d != null) setState(() => selectedDate = d);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(selectedStart == null ? 'Sélectionner une heure' : selectedStart!.format(context)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                  if (t != null) setState(() => selectedStart = t);
                },
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description / Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isUrgent
                              ? "Demande urgente envoyée à l'artisan"
                              : 'Demande normale créée (à négocier par chat)'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: Text(isUrgent ? 'Envoyer urgent' : 'Créer réservation'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


