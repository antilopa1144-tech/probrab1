part of 'new_home_screen.dart';

class _NewHomeScreenState extends ConsumerState<NewHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final next = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = next);
    });
  }

  List<CalculatorDefinitionV2> get _popularCalculators {
    return CalculatorRegistry.getCatalogPopular(limit: 6);
  }

  List<CalculatorDefinitionV2> get _recentCalculators {
    // Placeholder: интеграция с историей расчетов появится после внедрения хранилища истории
    return CalculatorRegistry.getCatalogPopular(limit: 3);
  }

  List<CalculatorDefinitionV2> _filteredCalculators(AppLocalizations loc) {
    final all = CalculatorRegistry.catalogCalculators;
    if (_searchQuery.isEmpty) return all;

    final query = _searchQuery.toLowerCase();
    return all.where((calc) {
      final title = loc.translate(calc.titleKey).toLowerCase();
      final sub = loc.translate(calc.subCategoryKey).toLowerCase();
      return title.contains(query) ||
          sub.contains(query) ||
          calc.id.toLowerCase().contains(query) ||
          calc.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList(growable: false);
  }

  void _openCalculator(CalculatorDefinitionV2 calc) {
    if (calc.id == 'dsp') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const DspScreen(),
      ));
    } else {
      CalculatorNavigationHelper.navigateToCalculator(context, calc);
    }
  }

  void _openFavorites() {
    if (widget.onTabRequested != null) {
      widget.onTabRequested!(2);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FavoriteCalculatorsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);

    final isSearching = _searchQuery.isNotEmpty;
    final filtered = isSearching ? _filteredCalculators(loc) : const <CalculatorDefinitionV2>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // zinc-950
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, loc, favoritesCount: favorites.length),
            Expanded(
              child: isSearching
                  ? _buildSearchResults(theme, loc, favorites, filtered)
                  : _buildHomeContent(theme, loc, favorites),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations loc, {
    required int favoritesCount,
  }) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.construction_rounded,
                      size: 18,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Probrab AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Калькуляторы материалов',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              const Color(0xFFA1A1AA).withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openFavorites,
                  icon: Icon(
                    favoritesCount > 0
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Что нужно посчитать?',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
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
                fillColor: const Color(0xFF18181B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
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

  Widget _buildHomeContent(
    ThemeData theme,
    AppLocalizations loc,
    List<String> favorites,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        _buildPopularSection(theme, loc, favorites),
        const SizedBox(height: 24),
        if (_recentCalculators.isNotEmpty) ...[
          _buildRecentSection(theme, loc),
          const SizedBox(height: 24),
        ],
        _buildCategoriesGrid(theme, loc),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSearchResults(
    ThemeData theme,
    AppLocalizations loc,
    List<String> favorites,
    List<CalculatorDefinitionV2> results,
  ) {
    if (results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Ничего не найдено',
        subtitle: 'Попробуйте другой запрос',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: results.length + 1,
      separatorBuilder: (context, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Найдено: ${results.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFA1A1AA),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final calc = results[index - 1];
        final isFavorite = favorites.contains(calc.id);
        return _buildCalculatorCard(calc, loc, isFavorite: isFavorite);
      },
    );
  }

  Widget _buildPopularSection(
    ThemeData theme,
    AppLocalizations loc,
    List<String> favorites,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.flash_on_rounded,
              size: 16,
              color: Color(0xFFFBBF24),
            ),
            SizedBox(width: 8),
            Text(
              'Быстрый доступ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _popularCalculators.length,
            separatorBuilder: (context, _) => const SizedBox(width: 8),
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
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openCalculator(calc),
        onLongPress: () => _showCalculatorPresets(calc),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF27272A)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getCalculatorIcon(calc), style: const TextStyle(fontSize: 20)),
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
              Icons.trending_up_rounded,
              size: 16,
              color: Color(0xFF71717A),
            ),
            SizedBox(width: 8),
            Text(
              'Часто считают',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8),
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
      color: const Color(0xFF18181B).withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openCalculator(calc),
        onLongPress: () => _showCalculatorPresets(calc),
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
              Text(_getCalculatorIcon(calc), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                loc.translate(calc.titleKey),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(ThemeData theme, AppLocalizations loc) {
    final available = CalculatorRegistry.catalogCalculators
        .map((c) => c.subCategoryKey)
        .toSet();

    final categories = _homeCategories
        .where(
          (c) => c.subCategoryKey == null || available.contains(c.subCategoryKey),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: Color(0xFF71717A),
            ),
            SizedBox(width: 8),
            Text(
              'Категории',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            for (final category in categories)
              _buildCategoryTile(category, loc),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTile(_HomeCategory category, AppLocalizations loc) {
    final label = category.subCategoryKey == null
        ? 'Все калькуляторы'
        : loc.translate(category.subCategoryKey!);

    return Material(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CalculatorCatalogScreen(
                subCategoryKey: category.subCategoryKey,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF27272A)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(category.icon, color: const Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(
    CalculatorDefinitionV2 calc,
    AppLocalizations loc, {
    required bool isFavorite,
  }) {
    final accentColor = calc.accentColor != null
        ? Color(calc.accentColor!)
        : const Color(0xFFFBBF24);

    return Material(
      color: const Color(0xFF18181B).withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openCalculator(calc),
        onLongPress: () => _showCalculatorPresets(calc),
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
                      loc.translate(calc.subCategoryKey),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: () => ref
                    .read(favoritesProvider.notifier)
                    .toggleFavorite(calc.id),
                icon: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFF71717A),
                ),
              ),
              IconButton(
                tooltip: 'Пресеты',
                onPressed: () => _showCalculatorPresets(calc),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF52525B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF3F3F46)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF71717A)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF52525B)),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalculatorIcon(CalculatorDefinitionV2 calc) {
    final iconMap = {
      'bathroom_tile': '🚿',
      'foundation_strip': '🏗️',
      'foundation_slab': '🏗️',
      'wall_paint': '🎨',
      'walls_wallpaper': '🧻',
      'walls_gkl': '🧱',
      'floors_laminate': '🪵',
      'floors_linoleum': '🧻',
      'floors_screed': '🧱',
      'floors_self_leveling': '🧱',
      'floors_tile': '🧱',
      'floors_warm': '🔥',
      'floors_parquet': '🪵',
      'ceilings_gkl': '🏗️',
      'roofing_metal': '🏠',
      'roofing_soft': '🏠',
      'insulation_foam': '🧊',
      'insulation_mineral': '🧊',
    };

    return iconMap[calc.id] ?? '🧰';
  }

  void _showCalculatorPresets(CalculatorDefinitionV2 calc) {
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
          color: Color(0xFF18181B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F3F46),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
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
                            loc.translate(calc.subCategoryKey),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Пресеты:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFA1A1AA),
                    ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openCalculator(calc);
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
      color: const Color(0xFF27272A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);

          Map<String, double>? initialInputs;
          if (areaValue != null && calc.fields.isNotEmpty) {
            final firstField = calc.fields.first;
            initialInputs = {firstField.key: areaValue};
          }

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
                          color: Color(0xFF71717A),
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

class _HomeCategory {
  final String? subCategoryKey;
  final IconData icon;

  const _HomeCategory({required this.subCategoryKey, required this.icon});
}

const List<_HomeCategory> _homeCategories = [
  _HomeCategory(subCategoryKey: 'subcategory.floors', icon: Icons.square_foot_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.walls', icon: Icons.crop_16_9_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.ceilings', icon: Icons.horizontal_rule_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.roofing', icon: Icons.roofing),
  _HomeCategory(subCategoryKey: 'subcategory.paint', icon: Icons.format_paint),
  _HomeCategory(subCategoryKey: 'subcategory.strip', icon: Icons.foundation),
  _HomeCategory(subCategoryKey: 'subcategory.slab', icon: Icons.foundation),
  _HomeCategory(subCategoryKey: 'subcategory.concrete', icon: Icons.water_drop_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.insulation', icon: Icons.ac_unit_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.partitions', icon: Icons.view_agenda_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.osb_plywood', icon: Icons.grid_on_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.electrics', icon: Icons.electrical_services_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.plumbing', icon: Icons.plumbing_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.heating', icon: Icons.local_fire_department_rounded),
  _HomeCategory(subCategoryKey: 'subcategory.bathroom', icon: Icons.bathroom_rounded),
  _HomeCategory(subCategoryKey: null, icon: Icons.apps_rounded),
];
