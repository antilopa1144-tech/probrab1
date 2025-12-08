// Репозиторий расчётов (цены и прочее)

import 'package:firebase_analytics/firebase_analytics.dart';
import '../../data/models/price_item.dart';
import '../usecases/calculator_usecase.dart';
import '../../core/cache/calculation_cache.dart';
// Модульные калькуляторы
import 'modules/all_modules.dart' as modules;
import '../usecases/calculate_sound_insulation.dart';

import 'package:flutter/foundation.dart';

/// Описание поля ввода (одно поле формы: периметр, ширина и т.п.)
@immutable
class InputFieldDefinition {
  /// ID поля (используется во входной карте inputs['perimeter'])
  final String key;

  /// Ключ для перевода (например 'input.perimeter')
  final String labelKey;

  /// Тип клавиатуры/ввода (number, text и т.п.)
  final String type;

  /// Значение по умолчанию
  final double defaultValue;

  /// Минимальное значение (null = нет ограничения)
  final double? minValue;

  /// Максимальное значение (null = нет ограничения)
  final double? maxValue;

  /// Обязательное поле
  final bool required;

  const InputFieldDefinition({
    required this.key,
    required this.labelKey,
    this.type = 'number',
    this.defaultValue = 0.0,
    this.minValue,
    this.maxValue,
    this.required = true,
  });
}

/// Описание самого калькулятора (одного инструмента)
@immutable
class CalculatorDefinition {
  /// Уникальный ID (например 'calculator.stripTitle')
  final String id;

  /// Ключ заголовка для локализации
  final String titleKey;

  /// Поля ввода, которые нужно отрисовать на экране
  final List<InputFieldDefinition> fields;

  /// Ключи для подписей результатов (volume, rebar и т.п.)
  final Map<String, String> resultLabels;

  /// ГЛАВНОЕ: ссылка на класс-юзкейс, в котором живёт математика
  final CalculatorUseCase useCase;

  /// Категория (Дом → Внутренняя отделка → Стены)
  final String category;

  /// Подкатегория внутри категории (например, 'Ленточный фундамент')
  final String subCategory;

  /// Советы мастера, которые будет отображать универсальный экран.
  final List<String> tips;

  const CalculatorDefinition({
    required this.id,
    required this.titleKey,
    required this.fields,
    required this.resultLabels,
    required this.useCase,
    this.category = '',
    this.subCategory = '',
    this.tips = const [],
  });

  /// Кэш для результатов расчётов
  static final _cache = CalculationCache();

  /// Возвращает полный CalculatorResult (значения + цена).
  /// Использует кэширование для повторных расчётов с теми же параметрами.
  CalculatorResult run(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    // Попытка получить из кэша
    if (useCache) {
      final cachedValues = _cache.get(id, inputs);
      if (cachedValues != null) {
        // Возвращаем кэшированный результат (без цены, т.к. цены могут измениться)
        // НЕ логируем в Analytics для кэшированных результатов
        return CalculatorResult(values: cachedValues, totalPrice: null);
      }
    }

    // Выполняем расчёт
    final result = useCase.call(inputs, priceList);

    // Логирование использования калькулятора в Firebase Analytics
    // ТОЛЬКО для новых расчётов (не из кэша)
    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'calculator_used',
        parameters: {
          'calculator_id': id,
          'calculator_category': category,
          'calculator_subcategory': subCategory,
        },
      );
    } catch (e) {
      // Игнорируем ошибки Firebase в тестах
    }

    // Сохраняем в кэш
    if (useCache) {
      _cache.set(id, inputs, result.values);
    }

    return result;
  }

  /// Адаптер под старый код, который ожидает просто `Map<String, double>`.
  Map<String, double> compute(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    final result = run(inputs, priceList, useCache: useCache);
    return result.values;
  }

  /// Alias для совместимости (некоторые экраны ожидают calculate()).
  Map<String, double> calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    return compute(inputs, priceList, useCache: useCache);
  }

  /// Очистить кэш для этого калькулятора
  void clearCache() {
    _cache.clearForCalculator(id);
  }

  /// Получить статистику кэша
  static CacheStats getCacheStats() {
    return _cache.getStats();
  }

  /// Очистить весь кэш
  static void clearAllCache() {
    _cache.clear();
  }
}

/// ===== КАЛЬКУЛЯТОРЫ ФУНДАМЕНТА =====
/// Импортированы из модуля modules/foundation/
final List<CalculatorDefinition> foundationCalculators =
    modules.foundationCalculators;

/// ===== КАЛЬКУЛЯТОРЫ СТЕН =====
/// Перенесено в modules/walls/wall_calculators.dart
final List<CalculatorDefinition> wallCalculators = modules.wallCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ПОЛОВ =====
/// Перенесено в modules/floors/floor_calculators.dart
final List<CalculatorDefinition> floorCalculators = modules.floorCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ПОТОЛКОВ =====
/// Перенесено в modules/ceilings/ceiling_calculators.dart
final List<CalculatorDefinition> ceilingCalculators =
    modules.ceilingCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ПЕРЕГОРОДОК =====
/// Перенесено в modules/partitions/partition_calculators.dart
final List<CalculatorDefinition> partitionCalculators =
    modules.partitionCalculators;

/// ===== КАЛЬКУЛЯТОРЫ УТЕПЛЕНИЯ =====
/// Перенесено в modules/insulation/insulation_calculators.dart
final List<CalculatorDefinition> insulationCalculators =
    modules.insulationCalculators;

/// ===== КАЛЬКУЛЯТОРЫ НАРУЖНОЙ ОТДЕЛКИ =====
/// Перенесено в modules/exterior/exterior_calculators.dart
final List<CalculatorDefinition> exteriorCalculators =
    modules.exteriorCalculators;

/// ===== КАЛЬКУЛЯТОРЫ КРОВЛИ =====
/// Перенесено в modules/roofing/roofing_calculators.dart
final List<CalculatorDefinition> roofingCalculators =
    modules.roofingCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ИНЖЕНЕРНЫХ РАБОТ =====
/// Перенесено в modules/engineering/engineering_calculators.dart
final List<CalculatorDefinition> engineeringCalculators =
    modules.engineeringCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ВАННОЙ =====

/// Перенесено в modules/bathroom/bathroom_calculators.dart
final List<CalculatorDefinition> bathroomCalculators =
    modules.bathroomCalculators;

/// ===== КАЛЬКУЛЯТОРЫ СМЕСЕЙ =====
/// Перенесено в modules/mix/mix_calculators.dart
final List<CalculatorDefinition> mixCalculators = modules.mixCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ОКОН/ДВЕРЕЙ =====
/// Перенесено в modules/windows_doors/windows_doors_calculators.dart
final List<CalculatorDefinition> windowsDoorsCalculators =
    modules.windowsDoorsCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ШУМОИЗОЛЯЦИИ =====

final List<CalculatorDefinition> soundInsulationCalculators = [
  CalculatorDefinition(
    id: 'insulation_sound',
    titleKey: 'calculator.soundInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Шумоизоляция',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 50.0,
      ),
      InputFieldDefinition(
        key: 'insulationType',
        labelKey: 'input.insulationType',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Шумоизоляция особенно важна для межкомнатных перегородок.',
      'Используйте материалы с высоким коэффициентом звукопоглощения.',
      'Обеспечьте герметичность стыков.',
    ],
    useCase: CalculateSoundInsulation(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ КОНСТРУКЦИЙ =====
/// Перенесено в modules/structure/structure_calculators.dart
final List<CalculatorDefinition> structureCalculators =
    modules.structureCalculators;

/// Общий список всех калькуляторов приложения.
const List<CalculatorDefinition> finishCalculators = [];

final List<CalculatorDefinition> calculators = [
  ...foundationCalculators,
  ...wallCalculators,
  ...floorCalculators,
  ...ceilingCalculators,
  ...partitionCalculators,
  ...insulationCalculators,
  ...soundInsulationCalculators,
  ...exteriorCalculators,
  ...roofingCalculators,
  ...bathroomCalculators,
  ...engineeringCalculators,
  ...mixCalculators,
  ...windowsDoorsCalculators,
  ...structureCalculators,
  ...finishCalculators,
];

/// Найти калькулятор по ID.
CalculatorDefinition? findCalculatorById(String id) {
  try {
    return calculators.firstWhere((calc) => calc.id == id);
  } catch (_) {
    return null;
  }
}

/// Централизованный реестр всех калькуляторов приложения.
/// Предоставляет оптимизированный доступ к калькуляторам через индексы.
///
/// Использование:
/// ```dart
/// final calc = CalculatorRegistryV1.instance.getById('laminate');
/// final floors = CalculatorRegistryV1.instance.getByCategory('Полы');
/// final results = CalculatorRegistryV1.instance.search('ламинат');
/// ```
class CalculatorRegistryV1 {
  // Singleton pattern
  static final CalculatorRegistryV1 _instance =
      CalculatorRegistryV1._internal();
  static CalculatorRegistryV1 get instance => _instance;

  CalculatorRegistryV1._internal() {
    _buildIndices();
  }

  /// Индекс для быстрого поиска по ID (O(1))
  final Map<String, CalculatorDefinition> _idIndex = {};

  /// Индекс для быстрого поиска по категории (O(1))
  final Map<String, List<CalculatorDefinition>> _categoryIndex = {};

  /// Индекс для быстрого поиска по подкатегории (O(1))
  final Map<String, List<CalculatorDefinition>> _subCategoryIndex = {};

  /// Построить все индексы из существующего списка calculators
  void _buildIndices() {
    _idIndex.clear();
    _categoryIndex.clear();
    _subCategoryIndex.clear();

    for (final calc in calculators) {
      // Индекс по ID
      _idIndex[calc.id] = calc;

      // Индекс по категории
      _categoryIndex.putIfAbsent(calc.category, () => []).add(calc);

      // Индекс по подкатегории
      if (calc.subCategory.isNotEmpty) {
        _subCategoryIndex.putIfAbsent(calc.subCategory, () => []).add(calc);
      }
    }
  }

  /// Получить калькулятор по ID (O(1))
  CalculatorDefinition? getById(String id) {
    return _idIndex[id];
  }

  /// Получить все калькуляторы категории (O(1))
  List<CalculatorDefinition> getByCategory(String category) {
    return _categoryIndex[category] ?? [];
  }

  /// Получить все калькуляторы подкатегории (O(1))
  List<CalculatorDefinition> getBySubCategory(String subCategory) {
    return _subCategoryIndex[subCategory] ?? [];
  }

  /// Получить все уникальные категории
  List<String> getAllCategories() {
    return _categoryIndex.keys.toList()..sort();
  }

  /// Получить все подкатегории для категории
  List<String> getSubCategories(String category) {
    final calculators = getByCategory(category);
    final subCategories = calculators
        .map((c) => c.subCategory)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return subCategories..sort();
  }

  /// Поиск калькуляторов по запросу
  /// Возвращает список калькуляторов, отсортированных по релевантности
  List<CalculatorDefinition> search(String query) {
    if (query.isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final results = <_SearchResultV1>[];

    for (final calculator in calculators) {
      int relevance = 0;

      // Поиск в ID (наивысший приоритет)
      if (calculator.id.toLowerCase().contains(normalizedQuery)) {
        relevance += 100;
      }

      // Поиск в titleKey
      if (calculator.titleKey.toLowerCase().contains(normalizedQuery)) {
        relevance += 50;
      }

      // Поиск в категории
      if (calculator.category.toLowerCase().contains(normalizedQuery)) {
        relevance += 30;
      }

      // Поиск в подкатегории
      if (calculator.subCategory.toLowerCase().contains(normalizedQuery)) {
        relevance += 20;
      }

      if (relevance > 0) {
        results.add(_SearchResultV1(calculator, relevance));
      }
    }

    // Сортировка по релевантности
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.map((r) => r.calculator).toList();
  }

  /// Получить все калькуляторы
  List<CalculatorDefinition> getAll() {
    return List.unmodifiable(calculators);
  }

  /// Получить количество калькуляторов
  int get count => calculators.length;

  /// Проверить, существует ли калькулятор с данным ID
  bool contains(String id) {
    return _idIndex.containsKey(id);
  }

  /// Получить статистику по категориям
  Map<String, int> getCategoryStats() {
    return _categoryIndex.map((category, calculators) {
      return MapEntry(category, calculators.length);
    });
  }

  /// Фильтровать калькуляторы по условию
  List<CalculatorDefinition> filter(
    bool Function(CalculatorDefinition) predicate,
  ) {
    return calculators.where(predicate).toList();
  }

  /// Пересоздать индексы (используется при динамическом обновлении списка)
  void rebuildIndices() {
    _buildIndices();
  }
}

/// Внутренний класс для хранения результатов поиска с релевантностью
class _SearchResultV1 {
  final CalculatorDefinition calculator;
  final int relevance;

  _SearchResultV1(this.calculator, this.relevance);
}
