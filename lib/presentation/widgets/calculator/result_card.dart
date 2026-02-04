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

/// Элемент для MaterialsCardModern.
///
/// Используется для отображения одной строки материала/параметра.
///
/// Пример:
/// ```dart
/// MaterialItem(
///   name: 'Плитка',
///   value: '120 шт',
///   subtitle: '10.5 м²',
///   icon: Icons.grid_on,
/// )
/// ```
class MaterialItem {
  /// Название материала/параметра
  final String name;

  /// Значение (количество, размер и т.д.)
  final String value;

  /// Дополнительная информация (опционально)
  final String? subtitle;

  /// Иконка материала
  final IconData icon;

  const MaterialItem({
    required this.name,
    required this.value,
    this.subtitle,
    required this.icon,
  });
}

/// Современная карточка материалов с улучшенной читаемостью.
///
/// **ВАЖНО: Используйте этот виджет для всех новых кастомных калькуляторов!**
///
/// Каждый элемент имеет:
/// - Иконку в цветном квадрате (36×36px)
/// - Название и опциональный подзаголовок
/// - Значение в цветном бейдже
/// - Разделители между элементами
///
/// ## Пример использования в калькуляторе:
///
/// ```dart
/// Widget _buildMaterialsCard() {
///   const accentColor = CalculatorColors.interior;
///
///   final items = <MaterialItem>[
///     MaterialItem(
///       name: 'Плитка',
///       value: '${_result.tilesNeeded} шт',
///       subtitle: '${_result.tilesArea.toStringAsFixed(1)} м²',
///       icon: Icons.grid_on,
///     ),
///     MaterialItem(
///       name: 'Клей',
///       value: '${_result.glueBags} меш.',
///       subtitle: '25 кг/мешок',
///       icon: Icons.shopping_bag,
///     ),
///     MaterialItem(
///       name: 'Затирка',
///       value: '${_result.groutWeight.toStringAsFixed(1)} кг',
///       icon: Icons.gradient,
///     ),
///   ];
///
///   return MaterialsCardModern(
///     title: 'Материалы',
///     titleIcon: Icons.construction,
///     items: items,
///     accentColor: accentColor,
///   );
/// }
/// ```
///
/// ## Рекомендации по иконкам:
/// - Материалы: Icons.construction, Icons.category
/// - Плитка/панели: Icons.grid_on, Icons.view_module
/// - Жидкости (краска, клей): Icons.water_drop, Icons.format_paint
/// - Упаковки: Icons.shopping_bag, Icons.inventory_2
/// - Кабели/трубы: Icons.cable, Icons.timeline
/// - Инструменты: Icons.build, Icons.handyman
/// - Электрика: Icons.electrical_services, Icons.bolt
/// - Информация: Icons.info_outline, Icons.summarize
class MaterialsCardModern extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<MaterialItem> items;
  final Color accentColor;
  final Widget? footer;

  const MaterialsCardModern({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.items,
    required this.accentColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(titleIcon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Список материалов
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            return _buildMaterialRow(item, isLast);
          }),
          // Footer (опционально)
          if (footer != null) footer!,
        ],
      ),
    );
  }

  Widget _buildMaterialRow(MaterialItem item, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка в квадрате
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              // Название, подзаголовок и значение в колонке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: CalculatorDesignSystem.bodySmall.copyWith(
                          color: CalculatorColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Значение в бейдже - теперь под названием
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.value,
                        style: CalculatorDesignSystem.titleSmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: CalculatorColors.textSecondary.withValues(alpha: 0.15),
          ),
      ],
    );
  }
}
