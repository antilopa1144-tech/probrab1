import 'package:firebase_analytics/firebase_analytics.dart';
import '../../core/enums/calculator_category.dart';
import '../../core/cache/calculation_cache.dart';
import '../../data/models/price_item.dart';
import '../usecases/calculator_usecase.dart';
import 'calculator_field.dart';
import 'calculator_hint.dart';

/// Улучшенное определение калькулятора с поддержкой подсказок и валидации.
///
/// Этот класс представляет собой декларативное описание калькулятора,
/// которое используется для автоматической генерации UI и выполнения расчётов.
///
/// ## Основные возможности:
///
/// - **Декларативные поля**: Определение полей ввода с типами, валидацией и единицами измерения
/// - **Подсказки**: Контекстные подсказки до и после расчёта
/// - **Группировка полей**: Логическая группировка полей для лучшего UX
/// - **Зависимости полей**: Условное отображение полей на основе других значений
/// - **Метаданные**: Иконки, цвета, сложность, популярность для каталога
///
/// ## Пример использования:
///
/// ```dart
/// final paintCalculator = CalculatorDefinitionV2(
///   id: 'wall_paint',
///   titleKey: 'calculator.wall_paint.title',
///   category: CalculatorCategory.wallFinishing,
///   subCategory: 'paint',
///   fields: [
///     CalculatorField(
///       key: 'area',
///       labelKey: 'input.area',
///       unitType: UnitType.squareMeters,
///       defaultValue: 0,
///       required: true,
///     ),
///   ],
///   useCase: CalculateWallPaint(),
/// );
/// ```
///
/// ## Миграция с V1:
///
/// Старая система использовала `CalculatorDefinition` с жестко закодированными полями.
/// V2 позволяет динамически создавать формы и лучше интегрируется с проектами.
class CalculatorDefinitionV2 {
  /// Уникальный ID калькулятора
  final String id;

  /// Ключ перевода для названия
  final String titleKey;

  /// Ключ перевода для краткого описания
  final String? descriptionKey;

  /// Категория калькулятора
  final CalculatorCategory category;

  /// Подкатегория (строка)
  final String subCategory;

  /// Список полей ввода
  final List<CalculatorField> fields;

  /// Подсказки (показываются до расчёта)
  final List<CalculatorHint> beforeHints;

  /// Подсказки (показываются после расчёта)
  final List<CalculatorHint> afterHints;

  /// UseCase для выполнения расчёта
  final CalculatorUseCase useCase;

  /// Метаданные: иконка
  final String? iconName;

  /// Метаданные: цвет акцента
  final int? accentColor;

  /// Сложность калькулятора (1-5)
  final int complexity;

  /// Популярность (для сортировки)
  final int popularity;

  /// Избранное
  final bool isFavorite;

  /// Теги для поиска
  final List<String> tags;

  const CalculatorDefinitionV2({
    required this.id,
    required this.titleKey,
    this.descriptionKey,
    required this.category,
    required this.subCategory,
    required this.fields,
    this.beforeHints = const [],
    this.afterHints = const [],
    required this.useCase,
    this.iconName,
    this.accentColor,
    this.complexity = 1,
    this.popularity = 0,
    this.isFavorite = false,
    this.tags = const [],
  });

  /// Кэш для результатов расчётов
  static final _cache = CalculationCache();

  /// Выполнить расчёт с кэшированием
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    // Попытка получить из кэша
    if (useCache) {
      final cachedValues = _cache.get(id, inputs);
      if (cachedValues != null) {
        // Возвращаем кэшированный результат
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
      name: 'calculator_used_v2',
      parameters: {
        'calculator_id': id,
        'calculator_category': category.name,
        'calculator_subcategory': subCategory,
        'complexity': complexity.toString(),
      },
    );
    } catch (e) {
      // Игнорируем ошибки Firebase, если сервис недоступен
    }

    // Сохраняем в кэш
    if (useCache) {
      _cache.set(id, inputs, result.values);
    }

    return result;
  }

  /// Получить отсортированные поля
  List<CalculatorField> get sortedFields {
    final sorted = List<CalculatorField>.from(fields);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Получить видимые поля с учётом зависимостей
  List<CalculatorField> getVisibleFields(Map<String, double> inputs) {
    return sortedFields.where((field) {
      if (field.dependency == null) return true;
      return field.dependency!.isSatisfied(inputs);
    }).toList();
  }

  /// Получить подсказки перед расчётом
  List<CalculatorHint> getBeforeHints(Map<String, double> inputs) {
    return beforeHints.where((hint) {
      if (hint.condition == null) return true;
      return hint.condition!.isSatisfiedByInputs(inputs);
    }).toList();
  }

  /// Получить подсказки после расчёта
  List<CalculatorHint> getAfterHints(
    Map<String, double> inputs,
    Map<String, double> results,
  ) {
    return afterHints.where((hint) {
      if (hint.condition == null) return true;

      // Проверяем условие на входных данных или результатах
      if (hint.condition!.fieldKey != null) {
        return hint.condition!.isSatisfiedByInputs(inputs);
      } else if (hint.condition!.resultKey != null) {
        return hint.condition!.isSatisfiedByResults(results);
      }

      return true;
    }).toList();
  }

  /// Получить поля по группе
  Map<String, List<CalculatorField>> getFieldsByGroup() {
    final grouped = <String, List<CalculatorField>>{};

    for (final field in sortedFields) {
      final groupName = field.group ?? 'default';
      grouped.putIfAbsent(groupName, () => []);
      grouped[groupName]!.add(field);
    }

    return grouped;
  }

  /// Создать копию с изменениями
  CalculatorDefinitionV2 copyWith({
    String? id,
    String? titleKey,
    String? descriptionKey,
    CalculatorCategory? category,
    String? subCategory,
    List<CalculatorField>? fields,
    List<CalculatorHint>? beforeHints,
    List<CalculatorHint>? afterHints,
    CalculatorUseCase? useCase,
    String? iconName,
    int? accentColor,
    int? complexity,
    int? popularity,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return CalculatorDefinitionV2(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      fields: fields ?? this.fields,
      beforeHints: beforeHints ?? this.beforeHints,
      afterHints: afterHints ?? this.afterHints,
      useCase: useCase ?? this.useCase,
      iconName: iconName ?? this.iconName,
      accentColor: accentColor ?? this.accentColor,
      complexity: complexity ?? this.complexity,
      popularity: popularity ?? this.popularity,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }
}
