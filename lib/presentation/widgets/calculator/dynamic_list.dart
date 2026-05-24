import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);

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
                    label: Text(addButtonText ?? loc.translate('action.add')), 
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
              label: Text(addButtonText ?? loc.translate('action.add')), 
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
    final loc = AppLocalizations.of(context);

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
            label: Text(addButtonText ?? loc.translate('action.add')), 
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
      addButtonText: AppLocalizations.of(context).translate('common.add_opening'),
      itemBuilder: (context, opening, index) {
        return Row(
          children: [
            Expanded(
              child: _OpeningNumericField(
                label: AppLocalizations.of(context).translate('input.width'),
                value: opening.width,
                onChanged: (v) => onWidthChanged(index, v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OpeningNumericField(
                label: AppLocalizations.of(context).translate('input.height'),
                value: opening.height,
                onChanged: (v) => onHeightChanged(index, v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: _OpeningNumericField(
                label: AppLocalizations.of(context).translate('common.count_label'),
                value: opening.count.toDouble(),
                onChanged: (v) => onCountChanged(index, v.toInt()),
                isInt: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OpeningNumericField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isInt;

  const _OpeningNumericField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isInt = false,
  });

  @override
  State<_OpeningNumericField> createState() => _OpeningNumericFieldState();
}

class _OpeningNumericFieldState extends State<_OpeningNumericField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(_OpeningNumericField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) =>
      widget.isInt ? value.toInt().toString() : value.toStringAsFixed(1);

  void _commit() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null) {
      _controller.text = _format(widget.value);
      return;
    }
    widget.onChanged(parsed);
    _controller.text = _format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? CalculatorColors.cardBackgroundDark : Colors.white;
    final textColor = CalculatorColors.getTextPrimary(isDark);
    final labelColor = CalculatorColors.getTextSecondary(isDark);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
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
      onChanged: (text) {
        if (text.isEmpty || text.endsWith('.')) return;
        final parsed = double.tryParse(text.replaceAll(',', '.'));
        if (parsed != null) widget.onChanged(parsed);
      },
      onEditingComplete: _commit,
      onTapOutside: (_) => _commit(),
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


