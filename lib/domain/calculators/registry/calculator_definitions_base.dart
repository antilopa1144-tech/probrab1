/// Базовые классы для определений калькуляторов.
///
/// Этот файл содержит общие модели данных, используемые всеми калькуляторами.

import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../data/models/price_item.dart';
import '../../../core/cache/calculation_cache.dart';
import '../../usecases/calculator_usecase.dart';

/// Описание поля ввода (одно поле формы: периметр, ширина и т.п.)
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
    FirebaseAnalytics.instance.logEvent(
      name: 'calculator_used',
      parameters: {
        'calculator_id': id,
        'calculator_category': category,
        'calculator_subcategory': subCategory,
      },
    );

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
