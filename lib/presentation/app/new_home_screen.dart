import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/calculators/calculator_registry.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../core/enums/calculator_category.dart';
import '../../core/localization/app_localizations.dart';
import '../utils/calculator_navigation_helper.dart';
import '../providers/favorites_provider.dart';

/// Современный главный экран с дизайном из прототипа
class NewHomeScreen extends ConsumerStatefulWidget {
  const NewHomeScreen({super.key});

  @override
  ConsumerState<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends ConsumerState<NewHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CalculatorCategory? _activeCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CalculatorDefinitionV2> get _popularCalculators {
    return CalculatorRegistry.getPopular(limit: 6);
  }

  List<CalculatorDefinitionV2> get _recentCalculators {
    // TODO: Интеграция с историей расчетов
    return CalculatorRegistry.getPopular(limit: 3);
  }

  List<CalculatorDefinitionV2> get _filteredCalculators {
    var calcs = _activeCategory == null
        ? CalculatorRegistry.allCalculators
        : CalculatorRegistry.getByCategory(_activeCategory);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      calcs = calcs.where((calc) {
        final loc = AppLocalizations.of(context);
        final title = loc.translate(calc.titleKey).toLowerCase();
        return title.contains(query) ||
            calc.id.toLowerCase().contains(query) ||
            calc.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return calcs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // zinc-950
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, loc),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 16),

                  // Популярные (только если нет поиска)
                  if (_searchQuery.isEmpty) ...[
                    _buildPopularSection(theme, loc),
                    const SizedBox(height: 24),
                  ],

                  // Недавние (только если нет поиска)
                  if (_searchQuery.isEmpty && _recentCalculators.isNotEmpty) ...[
                    _buildRecentSection(theme, loc),
                    const SizedBox(height: 24),
                  ],

                  // Категории
                  _buildCategoriesSection(theme, loc),

                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF27272A).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24), // amber-400
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: Color(0xFF18181B), // zinc-900
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Прораб',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Favorites button
                Consumer(
                  builder: (context, ref, _) {
                    final favorites = ref.watch(favoritesProvider);
                    return IconButton(
                      onPressed: () {
                        // TODO: Показать избранные
                      },
                      icon: Icon(
                        favorites.isNotEmpty ? Icons.star : Icons.star_outline,
                        color: const Color(0xFF71717A), // zinc-500
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Что нужно посчитать?',
                hintStyle: const TextStyle(color: Color(0xFF71717A)), // zinc-500
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF71717A),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF71717A),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF18181B), // zinc-900
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF27272A)), // zinc-800
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.5), // amber-400/50
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSection(ThemeData theme, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: Color(0xFFFBBF24), // amber-400
            ),
            SizedBox(width: 8),
            Text(
              'Популярные',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8), // zinc-300
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal scroll list
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _popularCalculators.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final calc = _popularCalculators[index];
              return _buildPopularCard(calc, loc);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularCard(CalculatorDefinitionV2 calc, AppLocalizations loc) {
    return Material(
      color: const Color(0xFF18181B), // zinc-900
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openCalculator(calc),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF27272A)), // zinc-800
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getCalculatorIcon(calc),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                loc.translate(calc.titleKey),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(ThemeData theme, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: Color(0xFF71717A), // zinc-500
            ),
            SizedBox(width: 8),
            Text(
              'Недавние',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8), // zinc-300
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentCalculators.map((calc) {
            return _buildRecentChip(calc, loc);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentChip(CalculatorDefinitionV2 calc, AppLocalizations loc) {
    return Material(
      color: const Color(0xFF18181B).withValues(alpha: 0.5), // zinc-900/50
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openCalculator(calc),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF27272A).withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getCalculatorIcon(calc),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                loc.translate(calc.titleKey),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA1A1AA), // zinc-400
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.grid_3x3_rounded,
              size: 16,
              color: Color(0xFF71717A), // zinc-500
            ),
            SizedBox(width: 8),
            Text(
              'Категории',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8), // zinc-300
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip(null, 'Все', Icons.grid_view_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip(
                CalculatorCategory.interior,
                loc.translate(CalculatorCategory.interior.translationKey),
                Icons.home_repair_service_rounded,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                CalculatorCategory.exterior,
                loc.translate(CalculatorCategory.exterior.translationKey),
                Icons.landscape_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Calculator list
        ..._filteredCalculators.map((calc) => _buildCalculatorCard(calc, loc)),

        // Empty state
        if (_filteredCalculators.isEmpty) _buildEmptyState(),
      ],
    );
  }

  Widget _buildCategoryChip(CalculatorCategory? category, String label, IconData icon) {
    final isActive = _activeCategory == category;

    return Material(
      color: isActive
          ? const Color(0xFFFBBF24) // amber-400
          : const Color(0xFF18181B), // zinc-900
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _activeCategory = category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? const Color(0xFF18181B) // zinc-900
                    : const Color(0xFFA1A1AA), // zinc-400
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF18181B)
                      : const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(CalculatorDefinitionV2 calc, AppLocalizations loc) {
    final accentColor = calc.accentColor != null
        ? Color(calc.accentColor!)
        : const Color(0xFFFBBF24); // amber-400

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF18181B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openCalculator(calc),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF27272A).withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getCalculatorIcon(calc),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate(calc.titleKey),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.translate(calc.category.translationKey),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF71717A), // zinc-500
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF52525B), // zinc-600
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFF3F3F46), // zinc-700
            ),
            SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF71717A), // zinc-500
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Попробуйте другой запрос',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF52525B), // zinc-600
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalculatorIcon(CalculatorDefinitionV2 calc) {
    // Маппинг иконок для калькуляторов
    final iconMap = {
      'wall_paint': '🖌️',
      'wallpaper': '🎨',
      'tile': '🔲',
      'laminate': '🪵',
      'screed': '🧱',
      'parquet': '🪵',
      'gkl_ceiling': '⬜',
      'bathroom_tile': '🚿',
      'waterproofing': '💧',
      'warm_floor': '🔥',
      'electrics': '⚡',
      'foundation_strip': '🏗️',
      'foundation_slab': '🏗️',
      'roofing_metal': '🏠',
      'roofing_soft': '🏠',
    };

    return iconMap[calc.id] ?? '📐';
  }

  void _openCalculator(CalculatorDefinitionV2 calc) {
    // Показываем модальное окно предпросмотра
    _showCalculatorPreview(calc);
  }

  void _showCalculatorPreview(CalculatorDefinitionV2 calc) {
    final loc = AppLocalizations.of(context);
    final accentColor = calc.accentColor != null
        ? Color(calc.accentColor!)
        : const Color(0xFFFBBF24);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF18181B), // zinc-900
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F3F46), // zinc-700
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon and title
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _getCalculatorIcon(calc),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate(calc.titleKey),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.translate(calc.category.translationKey),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF71717A), // zinc-500
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick presets
                const Text(
                  'Быстрый выбор:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA1A1AA), // zinc-400
                  ),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: [
                    _buildPresetButton(calc, '🚿', 'Ванная', '4 м²', 4.0),
                    _buildPresetButton(calc, '🍳', 'Кухня', '10 м²', 10.0),
                    _buildPresetButton(calc, '🛏️', 'Спальня', '15 м²', 15.0),
                    _buildPresetButton(calc, '📏', 'Свои размеры', '', null),
                  ],
                ),
                const SizedBox(height: 24),

                // Open button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      CalculatorNavigationHelper.navigateToCalculator(
                        context,
                        calc,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Открыть калькулятор',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(
    CalculatorDefinitionV2 calc,
    String icon,
    String title,
    String area,
    double? areaValue,
  ) {
    return Material(
      color: const Color(0xFF27272A), // zinc-800
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Закрываем модальное окно

          // Предзаполняем первое поле (обычно area)
          Map<String, double>? initialInputs;
          if (areaValue != null && calc.fields.isNotEmpty) {
            final firstField = calc.fields.first;
            initialInputs = {firstField.key: areaValue};
          }

          // Открываем калькулятор с предзаполненными данными
          CalculatorNavigationHelper.navigateToCalculator(
            context,
            calc,
            initialInputs: initialInputs,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (area.isNotEmpty)
                      Text(
                        area,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71717A), // zinc-500
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
