import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../providers/review_provider.dart';
import '../../services/booking_service.dart';
import '../../services/storage_service.dart';
import '../reviews/review_form_page.dart';
import '../chat/chat_detail_page.dart';

class ClientBookingPage extends StatefulWidget {
  const ClientBookingPage({super.key});

  @override
  State<ClientBookingPage> createState() => _ClientBookingPageState();
}

class _ClientBookingPageState extends State<ClientBookingPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String? _userId;
  late final ReviewProvider _reviewProvider;

  @override
  void initState() {
    super.initState();
    _reviewProvider = ReviewProvider()..addListener(_handleReviewProvider);
    _loadBookings();
    _loadUserInfoAndReviews();
  }

  @override
  void dispose() {
    _reviewProvider.removeListener(_handleReviewProvider);
    _reviewProvider.dispose();
    super.dispose();
  }

  void _handleReviewProvider() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings = await BookingService.getMyBookings();
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

  Future<void> _loadUserInfoAndReviews() async {
    final info = await StorageService.getUserInfo();
    setState(() {
      _userId = info['userId'];
    });
    await _reviewProvider.loadMyReviews();
  }

  Future<void> _openReviewForm(Booking booking) async {
    if (_userId == null) return;
    final existingReview = _reviewProvider.findMyReviewForBooking(booking.id);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormPage(
          artisanId: booking.artisanId,
          artisanName: booking.artisanName ?? 'Artisan',
          clientId: _userId!,
          bookingId: booking.id,
          existingReview: existingReview,
        ),
      ),
    );

    if (result == true) {
      await _reviewProvider.loadMyReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis enregistré'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes réservations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
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
                                Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune réservation',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _bookings.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              final isUrgent = booking.urgency; // urgency est maintenant un bool
                              final review = _reviewProvider.findMyReviewForBooking(booking.id);
                              return Card(
                                child: ListTile(
                                  title: Text(booking.artisanName ?? 'Artisan'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${_getStatusText(booking.status)} • ${DateFormat('dd/MM/yyyy HH:mm').format(booking.scheduledDate)}'),
                                      if (booking.description.isNotEmpty)
                                        Text(
                                          booking.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isUrgent) const _UrgentChip(),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ChatDetailPage(
                                                bookingId: booking.id,
                                                otherUserName: booking.artisanName ?? 'Artisan',
                                                otherUserAvatar: booking.artisan?['profile_picture'] as String?,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        tooltip: 'Ouvrir le chat',
                                      ),
                                      if (booking.status == BookingStatus.completed)
                                        IconButton(
                                          onPressed: _userId == null ? null : () => _openReviewForm(booking),
                                          icon: Icon(review != null ? Icons.edit : Icons.rate_review_outlined),
                                          tooltip: review != null ? 'Modifier mon avis' : 'Laisser un avis',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
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
        return 'Refusé';
    }
  }
}

class _UrgentChip extends StatelessWidget {
  const _UrgentChip();
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text('Urgent'),
      avatar: const Icon(Icons.priority_high, size: 16, color: Colors.white),
      backgroundColor: Colors.red.shade400,
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }
}


