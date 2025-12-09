import 'package:flutter/material.dart';
import '../../core/enums/unit_type.dart';
import '../../core/validation/input_sanitizer.dart';

/// Карточка результата расчёта.
class ResultCard extends StatelessWidget {
  final String label;
  final double value;
  final UnitType unitType;
  final bool isPrimary;
  final IconData? icon;

  const ResultCard({
    super.key,
    required this.label,
    required this.value,
    required this.unitType,
    this.isPrimary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isPrimary ? 4 : 0,
      color: isPrimary
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: EdgeInsets.all(isPrimary ? 24 : 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: isPrimary ? 32 : 24,
                color: isPrimary
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              SizedBox(width: isPrimary ? 16 : 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: (isPrimary
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      color: isPrimary
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        InputSanitizer.formatNumber(value),
                        style: (isPrimary
                                ? theme.textTheme.headlineMedium
                                : theme.textTheme.titleLarge)
                            ?.copyWith(
                          color: isPrimary
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unitType.symbol,
                        style: (isPrimary
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                          color: isPrimary
                              ? colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8)
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Список результатов расчёта.
class ResultsList extends StatelessWidget {
  final Map<String, (double, UnitType, String)> results;
  final String? primaryResultKey;
  final Map<String, IconData>? icons;

  const ResultsList({
    super.key,
    required this.results,
    this.primaryResultKey,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    final resultWidgets = <Widget>[];

    // Добавляем основной результат первым
    if (primaryResultKey != null && results.containsKey(primaryResultKey)) {
      final (value, unit, label) = results[primaryResultKey]!;
      resultWidgets.add(
        ResultCard(
          label: label,
          value: value,
          unitType: unit,
          isPrimary: true,
          icon: icons?[primaryResultKey],
        ),
      );
    }

    // Добавляем остальные результаты
    results.forEach((key, data) {
      if (key != primaryResultKey) {
        final (value, unit, label) = data;
        resultWidgets.add(
          ResultCard(
            label: label,
            value: value,
            unitType: unit,
            isPrimary: false,
            icon: icons?[key],
          ),
        );
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: resultWidgets
          .expand((widget) => [widget, const SizedBox(height: 12)])
          .toList()
        ..removeLast(), // Убираем последний SizedBox
    );
  }
}
