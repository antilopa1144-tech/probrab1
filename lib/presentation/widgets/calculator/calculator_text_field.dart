import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Стандартизированное текстовое поле для калькуляторов
///
/// Автоматически настраивает:
/// - Числовую клавиатуру для чисел
/// - Правильный стиль и отступы
/// - Валидацию (опционально)
/// - Форматирование (опционально)
///
/// Пример использования:
/// ```dart
/// CalculatorTextField(
///   label: 'Длина (м)',
///   value: 4.0,
///   onChanged: (value) => setState(() => _length = value),
/// )
/// ```
class CalculatorTextField extends StatefulWidget {
  /// Метка поля
  final String label;

  /// Текущее значение
  final double value;

  /// Callback при изменении значения
  final ValueChanged<double> onChanged;

  /// Hint text (подсказка)
  final String? hint;

  /// Суффикс (единица измерения)
  final String? suffix;

  /// Иконка (опционально)
  final IconData? icon;

  /// Минимальное значение
  final double? minValue;

  /// Максимальное значение
  final double? maxValue;

  /// Количество знаков после запятой
  final int decimalPlaces;

  /// Только целые числа
  final bool isInteger;

  /// Disabled состояние
  final bool enabled;

  /// Акцентный цвет (для focus)
  final Color? accentColor;

  /// Фоновый цвет
  final Color? fillColor;

  const CalculatorTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.suffix,
    this.icon,
    this.minValue,
    this.maxValue,
    this.decimalPlaces = 1,
    this.isInteger = false,
    this.enabled = true,
    this.accentColor,
    this.fillColor,
  });

  @override
  State<CalculatorTextField> createState() => _CalculatorTextFieldState();
}

class _CalculatorTextFieldState extends State<CalculatorTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(CalculatorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.isInteger) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(widget.decimalPlaces);
    }
  }

  void _handleChange(String text) {
    if (text.isEmpty) {
      widget.onChanged(0.0);
      return;
    }

    final normalized = text.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) return;

    // Валидация диапазона
    double value = parsed;
    if (widget.minValue != null && value < widget.minValue!) {
      value = widget.minValue!;
    }
    if (widget.maxValue != null && value > widget.maxValue!) {
      value = widget.maxValue!;
    }

    if (value != parsed) {
      final formatted = _formatValue(value);
      if (_controller.text != formatted) {
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? CalculatorColors.interior;
    final allowNegative = widget.minValue != null && widget.minValue! < 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.numberWithOptions(
        decimal: !widget.isInteger,
        signed: allowNegative,
      ),
      inputFormatters: [
        if (widget.isInteger)
          FilteringTextInputFormatter.allow(
            RegExp(allowNegative ? r'^-?\d*$' : r'^\d*$'),
          )
        else
          FilteringTextInputFormatter.allow(
            RegExp(allowNegative ? r'^-?\d*[.,]?\d*$' : r'^\d*[.,]?\d*$'),
          ),
      ],
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixText: widget.suffix,
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, size: 20, color: accent)
            : null,
        filled: true,
        fillColor: widget.fillColor ?? CalculatorColors.getInputBackground(isDark),
        border: OutlineInputBorder(
          borderRadius: CalculatorDesignSystem.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CalculatorDesignSystem.inputBorderRadius,
          borderSide: isDark
              ? BorderSide(color: CalculatorColors.borderDefaultDark, width: 1)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CalculatorDesignSystem.inputBorderRadius,
          borderSide: BorderSide(
            color: accent,
            width: CalculatorDesignSystem.borderWidthMedium,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: CalculatorDesignSystem.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: CalculatorDesignSystem.bodySmall.copyWith(
          color: CalculatorColors.getTextSecondary(isDark),
        ),
        suffixStyle: CalculatorDesignSystem.bodySmall.copyWith(
          color: CalculatorColors.getTextTertiary(isDark),
        ),
      ),
      style: CalculatorDesignSystem.bodyMedium.copyWith(
        height: 1.2,
        color: CalculatorColors.getTextPrimary(isDark),
      ),
      onChanged: _handleChange,
    );
  }
}

/// Компактная версия поля ввода (для использования в строках)
class CalculatorTextFieldCompact extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isInteger;
  final int decimalPlaces;

  const CalculatorTextFieldCompact({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isInteger = false,
    this.decimalPlaces = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CalculatorTextField(
      label: label,
      value: value,
      onChanged: onChanged,
      isInteger: isInteger,
      decimalPlaces: decimalPlaces,
    );
  }
}

/// Готовый набор полей для размеров комнаты (длина, ширина, высота)
class RoomDimensionsFields extends StatelessWidget {
  final double length;
  final double width;
  final double height;
  final ValueChanged<double> onLengthChanged;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;
  final Color? accentColor;

  const RoomDimensionsFields({
    super.key,
    required this.length,
    required this.width,
    required this.height,
    required this.onLengthChanged,
    required this.onWidthChanged,
    required this.onHeightChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CalculatorTextField(
                label: 'Длина (м)',
                value: length,
                onChanged: onLengthChanged,
                icon: Icons.straighten,
                minValue: 0.1,
                maxValue: 100,
                accentColor: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalculatorTextField(
                label: 'Ширина (м)',
                value: width,
                onChanged: onWidthChanged,
                icon: Icons.straighten,
                minValue: 0.1,
                maxValue: 100,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: 'Высота потолка (м)',
          value: height,
          onChanged: onHeightChanged,
          icon: Icons.height,
          minValue: 1.5,
          maxValue: 10,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

/// Поле для выбора из предустановленных значений с возможностью ручного ввода
class CalculatorTextFieldWithPresets extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final List<double> presets;
  final Color? accentColor;

  const CalculatorTextFieldWithPresets({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.presets,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalculatorTextField(
          label: label,
          value: value,
          onChanged: onChanged,
          accentColor: accentColor,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: presets.map((preset) {
            final isSelected = (value - preset).abs() < 0.01;
            return FilterChip(
              label: Text(preset.toString()),
              selected: isSelected,
              onSelected: (_) => onChanged(preset),
              selectedColor: accentColor ?? CalculatorColors.interior,
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
      ],
    );
  }
}
