import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

/// Категории материалов для проектов
enum MaterialCategory {
  cement(Icons.construction_rounded, Colors.grey),
  brick(Icons.view_comfy_rounded, Colors.red),
  tile(Icons.grid_on_rounded, Colors.blue),
  paint(Icons.format_paint_rounded, Colors.purple),
  wood(Icons.forest_rounded, Colors.brown),
  metal(Icons.hardware_rounded, Colors.blueGrey),
  electrical(Icons.electric_bolt_rounded, Colors.amber),
  plumbing(Icons.plumbing_rounded, Colors.cyan),
  insulation(Icons.layers_rounded, Colors.green),
  other(Icons.category_rounded, Colors.orange);

  final IconData icon;
  final Color color;

  const MaterialCategory(this.icon, this.color);

  /// Получить локализованную метку
  String getLabel(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return loc.translate('common.category_$name');
  }
}

/// Chip для выбора категории материала
class MaterialCategoryChip extends StatelessWidget {
  /// Категория материала
  final MaterialCategory category;

  /// Выбрана ли категория
  final bool isSelected;

  /// Callback при выборе категории
  final VoidCallback? onSelected;

  /// Показывать ли иконку
  final bool showIcon;

  /// Компактный режим
  final bool compact;

  const MaterialCategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onSelected,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = category.color;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              category.icon,
              size: compact ? 16 : 18,
              color: isSelected ? Colors.white : categoryColor,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            category.getLabel(context),
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: compact ? 12 : 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected != null ? (_) => onSelected!() : null,
      backgroundColor: categoryColor.withValues(alpha: 0.1),
      selectedColor: categoryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        side: BorderSide(
          color: isSelected ? categoryColor : categoryColor.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}

/// Список chips для выбора категорий материалов
class MaterialCategoryChipList extends StatelessWidget {
  /// Выбранные категории
  final Set<MaterialCategory> selectedCategories;

  /// Callback при изменении выбранных категорий
  final ValueChanged<Set<MaterialCategory>>? onChanged;

  /// Компактный режим
  final bool compact;

  /// Показывать ли иконки
  final bool showIcons;

  /// Режим множественного выбора
  final bool multiSelect;

  const MaterialCategoryChipList({
    super.key,
    required this.selectedCategories,
    this.onChanged,
    this.compact = false,
    this.showIcons = true,
    this.multiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: MaterialCategory.values.map((category) {
        final isSelected = selectedCategories.contains(category);

        return MaterialCategoryChip(
          category: category,
          isSelected: isSelected,
          showIcon: showIcons,
          compact: compact,
          onSelected: onChanged != null
              ? () {
                  final newSelection = Set<MaterialCategory>.from(selectedCategories);
                  if (multiSelect) {
                    if (isSelected) {
                      newSelection.remove(category);
                    } else {
                      newSelection.add(category);
                    }
                  } else {
                    // Одиночный выбор
                    if (isSelected) {
                      newSelection.clear();
                    } else {
                      newSelection.clear();
                      newSelection.add(category);
                    }
                  }
                  onChanged!(newSelection);
                }
              : null,
        );
      }).toList(),
    );
  }
}

/// Dialog для выбора категорий материалов
class MaterialCategorySelectionDialog extends StatefulWidget {
  /// Изначально выбранные категории
  final Set<MaterialCategory> initialSelection;

  /// Режим множественного выбора
  final bool multiSelect;

  const MaterialCategorySelectionDialog({
    super.key,
    this.initialSelection = const {},
    this.multiSelect = true,
  });

  @override
  State<MaterialCategorySelectionDialog> createState() =>
      _MaterialCategorySelectionDialogState();
}

class _MaterialCategorySelectionDialogState
    extends State<MaterialCategorySelectionDialog> {
  late Set<MaterialCategory> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        loc.translate('common.select_categories'),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.multiSelect && _selectedCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      loc.translate('common.selected_count').replaceAll('{count}', '${_selectedCategories.length}'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories.clear();
                        });
                      },
                      child: Text(loc.translate('common.clear')),
                    ),
                  ],
                ),
              ),
            MaterialCategoryChipList(
              selectedCategories: _selectedCategories,
              multiSelect: widget.multiSelect,
              onChanged: (newSelection) {
                setState(() {
                  _selectedCategories = newSelection;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.translate('button.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedCategories),
          child: Text(loc.translate('common.apply')),
        ),
      ],
    );
  }
}
