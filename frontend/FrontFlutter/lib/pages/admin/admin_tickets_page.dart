import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../services/ticket_service.dart';

class AdminTicketsPage extends StatefulWidget {
  const AdminTicketsPage({super.key});

  @override
  State<AdminTicketsPage> createState() => _AdminTicketsPageState();
}

class _AdminTicketsPageState extends State<AdminTicketsPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tickets = await TicketService.getAllTickets();
      setState(() {
        _tickets = tickets;
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
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadTickets,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : _tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.support_agent, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun ticket',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      final isHighPriority = ticket.priority == TicketPriority.high || ticket.priority == TicketPriority.urgent;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.support_agent,
                            color: isHighPriority ? Colors.deepOrange : Colors.indigo,
                          ),
                          title: Text(ticket.subject),
                          subtitle: Text('${_getPriorityText(ticket.priority)} • ${_getStatusText(ticket.status)} • ${_getCategoryText(ticket.category)}'),
                          trailing: TextButton(
                            onPressed: () {
                              _showTicketDetails(context, ticket);
                            },
                            child: const Text('Détails'),
                          ),
                        ),
                      );
                    },
                  );
  }

  String _getPriorityText(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Priorité basse';
      case TicketPriority.medium:
        return 'Priorité normale';
      case TicketPriority.high:
        return 'Priorité haute';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Ouvert';
      case TicketStatus.inProgress:
        return 'En cours';
      case TicketStatus.resolved:
        return 'Résolu';
      case TicketStatus.closed:
        return 'Fermé';
    }
  }

  String _getCategoryText(TicketCategory category) {
    switch (category) {
      case TicketCategory.technical:
        return 'Technique';
      case TicketCategory.billing:
        return 'Facturation';
      case TicketCategory.account:
        return 'Compte / Profil';
      case TicketCategory.booking:
        return 'Réservation';
      case TicketCategory.other:
        return 'Autre';
    }
  }

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(ticket.description),
              const SizedBox(height: 16),
              Text('Statut: ${_getStatusText(ticket.status)}'),
              Text('Priorité: ${_getPriorityText(ticket.priority)}'),
              Text('Catégorie: ${_getCategoryText(ticket.category)}'),
              if (ticket.adminNotes != null) ...[
                const SizedBox(height: 16),
                Text('Notes admin:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(ticket.adminNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (ticket.status == TicketStatus.open)
            FilledButton(
              onPressed: () async {
                try {
                  // Afficher un indicateur de chargement
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  await TicketService.updateTicketStatus(
                    ticket.id,
                    status: TicketStatus.inProgress,
                  );
                  
                  _loadTickets();
                  
                  if (mounted) {
                    Navigator.of(context).pop(); // Fermer le dialog de chargement
                    Navigator.of(context).pop(); // Fermer le dialog de détails
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket pris en charge. Un email a été envoyé au client.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop(); // Fermer le dialog de chargement si ouvert
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Prendre en charge'),
            ),
          if (ticket.status == TicketStatus.inProgress)
            FilledButton.tonal(
              onPressed: () async {
                try {
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  await TicketService.updateTicketStatus(
                    ticket.id,
                    status: TicketStatus.resolved,
                  );

                  _loadTickets();

                  if (mounted) {
                    Navigator.of(context).pop(); // dialog de chargement
                    Navigator.of(context).pop(); // dialog de détails
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket marqué comme complété. Un email a été envoyé au client.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop(); // dialog de chargement si ouvert
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Marquer comme complété'),
            ),
        ],
      ),
    );
  }
}


