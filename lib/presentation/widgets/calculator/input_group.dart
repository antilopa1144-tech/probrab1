import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Группа полей ввода с заголовком и опциональной иконкой
///
/// Используется для логической группировки связанных полей ввода
/// (например, "Геометрия", "Проемы", "Параметры материала")
///
/// Поддерживает collapsible режим (сворачивание/разворачивание)
///
/// Пример использования:
/// ```dart
/// InputGroup(
///   title: 'Геометрия',
///   icon: Icons.straighten,
///   accentColor: CalculatorColors.interior,
///   children: [
///     Row(
///       children: [
///         Expanded(child: TextField(decoration: InputDecoration(labelText: 'Длина'))),
///         SizedBox(width: 12),
///         Expanded(child: TextField(decoration: InputDecoration(labelText: 'Ширина'))),
///       ],
///     ),
///     SizedBox(height: 12),
///     TextField(decoration: InputDecoration(labelText: 'Высота')),
///   ],
/// )
/// ```
class InputGroup extends StatefulWidget {
  /// Заголовок группы
  final String title;

  /// Иконка заголовка (опционально)
  final IconData? icon;

  /// Список виджетов внутри группы
  final List<Widget> children;

  /// Акцентный цвет (для иконки и границ)
  final Color? accentColor;

  /// Можно ли сворачивать/разворачивать группу
  final bool isCollapsible;

  /// Развёрнута ли группа по умолчанию (если collapsible)
  final bool initiallyExpanded;

  /// Фоновый цвет карточки
  final Color? backgroundColor;

  /// Показывать ли тень
  final bool showShadow;

  /// Дополнительный padding
  final EdgeInsets? padding;

  /// Trailing виджет в заголовке (например, кнопка "Добавить")
  final Widget? trailing;

  const InputGroup({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.accentColor,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.backgroundColor,
    this.showShadow = true,
    this.padding,
    this.trailing,
  });

  @override
  State<InputGroup> createState() => _InputGroupState();
}

class _InputGroupState extends State<InputGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsible) {
      return _buildCollapsibleGroup();
    } else {
      return _buildStaticGroup();
    }
  }

  /// Статичная группа (не сворачивается)
  Widget _buildStaticGroup() {
    return Container(
      padding: widget.padding ?? CalculatorDesignSystem.cardPadding,
      decoration: widget.showShadow
          ? CalculatorDesignSystem.cardDecoration(
              color: widget.backgroundColor ?? Colors.white,
            )
          : CalculatorDesignSystem.cardDecorationFlat(
              color: widget.backgroundColor ?? Colors.white,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ..._buildChildrenWithSpacing(),
        ],
      ),
    );
  }

  /// Collapsible группа (с ExpansionTile)
  Widget _buildCollapsibleGroup() {
    return Container(
      decoration: widget.showShadow
          ? CalculatorDesignSystem.cardDecoration(
              color: widget.backgroundColor ?? Colors.white,
            )
          : CalculatorDesignSystem.cardDecorationFlat(
              color: widget.backgroundColor ?? Colors.white,
            ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: _buildHeader(),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          tilePadding: widget.padding ?? CalculatorDesignSystem.cardPadding,
          childrenPadding: EdgeInsets.only(
            left: (widget.padding?.left ?? CalculatorDesignSystem.spacingM),
            right: (widget.padding?.right ?? CalculatorDesignSystem.spacingM),
            bottom: (widget.padding?.bottom ?? CalculatorDesignSystem.spacingM),
          ),
          children: _buildChildrenWithSpacing(),
        ),
      ),
    );
  }

  /// Заголовок группы
  Widget _buildHeader() {
    final color = widget.accentColor ?? CalculatorColors.interior;

    return Row(
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: color,
            size: CalculatorDesignSystem.iconSizeMedium,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            widget.title,
            style: CalculatorDesignSystem.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  /// Добавить spacing между children
  List<Widget> _buildChildrenWithSpacing() {
    final result = <Widget>[];
    for (int i = 0; i < widget.children.length; i++) {
      result.add(widget.children[i]);
      if (i < widget.children.length - 1) {
        result.add(const SizedBox(height: 12));
      }
    }
    return result;
  }
}

/// Лёгкая версия InputGroup без карточки (только заголовок)
class InputGroupSimple extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Color? accentColor;
  final Widget? trailing;

  const InputGroupSimple({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? CalculatorColors.interior;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: color,
                size: CalculatorDesignSystem.iconSizeMedium,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        ..._buildChildrenWithSpacing(),
      ],
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(const SizedBox(height: 12));
      }
    }
    return result;
  }
}

/// InputGroup с цветным фоном
class InputGroupColored extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Color accentColor;
  final Widget? trailing;

  const InputGroupColored({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    required this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Светлый оттенок акцентного цвета
    final lightColor = _getLightColor(accentColor);

    return InputGroup(
      title: title,
      icon: icon,
      accentColor: accentColor,
      backgroundColor: lightColor,
      showShadow: false,
      trailing: trailing,
      children: children,
    );
  }

  Color _getLightColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.3).clamp(0.0, 1.0))
        .toColor();
  }
}
