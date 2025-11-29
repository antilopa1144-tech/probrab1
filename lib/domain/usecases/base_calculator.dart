import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Базовый класс для всех калькуляторов с общими утилитами.
/// 
/// Предоставляет:
/// - Стандартизированный поиск цен
/// - Валидацию входных данных
/// - Общие вычислительные функции
/// - Обработку ошибок
abstract class BaseCalculator implements CalculatorUseCase {
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
  double safeDivide(double numerator, double denominator, {double defaultValue = 0.0}) {
    if (denominator == 0 || denominator.isNaN || denominator.isInfinite) {
      return defaultValue;
    }
    final result = numerator / denominator;
    if (result.isNaN || result.isInfinite) {
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

  /// Создать результат с автоматическим округлением.
  /// 
  /// Округляет все значения до 2 знаков после запятой для читаемости.
  CalculatorResult createResult({
    required Map<String, double> values,
    double? totalPrice,
    int decimals = 2,
  }) {
    final roundedValues = <String, double>{};
    for (final entry in values.entries) {
      roundedValues[entry.key] = _roundToDecimals(entry.value, decimals);
    }

    return CalculatorResult(
      values: roundedValues,
      totalPrice: totalPrice != null ? _roundToDecimals(totalPrice, decimals) : null,
    );
  }

  /// Округлить число до указанного количества десятичных знаков.
  double _roundToDecimals(double value, int decimals) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final factor = pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }

  /// Валидация входных данных (переопределить в подклассе при необходимости).
  /// 
  /// Возвращает null если данные валидны, иначе сообщение об ошибке.
  String? validateInputs(Map<String, double> inputs) {
    // Базовая реализация - проверка на отрицательные значения
    for (final entry in inputs.entries) {
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
    // Валидация входных данных
    final validationError = validateInputs(inputs);
    if (validationError != null) {
      return createResult(
        values: {'error': 1.0},
        totalPrice: null,
      );
    }

    // Вызов конкретной реализации
    return calculate(inputs, priceList);
  }

  /// Конкретная реализация расчёта (должна быть переопределена в подклассе).
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  );
}
