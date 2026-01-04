// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import '../models/calculator_constant.dart';
import './calculator_usecase.dart';
import '../../core/exceptions/calculation_exception.dart';

/// Базовый класс для всех калькуляторов с общими утилитами.
///
/// Этот класс предоставляет общую функциональность для всех калькуляторов,
/// что позволяет избежать дублирования кода и обеспечить единообразие.
///
/// ## Основные возможности:
///
/// ### 1. Поиск цен
/// - `findPrice(List<PriceItem> priceList, List<String> skus)` - поиск цены по SKU
///
/// ### 2. Валидация входных данных
/// - `validateInputs(Map<String, double> inputs)` - базовая валидация (можно переопределить)
/// - `getInput(...)` - безопасное получение значения с ограничениями
/// - `getIntInput(...)` - получение целочисленного значения
///
/// ### 3. Математические утилиты
/// - `safeDivide(...)` - безопасное деление с проверкой на ноль и переполнение
/// - `calculateVolume(...)` - расчёт объёма по площади и толщине
/// - `addMargin(...)` - добавление процентного запаса
/// - `calculateUnitsNeeded(...)` - расчёт количества единиц с запасом
/// - `calculateTileArea(...)` - расчёт площади плитки/панели
///
/// ### 4. Обработка ошибок
/// - Автоматическая обёртка неожиданных ошибок в `CalculationException`
/// - Проверка на переполнение и некорректные значения в `createResult`
/// - Валидация входных данных с выбрасыванием исключений
///
/// ## Пример создания калькулятора:
///
/// ```dart
/// class CalculatePlaster extends BaseCalculator {
///   @override
///   CalculatorResult calculate(
///     Map<String, double> inputs,
///     List<PriceItem> priceList,
///   ) {
///     final area = getInput(inputs, 'area', minValue: 0.1);
///     final thickness = getInput(inputs, 'thickness', defaultValue: 10.0);
///
///     final volume = calculateVolume(area, thickness);
///     final plasterNeeded = addMargin(volume, 10.0);
///
///     final price = findPrice(priceList, ['plaster', 'gypsum_plaster']);
///     final totalPrice = calculateCost(plasterNeeded, price?.price);
///
///     return createResult(
///       values: {'plasterNeeded': plasterNeeded, 'volume': volume},
///       totalPrice: totalPrice,
///     );
///   }
/// }
/// ```
///
/// ## Обработка ошибок:
///
/// Класс автоматически:
/// - Валидирует входные данные через `validateInputs()`
/// - Оборачивает ошибки в `CalculationException`
/// - Проверяет результаты на переполнение в `createResult()`
///
/// Если нужно кастомное поведение, переопределите `validateInputs()` или
/// используйте `safeDivide(..., throwOnZero: true)` для явной обработки ошибок.
abstract class BaseCalculator implements CalculatorUseCase {
  Map<String, double>? _lastInputs;
  CalculatorResult? _lastResult;

  /// Константы калькулятора (загружаются из Remote Config или локальных JSON файлов).
  ///
  /// Устанавливаются перед вызовом calculate().
  /// Если null, используются дефолтные значения в методах getConstant*.
  ///
  /// Пример использования:
  /// ```dart
  /// calculator.constants = await constantsRepository.getConstants('warmfloor');
  /// final result = calculator.calculate(inputs, prices);
  /// ```
  CalculatorConstants? constants;

  /// Современные нормативы по умолчанию для всех расчётов.
  ///
  /// Используется для соответствия актуальным требованиям (ГЭСН/ФЕР).
  List<String> get normativeSources => const ['ГЭСН-2024', 'ФЕР-2022'];

  /// Поиск цены по списку возможных SKU.
  /// 
  /// Возвращает первый найденный PriceItem или null.
  PriceItem? findPrice(List<PriceItem> priceList, List<String> skus) {
    for (final sku in skus) {
      try {
        return priceList.firstWhere((item) => item.sku == sku);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Получить входное значение с валидацией и значением по умолчанию.
  /// 
  /// - [inputs]: карта входных данных
  /// - [key]: ключ параметра
  /// - [defaultValue]: значение по умолчанию
  /// - [minValue]: минимальное допустимое значение (null = без ограничения)
  /// - [maxValue]: максимальное допустимое значение (null = без ограничения)
  double getInput(
    Map<String, double> inputs,
    String key, {
    double defaultValue = 0.0,
    double? minValue,
    double? maxValue,
  }) {
    var value = inputs[key] ?? defaultValue;
    
    // Применяем ограничения
    if (minValue != null && value < minValue) {
      value = minValue;
    }
    if (maxValue != null && value > maxValue) {
      value = maxValue;
    }
    
    return value;
  }

  /// Получить целочисленное входное значение.
  int getIntInput(
    Map<String, double> inputs,
    String key, {
    int defaultValue = 0,
    int? minValue,
    int? maxValue,
  }) {
    var value = (inputs[key] ?? defaultValue.toDouble()).round();
    
    if (minValue != null && value < minValue) {
      value = minValue;
    }
    if (maxValue != null && value > maxValue) {
      value = maxValue;
    }
    
    return value;
  }

  /// Вычислить периметр квадратной/прямоугольной комнаты по площади.
  /// 
  /// Используется когда периметр не указан явно.
  /// Предполагается квадратная комната как приближение.
  double estimatePerimeter(double area) {
    if (area <= 0) return 0;
    return 4 * sqrt(area);
  }

  /// Вычислить объём по площади и толщине.
  /// 
  /// - [area]: площадь в м²
  /// - [thickness]: толщина в мм
  /// - Результат в м³
  double calculateVolume(double area, double thickness) {
    if (area <= 0 || thickness <= 0) return 0;
    return area * (thickness / 1000);
  }

  /// Добавить процентный запас к количеству.
  /// 
  /// - [quantity]: исходное количество
  /// - [percent]: процент запаса (10 = 10%)
  double addMargin(double quantity, double percent) {
    if (quantity <= 0) return 0;
    return quantity * (1 + percent / 100);
  }

  /// Округлить вверх до целого (для упаковок, листов и т.п.).
  int ceilToInt(double value) {
    if (value <= 0) return 0;
    return value.ceil();
  }

  /// Безопасное деление с проверкой на ноль.
  /// 
  /// Выбрасывает CalculationException при делении на ноль, если [throwOnZero] = true.
  double safeDivide(
    double numerator,
    double denominator, {
    double defaultValue = 0.0,
    bool throwOnZero = false,
    String? context,
  }) {
    if (denominator == 0 || denominator.isNaN || denominator.isInfinite) {
      if (throwOnZero && denominator == 0) {
        throw CalculationException.divisionByZero(
          context ?? 'safeDivide($numerator, $denominator)',
        );
      }
      return defaultValue;
    }
    final result = numerator / denominator;
    if (result.isNaN || result.isInfinite) {
      if (throwOnZero) {
        throw CalculationException.overflow(
          context ?? 'safeDivide($numerator, $denominator) = $result',
        );
      }
      return defaultValue;
    }
    return result;
  }

  /// Вычислить полезную площадь (за вычетом проёмов).
  /// 
  /// - [totalArea]: общая площадь
  /// - [windowsArea]: площадь окон
  /// - [doorsArea]: площадь дверей
  double calculateUsefulArea(
    double totalArea, {
    double windowsArea = 0.0,
    double doorsArea = 0.0,
  }) {
    final useful = totalArea - windowsArea - doorsArea;
    return useful < 0 ? 0 : useful;
  }

  /// Вычислить количество единиц с учётом запаса.
  /// 
  /// - [totalQuantity]: общее требуемое количество
  /// - [unitSize]: размер одной единицы
  /// - [marginPercent]: процент запаса (по умолчанию 10%)
  int calculateUnitsNeeded(
    double totalQuantity,
    double unitSize, {
    double marginPercent = 10.0,
  }) {
    if (totalQuantity <= 0 || unitSize <= 0) return 0;
    final withMargin = addMargin(totalQuantity, marginPercent);
    return ceilToInt(withMargin / unitSize);
  }

  /// Вычислить площадь прямоугольника.
  double calculateRectangleArea(double width, double height) {
    if (width <= 0 || height <= 0) return 0;
    return width * height;
  }

  /// Вычислить площадь плитки/панели в м².
  /// 
  /// - [width]: ширина в см
  /// - [height]: высота в см
  double calculateTileArea(double width, double height) {
    if (width <= 0 || height <= 0) return 0;
    return (width / 100) * (height / 100);
  }

  /// Преобразовать см в метры.
  double cmToMeters(double cm) => cm / 100;

  /// Преобразовать мм в метры.
  double mmToMeters(double mm) => mm / 1000;

  /// Вычислить стоимость с учётом количества и цены.
  double? calculateCost(double? quantity, double? price) {
    if (quantity == null || price == null) return null;
    if (quantity <= 0 || price <= 0) return null;
    return quantity * price;
  }

  /// Суммировать стоимости (игнорируя null).
  double? sumCosts(List<double?> costs) {
    final nonNullCosts = costs.where((c) => c != null).cast<double>().toList();
    if (nonNullCosts.isEmpty) return null;
    return nonNullCosts.reduce((a, b) => a + b);
  }

  /// Округлить объёмные материалы (краска, стяжка и т.п.).
  ///
  /// Правила:
  /// - < 1: округляем до 1 знака (0.1, 0.5 л)
  /// - 1-10: округляем до 0.5 (5.5, 6.0 л)
  /// - 10-100: округляем до целых (15, 27 л)
  /// - > 100: округляем до 5 (105, 150 л)
  double roundBulk(double value) {
    if (value <= 0) return 0;
    if (value < 1) {
      return (value * 10).ceil() / 10; // 0.1, 0.2, 0.3...
    } else if (value < 10) {
      return (value * 2).ceil() / 2; // 0.5, 1.0, 1.5...
    } else if (value < 100) {
      return value.ceil().toDouble(); // 11, 12, 13...
    } else {
      return (value / 5).ceil() * 5.0; // 105, 110, 115...
    }
  }

  /// Создать результат с автоматическим округлением.
  /// 
  /// Округляет все значения до 2 знаков после запятой для читаемости.
  /// Проверяет на переполнение и некорректные значения.
  CalculatorResult createResult({
    required Map<String, double> values,
    double? totalPrice,
    int decimals = 2,
    String? calculatorId,
    List<String>? norms,
  }) {
    final roundedValues = <String, double>{};
    
    for (final entry in values.entries) {
      final value = entry.value;
      
      // Проверка на переполнение
      if (value.isInfinite || value.isNaN) {
        throw CalculationException.overflow(
          'Значение ${entry.key} = $value в калькуляторе ${calculatorId ?? "unknown"}',
        );
      }
      
      // Проверка на разумные пределы (предотвращение ошибок ввода)
      if (value.abs() > 1e10) {
        throw CalculationException.custom(
          'Значение ${entry.key} слишком большое: $value',
          calculatorId: calculatorId,
        );
      }
      
      roundedValues[entry.key] = _roundToDecimals(value, decimals);
    }

    double? roundedPrice;
    if (totalPrice != null) {
      if (totalPrice.isInfinite || totalPrice.isNaN) {
        throw CalculationException.overflow(
          'Итоговая стоимость некорректна: $totalPrice',
        );
      }
      if (totalPrice.abs() > 1e10) {
        throw CalculationException.custom(
          'Итоговая стоимость слишком большая: $totalPrice',
          calculatorId: calculatorId,
        );
      }
      roundedPrice = _roundToDecimals(totalPrice, decimals);
    }

    return CalculatorResult(
      values: roundedValues,
      totalPrice: roundedPrice,
      norms: norms ?? normativeSources,
    );
  }

  /// Округлить число до указанного количества десятичных знаков.
  double _roundToDecimals(double value, int decimals) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final factor = pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }

  // ============================================================================
  // Методы работы с константами калькулятора
  // ============================================================================

  /// Получить числовое значение константы (double).
  ///
  /// Использует fallback стратегию:
  /// 1. Значение из загруженных констант (constants)
  /// 2. Дефолтное значение (defaultValue)
  ///
  /// Параметры:
  /// - [constantKey]: ключ константы (например, 'room_power')
  /// - [valueKey]: ключ значения (например, 'bathroom')
  /// - [defaultValue]: значение по умолчанию (обязательно для backward compatibility)
  ///
  /// Пример:
  /// ```dart
  /// final bathroomPower = getConstantDouble(
  ///   'room_power',
  ///   'bathroom',
  ///   defaultValue: 180.0, // Hardcoded fallback
  /// );
  /// ```
  double getConstantDouble(
    String constantKey,
    String valueKey, {
    required double defaultValue,
  }) {
    // Если константы не загружены, используем default
    if (constants == null) return defaultValue;

    final constant = constants!.constants[constantKey];
    if (constant == null) return defaultValue;

    final value = constant.values[valueKey];
    if (value == null) return defaultValue;

    // Автоматическая конверсия типов
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return defaultValue;
  }

  /// Получить целочисленное значение константы (int).
  ///
  /// Использует fallback стратегию:
  /// 1. Значение из загруженных констант (constants)
  /// 2. Дефолтное значение (defaultValue)
  ///
  /// Параметры:
  /// - [constantKey]: ключ константы
  /// - [valueKey]: ключ значения
  /// - [defaultValue]: значение по умолчанию
  ///
  /// Пример:
  /// ```dart
  /// final minSocketsPerRoom = getConstantInt(
  ///   'socket_calculation',
  ///   'min_per_room',
  ///   defaultValue: 3,
  /// );
  /// ```
  int getConstantInt(
    String constantKey,
    String valueKey, {
    required int defaultValue,
  }) {
    if (constants == null) return defaultValue;

    final constant = constants!.constants[constantKey];
    if (constant == null) return defaultValue;

    final value = constant.values[valueKey];
    if (value == null) return defaultValue;

    // Автоматическая конверсия типов
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    return defaultValue;
  }

  /// Получить строковое значение константы.
  ///
  /// Параметры:
  /// - [constantKey]: ключ константы
  /// - [valueKey]: ключ значения
  /// - [defaultValue]: значение по умолчанию
  ///
  /// Пример:
  /// ```dart
  /// final unit = getConstantString(
  ///   'measurements',
  ///   'power_unit',
  ///   defaultValue: 'Вт/м²',
  /// );
  /// ```
  String getConstantString(
    String constantKey,
    String valueKey, {
    required String defaultValue,
  }) {
    if (constants == null) return defaultValue;

    final constant = constants!.constants[constantKey];
    if (constant == null) return defaultValue;

    final value = constant.values[valueKey];
    if (value == null) return defaultValue;

    if (value is String) return value;
    return value.toString();
  }

  /// Получить Map значений константы.
  ///
  /// Полезно для констант, которые содержат несколько связанных значений.
  ///
  /// Параметры:
  /// - [constantKey]: ключ константы
  /// - [defaultValue]: Map по умолчанию
  ///
  /// Пример:
  /// ```dart
  /// final roomPowers = getConstantMap(
  ///   'room_power',
  ///   defaultValue: {
  ///     'bathroom': 180.0,
  ///     'living_room': 150.0,
  ///   },
  /// );
  /// final bathroomPower = roomPowers['bathroom'] as double? ?? 180.0;
  /// ```
  Map<String, dynamic> getConstantMap(
    String constantKey, {
    Map<String, dynamic>? defaultValue,
  }) {
    if (constants == null) return defaultValue ?? {};

    final constant = constants!.constants[constantKey];
    if (constant == null) return defaultValue ?? {};

    return constant.values;
  }

  /// Получить коэффициент (числовое значение из категории coefficients).
  ///
  /// Shortcut для getConstantDouble с семантикой коэффициента.
  ///
  /// Пример:
  /// ```dart
  /// final multiplier = getCoefficient(
  ///   'room_type_multipliers',
  ///   'apartment',
  ///   defaultValue: 1.0,
  /// );
  /// ```
  double getCoefficient(
    String constantKey,
    String valueKey, {
    required double defaultValue,
  }) {
    return getConstantDouble(constantKey, valueKey, defaultValue: defaultValue);
  }

  /// Получить процент запаса (из категории margins).
  ///
  /// Shortcut для getConstantDouble с семантикой процентного запаса.
  ///
  /// Пример:
  /// ```dart
  /// final cableMargin = getMarginPercent(
  ///   'cable_margins',
  ///   'standard_margin',
  ///   defaultValue: 15.0,
  /// );
  /// // Использование:
  /// final totalCable = addMargin(baseCable, cableMargin);
  /// ```
  double getMarginPercent(
    String constantKey,
    String valueKey, {
    required double defaultValue,
  }) {
    return getConstantDouble(constantKey, valueKey, defaultValue: defaultValue);
  }

  /// Проверить, загружены ли константы калькулятора.
  ///
  /// Возвращает true если константы доступны, false если используются defaults.
  bool get hasConstants => constants != null;

  /// Получить версию загруженных констант.
  ///
  /// Возвращает версию констант или null если константы не загружены.
  String? get constantsVersion => constants?.version;

  /// Получить источник констант для отладки.
  ///
  /// Возвращает строку с информацией о константах.
  String get constantsInfo {
    if (constants == null) {
      return 'Using hardcoded defaults';
    }
    return 'Constants v${constants!.version} (${constants!.constants.length} items)';
  }

  // ============================================================================
  // Конец методов работы с константами
  // ============================================================================

  /// Валидация входных данных (переопределить в подклассе при необходимости).
  /// 
  /// Возвращает null если данные валидны, иначе сообщение об ошибке.
  String? validateInputs(Map<String, double> inputs) {
    // Базовая реализация - проверка на отрицательные значения
    for (final entry in inputs.entries) {
      if (entry.value.isNaN || entry.value.isInfinite) {
        return 'Значение ${entry.key} некорректно';
      }
      if (entry.value < 0) {
        return 'Значение ${entry.key} не может быть отрицательным';
      }
    }
    return null;
  }

  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    try {
      // Валидация входных данных
      final validationError = validateInputs(inputs);
      if (validationError != null) {
        throw CalculationException.invalidInput(
          runtimeType.toString(),
          validationError,
        );
      }

      if (_lastResult != null && _areInputsEqual(inputs, _lastInputs)) {
        return _lastResult!;
      }

      // Вызов конкретной реализации
      final result = calculate(inputs, priceList);
      _lastInputs = Map<String, double>.from(inputs);
      _lastResult = result;
      return result;
    } on CalculationException {
      // Пробрасываем CalculationException дальше
      rethrow;
    } catch (e, stackTrace) {
      // Оборачиваем неожиданные ошибки в CalculationException
      throw CalculationException(
        'Неожиданная ошибка в калькуляторе ${runtimeType.toString()}: $e',
        code: 'UNEXPECTED_ERROR',
        details: stackTrace.toString(),
      );
    }
  }

  void invalidateCache() {
    _lastInputs = null;
    _lastResult = null;
  }

  bool _areInputsEqual(Map<String, double> a, Map<String, double>? b) {
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  /// Конкретная реализация расчёта (должна быть переопределена в подклассе).
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  );
}
