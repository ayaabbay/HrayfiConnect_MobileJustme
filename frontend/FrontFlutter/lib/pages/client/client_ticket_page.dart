import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../services/ticket_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';

class ClientTicketPage extends StatefulWidget {
  const ClientTicketPage({super.key});

  @override
  State<ClientTicketPage> createState() => _ClientTicketPageState();
}

class _ClientTicketPageState extends State<ClientTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.general;
  TicketPriority _selectedPriority = TicketPriority.medium;
  final List<String> _attachments = [];
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final userInfo = await StorageService.getUserInfo();
      final userId = userInfo['userId']!;

      await TicketService.createTicket(
        userId: userId,
        category: _selectedCategory,
        priority: _selectedPriority,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket créé avec succès. L\'administration va vous répondre rapidement.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la création du ticket';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          errorMessage = e.toString();
        }
        setState(() {
          _error = errorMessage;
          _isSubmitting = false;
        });
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
      appBar: AppBar(
        title: const Text('Créer un ticket support'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Décrivez votre problème et notre équipe vous répondra dans les plus brefs délais.',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Catégorie
            Text(
              'Catégorie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TicketCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TicketCategory.technical,
                  child: Text('Problème technique'),
                ),
                DropdownMenuItem(
                  value: TicketCategory.billing,
                  child: Text('Problème de facturation'),
                ),
                DropdownMenuItem(
                  value: TicketCategory.general,
                  child: Text('Général'),
                ),
                DropdownMenuItem(
                  value: TicketCategory.complaint,
                  child: Text('Réclamation'),
                ),
                DropdownMenuItem(
                  value: TicketCategory.other,
                  child: Text('Autre'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            // Priorité
            Text(
              'Priorité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TicketPriority>(
              segments: const [
                ButtonSegment(
                  value: TicketPriority.low,
                  label: Text('Basse'),
                  icon: Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: TicketPriority.medium,
                  label: Text('Normal'),
                  icon: Icon(Icons.remove, size: 16),
                ),
                ButtonSegment(
                  value: TicketPriority.high,
                  label: Text('Haute'),
                  icon: Icon(Icons.arrow_upward, size: 16),
                ),
                ButtonSegment(
                  value: TicketPriority.urgent,
                  label: Text('Urgente'),
                  icon: Icon(Icons.priority_high, size: 16),
                ),
              ],
              selected: {_selectedPriority},
              onSelectionChanged: (Set<TicketPriority> newSelection) {
                setState(() => _selectedPriority = newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            // Sujet
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Sujet',
                prefixIcon: Icon(Icons.title_outlined),
                border: OutlineInputBorder(),
                hintText: 'Résumé du problème',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un sujet';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description détaillée',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
                hintText: 'Décrivez votre problème en détail...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez décrire votre problème';
                }
                if (value.trim().length < 20) {
                  return 'La description doit contenir au moins 20 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Pièces jointes
            Text(
              'Pièces jointes (optionnel)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // Simuler l'ajout d'une pièce jointe
                setState(() {
                  _attachments.add('capture_${_attachments.length + 1}.png');
                });
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('Ajouter un fichier'),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._attachments.map((file) => Chip(
                    label: Text(file),
                    onDeleted: () {
                      setState(() => _attachments.remove(file));
                    },
                  )),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitTicket,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Créer le ticket', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

