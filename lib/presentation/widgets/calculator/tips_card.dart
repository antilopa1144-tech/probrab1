import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Карточка полезных советов для калькуляторов.
///
/// Отображает список советов с иконками и чек-марками.
/// Используется во всех калькуляторах для предоставления
/// контекстных рекомендаций пользователю.
///
/// ## Пример использования:
///
/// ```dart
/// TipsCard(
///   tips: [
///     'Используйте бетон марки М300 для фундамента',
///     'Арматуру связывайте проволокой, а не сваривайте',
///     'Заливайте бетон в один день для монолитности',
///   ],
///   accentColor: CalculatorColors.foundation,
///   title: 'Полезные советы', // опционально, по умолчанию 'common.tips'
/// )
/// ```
///
/// ## Динамические советы в зависимости от типа:
///
/// ```dart
/// TipsCard(
///   tips: _getTipsForType(_selectedType),
///   accentColor: _accentColor,
/// )
///
/// List<String> _getTipsForType(MyType type) {
///   final tips = <String>[];
///   switch (type) {
///     case MyType.option1:
///       tips.addAll([loc.translate('calc.tip.option1_1'), loc.translate('calc.tip.option1_2')]);
///       break;
///     case MyType.option2:
///       tips.addAll([loc.translate('calc.tip.option2_1'), loc.translate('calc.tip.option2_2')]);
///       break;
///   }
///   tips.add(loc.translate('calc.tip.common')); // общий совет для всех
///   return tips;
/// }
/// ```
class TipsCard extends StatelessWidget {
  /// Список советов для отображения
  final List<String> tips;

  /// Акцентный цвет для чек-марок
  final Color accentColor;

  /// Заголовок карточки (по умолчанию 'Полезные советы')
  final String? title;

  /// Иконка заголовка (по умолчанию lightbulb_outline)
  final IconData? titleIcon;

  const TipsCard({
    super.key,
    required this.tips,
    required this.accentColor,
    this.title,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                titleIcon ?? Icons.lightbulb_outline,
                size: 20,
                color: CalculatorColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? 'Полезные советы',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => _buildTipItem(tip)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактная версия TipsCard без карточки (для встраивания в другие карточки).
///
/// Используется когда нужно добавить советы внутрь существующей карточки,
/// а не создавать отдельную.
class TipsSection extends StatelessWidget {
  /// Список советов для отображения
  final List<String> tips;

  /// Акцентный цвет для чек-марок
  final Color accentColor;

  /// Заголовок секции (опционально)
  final String? title;

  const TipsSection({
    super.key,
    required this.tips,
    required this.accentColor,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: CalculatorColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title!,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ...tips.map((tip) => _buildTipItem(tip)),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
