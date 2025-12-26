import '../models/calculator_definition_v2.dart';
import 'paint_universal_calculator_v2.dart';
import 'paint_calculator_v2.dart';
import 'laminate_calculator_v2.dart';
import 'screed_calculator_v2.dart';
import 'tile_calculator_v2.dart';
import 'wallpaper_calculator_v2.dart';
import 'gkl_wall_calculator_v2.dart';
import 'linoleum_calculator_v2.dart';
import 'self_leveling_floor_calculator_v2.dart';
import 'strip_foundation_calculator_v2.dart';
import 'slab_foundation_calculator_v2.dart';
import 'metal_roofing_calculator_v2.dart';
import 'soft_roofing_calculator_v2.dart';
import 'parquet_calculator_v2.dart';
import 'gkl_ceiling_calculator_v2.dart';
import 'ceilings_paint_calculator_v2.dart';
import 'bathroom_tile_calculator_v2.dart';
import 'plinth_calculator_v2.dart';
import 'concrete_universal_calculator_v2.dart';
import 'sheeting_osb_plywood_calculator_v2.dart';
import 'dsp_calculator_v2.dart';
import 'definitions/index.dart';
import 'calculator_search_index.dart';

/// Реестр всех калькуляторов приложения.
///
/// Централизованное хранилище всех доступных калькуляторов V2.
/// Предоставляет методы для поиска, фильтрации и получения калькуляторов.
///
/// ## Основные функции:
///
/// - **Поиск по ID**: `getById(String id)` - получить калькулятор по уникальному идентификатору
/// - **Фильтрация по категории**: `getByCategory(CalculatorCategory)` - получить все калькуляторы категории
/// - **Популярные**: `getPopular({int limit})` - получить топ популярных калькуляторов
/// - **Поиск**: `search(String query)` - поиск по названию, ID или тегам
/// - **Избранные**: `getFavorites()` - получить избранные калькуляторы
/// - **По сложности**: `getByComplexity(int)` - фильтр по уровню сложности
///
/// ## Примеры использования:
///
/// ```dart
/// // Получить калькулятор по ID
/// final calc = CalculatorRegistry.getById('wall_paint');
///
/// // Найти все калькуляторы для полов
/// final floorCalcs = CalculatorRegistry.getByCategory(CalculatorCategory.flooring);
///
/// // Получить топ-5 популярных
/// final popular = CalculatorRegistry.getPopular(limit: 5);
///
/// // Поиск по запросу
/// final results = CalculatorRegistry.search('плитка');
/// ```
///
/// ## Добавление новых калькуляторов:
///
/// 1. Создайте файл `*_calculator_v2.dart` в `lib/domain/calculators/`
/// 2. Определите `final calculatorNameV2 = CalculatorDefinitionV2(...)`
/// 3. Импортируйте файл в `calculator_registry.dart`
/// 4. Добавьте в список `allCalculators`
class CalculatorRegistry {
  /// Базовые (ручные) определения V2.
  static final List<CalculatorDefinitionV2> _seedCalculators = [
    // Универсальные
    concreteUniversalCalculatorV2,

    // Фундамент
    stripFoundationCalculatorV2,
    slabFoundationCalculatorV2,

    // Отделка стен
    paintUniversalCalculatorV2,
    paintCalculatorV2,
    wallpaperCalculatorV2,
    gklWallCalculatorV2,

    // Полы
    laminateCalculatorV2,
    linoleumCalculatorV2,
    screedCalculatorV2,
    selfLevelingFloorCalculatorV2,
    tileCalculatorV2,
    plinthCalculatorV2,
    sheetingOsbPlywoodCalculatorV2,
    dspCalculatorV2,

    // Кровля
    metalRoofingCalculatorV2,
    softRoofingCalculatorV2,

    // Полы (дополнительные)
    parquetCalculatorV2,

    // Потолки
    ceilingsPaintCalculatorV2,
    gklCeilingCalculatorV2,

    // Отделка (дополнительные)
    bathroomTileCalculatorV2,
  ];

  /// Все доступные калькуляторы (версия 2)
  static List<CalculatorDefinitionV2>? _allCalculators;

  /// Калькуляторы, которые показываем в каталоге/на главной.
  static List<CalculatorDefinitionV2> get catalogCalculators =>
      allCalculators.toList(growable: false);

  /// Популярные калькуляторы из заданного набора (без кэширования).
  static List<CalculatorDefinitionV2> getPopularFrom(
    Iterable<CalculatorDefinitionV2> source, {
    int limit = 10,
  }) {
    final sorted = source.toList(growable: false);
    sorted.sort((a, b) => b.popularity.compareTo(a.popularity));
    return sorted.take(limit).toList(growable: false);
  }

  static List<CalculatorDefinitionV2> getCatalogPopular({int limit = 10}) {
    return getPopularFrom(catalogCalculators, limit: limit);
  }

  static List<CalculatorDefinitionV2> get allCalculators {
    return _allCalculators ??= _buildAllCalculators();
  }

  /// Кэш для быстрого поиска по ID (O(1) вместо O(n))
  static Map<String, CalculatorDefinitionV2>? _idCache;

  /// Кэш для популярных калькуляторов
  static List<CalculatorDefinitionV2>? _popularCache;

  /// Кэш для поиска по категориям
  static final Map<dynamic, List<CalculatorDefinitionV2>> _categoryCache = {};

  /// Индекс для быстрого поиска по словам/тегам
  static CalculatorSearchIndex? _searchIndex;

  static Map<String, CalculatorDefinitionV2> get _idCacheLazy {
    return _idCache ??= _buildIdCache();
  }

  static CalculatorSearchIndex get _searchIndexLazy {
    return _searchIndex ??= CalculatorSearchIndex()..buildIndex(allCalculators);
  }

  /// Получить калькулятор по ID (O(1) - оптимизировано с Map)
  static CalculatorDefinitionV2? getById(String id) {
    return _idCacheLazy[id];
  }

  /// Получить калькуляторы по категории (с кэшированием)
  static List<CalculatorDefinitionV2> getByCategory(dynamic category) {
    // Проверяем кэш
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!;
    }

    // Вычисляем и кэшируем
    final result = allCalculators.where((calc) => calc.category == category).toList();
    _categoryCache[category] = result;
    return result;
  }

  /// Получить популярные калькуляторы (с кэшированием)
  static List<CalculatorDefinitionV2> getPopular({int limit = 10}) {
    // Проверяем кэш
    if (_popularCache == null) {
      final sorted = List<CalculatorDefinitionV2>.from(allCalculators);
      sorted.sort((a, b) => b.popularity.compareTo(a.popularity));
      _popularCache = sorted;
    }

    return _popularCache!.take(limit).toList();
  }

  /// Поиск калькуляторов по запросу
  static List<CalculatorDefinitionV2> search(String query) {
    if (query.isEmpty) return allCalculators;

    final matches = _searchIndexLazy.search(query).toSet();
    if (matches.isEmpty) return [];
    return allCalculators.where((calc) => matches.contains(calc.id)).toList();
  }

  /// Получить избранные калькуляторы
  static List<CalculatorDefinitionV2> getFavorites() {
    return allCalculators.where((calc) => calc.isFavorite).toList();
  }

  /// Получить калькуляторы по сложности
  static List<CalculatorDefinitionV2> getByComplexity(int complexity) {
    return allCalculators.where((calc) => calc.complexity == complexity).toList();
  }

  /// Количество калькуляторов
  static int get count => allCalculators.length;

  /// Проверить существование калькулятора (O(1) через кэш)
  static bool exists(String id) {
    return _idCacheLazy.containsKey(id);
  }

  /// Очистить все кэши (используйте при добавлении калькуляторов динамически)
  static void clearCache() {
    _idCache = null;
    _popularCache = null;
    _categoryCache.clear();
    _searchIndex = null;
    _idCache = _buildIdCache();
  }

  /// Добавить калькулятор динамически (для плагинов/расширений)
  static void register(CalculatorDefinitionV2 calculator) {
    final idCache = _idCacheLazy;
    if (!idCache.containsKey(calculator.id)) {
      allCalculators.add(calculator);
      idCache[calculator.id] = calculator;

      // Инвалидируем кэши
      _popularCache = null;
      _categoryCache.remove(calculator.category);
      _searchIndex = null;
    }
  }

  /// Построить полный список калькуляторов из ручных V2 и сгенерированных V2.
  static List<CalculatorDefinitionV2> _buildAllCalculators() {
    final overrides = {for (final calc in _seedCalculators) calc.id: calc};
    final skipIds = overrides.keys.toSet();
    final migrated = [
      ...foundationCalculators,
      ...wallsCalculators,
      ...flooringCalculators,
      ...ceilingCalculators,
      ...roofingCalculators,
      ...facadeCalculators,
      ...engineeringCalculators,
      ...interiorCalculators,
    ].where((c) => !skipIds.contains(c.id)).toList();

    final all = <CalculatorDefinitionV2>[
      ..._seedCalculators,
      ...migrated,
    ];

    return all;
  }

  /// Строим кэш для быстрого доступа по ID.
  static Map<String, CalculatorDefinitionV2> _buildIdCache() {
    return {for (final calc in allCalculators) calc.id: calc};
  }
}
