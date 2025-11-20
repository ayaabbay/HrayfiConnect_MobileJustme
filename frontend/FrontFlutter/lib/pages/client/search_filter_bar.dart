import 'package:flutter/material.dart';
//import '../../models/artisan.dart';
class SearchBarWithFilter extends StatelessWidget {
  const SearchBarWithFilter({
    required this.controller,
    required this.onFilterTap,
    this.onSubmit,
    this.onClear,
    this.hasActiveFilters = false,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onFilterTap;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onClear;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSubmit,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Effacer la recherche',
                                onPressed: onClear,
                              ),
                        hintText: 'Rechercher un artisan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    );
                },
              ),
              ),
              const SizedBox(width: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.filledTonal(
                    onPressed: onFilterTap,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filtrer les artisans',
                    style: IconButton.styleFrom(
                      backgroundColor: hasActiveFilters ? theme.colorScheme.primaryContainer : null,
                      foregroundColor: hasActiveFilters ? theme.colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

