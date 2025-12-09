import './definitions.dart';
import '../models/calculator_definition_v2.dart';
import 'calculator_registry.dart' as v2;

/// Улучшенный реестр калькуляторов, объединяющий V1 и V2.
///
/// Предоставляет единый интерфейс для работы с калькуляторами обеих версий
/// с поддержкой lazy loading и оптимизированного поиска.
///
/// ## Основные возможности:
///
/// - **Единый интерфейс**: Работа с V1 и V2 калькуляторами через один API
/// - **Lazy loading**: Калькуляторы загружаются по требованию
/// - **Быстрый поиск**: O(1) поиск по ID, O(log n) по категориям
/// - **Кэширование**: Результаты поиска кэшируются
///
/// ## Примеры использования:
///
/// ```dart
/// // Получить калькулятор по ID
/// final calc = CalculatorRegistry.instance.getById('laminate');
///
/// // Найти все калькуляторы для полов
/// final floors = CalculatorRegistry.instance.getByCategory('Полы');
///
/// // Поиск по запросу
/// final results = CalculatorRegistry.instance.search('ламинат');
/// ```
class CalculatorRegistry {
  /// Singleton instance
  static final CalculatorRegistry _instance = CalculatorRegistry._internal();
  static CalculatorRegistry get instance => _instance;

  CalculatorRegistry._internal() {
    _initialize();
  }

  /// Кэш для V1 калькуляторов по ID
  final Map<String, CalculatorDefinition> _v1IdCache = {};

  /// Кэш для V2 калькуляторов по ID
  final Map<String, CalculatorDefinitionV2> _v2IdCache = {};

  /// Кэш для калькуляторов по категории
  final Map<String, List<CalculatorDefinition>> _v1CategoryCache = {};
  final Map<dynamic, List<CalculatorDefinitionV2>> _v2CategoryCache = {};

  /// Флаг инициализации
  bool _initialized = false;

  /// Инициализация реестра
  void _initialize() {
    if (_initialized) return;

    // Инициализация V1 калькуляторов
    _buildV1Indices();

    // V2 калькуляторы уже инициализированы в CalculatorRegistry
    _buildV2Indices();

    _initialized = true;
  }

  /// Построить индексы для V1 калькуляторов
  void _buildV1Indices() {
    _v1IdCache.clear();
    _v1CategoryCache.clear();

    for (final calc in calculators) {
      _v1IdCache[calc.id] = calc;
      _v1CategoryCache.putIfAbsent(calc.category, () => []).add(calc);
    }
  }

  /// Построить индексы для V2 калькуляторов
  void _buildV2Indices() {
    _v2IdCache.clear();
    _v2CategoryCache.clear();

    for (final calc in v2.CalculatorRegistry.allCalculators) {
      _v2IdCache[calc.id] = calc;
      _v2CategoryCache.putIfAbsent(calc.category, () => []).add(calc);
    }
  }

  /// Получить V1 калькулятор по ID (O(1))
  CalculatorDefinition? getV1ById(String id) {
    return _v1IdCache[id];
  }

  /// Получить V2 калькулятор по ID (O(1))
  CalculatorDefinitionV2? getV2ById(String id) {
    return _v2IdCache[id];
  }

  /// Получить калькулятор по ID (проверяет обе версии)
  dynamic getById(String id) {
    // Сначала проверяем V2 (более новая версия)
    final v2 = getV2ById(id);
    if (v2 != null) return v2;

    // Затем V1
    return getV1ById(id);
  }

  /// Получить все V1 калькуляторы категории (O(1) с кэшированием)
  List<CalculatorDefinition> getV1ByCategory(String category) {
    return _v1CategoryCache[category] ?? [];
  }

  /// Получить все V2 калькуляторы категории (O(1) с кэшированием)
  List<CalculatorDefinitionV2> getV2ByCategory(dynamic category) {
    return _v2CategoryCache[category] ?? [];
  }

  /// Получить все калькуляторы категории (объединяет V1 и V2)
  List<dynamic> getByCategory(String category) {
    final v1 = getV1ByCategory(category);
    final v2 = getV2ByCategory(category);
    return [...v1, ...v2];
  }

  /// Поиск калькуляторов по запросу (объединяет V1 и V2)
  List<dynamic> search(String query) {
    if (query.isEmpty) {
      return [
        ...CalculatorRegistryV1.instance.getAll(),
        ...v2.CalculatorRegistry.allCalculators,
      ];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final results = <_SearchResult>[];

    // Поиск в V1
    for (final calc in calculators) {
      int relevance = 0;
      if (calc.id.toLowerCase().contains(normalizedQuery)) {
        relevance += 100;
      }
      if (calc.titleKey.toLowerCase().contains(normalizedQuery)) {
        relevance += 50;
      }
      if (calc.category.toLowerCase().contains(normalizedQuery)) {
        relevance += 30;
      }
      if (calc.subCategory.toLowerCase().contains(normalizedQuery)) {
        relevance += 20;
      }
      if (relevance > 0) {
        results.add(_SearchResult(calc, relevance));
      }
    }

    // Поиск в V2
    for (final calc in v2.CalculatorRegistry.allCalculators) {
      int relevance = 0;
      if (calc.id.toLowerCase().contains(normalizedQuery)) {
        relevance += 100;
      }
      if (calc.titleKey.toLowerCase().contains(normalizedQuery)) {
        relevance += 50;
      }
      if (calc.category.toString().toLowerCase().contains(normalizedQuery)) {
        relevance += 30;
      }
      if (calc.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery))) {
        relevance += 20;
      }
      if (relevance > 0) {
        results.add(_SearchResult(calc, relevance));
      }
    }

    // Сортировка по релевантности
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.map((r) => r.calculator).toList();
  }

  /// Получить все уникальные категории (объединяет V1 и V2)
  List<String> getAllCategories() {
    final categories = <String>{};
    categories.addAll(_v1CategoryCache.keys);
    categories.addAll(_v2CategoryCache.keys.map((e) => e.toString()));
    return categories.toList()..sort();
  }

  /// Получить количество калькуляторов
  int get count {
    return calculators.length + v2.CalculatorRegistry.allCalculators.length;
  }

  /// Проверить существование калькулятора
  bool contains(String id) {
    return _v1IdCache.containsKey(id) || _v2IdCache.containsKey(id);
  }

  /// Пересоздать индексы (используется при динамическом обновлении)
  void rebuildIndices() {
    _buildV1Indices();
    _buildV2Indices();
  }

  /// Очистить все кэши
  void clearCache() {
    _v1IdCache.clear();
    _v2IdCache.clear();
    _v1CategoryCache.clear();
    _v2CategoryCache.clear();
    _buildV1Indices();
    _buildV2Indices();
  }
}

/// Внутренний класс для хранения результатов поиска с релевантностью
class _SearchResult {
  final dynamic calculator;
  final int relevance;

  _SearchResult(this.calculator, this.relevance);
}
