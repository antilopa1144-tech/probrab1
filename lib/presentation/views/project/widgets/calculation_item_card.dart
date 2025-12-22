import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/models/project_v2.dart';

/// Карточка расчёта проекта.
class CalculationItemCard extends StatelessWidget {
  final ProjectCalculation calculation;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const CalculationItemCard({
    super.key,
    required this.calculation,
    this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final results = calculation.resultsMap;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calculation.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calculation.calculatorId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                    tooltip: 'Удалить',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(calculation.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (results.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...results.entries.take(3).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatResultKey(entry.key),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatResultValue(entry.key, entry.value),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (calculation.notes != null &&
                  calculation.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  calculation.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('button.open_for_recalculation'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatResultKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String _formatResultValue(String key, double value) {
    final format = NumberFormat('#,##0.00', 'ru_RU');

    if (key.contains('area')) return '${format.format(value)} м?';
    if (key.contains('volume')) return '${format.format(value)} м?';
    if (key.contains('length') || key.contains('perimeter')) {
      return '${format.format(value)} м';
    }
    if (key.contains('kg') || key.contains('weight')) {
      return '${format.format(value)} кг';
    }
    if (key.contains('liters') || key.contains('l')) {
      return '${format.format(value)} л';
    }
    if (key.contains('pieces') ||
        key.contains('pcs') ||
        key.contains('needed')) {
      return '${format.format(value)} шт.';
    }
    if (key.contains('price') || key.contains('cost')) {
      return '${format.format(value)} ?';
    }

    return format.format(value);
  }
}
