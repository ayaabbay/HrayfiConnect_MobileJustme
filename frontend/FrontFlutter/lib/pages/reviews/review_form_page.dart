import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../providers/review_provider.dart';
import '../../widgets/star_rating_input.dart';

class ReviewFormPage extends StatefulWidget {
  const ReviewFormPage({
    super.key,
    required this.artisanId,
    required this.artisanName,
    required this.clientId,
    required this.bookingId,
    this.existingReview,
  });

  final String artisanId;
  final String artisanName;
  final String clientId;
  final String? bookingId;
  final Review? existingReview;

  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  late int _rating;
  late ReviewProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ReviewProvider()..addListener(_handleProvider);
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _titleController.text = widget.existingReview!.title;
      _commentController.text = widget.existingReview!.comment;
    } else {
      _rating = 5;
    }
  }

  void _handleProvider() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_handleProvider);
    _provider.dispose();
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de soumettre un avis sans réservation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final comment = _commentController.text.trim();

    Review? review;
    if (widget.existingReview == null) {
      review = await _provider.submitReview(
        bookingId: widget.bookingId!,
        clientId: widget.clientId,
        artisanId: widget.artisanId,
        rating: _rating,
        comment: comment,
        title: title,
      );
    } else {
      review = await _provider.updateReview(
        widget.existingReview!.id,
        artisanId: widget.artisanId,
        rating: _rating,
        comment: comment,
        title: title,
      );
    }

    if (review != null && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.error ?? 'Erreur lors de la sauvegarde'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier mon avis' : 'Laisser un avis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                widget.artisanName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Note',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              StarRatingInput(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez ajouter un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(),
                ),
                minLines: 4,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez partager votre expérience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _provider.isSubmitting ? null : _submit,
                child: _provider.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Mettre à jour' : 'Publier l\'avis'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


