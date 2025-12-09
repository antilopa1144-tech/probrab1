import './definitions.dart';
import './modules/all_modules.dart' as modules;

/// Реестр с lazy loading калькуляторов по категориям.
///
/// Калькуляторы загружаются только при первом обращении к категории,
/// что ускоряет старт приложения и уменьшает потребление памяти.
///
/// ## Пример использования:
///
/// ```dart
/// final registry = LazyLoadingRegistry.instance;
/// final foundationCalcs = await registry.getByCategory('Фундамент');
/// ```
class LazyLoadingRegistry {
  /// Singleton instance
  static final LazyLoadingRegistry _instance = LazyLoadingRegistry._internal();
  static LazyLoadingRegistry get instance => _instance;

  LazyLoadingRegistry._internal();

  /// Кэш загруженных калькуляторов по категориям
  final Map<String, List<CalculatorDefinition>> _categoryCache = {};

  /// Флаги загрузки категорий
  final Set<String> _loadedCategories = {};

  /// Загрузчики калькуляторов по категориям
  final Map<String, List<CalculatorDefinition> Function()> _loaders = {
    'Фундамент': () => modules.foundationCalculators,
    'Стены': () => modules.wallCalculators,
    'Полы': () => modules.floorCalculators,
    'Потолки': () => modules.ceilingCalculators,
    'Перегородки': () => modules.partitionCalculators,
    'Утепление': () => modules.insulationCalculators,
    'Наружная отделка': () => modules.exteriorCalculators,
    'Кровля': () => modules.roofingCalculators,
    'Инженерные работы': () => modules.engineeringCalculators,
    'Ванная': () => modules.bathroomCalculators,
    'Смеси': () => modules.mixCalculators,
    'Окна/Двери': () => modules.windowsDoorsCalculators,
    'Конструкции': () => modules.structureCalculators,
  };

  /// Получить калькуляторы категории (lazy loading).
  ///
  /// Калькуляторы загружаются только при первом обращении.
  List<CalculatorDefinition> getByCategory(String category) {
    // Проверяем кэш
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!;
    }

    // Загружаем калькуляторы
    final loader = _loaders[category];
    if (loader == null) {
      return [];
    }

    final calculators = loader();
    _categoryCache[category] = calculators;
    _loadedCategories.add(category);

    return calculators;
  }

  /// Предзагрузить категорию.
  ///
  /// Полезно для предзагрузки популярных категорий при старте приложения.
  void preloadCategory(String category) {
    if (!_loadedCategories.contains(category)) {
      getByCategory(category);
    }
  }

  /// Предзагрузить несколько категорий.
  void preloadCategories(List<String> categories) {
    for (final category in categories) {
      preloadCategory(category);
    }
  }

  /// Получить все загруженные категории.
  List<String> getLoadedCategories() {
    return _loadedCategories.toList();
  }

  /// Очистить кэш категории.
  void clearCategory(String category) {
    _categoryCache.remove(category);
    _loadedCategories.remove(category);
  }

  /// Очистить весь кэш.
  void clearAll() {
    _categoryCache.clear();
    _loadedCategories.clear();
  }

  /// Получить все доступные категории.
  List<String> getAllCategories() {
    return _loaders.keys.toList();
  }
}
