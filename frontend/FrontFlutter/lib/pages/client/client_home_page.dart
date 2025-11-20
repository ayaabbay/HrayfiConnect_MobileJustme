import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/artisan_service.dart';
import 'artisan_card.dart';
import 'artisan_detail_page.dart';
import 'search_filter_bar.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Artisan> _allArtisans = [];
  List<Artisan> _visibleArtisans = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedTrade;
  String? _selectedLocation;
  double _minRating = 0;
  int _minExperience = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadArtisans();
  }

  Future<void> _loadArtisans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artisans = await ArtisanService.getArtisans();
      setState(() {
        _allArtisans = artisans;
        _visibleArtisans = List.of(artisans);
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
  void dispose() {
    _searchController
      ..removeListener(_applyFilters)
      ..dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FilterBottomSheet(
        selectedTrade: _selectedTrade,
        selectedLocation: _selectedLocation,
        minRating: _minRating,
        minExperience: _minExperience,
        availableTrades: _allArtisans.map((a) => a.trade).toSet().toList(),
        availableLocations: [], // TODO: Ajouter location si disponible dans le modèle
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTrade = result.trade;
        _selectedLocation = result.location;
        _minRating = result.minRating;
        _minExperience = result.minExperience;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _visibleArtisans = _allArtisans.where((artisan) {
        final matchesQuery = query.isEmpty ||
            artisan.fullName.toLowerCase().contains(query) ||
            artisan.trade.toLowerCase().contains(query) ||
            (artisan.description?.toLowerCase().contains(query) ?? false);
        
        final matchesTrade = _selectedTrade == null || artisan.trade == _selectedTrade;
        
        // Note: Le modèle Artisan n'a pas de location, on filtre seulement par trade pour l'instant
        // TODO: Ajouter location au modèle si nécessaire
        
        final matchesExperience = artisan.yearsOfExperience != null && 
            artisan.yearsOfExperience! >= _minExperience;
        
        return matchesQuery && matchesTrade && matchesExperience;
      }).toList();
    });
  }

  bool get _hasActiveFilters =>
      _selectedTrade != null ||
      _selectedLocation != null ||
      _minRating > 0 ||
      _minExperience > 0 ||
      _searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Client'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: SearchBarWithFilter(
            controller: _searchController,
            hasActiveFilters: _hasActiveFilters,
            onClear: () {
              _searchController.clear();
              _applyFilters();
            },
            onSubmit: (_) => _applyFilters(),
            onFilterTap: _openFilters,
          ),
        ),
      ),
      body: _isLoading
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
                        onPressed: _loadArtisans,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _visibleArtisans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun artisan ne correspond à vos critères',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez d\'élargir votre recherche ou de réinitialiser les filtres.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _visibleArtisans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final artisan = _visibleArtisans[index];
                return ArtisanCard(
                  artisan: artisan,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtisanDetailPage(artisan: artisan),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    required this.selectedTrade,
    required this.selectedLocation,
    required this.minRating,
    required this.minExperience,
    required this.availableTrades,
    required this.availableLocations,
    super.key,
  });

  final String? selectedTrade;
  final String? selectedLocation;
  final double minRating;
  final int minExperience;
  final List<String> availableTrades;
  final List<String> availableLocations;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _trade = widget.selectedTrade;
  late String? _location = widget.selectedLocation;
  late double _rating = widget.minRating;
  late int _experience = widget.minExperience;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Filtres', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _trade = null;
                      _location = null;
                      _rating = 0;
                      _experience = 0;
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Métier', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _trade == null,
                  onSelected: (_) => setState(() => _trade = null),
                ),
                ...widget.availableTrades.map(
                  (trade) => ChoiceChip(
                    label: Text(trade),
                    selected: _trade == trade,
                    onSelected: (selected) => setState(() => _trade = selected ? trade : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Localisation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _location,
              decoration: const InputDecoration(
                labelText: 'Ville ou arrondissement',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Toutes les localisations'),
                ),
                ...widget.availableLocations.map(
                  (location) => DropdownMenuItem<String?>(
                    value: location,
                    child: Text(location),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _location = value),
            ),
            const SizedBox(height: 24),
            Text('Note minimum : ${_rating.toStringAsFixed(1)} ⭐', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rating.toStringAsFixed(1),
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 24),
            Text('Années d\'expérience minimum : $_experience',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _experience.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: '$_experience ans',
              onChanged: (value) => setState(() => _experience = value.round()),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _FilterResult(
                    trade: _trade,
                    location: _location,
                    minRating: _rating,
                    minExperience: _experience,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Appliquer les filtres'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({
    required this.trade,
    required this.location,
    required this.minRating,
    required this.minExperience,
  });

  final String? trade;
  final String? location;
  final double minRating;
  final int minExperience;
}