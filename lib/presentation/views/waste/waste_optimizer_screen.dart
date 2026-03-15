import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/waste_optimization.dart';

/// Экран оптимизации отходов.
class WasteOptimizerScreen extends StatelessWidget {
  final String materialId;
  final double requiredArea;
  final double standardSize;

  const WasteOptimizerScreen({
    super.key,
    required this.materialId,
    required this.requiredArea,
    required this.standardSize,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final optimization = WasteOptimization.calculate(
      materialId: materialId,
      requiredArea: requiredArea,
      standardSize: standardSize,
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('waste.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('waste.results_title'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatCard(
                      icon: Icons.square_foot,
                      label: loc.translate('waste.required_area'),
                      value: loc.translate('waste.value.area', {
                        'value': requiredArea.toStringAsFixed(2),
                      }),
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.inventory_2,
                      label: loc.translate('waste.optimized_quantity'),
                      value: loc.translate('waste.value.items', {
                        'value': optimization.optimizedQuantity.toStringAsFixed(1),
                      }),
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.percent,
                      label: loc.translate('waste.waste_percent'),
                      value: loc.translate('waste.value.percent', {
                        'value': optimization.wastePercentage.toStringAsFixed(1),
                      }),
                      color: optimization.wastePercentage < 10
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    if (optimization.wasteReduction > 0)
                      _StatCard(
                        icon: Icons.trending_down,
                        label: loc.translate('waste.reduction'),
                        value: loc.translate('waste.value.percent', {
                          'value': optimization.wasteReduction.toStringAsFixed(1),
                        }),
                        color: Colors.green,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (optimization.recommendationKeys.isNotEmpty)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('waste.recommendations'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...optimization.recommendationKeys.map(
                        (key) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(loc.translate(key))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
