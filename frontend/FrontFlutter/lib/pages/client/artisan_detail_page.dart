import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'booking_modal.dart';
import 'star_rating_widget.dart';

class ArtisanDetailPage extends StatelessWidget {
  const ArtisanDetailPage({required this.artisan, super.key});

  final Artisan artisan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${artisan.firstName} ${artisan.lastName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: artisan.profilePicture == null || artisan.profilePicture!.isEmpty
                  ? Container(
                      height: 220,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, size: 80, color: Colors.grey),
                    )
                  : Image.network(
                      artisan.profilePicture!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 80, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan.companyName ?? artisan.trade,
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${artisan.firstName} ${artisan.lastName}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (artisan.isVerified) Icon(Icons.verified, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // TODO: Charger le rating depuis ReviewService
                StarRatingWidget(rating: 0.0, size: 22),
                const SizedBox(width: 8),
                Text(
                  '0.0',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                Chip(
                  label: Text(artisan.trade),
                  avatar: const Icon(Icons.work_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'À propos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              artisan.description ?? 'Aucune description disponible',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Informations clés',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.phone_outlined, label: 'Téléphone', value: artisan.phone),
            _DetailRow(icon: Icons.email_outlined, label: 'Email', value: artisan.email),
            _DetailRow(
              icon: Icons.calendar_month_outlined,
              label: 'Expérience',
              value: '${artisan.yearsOfExperience ?? 0} ans',
            ),
            const SizedBox(height: 24),
            if (artisan.certifications.isNotEmpty) ...[
              Text(
                'Certifications',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...artisan.certifications.map(
                (cert) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cert, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _openBookingModal(context),
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text('Booker'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBookingModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => BookingModal(artisan: artisan),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}