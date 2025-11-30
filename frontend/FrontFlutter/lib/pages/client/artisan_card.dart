import 'package:flutter/material.dart';

import '../../models/user.dart';
import 'star_rating_widget.dart';

class ArtisanCard extends StatelessWidget {
  const ArtisanCard({
    required this.artisan,
    required this.onTap,
    super.key,
  });

  final Artisan artisan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: SizedBox(
                  width: 110,
                  child: artisan.profilePicture == null || artisan.profilePicture!.isEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 48, color: Colors.grey),
                        )
                      : Image.network(
                          artisan.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 48, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${artisan.firstName} ${artisan.lastName}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (artisan.isVerified)
                            Icon(Icons.verified, color: theme.colorScheme.primary, size: 18),
                        ],
                      ),
                      Text(
                        artisan.description ?? 'Aucune description',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          StarRatingWidget(rating: artisan.averageRating ?? 0.0, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            (artisan.averageRating ?? 0).toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${artisan.totalReviews ?? 0})',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${artisan.yearsOfExperience ?? 0} ans exp.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}