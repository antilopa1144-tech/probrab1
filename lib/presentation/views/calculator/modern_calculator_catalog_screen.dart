import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../providers/settings_provider.dart';
import '../../utils/calculator_navigation_helper.dart';

/// Современный каталог калькуляторов в iOS-стиле (из HTML Dashboard)
class ModernCalculatorCatalogScreen extends ConsumerStatefulWidget {
  const ModernCalculatorCatalogScreen({super.key});

  @override
  ConsumerState<ModernCalculatorCatalogScreen> createState() =>
      _ModernCalculatorCatalogScreenState();
}

class _ModernCalculatorCatalogScreenState
    extends ConsumerState<ModernCalculatorCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _activeCategory = 'all';

  // Категории из HTML
  final List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'Все'},
    {'id': 'walls', 'label': 'Стены'},
    {'id': 'floor', 'label': 'Пол'},
    {'id': 'finish', 'label': 'Отделка'},
    {'id': 'wood', 'label': 'Дерево'},
  ];

  // Данные инструментов с цветами и иконками (из HTML)
  final Map<String, Map<String, dynamic>> toolsData = {
    'mixes_plaster': {
      'icon': Icons.bakery_dining_rounded,
      'color': const Color(0xFF3B82F6),
      'bg': const Color(0xFFDBEAFE),
      'bgDark': const Color(0xFF1E3A8A),
      'cat': ['walls'],
    },
    'dsp': {
      'icon': Icons.handyman_rounded,
      'color': const Color(0xFF64748B),
      'bg': const Color(0xFFF1F5F9),
      'bgDark': const Color(0xFF334155),
      'cat': ['floor', 'walls'],
    },
    'mixes_primer': {
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF0EA5E9),
      'bg': const Color(0xFFE0F2FE),
      'bgDark': const Color(0xFF075985),
      'cat': ['walls', 'floor', 'finish'],
    },
    'mixes_putty': {
      'icon': Icons.layers_rounded,
      'color': const Color(0xFF14B8A6),
      'bg': const Color(0xFFCCFBF1),
      'bgDark': const Color(0xFF115E59),
      'cat': ['walls', 'finish'],
    },
    'paint_universal': {
      'icon': Icons.format_paint_rounded,
      'color': const Color(0xFFF97316),
      'bg': const Color(0xFFFFEDD5),
      'bgDark': const Color(0xFF9A3412),
      'cat': ['walls', 'finish'],
    },
    'wood': {
      'icon': Icons.forest_rounded,
      'color': const Color(0xFFD97706),
      'bg': const Color(0xFFFEF3C7),
      'bgDark': const Color(0xFF92400E),
      'cat': ['wood', 'finish'],
    },
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final next = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = next);
    });
  }

  List<String> _getCategoriesForCalculator(CalculatorDefinitionV2 calc) {
    // Сначала проверяем toolsData
    final toolData = toolsData[calc.id];
    if (toolData != null) {
      return toolData['cat'] as List<String>;
    }

    // Автоматическое определение категорий по subCategory
    final sub = calc.subCategory;
    final categories = <String>[];

    // Стены
    if (sub.contains('wall') || sub.contains('paint') || sub.contains('plaster') ||
        sub.contains('putty') || sub.contains('gkl') || sub == 'interior') {
      categories.add('walls');
    }

    // Пол
    if (sub.contains('floor') || sub.contains('screed') || sub.contains('laminate') ||
        sub.contains('tile') || sub.contains('linoleum') || sub.contains('parquet')) {
      categories.add('floor');
    }

    // Отделка
    if (sub.contains('paint') || sub.contains('tile') || sub.contains('finish') ||
        sub.contains('wallpaper') || sub.contains('ceiling')) {
      categories.add('finish');
    }

    // Дерево
    if (sub.contains('wood') || sub.contains('parquet')) {
      categories.add('wood');
    }

    // Если категорий нет - добавляем хотя бы в 'all'
    if (categories.isEmpty) {
      categories.add('all');
    }

    return categories;
  }

  List<CalculatorDefinitionV2> _filtered(AppLocalizations loc) {
    var calculators = CalculatorRegistry.catalogCalculators;

    // Фильтр по категории
    if (_activeCategory != 'all') {
      calculators = calculators.where((calc) {
        final cats = _getCategoriesForCalculator(calc);
        return cats.contains(_activeCategory);
      }).toList();
    }

    // Поиск
    if (_query.isEmpty) return calculators;

    final q = _query.toLowerCase();
    return calculators.where((calc) {
      final title = loc.translate(calc.titleKey).toLowerCase();
      final sub = loc.translate('subcategory.${calc.subCategory}').toLowerCase();
      return title.contains(q) ||
          sub.contains(q) ||
          calc.id.toLowerCase().contains(q) ||
          calc.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final calculators = _filtered(loc);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'МОИ ПРОЕКТЫ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Инструменты',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      // Кнопка темной темы (как в HTML)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E2E2E)
                                : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            ref.read(settingsProvider.notifier).updateDarkMode(!isDark);
                          },
                          icon: Icon(
                            isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                            color: isDark ? Colors.amber : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Поиск
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: isDark ? 20 : 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: Colors.grey[400], size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Поиск...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: Icon(Icons.close_rounded,
                                color: Colors.grey[400], size: 20),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Категории-чипы
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isActive = _activeCategory == cat['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _activeCategory = cat['id']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark
                                      ? const Color(0xFF1C1C1C)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    : (isDark
                                        ? const Color(0xFF2E2E2E)
                                        : const Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? (isDark
                                        ? const Color(0xFF0F172A)
                                        : Colors.white)
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Калькуляторы - сетка 2 колонки
            Expanded(
              child: calculators.isEmpty
                  ? const Center(child: Text('Ничего не найдено'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: calculators.length,
                      itemBuilder: (context, index) {
                        final calc = calculators[index];
                        final toolData = toolsData[calc.id];

                        return _CalculatorCard(
                          calc: calc,
                          title: loc.translate(calc.titleKey),
                          subtitle:
                              loc.translate('subcategory.${calc.subCategory}'),
                          icon: toolData?['icon'] ?? Icons.calculate_rounded,
                          iconColor: toolData?['color'] ?? Colors.blue,
                          iconBg: isDark
                              ? (toolData?['bgDark'] ?? Colors.blue.shade900)
                              : (toolData?['bg'] ?? Colors.blue.shade50),
                          isDark: isDark,
                          onTap: () {
                            CalculatorNavigationHelper.navigateToCalculator(
                              context,
                              calc,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final CalculatorDefinitionV2 calc;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isDark;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.calc,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: isDark ? 20 : 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const Spacer(),

            // Текст
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
