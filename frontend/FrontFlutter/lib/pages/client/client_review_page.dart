import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/booking.dart';
import '../../services/review_service.dart';
import '../../services/booking_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../services/artisan_service.dart';

class ClientReviewPage extends StatefulWidget {
  final String? artisanId;
  final String? bookingId;

  const ClientReviewPage({super.key, this.artisanId, this.bookingId});

  @override
  State<ClientReviewPage> createState() => _ClientReviewPageState();
}

class _ClientReviewPageState extends State<ClientReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _titleController = TextEditingController();
  double _rating = 0.0;
  Artisan? _selectedArtisan;
  Booking? _selectedBooking;
  List<Booking> _completedBookings = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingBookings = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.artisanId != null) {
        final artisans = await ArtisanService.getArtisans();
        _selectedArtisan = artisans.firstWhere(
          (a) => a.id == widget.artisanId,
          orElse: () => artisans.isNotEmpty ? artisans.first : throw Exception('Artisan non trouvé'),
        );
      } else if (widget.bookingId != null) {
        // Charger le booking pour obtenir l'artisan
        final bookings = await BookingService.getMyBookings();
        _selectedBooking = bookings.firstWhere(
          (b) => b.id == widget.bookingId,
          orElse: () => throw Exception('Réservation non trouvée'),
        );
        if (_selectedBooking!.artisanId.isNotEmpty) {
          final artisans = await ArtisanService.getArtisans();
          _selectedArtisan = artisans.firstWhere(
            (a) => a.id == _selectedBooking!.artisanId,
            orElse: () => throw Exception('Artisan non trouvé'),
          );
        }
      }
      // Si aucun artisan n'est spécifié, on laisse l'utilisateur choisir

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
  
  Future<void> _selectArtisan() async {
    try {
      final artisans = await ArtisanService.getArtisans();
      
      if (artisans.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun artisan disponible'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final selected = await showDialog<Artisan>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sélectionner un artisan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: artisans.length,
              itemBuilder: (context, index) {
                final artisan = artisans[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: artisan.profilePicture != null
                        ? NetworkImage(artisan.profilePicture!)
                        : null,
                    child: artisan.profilePicture == null
                        ? Text(artisan.firstName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(artisan.fullName),
                  subtitle: Text(artisan.trade),
                  onTap: () => Navigator.pop(context, artisan),
                );
              },
            ),
          ),
        ),
      );
      
      if (selected != null) {
        setState(() {
          _selectedArtisan = selected;
          _selectedBooking = null;
          _completedBookings = [];
        });
        // Charger les réservations complétées pour cet artisan
        await _loadCompletedBookings(selected.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // NOUVELLE MÉTHODE: Charger les réservations complétées pour un artisan
  Future<void> _loadCompletedBookings(String artisanId) async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final allBookings = await BookingService.getMyBookings();
      
      // Filtrer les réservations complétées avec cet artisan
      final completed = allBookings.where(
        (b) => b.artisanId == artisanId && b.status == BookingStatus.completed,
      ).toList();
      
      setState(() {
        _completedBookings = completed;
        _isLoadingBookings = false;
      });
      
      // Si aucune réservation complétée, afficher un message
      if (completed.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune réservation complétée trouvée avec cet artisan. Vous devez d\'abord compléter une réservation avec cet artisan avant de pouvoir laisser un avis.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingBookings = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des réservations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NOUVELLE MÉTHODE: Sélectionner une réservation complétée
  Future<void> _selectBooking() async {
    if (_completedBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune réservation complétée disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showDialog<Booking>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une réservation'),
        content: SizedBox(
          width: double.maxFinite,
          child: _completedBookings.length == 1
              ? Text(
                  'Réservation du ${_formatDate(_completedBookings.first.scheduledDate)}',
                  style: const TextStyle(fontSize: 16),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _completedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _completedBookings[index];
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Réservation du ${_formatDate(booking.scheduledDate)}'),
                      subtitle: Text(
                        booking.description.length > 50
                            ? '${booking.description.substring(0, 50)}...'
                            : booking.description,
                      ),
                      onTap: () => Navigator.pop(context, booking),
                    );
                  },
                ),
        ),
        actions: [
          if (_completedBookings.length == 1)
            TextButton(
              onPressed: () => Navigator.pop(context, _completedBookings.first),
              child: const Text('Utiliser cette réservation'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedBooking = selected;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitReview() async {
    if (_selectedArtisan == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un artisan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez attribuer une note'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Vérifier qu'une réservation complétée est disponible
    if (_completedBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune réservation complétée trouvée avec cet artisan. Vous devez d\'abord compléter une réservation avec cet artisan avant de pouvoir laisser un avis.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Si aucune réservation n'est sélectionnée, utiliser la première disponible
    if (_selectedBooking == null) {
      if (_completedBookings.length == 1) {
        _selectedBooking = _completedBookings.first;
      } else {
        // Demander à l'utilisateur de sélectionner une réservation
        await _selectBooking();
        if (_selectedBooking == null) {
          return; // L'utilisateur a annulé
        }
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final userInfo = await StorageService.getUserInfo();
      final clientId = userInfo['userId']!;

      // Vérifier que la réservation sélectionnée est bien complétée
      if (_selectedBooking!.status != BookingStatus.completed) {
        throw Exception('Vous ne pouvez laisser un avis que pour les réservations complétées. Cette réservation a le statut: ${_selectedBooking!.status.name}');
      }
      
      // Vérifier que la réservation appartient bien à l'artisan sélectionné
      if (_selectedBooking!.artisanId != _selectedArtisan!.id) {
        throw Exception('La réservation sélectionnée ne correspond pas à l\'artisan choisi.');
      }
      
      // Créer l'avis - cela sera sauvegardé dans la base de données
      await ReviewService.createReview(
        bookingId: _selectedBooking!.id,
        clientId: clientId,
        artisanId: _selectedArtisan!.id,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
        title: _titleController.text.trim().isEmpty
            ? 'Avis sur ${_selectedArtisan!.fullName}'
            : _titleController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avis envoyé avec succès pour ${_selectedArtisan!.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'envoi de l\'avis';
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
        title: const Text('Écrire un avis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !_isSubmitting
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
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélection ou affichage de l'artisan
            if (_selectedArtisan == null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_search, size: 32),
                  title: const Text('Sélectionner un artisan'),
                  subtitle: const Text('Choisissez l\'artisan que vous souhaitez noter'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectArtisan,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _selectedArtisan!.profilePicture != null
                            ? NetworkImage(_selectedArtisan!.profilePicture!)
                            : null,
                        child: _selectedArtisan!.profilePicture == null
                            ? const Icon(Icons.person, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedArtisan!.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _selectedArtisan!.trade,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _selectArtisan,
                        child: const Text('Changer'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Afficher les réservations complétées disponibles
              if (_isLoadingBookings)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_completedBookings.isEmpty)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune réservation complétée trouvée avec cet artisan. Vous devez d\'abord compléter une réservation avec cet artisan avant de pouvoir laisser un avis.',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Sélection de la réservation
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _selectedBooking == null
                          ? 'Sélectionner une réservation complétée'
                          : 'Réservation du ${_formatDate(_selectedBooking!.scheduledDate)}',
                    ),
                    subtitle: _selectedBooking == null
                        ? Text('${_completedBookings.length} réservation(s) complétée(s) disponible(s)')
                        : Text(
                            _selectedBooking!.description.length > 50
                                ? '${_selectedBooking!.description.substring(0, 50)}...'
                                : _selectedBooking!.description,
                          ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _selectBooking,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
            // Titre (optionnel)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre (optionnel)',
                prefixIcon: Icon(Icons.title_outlined),
                border: OutlineInputBorder(),
                hintText: 'Résumé de votre avis',
              ),
            ),
            const SizedBox(height: 16),
            // Note avec étoiles interactives
            Text(
              'Note',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Permettre de changer la note en tapant
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _rating = (index + 1).toDouble());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              index < _rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 48,
                              color: Colors.amber,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rating == 0.0
                        ? 'Appuyez sur une étoile'
                        : '${_rating.toStringAsFixed(1)} / 5.0',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Commentaire
            Text(
              'Commentaire',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience avec cet artisan...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez écrire un commentaire';
                }
                if (value.trim().length < 10) {
                  return 'Le commentaire doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitReview,
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
                  : const Text('Publier l\'avis', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}