import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/material_repository.dart';
import '../../../domain/entities/material_comparison.dart';

/// Экран сравнения материалов.
class MaterialComparisonScreen extends ConsumerStatefulWidget {
  final String calculatorId;
  final double requiredQuantity;

  const MaterialComparisonScreen({
    super.key,
    required this.calculatorId,
    required this.requiredQuantity,
  });

  @override
  ConsumerState<MaterialComparisonScreen> createState() =>
      _MaterialComparisonScreenState();
}

class _MaterialComparisonScreenState
    extends ConsumerState<MaterialComparisonScreen> {
  MaterialOption? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final materialsAsync =
        ref.watch(materialsForCalculatorProvider(widget.calculatorId));

    return materialsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(loc.translate('material_comparison.title'))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(loc.translate('material_comparison.title'))),
        body: Center(child: Text(loc.translate('material_comparison.loading_error'))),
      ),
      data: (options) {
        if (options.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.translate('material_comparison.title'))),
            body: Center(child: Text(loc.translate('material_comparison.empty'))),
          );
        }

        final selectedOption = (_selectedOption != null &&
                options.any((option) => option.id == _selectedOption!.id))
            ? _selectedOption!
            : options.first;

        final comparison = MaterialComparison(
          calculatorId: widget.calculatorId,
          requiredQuantity: widget.requiredQuantity,
          options: options,
          recommended: options.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.translate('material_comparison.title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: loc.translate('material_comparison.add_option'),
                onPressed: () => _showAddOptionDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('material_comparison.recommendations'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RecommendationCard(
                      title: loc.translate('material_comparison.card.cheapest'),
                      option: comparison.cheapest,
                    ),
                    const SizedBox(height: 8),
                    _RecommendationCard(
                      title: loc.translate('material_comparison.card.durable'),
                      option: comparison.mostDurable,
                    ),
                    const SizedBox(height: 8),
                    _RecommendationCard(
                      title: loc.translate('material_comparison.card.optimal'),
                      option: comparison.optimal,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: options.length,
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    final option = options[index];

                    return RepaintBoundary(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(option.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('material_comparison.service_life', {
                                  'value': option.durabilityYears.toString(),
                                }),
                              ),
                            ],
                          ),
                          trailing: selectedOption.id == option.id
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  tooltip: loc.translate('button.select'),
                                  onPressed: () {
                                    setState(() {
                                      _selectedOption = option;
                                    });
                                  },
                                ),
                          onTap: () {
                            setState(() {
                              _selectedOption = option;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOptionDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('material_comparison.add_option')),
        content: Text(loc.translate('material_comparison.in_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('button.close')),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final MaterialOption? option;

  const _RecommendationCard({
    required this.title,
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    if (option == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(option!.name),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
