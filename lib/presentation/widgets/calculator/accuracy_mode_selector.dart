import 'package:flutter/material.dart';
import '../../../domain/accuracy/accuracy_mode.dart';

/// Виджет выбора режима точности расчёта.
///
/// Отображает 3 сегмента: Базовый / Реальный / Профессиональный.
/// По умолчанию выбран "Реальный" (realistic).
class AccuracyModeSelector extends StatelessWidget {
  final AccuracyMode selected;
  final ValueChanged<AccuracyMode> onChanged;

  const AccuracyModeSelector({
    super.key,
    this.selected = AccuracyMode.realistic,
    required this.onChanged,
  });

  static const _labels = {
    AccuracyMode.basic: 'Базовый',
    AccuracyMode.realistic: 'Реальный',
    AccuracyMode.professional: 'Профи',
  };

  static const _descriptions = {
    AccuracyMode.basic: 'По нормативу, без поправок',
    AccuracyMode.realistic: 'Для обычного ремонта',
    AccuracyMode.professional: 'С запасом на сложные условия',
  };

  static const _icons = {
    AccuracyMode.basic: Icons.speed,
    AccuracyMode.realistic: Icons.home_repair_service,
    AccuracyMode.professional: Icons.engineering,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Точность расчёта',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ),
        SegmentedButton<AccuracyMode>(
          segments: AccuracyMode.values.map((mode) {
            return ButtonSegment<AccuracyMode>(
              value: mode,
              label: Text(
                _labels[mode]!,
                style: const TextStyle(fontSize: 12),
              ),
              icon: Icon(_icons[mode], size: 16),
            );
          }).toList(),
          selected: {selected},
          onSelectionChanged: (modes) {
            onChanged(modes.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (_descriptions[selected] != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              _descriptions[selected]!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? theme.colorScheme.onSurface.withAlpha(140)
                    : theme.colorScheme.onSurface.withAlpha(120),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
