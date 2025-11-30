import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../providers/review_provider.dart';
import '../../services/storage_service.dart';
import '../client/star_rating_widget.dart';
import 'review_form_page.dart';

class ReviewListPage extends StatefulWidget {
  const ReviewListPage({
    super.key,
    required this.artisanId,
    required this.artisanName,
    this.allowReviewCreation = false,
    this.bookingIdForCreation,
  });

  final String artisanId;
  final String artisanName;
  final bool allowReviewCreation;
  final String? bookingIdForCreation;

  @override
  State<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends State<ReviewListPage> {
  late final ReviewProvider _provider;
  String? _userId;
  int? _ratingFilter;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _provider = ReviewProvider()..addListener(_handleProviderChanged);
    _init();
  }

  void _handleProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _init() async {
    final info = await StorageService.getUserInfo();
    setState(() {
      _userId = info['userId'];
    });
    await _provider.loadArtisanReviews(widget.artisanId);
    await _provider.loadMyReviews();
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_handleProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _provider.loadArtisanReviews(
      widget.artisanId,
      minRating: _ratingFilter,
      maxRating: _ratingFilter,
    );
    await _provider.loadMyReviews();
  }

  void _applyFilter(int? rating) {
    setState(() {
      _ratingFilter = rating;
    });
    _provider.loadArtisanReviews(
      widget.artisanId,
      minRating: rating,
      maxRating: rating,
    );
  }

  Future<void> _openReviewForm({Review? review}) async {
    if (_userId == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormPage(
          artisanId: widget.artisanId,
          artisanName: widget.artisanName,
          clientId: _userId!,
          bookingId: review?.bookingId ?? widget.bookingIdForCreation,
          existingReview: review,
        ),
      ),
    );

    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _confirmDelete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'avis'),
        content: const Text('Voulez-vous vraiment supprimer cet avis ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _provider.deleteReview(review.id, widget.artisanId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_provider.error ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _userId != null;
    final canCreate = widget.allowReviewCreation && widget.bookingIdForCreation != null && isOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text('Avis de ${widget.artisanName}'),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openReviewForm(),
              icon: const Icon(Icons.rate_review),
              label: const Text('Rédiger un avis'),
            )
          : null,
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_provider.stats != null) _buildStatsCard(),
                  if (_provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: Colors.red.shade50,
                        child: ListTile(
                          leading: Icon(Icons.error_outline, color: Colors.red.shade400),
                          title: const Text('Impossible de charger les avis'),
                          subtitle: Text(_provider.error!),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refresh,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  if (_provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_provider.artisanReviews.isEmpty)
                    _buildEmptyState()
                  else
                    ..._provider.artisanReviews.map(
                      (review) => _ReviewTile(
                        review: review,
                        isOwner: review.clientId == _userId,
                        onEdit: () => _openReviewForm(review: review),
                        onDelete: () => _confirmDelete(review),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _provider.stats!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Note moyenne'),
                    StarRatingWidget(rating: stats.averageRating, size: 20),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Avis'),
                    Text(
                      stats.totalReviews.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: stats.ratingDistribution.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key} ★ - ${entry.value}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          final rating = index == 0 ? null : (6 - index);
          final label = rating == null ? 'Tous' : '$rating ★ et +';
          final selected = rating == null ? _ratingFilter == null : _ratingFilter == rating;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => _applyFilter(rating),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(height: 40),
        Icon(Icons.reviews_outlined, size: 72, color: Colors.grey),
        SizedBox(height: 12),
        Text('Aucun avis pour le moment'),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final Review review;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRatingWidget(rating: review.rating.toDouble(), size: 18),
                const SizedBox(width: 8),
                Text(
                  review.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: theme.textTheme.bodySmall,
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              review.clientName ?? 'Client',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}


