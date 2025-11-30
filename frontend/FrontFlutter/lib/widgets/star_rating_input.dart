import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
    this.color = Colors.amber,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return IconButton(
          onPressed: () => onChanged(index + 1),
          padding: const EdgeInsets.all(4),
          iconSize: size,
          constraints: const BoxConstraints(),
          icon: Icon(
            isFilled ? Icons.star : Icons.star_border,
            color: color,
          ),
        );
      }),
    );
  }
}


