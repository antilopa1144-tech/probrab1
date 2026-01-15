import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Визуальная карточка для выбора типа материала/опции
///
/// Используется для выбора между вариантами (например, "Под обои" vs "Под покраску")
/// Отображается как карточка с иконкой, заголовком и подзаголовком.
/// При выборе меняет цвет и границу.
///
/// Пример использования:
/// ```dart
/// Row(
///   children: [
///     Expanded(
///       child: TypeSelectorCard(
///         icon: Icons.wallpaper,
///         title: 'Под обои',
///         subtitle: '1 слой',
///         isSelected: selectedType == 0,
///         accentColor: CalculatorColors.interior,
///         onTap: () => setState(() => selectedType = 0),
///       ),
///     ),
///     SizedBox(width: 12),
///     Expanded(
///       child: TypeSelectorCard(
///         icon: Icons.format_paint,
///         title: 'Под покраску',
///         subtitle: '2 слоя',
///         isSelected: selectedType == 1,
///         accentColor: CalculatorColors.interior,
///         onTap: () => setState(() => selectedType = 1),
///       ),
///     ),
///   ],
/// )
/// ```
class TypeSelectorCard extends StatelessWidget {
  /// Иконка для отображения
  final IconData icon;

  /// Заголовок карточки
  final String title;

  /// Подзаголовок (дополнительное описание)
  final String? subtitle;

  /// Выбрана ли эта карточка
  final bool isSelected;

  /// Цвет акцента (используется при выборе)
  final Color accentColor;

  /// Callback при нажатии
  final VoidCallback onTap;

  /// Размер иконки
  final double iconSize;

  /// Показывать ли чекбокс при выборе
  final bool showCheckmark;

  const TypeSelectorCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    this.iconSize = 28,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Светлый оттенок акцентного цвета для фона
    final lightColor = _getLightColor(accentColor);
    final darkColor = _getDarkColor(accentColor);

    // Уменьшаем размеры если есть subtitle для экономии места
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final effectiveIconSize = hasSubtitle ? (iconSize * 0.75) : iconSize;
    final titleFontSize = hasSubtitle ? 10.0 : 14.0;
    final subtitleFontSize = 9.0;
    final padding = hasSubtitle ? 8.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CalculatorDesignSystem.animationDurationFast,
        curve: CalculatorDesignSystem.animationCurve,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isSelected ? lightColor : Colors.grey[50],
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey[200]!,
            width: isSelected
              ? CalculatorDesignSystem.borderWidthMedium
              : CalculatorDesignSystem.borderWidthThin,
          ),
          borderRadius: CalculatorDesignSystem.selectorBorderRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка с чекмарком
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? darkColor : Colors.grey[600],
                  size: effectiveIconSize,
                ),
                if (showCheckmark && isSelected)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: hasSubtitle ? 4 : 8),
            // Заголовок
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: isSelected ? darkColor : CalculatorColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Подзаголовок (если есть)
            if (hasSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  color: isSelected ? accentColor : CalculatorColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Получить светлый оттенок цвета
  Color _getLightColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.3).clamp(0.0, 1.0))
        .toColor();
  }

  /// Получить тёмный оттенок цвета
  Color _getDarkColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Вариант карточки выбора с меньшим размером (компактный)
class TypeSelectorCardCompact extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const TypeSelectorCardCompact({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TypeSelectorCard(
      icon: icon ?? Icons.check_circle_outline,
      title: title,
      subtitle: subtitle,
      isSelected: isSelected,
      accentColor: accentColor,
      onTap: onTap,
      iconSize: 20,
    );
  }
}

/// Группа карточек выбора типа
///
/// Автоматически создаёт Row или Column с карточками выбора
class TypeSelectorGroup extends StatelessWidget {
  /// Список опций для отображения
  final List<TypeSelectorOption> options;

  /// Индекс выбранного элемента
  final int selectedIndex;

  /// Callback при выборе
  final ValueChanged<int> onSelect;

  /// Акцентный цвет
  final Color accentColor;

  /// Направление (горизонтальное или вертикальное)
  final Axis direction;

  /// Расстояние между карточками
  final double spacing;

  const TypeSelectorGroup({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    required this.accentColor,
    this.direction = Axis.horizontal,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final cards = List.generate(
      options.length,
      (index) => Expanded(
        child: TypeSelectorCard(
          icon: options[index].icon,
          title: options[index].title,
          subtitle: options[index].subtitle,
          isSelected: selectedIndex == index,
          accentColor: accentColor,
          onTap: () => onSelect(index),
        ),
      ),
    );

    if (direction == Axis.horizontal) {
      return Row(
        children: _addSpacing(cards),
      );
    } else {
      return Column(
        children: _addSpacing(cards),
      );
    }
  }

  List<Widget> _addSpacing(List<Widget> children) {
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
    }
    return result;
  }
}

/// Модель опции для TypeSelectorGroup
class TypeSelectorOption {
  final IconData icon;
  final String title;
  final String? subtitle;

  const TypeSelectorOption({
    required this.icon,
    required this.title,
    this.subtitle,
  });
}
