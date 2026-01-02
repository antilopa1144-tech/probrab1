import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Модель строки результата
class ResultRowItem {
  /// Название материала/параметра
  final String label;

  /// Значение (количество)
  final String value;

  /// Дополнительная информация (опционально)
  final String? subtitle;

  /// Иконка (опционально)
  final IconData? icon;

  const ResultRowItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
  });
}

/// Тёмная карточка с итоговыми результатами (как в эталоне "Шпатлёвка")
///
/// Отображается внизу экрана, показывает детализированные результаты расчёта:
/// список материалов, стоимость, дополнительные параметры.
///
/// Пример использования:
/// ```dart
/// ResultCard(
///   title: 'Список покупок',
///   accentColor: CalculatorColors.interior,
///   results: [
///     ResultRowItem(
///       label: 'Стартовая шпатлёвка',
///       value: '2 мешка',
///       subtitle: 'Мешок 25кг',
///     ),
///     ResultRowItem(
///       label: 'Финишная шпатлёвка',
///       value: '3 шт',
///       subtitle: 'Ведро 15л',
///     ),
///   ],
///   totalRow: ResultRowItem(
///     label: 'Ориентировочная стоимость',
///     value: '5 000 ₽',
///   ),
/// )
/// ```
class ResultCard extends StatelessWidget {
  /// Заголовок карточки
  final String title;

  /// Иконка заголовка (опционально)
  final IconData? titleIcon;

  /// Список результатов
  final List<ResultRowItem> results;

  /// Итоговая строка (опционально, показывается после divider)
  final ResultRowItem? totalRow;

  /// Акцентный цвет (для иконок и итоговой строки)
  final Color accentColor;

  /// Фоновый цвет карточки
  final Color? backgroundColor;

  /// Дополнительный виджет снизу (например, кнопка)
  final Widget? footer;

  const ResultCard({
    super.key,
    required this.title,
    this.titleIcon,
    required this.results,
    this.totalRow,
    required this.accentColor,
    this.backgroundColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? CalculatorColors.resultCardBackground;

    return Container(
      padding: CalculatorDesignSystem.cardPaddingLarge,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: CalculatorDesignSystem.cardBorderRadius,
        boxShadow: [CalculatorColors.shadowLarge],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          _buildHeader(),

          // Разделитель
          CalculatorDesignSystem.divider(
            color: const Color.fromRGBO(255, 255, 255, 0.1),
          ),

          // Список результатов
          ...results.map((item) => _buildResultRow(item, false)),

          // Итоговая строка (если есть)
          if (totalRow != null) ...[
            CalculatorDesignSystem.divider(
              color: const Color.fromRGBO(255, 255, 255, 0.1),
            ),
            _buildResultRow(totalRow!, true),
          ],

          // Footer (если есть)
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (titleIcon != null) ...[
          Icon(
            titleIcon,
            color: accentColor,
            size: CalculatorDesignSystem.iconSizeMedium,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.resultCardText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(ResultRowItem item, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконка (опционально)
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 20,
              color: isTotal ? accentColor : Colors.white70,
            ),
            const SizedBox(width: 8),
          ],

          // Текст слева
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: isTotal
                        ? CalculatorColors.resultCardText
                        : Colors.white70,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.resultCardTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Значение справа
          Flexible(
            child: Text(
              item.value,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: isTotal ? accentColor : CalculatorColors.resultCardText,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Светлая версия ResultCard (белая карточка)
class ResultCardLight extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final List<ResultRowItem> results;
  final ResultRowItem? totalRow;
  final Color accentColor;
  final Widget? footer;

  const ResultCardLight({
    super.key,
    required this.title,
    this.titleIcon,
    required this.results,
    this.totalRow,
    required this.accentColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: CalculatorDesignSystem.cardPaddingLarge,
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  color: accentColor,
                  size: CalculatorDesignSystem.iconSizeMedium,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          CalculatorDesignSystem.divider(),

          // Список результатов
          ...results.map((item) => _buildResultRow(item, false)),

          // Итоговая строка
          if (totalRow != null) ...[
            CalculatorDesignSystem.divider(),
            _buildResultRow(totalRow!, true),
          ],

          // Footer
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(ResultRowItem item, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 20,
              color: isTotal ? accentColor : CalculatorColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: Text(
              item.value,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: isTotal ? accentColor : CalculatorColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
