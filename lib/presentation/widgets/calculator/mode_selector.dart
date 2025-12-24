import 'package:flutter/material.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Переключатель режимов (табы) для калькуляторов
///
/// Используется для переключения между режимами ввода данных
/// (например, "Комната" vs "Список стен")
///
/// Стиль основан на эталонном калькуляторе "Шпатлёвка"
///
/// Пример использования:
/// ```dart
/// ModeSelector(
///   options: ['Комната', 'Список стен'],
///   selectedIndex: _mode,
///   onSelect: (index) => setState(() => _mode = index),
///   accentColor: CalculatorColors.interior,
/// )
/// ```
class ModeSelector extends StatelessWidget {
  /// Список опций для отображения
  final List<String> options;

  /// Индекс выбранного элемента
  final int selectedIndex;

  /// Callback при выборе
  final ValueChanged<int> onSelect;

  /// Акцентный цвет (для выбранного элемента)
  final Color? accentColor;

  /// Высота переключателя
  final double height;

  const ModeSelector({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.accentColor,
    this.height = 40,
  }) : assert(options.length >= 2, 'Должно быть минимум 2 опции');

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: CalculatorDesignSystem.selectorBorderRadius,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(
          options.length,
          (index) => Expanded(
            child: _buildOption(
              options[index],
              selectedIndex == index,
              accent,
              () => onSelect(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    String text,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CalculatorDesignSystem.animationDurationFast,
        curve: CalculatorDesignSystem.animationCurve,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [CalculatorDesignSystem.cardDecoration().boxShadow![0]]
              : null,
        ),
        child: Text(
          text,
          style: CalculatorDesignSystem.bodyMedium.copyWith(
            color: isSelected ? accentColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Компактная версия ModeSelector с иконками
class ModeSelectorWithIcons extends StatelessWidget {
  final List<ModeSelectorIconOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color? accentColor;
  final double height;

  const ModeSelectorWithIcons({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.accentColor,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: CalculatorDesignSystem.selectorBorderRadius,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(
          options.length,
          (index) => Expanded(
            child: _buildOption(
              options[index],
              selectedIndex == index,
              accent,
              () => onSelect(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    ModeSelectorIconOption option,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CalculatorDesignSystem.animationDurationFast,
        curve: CalculatorDesignSystem.animationCurve,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [CalculatorDesignSystem.cardDecoration().boxShadow![0]]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                size: 18,
                color: isSelected ? accentColor : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                option.label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: isSelected ? accentColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Модель опции с иконкой
class ModeSelectorIconOption {
  final String label;
  final IconData? icon;

  const ModeSelectorIconOption({
    required this.label,
    this.icon,
  });
}

/// Вертикальный вариант ModeSelector (список)
class ModeSelectorVertical extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color? accentColor;

  const ModeSelectorVertical({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).primaryColor;

    return Column(
      children: List.generate(
        options.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildOption(
            options[index],
            selectedIndex == index,
            accent,
            () => onSelect(index),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    String text,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CalculatorDesignSystem.animationDurationFast,
        curve: CalculatorDesignSystem.animationCurve,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: CalculatorDesignSystem.selectorBorderRadius,
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey[300]!,
            width: isSelected
                ? CalculatorDesignSystem.borderWidthMedium
                : CalculatorDesignSystem.borderWidthThin,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
