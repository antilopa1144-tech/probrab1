import 'package:flutter/material.dart';

import '../../domain/calculators/calculator_registry.dart';
import '../../domain/entities/object_type.dart';
import '../../core/localization/app_localizations.dart';
import '../data/work_catalog.dart';
import '../utils/calculator_navigation_helper.dart';

class WorkItemsScreen extends StatelessWidget {
  final ObjectType objectType;
  final WorkAreaDefinition area;
  final WorkSectionDefinition section;

  const WorkItemsScreen({
    super.key,
    required this.objectType,
    required this.area,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.translate(section.title)),
            Text(
              loc.translate(area.title),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: section.items.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = section.items[index];
          return _WorkItemCard(item: item, accent: area.color);
        },
      ),
    );
  }
}

class _WorkItemCard extends StatelessWidget {
  final WorkItemDefinition item;
  final Color accent;

  const _WorkItemCard({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final definition = item.calculatorId != null
        ? CalculatorRegistry.getById(item.calculatorId!)
        : null;
    final Color calculatorAccent = definition?.accentColor != null
        ? Color(definition!.accentColor!)
        : accent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: calculatorAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: calculatorAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate(item.title),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          loc.translate(item.description!),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.tips.isNotEmpty)
              _TipsBlock(tips: item.tips, accent: calculatorAccent)
            else
              Text(
                loc.translate('work.screen.no_tips'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: item.calculatorId == null
                    ? null
                    : () {
                        CalculatorNavigationHelper.navigateToCalculatorById(
                          context,
                          item.calculatorId!,
                        );
                      },
                icon: Icon(
                  item.calculatorId == null
                      ? Icons.construction_outlined
                      : Icons.calculate_outlined,
                ),
                label: Text(
                  item.calculatorId == null
                      ? loc.translate('work.screen.in_development')
                      : loc.translate('work.screen.open_calculator'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: item.calculatorId == null
                      ? theme.colorScheme.surfaceContainerHighest
                      : calculatorAccent,
                  foregroundColor: item.calculatorId == null
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsBlock extends StatelessWidget {
  final List<String> tips;
  final Color accent;

  const _TipsBlock({required this.tips, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accent),
              const SizedBox(width: 8),
              Text(
                loc.translate('work.screen.tips_title'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: theme.textTheme.bodyMedium?.copyWith(color: accent),
                  ),
                  Expanded(
                    child: Text(
                      loc.translate(tip),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
