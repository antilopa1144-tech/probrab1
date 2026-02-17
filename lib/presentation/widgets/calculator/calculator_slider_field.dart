import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import 'calculator_text_field.dart';

/// Переиспользуемый виджет слайдера для калькуляторов.
///
/// Включает метку, текущее значение, слайдер и текстовое поле для ручного ввода.
///
/// Использование:
/// ```dart
/// CalculatorSliderField(
///   label: loc.translate('laminate_calc.label.area'),
///   value: _area,
///   min: 5,
///   max: 200,
///   suffix: loc.translate('common.sqm'),
///   accentColor: accentColor,
///   onChanged: (v) => setState(() { _area = v; _update(); }),
/// )
/// ```
class CalculatorSliderField extends StatelessWidget {
  /// Текст метки (например, "Площадь").
  final String label;

  /// Текущее значение слайдера.
  final double value;

  /// Минимальное значение.
  final double min;

  /// Максимальное значение.
  final double max;

  /// Количество делений (опционально).
  final int? divisions;

  /// Суффикс для отображения значения (например, "м²").
  final String suffix;

  /// Акцентный цвет слайдера.
  final Color accentColor;

  /// Callback при изменении значения.
  final ValueChanged<double> onChanged;

  /// Количество знаков после запятой для отображения (по умолчанию 0).
  final int decimalPlaces;

  /// Показывать ли значение справа (по умолчанию true).
  final bool showValue;

  const CalculatorSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.suffix,
    required this.accentColor,
    required this.onChanged,
    this.decimalPlaces = 0,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayValue = decimalPlaces == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(decimalPlaces);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showValue) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '$displayValue $suffix',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: accentColor,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        CalculatorTextField(
          label: label,
          value: value,
          onChanged: onChanged,
          suffix: suffix,
          accentColor: accentColor,
          minValue: min,
          maxValue: max,
          decimalPlaces: decimalPlaces,
        ),
      ],
    );
  }
}

/// Компактная версия слайдера без метки значения.
class CalculatorSliderFieldCompact extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const CalculatorSliderFieldCompact({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CalculatorDesignSystem.bodySmall.copyWith(
            color: CalculatorColors.getTextSecondary(isDark),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
