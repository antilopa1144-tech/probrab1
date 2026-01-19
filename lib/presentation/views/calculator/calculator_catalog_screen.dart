import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screed_unified_calculator_screen.dart';
import '../paint/paint_screen.dart';
import '../wood/wood_screen.dart';
import '../primer/primer_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/calculator_navigation_helper.dart';

class CalculatorCatalogScreen extends ConsumerStatefulWidget {
  final String? subCategoryKey;

  const CalculatorCatalogScreen({super.key, this.subCategoryKey});

  @override
  ConsumerState<CalculatorCatalogScreen> createState() =>
      _CalculatorCatalogScreenState();
}

class _CalculatorCatalogScreenState
    extends ConsumerState<CalculatorCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final next = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = next);
    });
  }

  List<CalculatorDefinitionV2> _filtered(AppLocalizations loc) {
    final baseSource = CalculatorRegistry.catalogCalculators;
    final base = widget.subCategoryKey == null
        ? baseSource
        : baseSource
            .where((c) => c.subCategoryKey == widget.subCategoryKey)
            .toList(growable: false);

    if (_query.isEmpty) return base;

    final q = _query.toLowerCase();
    return base.where((calc) {
      final title = loc.translate(calc.titleKey).toLowerCase();
      final sub = loc.translate(calc.subCategoryKey).toLowerCase();
      return title.contains(q) ||
          sub.contains(q) ||
          calc.id.toLowerCase().contains(q) ||
          calc.tags.any((t) {
            final tagValue =
                t.startsWith('tag.') ? loc.translate(t) : t;
            return tagValue.toLowerCase().contains(q);
          });
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final calculators = _filtered(loc);
    final title = widget.subCategoryKey == null
        ? loc.translate('catalog.all_calculators')
        : loc.translate(widget.subCategoryKey!);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: loc.translate('search.placeholder'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: calculators.isEmpty
                ? Center(child: Text(loc.translate('search.no_results')))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: calculators.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final calc = calculators[index];
                      final isFavorite = favorites.contains(calc.id);
                      return _CatalogCalculatorCard(
                        calc: calc,
                        title: loc.translate(calc.titleKey),
                        subtitle: loc.translate(calc.subCategoryKey),
                        isFavorite: isFavorite,
                        onToggleFavorite: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(calc.id),
                        onOpen: () {
                          // Специальные экраны с новым дизайном
                          if (calc.id == 'dsp' || calc.id == 'floors_screed' || calc.id == 'floors_screed_unified') {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const ScreedUnifiedCalculatorScreen(),
                            ));
                          } else if (calc.id == 'paint' || calc.id == 'paint_universal') {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const PaintScreen(),
                            ));
                          } else if (calc.id == 'wood') {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const WoodScreen(),
                            ));
                          } else if (calc.id == 'primer') {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const PrimerScreen(),
                            ));
                          } else {
                            CalculatorNavigationHelper.navigateToCalculator(
                              context,
                              calc,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CatalogCalculatorCard extends StatelessWidget {
  final CalculatorDefinitionV2 calc;
  final String title;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _CatalogCalculatorCard({
    required this.calc,
    required this.title,
    required this.subtitle,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? loc.translate('favorites.remove')
                    : loc.translate('favorites.add'),
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
