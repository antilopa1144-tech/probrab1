import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Модель элемента результата для отображения в header
class ResultItem {
  /// Ключ локализации или текст метки (отображается вверху мелким шрифтом)
  final String label;

  /// Значение результата (отображается крупным шрифтом)
  final String value;

  /// Иконка (опционально)
  final IconData? icon;

  const ResultItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

/// Заголовок с результатами расчёта (как в эталонном калькуляторе "Шпатлёвка")
///
/// Отображает 2-4 ключевых результата в верхней части экрана в цветной панели.
/// Это позволяет пользователю сразу видеть результаты без прокрутки.
///
/// Пример использования:
/// ```dart
/// CalculatorResultHeader(
///   accentColor: CalculatorColors.interior,
///   results: [
///     ResultItem(label: 'ПЛОЩАДЬ', value: '35.9 м²'),
///     ResultItem(label: 'СТАРТ', value: '2 мешков'),
///     ResultItem(label: 'ФИНИШ', value: '3 шт'),
///   ],
/// )
/// ```
class CalculatorResultHeader extends StatelessWidget {
  /// Акцентный цвет (фон header)
  final Color accentColor;

  /// Список результатов для отображения (2-4 элемента)
  final List<ResultItem> results;

  /// Использовать ли белую карточку внутри цветного фона
  /// По умолчанию true (эталонный стиль)
  final bool useWhiteCard;

  /// Дополнительный padding снизу
  final double bottomPadding;

  const CalculatorResultHeader({
    super.key,
    required this.accentColor,
    required this.results,
    this.useWhiteCard = true,
    this.bottomPadding = 24.0,
  }) : assert(results.length >= 2 && results.length <= 4,
          'Results должен содержать от 2 до 4 элементов');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        CalculatorDesignSystem.spacingM,
        0,
        CalculatorDesignSystem.spacingM,
        bottomPadding,
      ),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: CalculatorDesignSystem.headerBorderRadius,
      ),
      child: useWhiteCard ? _buildWhiteCard(isDark) : _buildDirectContent(),
    );
  }

  /// Белая карточка с тенью (эталонный стиль)
  Widget _buildWhiteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CalculatorColors.getCardBackground(isDark),
        borderRadius: CalculatorDesignSystem.cardBorderRadius,
        boxShadow: [CalculatorColors.shadowLarge],
      ),
      child: _buildResultsRow(isDark),
    );
  }

  /// Прямое отображение результатов без белой карточки
  Widget _buildDirectContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildResultsRow(false),
    );
  }

  /// Строка с результатами
  Widget _buildResultsRow([bool isDark = false]) {
    final List<Widget> children = [];

    for (int i = 0; i < results.length; i++) {
      children.add(
        Expanded(
          child: _buildHeaderItem(
            results[i],
            useWhiteCard ? accentColor : Colors.white,
            isDark,
          ),
        ),
      );

      // Добавляем разделитель между элементами (кроме последнего)
      if (i < results.length - 1) {
        children.add(
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: useWhiteCard
              ? CalculatorColors.getDivider(isDark)
              : const Color.fromRGBO(255, 255, 255, 0.3),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
    );
  }

  /// Отдельный элемент результата (колонка с меткой и значением)
  Widget _buildHeaderItem(ResultItem item, Color valueColor, bool isDark) {
    final labelColor = useWhiteCard
        ? CalculatorColors.getTextSecondary(isDark)
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: CalculatorDesignSystem.iconSizeSmall,
            color: labelColor,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          item.label.toUpperCase(),
          style: CalculatorDesignSystem.headerLabel.copyWith(
            color: labelColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.value,
            style: CalculatorDesignSystem.headerValue.copyWith(
              color: valueColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Вариант header без белой карточки (цветной фон)
class CalculatorResultHeaderColored extends StatelessWidget {
  final Color accentColor;
  final List<ResultItem> results;
  final double bottomPadding;

  const CalculatorResultHeaderColored({
    super.key,
    required this.accentColor,
    required this.results,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CalculatorResultHeader(
      accentColor: accentColor,
      results: results,
      useWhiteCard: false,
      bottomPadding: bottomPadding,
    );
  }
}
