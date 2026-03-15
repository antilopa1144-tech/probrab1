import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/models/project_v2.dart';

/// Карточка расчёта проекта.
class CalculationItemCard extends StatefulWidget {
  final ProjectCalculation calculation;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final bool expandByDefault;

  const CalculationItemCard({
    super.key,
    required this.calculation,
    this.onTap,
    required this.onDelete,
    this.expandByDefault = false,
  });

  @override
  State<CalculationItemCard> createState() => _CalculationItemCardState();
}

class _CalculationItemCardState extends State<CalculationItemCard> {
  late bool _isExpanded;
  static const int _previewResultCount = 3;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandByDefault;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final results = widget.calculation.resultsMap;

    // Determine which results to show
    final entriesToShow = _isExpanded
        ? results.entries.toList()
        : results.entries.take(_previewResultCount).toList();
    final hasMoreResults = results.length > _previewResultCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
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
                          widget.calculation.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCalculatorId(widget.calculation.calculatorId, loc),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: widget.onDelete,
                    tooltip: loc.translate('button.delete'),
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
                    dateFormat.format(widget.calculation.createdAt),
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
                ...entriesToShow.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatResultKey(entry.key, loc),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          _formatResultValue(entry.key, entry.value, loc),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (hasMoreResults) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(
                        _isExpanded
                            ? AppLocalizations.of(context)
                                .translate('button.show_less')
                            : AppLocalizations.of(context).translate(
                                'button.show_more',
                              ).replaceAll(
                                '{count}',
                                (results.length - _previewResultCount)
                                    .toString(),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
              if (widget.calculation.notes != null &&
                  widget.calculation.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.calculation.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.onTap != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onTap,
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

  String _formatResultKey(String key, AppLocalizations loc) {
    final localized = loc.translate('share.result_labels.$key');
    if (localized != 'share.result_labels.$key') return localized;

    final resultLocalized = loc.translate('result.$key');
    if (resultLocalized != 'result.$key') return resultLocalized;

    final directLocalized = loc.translate(key);
    if (directLocalized != key) return directLocalized;

    return key;
  }

  String _formatCalculatorId(String calculatorId, AppLocalizations loc) {
    // Пробуем найти локализованное название калькулятора
    final localized = loc.translate('share.calculator_names.$calculatorId');
    if (localized != 'share.calculator_names.$calculatorId') {
      return localized;
    }
    return calculatorId;
  }

  String _formatResultValue(String key, double value, AppLocalizations loc) {
    final format = NumberFormat('#,##0.00', 'ru_RU');
    final formatted = format.format(value);

    if (key.contains('area')) return '$formatted ${loc.translate('unit.sqm')}';
    if (key.contains('volume')) return '$formatted ${loc.translate('unit.cubicMeters')}';
    if (key.contains('length') || key.contains('perimeter')) {
      return '$formatted ${loc.translate('unit.meters')}';
    }
    if (key.contains('kg') || key.contains('weight')) {
      return '$formatted ${loc.translate('unit.kilograms')}';
    }
    if (key.contains('liter') || key.contains('liters') || key.endsWith('_l')) {
      return '$formatted ${loc.translate('unit.liters')}';
    }
    if (key.contains('pieces') ||
        key.contains('pcs') ||
        key.contains('needed') ||
        key.contains('count')) {
      return '$formatted ${loc.translate('unit.pieces')}';
    }
    if (key.contains('price') || key.contains('cost')) {
      return '$formatted ₽';
    }

    return formatted;
  }
}
