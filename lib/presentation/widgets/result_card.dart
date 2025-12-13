import 'package:flutter/material.dart';
import '../../core/enums/unit_type.dart';
import '../../core/validation/input_sanitizer.dart';

enum ResultsListLayout {
  flat,
  shoppingList,
}

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
  final ResultsListLayout layout;

  const ResultsList({
    super.key,
    required this.results,
    this.primaryResultKey,
    this.icons,
    this.layout = ResultsListLayout.flat,
  });

  bool _isParameterKey(String key) {
    final k = key.toLowerCase();
    return k == 'area' ||
        k == 'usefularea' ||
        k == 'realarea' ||
        k == 'volume' ||
        k.contains('thickness') ||
        k.contains('height') ||
        k.contains('width') ||
        k.contains('length') ||
        k.contains('perimeter') ||
        k.contains('count') ||
        k.contains('mode') ||
        k.contains('type');
  }

  bool _isConsumableKey(String key) {
    final k = key.toLowerCase();
    return k.contains('screw') ||
        k.contains('nail') ||
        k.contains('dowel') ||
        k.contains('fastener') ||
        k.contains('tape') ||
        k.contains('primer') ||
        k.contains('glue') ||
        k.contains('seal') ||
        k.contains('sealant') ||
        k.contains('compound') ||
        k.contains('grout') ||
        k.contains('mastic') ||
        k.contains('foam');
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    if (layout == ResultsListLayout.flat) {
      final resultWidgets = <Widget>[];

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
          ..removeLast(),
      );
    }

    final primaryWidget = <Widget>[];
    final materialWidgets = <Widget>[];
    final consumableWidgets = <Widget>[];
    final parameterWidgets = <Widget>[];

    for (final entry in results.entries) {
      final key = entry.key;
      final (value, unit, label) = entry.value;

      final card = ResultCard(
        label: label,
        value: value,
        unitType: unit,
        isPrimary: false,
        icon: icons?[key],
      );

      if (key == primaryResultKey) {
        primaryWidget.add(
          ResultCard(
            label: label,
            value: value,
            unitType: unit,
            isPrimary: true,
            icon: icons?[key],
          ),
        );
        continue;
      }

      if (_isParameterKey(key)) {
        parameterWidgets.add(card);
      } else if (_isConsumableKey(key)) {
        consumableWidgets.add(card);
      } else {
        materialWidgets.add(card);
      }
    }

    final widgets = <Widget>[];
    widgets.addAll(primaryWidget);

    if (materialWidgets.isNotEmpty) {
      widgets.add(_buildSectionTitle(context, 'Материалы'));
      widgets.addAll(materialWidgets);
    }

    if (consumableWidgets.isNotEmpty) {
      widgets.add(_buildSectionTitle(context, 'Расходники'));
      widgets.addAll(consumableWidgets);
    }

    if (parameterWidgets.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            title: Text(
              'Параметры',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: parameterWidgets
                .expand((w) => [w, const SizedBox(height: 12)])
                .toList()
              ..removeLast(),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets
          .expand((widget) => [widget, const SizedBox(height: 12)])
          .toList()
        ..removeLast(),
    );
  }
}
