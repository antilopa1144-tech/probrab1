import 'package:flutter/material.dart';

/// Конфигурация каталога калькуляторов
///
/// Содержит настройки внешнего вида, категории, популярные калькуляторы
/// и другие данные для отображения каталога.
class CatalogConfig {
  /// Данные инструментов с цветами, иконками и категориями
  static final Map<String, ToolData> toolsData = {
    'mixes_plaster': const ToolData(
      icon: Icons.bakery_dining_rounded,
      color: Color(0xFF3B82F6),
      bg: Color(0xFFDBEAFE),
      bgDark: Color(0xFF1E3A8A),
      categories: ['walls'],
      descriptionKey: 'tool.mixes_plaster.desc',
    ),
    'dsp': const ToolData(
      icon: Icons.handyman_rounded,
      color: Color(0xFF64748B),
      bg: Color(0xFFF1F5F9),
      bgDark: Color(0xFF334155),
      categories: ['floor', 'walls'],
      descriptionKey: 'tool.dsp.desc',
    ),
    'mixes_primer': const ToolData(
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0EA5E9),
      bg: Color(0xFFE0F2FE),
      bgDark: Color(0xFF075985),
      categories: ['walls', 'floor', 'finish'],
      descriptionKey: 'tool.mixes_primer.desc',
    ),
    'mixes_putty': const ToolData(
      icon: Icons.layers_rounded,
      color: Color(0xFF14B8A6),
      bg: Color(0xFFCCFBF1),
      bgDark: Color(0xFF115E59),
      categories: ['walls', 'finish'],
      descriptionKey: 'tool.mixes_putty.desc',
    ),
    'paint_universal': const ToolData(
      icon: Icons.format_paint_rounded,
      color: Color(0xFFF97316),
      bg: Color(0xFFFFEDD5),
      bgDark: Color(0xFF9A3412),
      categories: ['walls', 'finish'],
      descriptionKey: 'tool.paint_universal.desc',
    ),
    'wood': const ToolData(
      icon: Icons.forest_rounded,
      color: Color(0xFFD97706),
      bg: Color(0xFFFEF3C7),
      bgDark: Color(0xFF92400E),
      categories: ['wood', 'finish'],
      descriptionKey: 'tool.wood.desc',
    ),
    'tile': const ToolData(
      icon: Icons.grid_on_rounded,
      color: Color(0xFF8B5CF6),
      bg: Color(0xFFEDE9FE),
      bgDark: Color(0xFF5B21B6),
      categories: ['floor', 'finish', 'walls'],
      descriptionKey: 'tool.tile.desc',
    ),
    'laminate': const ToolData(
      icon: Icons.table_rows_rounded,
      color: Color(0xFFA855F7),
      bg: Color(0xFFF3E8FF),
      bgDark: Color(0xFF6B21A8),
      categories: ['floor'],
      descriptionKey: 'tool.laminate.desc',
    ),
    'concrete_universal': const ToolData(
      icon: Icons.foundation_rounded,
      color: Color(0xFF6B7280),
      bg: Color(0xFFF3F4F6),
      bgDark: Color(0xFF374151),
      categories: ['foundation', 'floor'],
      descriptionKey: 'tool.concrete.desc',
    ),
    'strip_foundation': const ToolData(
      icon: Icons.straighten_rounded,
      color: Color(0xFF78716C),
      bg: Color(0xFFF5F5F4),
      bgDark: Color(0xFF44403C),
      categories: ['foundation'],
      descriptionKey: 'tool.strip_foundation.desc',
    ),
    'slab_foundation': const ToolData(
      icon: Icons.crop_square_rounded,
      color: Color(0xFF57534E),
      bg: Color(0xFFE7E5E4),
      bgDark: Color(0xFF292524),
      categories: ['foundation'],
      descriptionKey: 'tool.slab_foundation.desc',
    ),
    'warm_floor': const ToolData(
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFFEF4444),
      bg: Color(0xFFFEE2E2),
      bgDark: Color(0xFF991B1B),
      categories: ['electric', 'floor'],
      descriptionKey: 'tool.warm_floor.desc',
    ),
    'metal_roofing': const ToolData(
      icon: Icons.roofing_rounded,
      color: Color(0xFF475569),
      bg: Color(0xFFF1F5F9),
      bgDark: Color(0xFF1E293B),
      categories: ['roofing'],
      descriptionKey: 'tool.metal_roofing.desc',
    ),
    'soft_roofing': const ToolData(
      icon: Icons.waves_rounded,
      color: Color(0xFF0891B2),
      bg: Color(0xFFCFFAFE),
      bgDark: Color(0xFF164E63),
      categories: ['roofing'],
      descriptionKey: 'tool.soft_roofing.desc',
    ),
  };

  /// Категории для фильтрации калькуляторов
  static final List<CategoryData> categories = [
    const CategoryData(id: 'all', labelKey: 'category.all'),
    const CategoryData(id: 'walls', labelKey: 'category.walls'),
    const CategoryData(id: 'floor', labelKey: 'category.floor'),
    const CategoryData(id: 'finish', labelKey: 'category.finish'),
    const CategoryData(id: 'wood', labelKey: 'category.wood'),
    const CategoryData(id: 'electric', labelKey: 'category.electric'),
    const CategoryData(id: 'foundation', labelKey: 'category.foundation'),
    const CategoryData(id: 'roofing', labelKey: 'category.roofing'),
  ];

  /// ID популярных калькуляторов (в порядке приоритета)
  ///
  /// Эти калькуляторы будут показаны в секции "Популярное" крупными карточками
  static const List<String> popularCalculatorIds = [
    'paint_universal',
    'tile',
    'laminate',
    'concrete_universal',
    'warm_floor',
    'mixes_putty',
  ];
}

/// Данные об инструменте/калькуляторе
class ToolData {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color bgDark;
  final List<String> categories;
  final String descriptionKey;

  const ToolData({
    required this.icon,
    required this.color,
    required this.bg,
    required this.bgDark,
    required this.categories,
    required this.descriptionKey,
  });
}

/// Данные о категории
class CategoryData {
  final String id;
  final String labelKey;

  const CategoryData({
    required this.id,
    required this.labelKey,
  });
}
