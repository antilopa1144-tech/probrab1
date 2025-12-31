import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/staggered_animation.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../providers/settings_provider.dart';
import '../../utils/calculator_navigation_helper.dart';

/// Премиальный каталог калькуляторов с кастомным интерфейсом.
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
    {'id': 'all', 'labelKey': 'category.all'},
    {'id': 'walls', 'labelKey': 'category.walls'},
    {'id': 'floor', 'labelKey': 'category.floor'},
    {'id': 'finish', 'labelKey': 'category.finish'},
    {'id': 'wood', 'labelKey': 'category.wood'},
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

    // Автоматическое определение категорий по subCategoryKey
    final sub = calc.subCategoryKey.replaceFirst('subcategory.', '');
    final categories = <String>[];

    // Стены
    if (sub.contains('wall') ||
        sub.contains('paint') ||
        sub.contains('plaster') ||
        sub.contains('putty') ||
        sub.contains('gkl') ||
        sub == 'interior') {
      categories.add('walls');
    }

    // Пол
    if (sub.contains('floor') ||
        sub.contains('screed') ||
        sub.contains('laminate') ||
        sub.contains('tile') ||
        sub.contains('linoleum') ||
        sub.contains('parquet')) {
      categories.add('floor');
    }

    // Отделка
    if (sub.contains('paint') ||
        sub.contains('tile') ||
        sub.contains('finish') ||
        sub.contains('wallpaper') ||
        sub.contains('ceiling')) {
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
      final sub = loc.translate(calc.subCategoryKey).toLowerCase();
      return title.contains(q) ||
          sub.contains(q) ||
          calc.id.toLowerCase().contains(q) ||
          calc.tags.any((t) {
            final tagValue = t.startsWith('tag.') ? loc.translate(t) : t;
            return tagValue.toLowerCase().contains(q);
          });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final calculators = _filtered(loc);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _PremiumPalette(isDark);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 3 : 2;
    final cardAspectRatio = width >= 900 ? 0.96 : 0.86;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: _buildHeader(loc, palette, isDark),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildSearchBar(loc, palette),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: _buildCategoryChips(loc, palette),
                    ),
                  ),
                  if (calculators.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(loc, palette),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: cardAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final calc = calculators[index];
                            final toolData = toolsData[calc.id];
                            final fallbackAccent = calc.accentColor != null
                                ? Color(calc.accentColor!)
                                : palette.accent;
                            final iconColor =
                                toolData?['color'] ?? fallbackAccent;
                            final iconBg = isDark
                                ? (toolData?['bgDark'] ??
                                    Color.lerp(
                                      iconColor,
                                      palette.surface,
                                      0.9,
                                    )!)
                                : (toolData?['bg'] ??
                                    Color.lerp(
                                      iconColor,
                                      palette.surfaceMuted,
                                      0.95,
                                    )!);

                            return StaggeredAnimation(
                              index: index,
                              child: _CalculatorCard(
                                title: loc.translate(calc.titleKey),
                                subtitle: loc.translate(calc.subCategoryKey),
                                icon: toolData?['icon'] ??
                                    Icons.calculate_rounded,
                                iconColor: iconColor,
                                iconBg: iconBg,
                                palette: palette,
                                onTap: () {
                                  CalculatorNavigationHelper
                                      .navigateToCalculator(
                                    context,
                                    calc,
                                  );
                                },
                              ),
                            );
                          },
                          childCount: calculators.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations loc,
    _PremiumPalette palette,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('app.name').toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.translate('catalog.tools'),
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.translate('catalog.all_calculators'),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildThemeToggle(palette, isDark),
      ],
    );
  }

  Widget _buildThemeToggle(_PremiumPalette palette, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
        boxShadow: palette.controlShadow,
      ),
      child: IconButton(
        onPressed: () {
          ref.read(settingsProvider.notifier).updateDarkMode(!isDark);
        },
        icon: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
          color: isDark ? palette.accent : palette.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc, _PremiumPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: palette.controlShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: palette.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              cursorColor: palette.accent,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: loc.translate('search.placeholder'),
                hintStyle: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: palette.textMuted,
                ),
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
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(AppLocalizations loc, _PremiumPalette palette) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = _activeCategory == cat['id'];
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? palette.accent
                        .withValues(alpha: palette.isDark ? 0.2 : 0.16)
                    : palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? palette.accent
                          .withValues(alpha: palette.isDark ? 0.7 : 0.5)
                      : palette.border,
                ),
              ),
              child: Center(
                child: Text(
                  loc.translate(cat['labelKey']!),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? palette.accent : palette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, _PremiumPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: palette.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('search.no_results'),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              loc.translate('search.try_another_query'),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: palette.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final _PremiumPalette palette;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSurface = Color.lerp(
      iconBg,
      palette.surface,
      palette.isDark ? 0.75 : 0.65,
    )!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
            boxShadow: palette.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconColor.withValues(
                        alpha: palette.isDark ? 0.3 : 0.2,
                      ),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor.withValues(alpha: 0.9),
                    size: 26,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumPalette {
  final bool isDark;

  const _PremiumPalette(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF11100F) : const Color(0xFFF6F2ED);
  Color get surface =>
      isDark ? const Color(0xFF1A1917) : const Color(0xFFFCFAF7);
  Color get surfaceMuted =>
      isDark ? const Color(0xFF23211E) : const Color(0xFFF0E9E1);
  Color get border =>
      isDark ? const Color(0xFF2C2925) : const Color(0xFFE2D9CF);
  Color get textPrimary =>
      isDark ? const Color(0xFFF1EAE1) : const Color(0xFF1F1B16);
  Color get textSecondary =>
      isDark ? const Color(0xFFB4ACA2) : const Color(0xFF6E645A);
  Color get textMuted =>
      isDark ? const Color(0xFF8E867D) : const Color(0xFF8C8176);
  Color get accent => const Color(0xFFE0823D);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: isDark ? 16 : 12,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get controlShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
          blurRadius: isDark ? 10 : 8,
          offset: const Offset(0, 4),
        ),
      ];
}
