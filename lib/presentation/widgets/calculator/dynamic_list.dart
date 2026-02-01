import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';

/// Динамический список элементов с возможностью добавления/удаления
///
/// Используется для проёмов (окна, двери), стен, комнат и других повторяющихся элементов
///
/// Пример использования:
/// ```dart
/// DynamicList<Opening>(
///   title: 'Проемы',
///   items: openings,
///   minItems: 1,
///   onAdd: () {
///     setState(() {
///       openings.add(Opening(width: 0.9, height: 2.1));
///     });
///   },
///   onRemove: (index) {
///     setState(() {
///       openings.removeAt(index);
///     });
///   },
///   itemBuilder: (context, opening, index) {
///     return Row(
///       children: [
///         Expanded(child: TextField(...)),
///         Expanded(child: TextField(...)),
///       ],
///     );
///   },
/// )
/// ```
class DynamicList<T> extends StatelessWidget {
  /// Заголовок списка (опционально)
  final String? title;

  /// Список элементов
  final List<T> items;

  /// Минимальное количество элементов (нельзя удалить меньше)
  final int minItems;

  /// Максимальное количество элементов (нельзя добавить больше)
  final int? maxItems;

  /// Callback для добавления элемента
  final VoidCallback onAdd;

  /// Callback для удаления элемента
  final void Function(int index) onRemove;

  /// Builder для отдельного элемента списка
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Акцентный цвет
  final Color? accentColor;

  /// Показывать номер элемента
  final bool showIndex;

  /// Текст кнопки добавления
  final String? addButtonText;

  /// Иконка кнопки добавления
  final IconData? addButtonIcon;

  /// Показывать разделители между элементами
  final bool showDividers;

  const DynamicList({
    super.key,
    this.title,
    required this.items,
    this.minItems = 1,
    this.maxItems,
    required this.onAdd,
    required this.onRemove,
    required this.itemBuilder,
    this.accentColor,
    this.showIndex = true,
    this.addButtonText,
    this.addButtonIcon,
    this.showDividers = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? CalculatorColors.interior;
    final canRemove = items.length > minItems;
    final canAdd = maxItems == null || items.length < maxItems!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок с кнопкой добавления
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CalculatorColors.getTextPrimary(isDark),
                  ),
                ),
                if (canAdd)
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: Icon(
                      addButtonIcon ?? Icons.add,
                      size: 18,
                    ),
                    label: Text(addButtonText ?? 'Добавить'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      backgroundColor: isDark
                          ? accent.withValues(alpha: 0.2)
                          : HSLColor.fromColor(accent).withLightness(0.95).toColor(),
                    ),
                  ),
              ],
            ),
          ),

        // Список элементов
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) {
            if (showDividers) {
              return CalculatorDesignSystem.divider(
                color: CalculatorColors.getDivider(isDark),
              );
            }
            return const SizedBox(height: 8);
          },
          itemBuilder: (context, index) {
            return _buildListItem(context, index, accent, canRemove, isDark);
          },
        ),

        // Кнопка добавления (если заголовка нет)
        if (title == null && canAdd) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onAdd,
              icon: Icon(addButtonIcon ?? Icons.add, size: 18),
              label: Text(addButtonText ?? 'Добавить'),
              style: TextButton.styleFrom(
                foregroundColor: accent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    Color accent,
    bool canRemove,
    bool isDark,
  ) {
    final itemBg = isDark ? CalculatorColors.inputBackgroundDark : Colors.grey[50];
    final itemBorder = isDark ? CalculatorColors.borderDefaultDark : Colors.grey[200]!;
    final indexBg = isDark
        ? accent.withValues(alpha: 0.2)
        : HSLColor.fromColor(accent).withLightness(0.95).toColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: CalculatorDesignSystem.cardBorderRadius,
        border: Border.all(color: itemBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Номер элемента
          if (showIndex)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: indexBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Содержимое элемента
          Expanded(
            child: itemBuilder(context, items[index], index),
          ),

          // Кнопка удаления
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.red,
              onPressed: () => onRemove(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }
}

/// Упрощённая версия DynamicList без карточек (простые строки)
class DynamicListSimple<T> extends StatelessWidget {
  final List<T> items;
  final int minItems;
  final int? maxItems;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Color? accentColor;
  final String? addButtonText;

  const DynamicListSimple({
    super.key,
    required this.items,
    this.minItems = 1,
    this.maxItems,
    required this.onAdd,
    required this.onRemove,
    required this.itemBuilder,
    this.accentColor,
    this.addButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? CalculatorColors.interior;
    final canRemove = items.length > minItems;
    final canAdd = maxItems == null || items.length < maxItems!;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: itemBuilder(context, items[index], index),
                ),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: Colors.red,
                    onPressed: () => onRemove(index),
                  ),
              ],
            );
          },
        ),
        if (canAdd) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addButtonText ?? 'Добавить'),
            style: TextButton.styleFrom(foregroundColor: accent),
          ),
        ],
      ],
    );
  }
}

/// Готовый компонент для списка проёмов (окна, двери)
class OpeningsList extends StatelessWidget {
  final List<OpeningData> openings;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, double width) onWidthChanged;
  final void Function(int index, double height) onHeightChanged;
  final void Function(int index, int count) onCountChanged;
  final Color? accentColor;

  const OpeningsList({
    super.key,
    required this.openings,
    required this.onAdd,
    required this.onRemove,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onCountChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicListSimple<OpeningData>(
      items: openings,
      minItems: 1,
      onAdd: onAdd,
      onRemove: onRemove,
      accentColor: accentColor,
      addButtonText: 'Добавить проём',
      itemBuilder: (context, opening, index) {
        return Row(
          children: [
            Expanded(
              child: _buildField(
                context,
                'Ширина',
                opening.width,
                (v) => onWidthChanged(index, v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildField(
                context,
                'Высота',
                opening.height,
                (v) => onHeightChanged(index, v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: _buildField(
                context,
                'Кол-во',
                opening.count.toDouble(),
                (v) => onCountChanged(index, v.toInt()),
                isInt: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildField(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged, {
    bool isInt = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? CalculatorColors.cardBackgroundDark : Colors.white;
    final textColor = CalculatorColors.getTextPrimary(isDark);
    final labelColor = CalculatorColors.getTextSecondary(isDark);

    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: labelColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: TextStyle(fontSize: 13, color: textColor),
      controller: TextEditingController(
        text: isInt ? value.toInt().toString() : value.toStringAsFixed(1),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

/// Модель данных для проёма
class OpeningData {
  double width;
  double height;
  int count;

  OpeningData({
    this.width = 0.9,
    this.height = 2.1,
    this.count = 1,
  });
}
