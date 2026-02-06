import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/catalog_palette.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/staggered_animation.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../config/catalog_config.dart';
import '../../providers/recent_calculators_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/calculator_navigation_helper.dart';
import '../tools/unit_converter_bottom_sheet.dart';
import '../tools/room_area_bottom_sheet.dart';
import '../tools/simple_calculator_bottom_sheet.dart';
import '../checklist/create_checklist_bottom_sheet.dart';
import '../checklist/checklist_details_screen.dart';

/// Улучшенный каталог калькуляторов с недавними и популярными секциями.
class ModernCalculatorCatalogScreenV2 extends ConsumerStatefulWidget {
  const ModernCalculatorCatalogScreenV2({super.key});

  @override
  ConsumerState<ModernCalculatorCatalogScreenV2> createState() =>
      _ModernCalculatorCatalogScreenV2State();
}

class _ModernCalculatorCatalogScreenV2State
    extends ConsumerState<ModernCalculatorCatalogScreenV2> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  String _activeCategory = 'all';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    // Проверяем конфиг
    final toolData = CatalogConfig.toolsData[calc.id];
    if (toolData != null) {
      return toolData.categories;
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

    // Электрика
    if (sub.contains('electric') || sub.contains('heating') || sub.contains('warm')) {
      categories.add('electric');
    }

    // Фундамент
    if (sub.contains('foundation') || sub.contains('concrete')) {
      categories.add('foundation');
    }

    // Кровля
    if (sub.contains('roof')) {
      categories.add('roofing');
    }

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
      final toolData = CatalogConfig.toolsData[calc.id];
      final desc = toolData != null
          ? loc.translate(toolData.descriptionKey).toLowerCase()
          : '';
      return title.contains(q) ||
          sub.contains(q) ||
          desc.contains(q) ||
          calc.id.toLowerCase().contains(q) ||
          calc.tags.any((t) {
            final tagValue = t.startsWith('tag.') ? loc.translate(t) : t;
            return tagValue.toLowerCase().contains(q);
          });
    }).toList();
  }

  void _navigateToCalculator(CalculatorDefinitionV2 calc) {
    // Снимаем фокус с поля поиска, чтобы при возврате не открывалась клавиатура
    _searchFocusNode.unfocus();

    // Добавляем в историю недавних
    ref.read(recentCalculatorsProvider.notifier).addRecent(calc.id);
    // Переходим на экран калькулятора
    CalculatorNavigationHelper.navigateToCalculator(context, calc);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final calculators = _filtered(loc);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = CatalogPalette(isDark);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 3 : 2;
    final cardAspectRatio = width >= 900 ? 0.96 : 0.86;

    final recentIds = ref.watch(recentCalculatorsProvider);
    final recentCalcs = recentIds
        .map((id) => CalculatorRegistry.getById(id))
        .where((calc) => calc != null)
        .cast<CalculatorDefinitionV2>()
        .take(5)
        .toList();

    final popularCalcs = CatalogConfig.popularCalculatorIds
        .map((id) => CalculatorRegistry.getById(id))
        .where((calc) => calc != null)
        .cast<CalculatorDefinitionV2>()
        .toList();

    final hasSearch = _query.isNotEmpty;
    final hasFilter = _activeCategory != 'all';
    final showRecent = !hasSearch && !hasFilter && recentCalcs.isNotEmpty;
    final showPopular = !hasSearch && !hasFilter && popularCalcs.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        title: Text(
          loc.translate('app.name').toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: palette.textMuted,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.build_outlined,
              color: palette.textMuted,
              size: 22,
            ),
            tooltip: loc.translate('catalog.tools_menu'),
            onSelected: (value) {
              switch (value) {
                case 'unit_converter':
                  UnitConverterBottomSheet.show(context);
                case 'room_area':
                  RoomAreaBottomSheet.show(context);
                case 'simple_calculator':
                  SimpleCalculatorBottomSheet.show(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'unit_converter',
                child: ListTile(
                  leading: const Icon(Icons.straighten_rounded),
                  title: Text(loc.translate('tools.unit_converter')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'room_area',
                child: ListTile(
                  leading: const Icon(Icons.square_foot_rounded),
                  title: Text(loc.translate('tools.room_area')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'simple_calculator',
                child: ListTile(
                  leading: const Icon(Icons.calculate_rounded),
                  title: Text(loc.translate('tools.simple_calculator')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              final checklist = await CreateChecklistBottomSheet.show(context);
              if (checklist != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChecklistDetailsScreen(checklistId: checklist.id),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.checklist_rounded,
              color: palette.textMuted,
              size: 22,
            ),
            tooltip: loc.translate('catalog.checklist_tooltip'),
          ),
          IconButton(
            onPressed: () {
              // TODO: Открыть настройки
              _showSettingsMenu(context, palette, isDark);
            },
            icon: Icon(
              Icons.settings_rounded,
              color: palette.textMuted,
              size: 22,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Заголовок
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  loc.translate('catalog.tools'),
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),

            // Поиск
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSearchBar(loc, palette),
              ),
            ),

            // Категории
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: _buildCategoryChips(loc, palette),
              ),
            ),

            // Счётчик результатов (если есть фильтр или поиск)
            if (hasSearch || hasFilter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Text(
                    loc.translate('search.found_count', {
                      'count': calculators.length.toString(),
                    }),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),

            // Недавние (если нет поиска и фильтра)
            if (showRecent) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        loc.translate('catalog.recent'),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(recentCalculatorsProvider.notifier)
                              .clearRecent();
                        },
                        child: Text(
                          loc.translate('action.clear'),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: recentCalcs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final calc = recentCalcs[index];
                      return _RecentCalculatorChip(
                        calc: calc,
                        palette: palette,
                        onTap: () => _navigateToCalculator(calc),
                        loc: loc,
                      );
                    },
                  ),
                ),
              ),
            ],

            // Популярное (если нет поиска и фильтра)
            if (showPopular) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    loc.translate('catalog.popular'),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final calc = popularCalcs[index];
                      final toolData = CatalogConfig.toolsData[calc.id];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PopularCalculatorCard(
                          calc: calc,
                          toolData: toolData,
                          palette: palette,
                          isDark: isDark,
                          onTap: () => _navigateToCalculator(calc),
                          loc: loc,
                        ),
                      );
                    },
                    childCount: popularCalcs.length,
                  ),
                ),
              ),
            ],

            // Заголовок секции с калькуляторами
            if (hasSearch || hasFilter || showPopular)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    hasSearch || hasFilter
                        ? loc.translate('catalog.results')
                        : loc.translate('catalog.all_calculators'),
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),

            // Пустое состояние
            if (calculators.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(loc, palette),
              )
            else
              // Сетка калькуляторов
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: cardAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final calc = calculators[index];
                      final toolData = CatalogConfig.toolsData[calc.id];
                      final fallbackAccent = calc.accentColor != null
                          ? Color(calc.accentColor!)
                          : palette.accent;
                      final iconColor = toolData?.color ?? fallbackAccent;
                      final iconBg = isDark
                          ? (toolData?.bgDark ??
                              Color.lerp(
                                iconColor,
                                palette.surface,
                                0.9,
                              )!)
                          : (toolData?.bg ??
                              Color.lerp(
                                iconColor,
                                palette.surfaceMuted,
                                0.95,
                              )!);

                      return StaggeredAnimation(
                        index: index,
                        child: _CalculatorCard(
                          title: loc.translate(calc.titleKey),
                          description: toolData != null
                              ? loc.translate(toolData.descriptionKey)
                              : loc.translate(calc.subCategoryKey),
                          icon: toolData?.icon ?? Icons.calculate_rounded,
                          iconColor: iconColor,
                          iconBg: iconBg,
                          palette: palette,
                          complexity: calc.complexity,
                          onTap: () => _navigateToCalculator(calc),
                          loc: loc,
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
    );
  }

  void _showSettingsMenu(
    BuildContext context,
    CatalogPalette palette,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  color: palette.accent,
                ),
                title: Text(
                  loc.translate('settings.theme'),
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                subtitle: Text(
                  isDark
                      ? loc.translate('settings.theme_dark')
                      : loc.translate('settings.theme_light'),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).updateDarkMode(!isDark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(AppLocalizations loc, CatalogPalette palette) {
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
              focusNode: _searchFocusNode,
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

  Widget _buildCategoryChips(AppLocalizations loc, CatalogPalette palette) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CatalogConfig.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = CatalogConfig.categories[index];
          final isActive = _activeCategory == cat.id;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat.id),
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
                  loc.translate(cat.labelKey),
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

  Widget _buildEmptyState(AppLocalizations loc, CatalogPalette palette) {
    final hasFilter = _activeCategory != 'all' || _query.isNotEmpty;

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
            if (hasFilter) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _activeCategory = 'all';
                    _searchController.clear();
                    _query = '';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  loc.translate('action.reset_filters'),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Карточка недавнего калькулятора (горизонтальный чип)
class _RecentCalculatorChip extends StatelessWidget {
  final CalculatorDefinitionV2 calc;
  final CatalogPalette palette;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _RecentCalculatorChip({
    required this.calc,
    required this.palette,
    required this.onTap,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final toolData = CatalogConfig.toolsData[calc.id];
    final iconColor =
        toolData?.color ?? Color(calc.accentColor ?? 0xFFE0823D);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
          boxShadow: palette.controlShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                toolData?.icon ?? Icons.calculate_rounded,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                loc.translate(calc.titleKey),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Крупная карточка популярного калькулятора
class _PopularCalculatorCard extends StatelessWidget {
  final CalculatorDefinitionV2 calc;
  final ToolData? toolData;
  final CatalogPalette palette;
  final bool isDark;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _PopularCalculatorCard({
    required this.calc,
    required this.toolData,
    required this.palette,
    required this.isDark,
    required this.onTap,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        toolData?.color ?? Color(calc.accentColor ?? 0xFFE0823D);
    final iconBg = isDark
        ? (toolData?.bgDark ??
            Color.lerp(iconColor, palette.surface, 0.85)!)
        : (toolData?.bg ??
            Color.lerp(iconColor, palette.surfaceMuted, 0.9)!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
            boxShadow: palette.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    toolData?.icon ?? Icons.calculate_rounded,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate(calc.titleKey),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toolData != null
                            ? loc.translate(toolData!.descriptionKey)
                            : loc.translate(calc.subCategoryKey),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка калькулятора в сетке
class _CalculatorCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final CatalogPalette palette;
  final int complexity;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _CalculatorCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.palette,
    required this.complexity,
    required this.onTap,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final iconSurface = Color.lerp(
      iconBg,
      palette.surface,
      palette.isDark ? 0.75 : 0.65,
    )!;

    // Индикатор сложности
    String complexityLabel;
    IconData complexityIcon;
    if (complexity <= 2) {
      complexityLabel = loc.translate('catalog.complexity.quick');
      complexityIcon = Icons.bolt_rounded;
    } else {
      complexityLabel = loc.translate('catalog.complexity.detailed');
      complexityIcon = Icons.tune_rounded;
    }

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 140;
                    final iconBox = isCompact ? 42.0 : 48.0;
                    final iconSize = isCompact ? 22.0 : 26.0;
                    final badgePadding = isCompact
                        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

                    return Row(
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
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
                            size: iconSize,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: badgePadding,
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      complexityIcon,
                                      size: 12,
                                      color: palette.textMuted,
                                    ),
                                    if (!isCompact) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        complexityLabel,
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: palette.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
                  description,
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
