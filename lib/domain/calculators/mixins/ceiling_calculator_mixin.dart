import 'dart:math';
import '../../usecases/base_calculator.dart';

/// Миксин для калькуляторов потолков.
///
/// Предоставляет общую функциональность для расчёта потолков:
/// - Расчёт площади потолка
/// - Расчёт количества материалов
/// - Расчёт стоимости материалов
///
/// ## Пример использования:
///
/// ```dart
/// class CalculateGKL extends BaseCalculator with CeilingCalculatorMixin {
///   @override
///   CalculatorResult calculate(
///     Map<String, double> inputs,
///     List<PriceItem> priceList,
///   ) {
///     final area = getInput(inputs, 'area', minValue: 0.1);
///     final sheetsNeeded = calculateSheetsNeeded(area, 3.0);
///     // ...
///   }
/// }
/// ```
mixin CeilingCalculatorMixin on BaseCalculator {
  /// Расчёт площади потолка.
  ///
  /// - [area]: площадь потолка (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateCeilingArea(double area, {double marginPercent = 10.0}) {
    return addMargin(area, marginPercent);
  }

  /// Расчёт количества листов/панелей для потолка.
  ///
  /// - [area]: площадь потолка (м²)
  /// - [sheetArea]: площадь одного листа (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculateSheetsNeeded(
    double area,
    double sheetArea, {
    double marginPercent = 10.0,
  }) {
    return calculateUnitsNeeded(area, sheetArea, marginPercent: marginPercent);
  }

  /// Расчёт профилей для каркаса потолка.
  ///
  /// - [area]: площадь потолка (м²)
  /// - [profileSpacing]: шаг профилей (м), по умолчанию 0.6
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateProfileLength(
    double area, {
    double profileSpacing = 0.6,
    double marginPercent = 10.0,
  }) {
    if (area <= 0 || profileSpacing <= 0) return 0;
    // Приблизительный расчёт: периметр + поперечные профили
    final perimeter = estimatePerimeter(area);
    final crossProfiles = (sqrt(area) / profileSpacing).ceil() * sqrt(area);
    final totalLength = perimeter + crossProfiles;
    return addMargin(totalLength, marginPercent);
  }

  /// Расчёт количества подвесов для потолка.
  ///
  /// - [area]: площадь потолка (м²)
  /// - [suspensionSpacing]: шаг подвесов (м), по умолчанию 0.6
  int calculateSuspensionsNeeded(
    double area, {
    double suspensionSpacing = 0.6,
  }) {
    if (area <= 0 || suspensionSpacing <= 0) return 0;
    // Количество подвесов = площадь / (шаг²)
    final count = (area / (suspensionSpacing * suspensionSpacing)).ceil();
    return count;
  }

  /// Расчёт количества саморезов для крепления.
  ///
  /// - [sheetsNeeded]: количество листов
  /// - [screwsPerSheet]: саморезов на лист, по умолчанию 25
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculateScrewsNeeded(
    int sheetsNeeded, {
    int screwsPerSheet = 25,
    double marginPercent = 10.0,
  }) {
    final total = sheetsNeeded * screwsPerSheet;
    return addMargin(total.toDouble(), marginPercent).ceil();
  }

  /// Расчёт стоимости материалов для потолка.
  ///
  /// - [sheetsArea]: площадь листов (м²)
  /// - [sheetPrice]: цена листа за м²
  /// - [profileLength]: длина профилей (м)
  /// - [profilePrice]: цена профиля за м
  /// - [suspensionsCount]: количество подвесов
  /// - [suspensionPrice]: цена подвеса
  /// - [screwsCount]: количество саморезов
  /// - [screwPrice]: цена самореза
  double? calculateCeilingCost({
    required double sheetsArea,
    double? sheetPrice,
    double profileLength = 0.0,
    double? profilePrice,
    int suspensionsCount = 0,
    double? suspensionPrice,
    int screwsCount = 0,
    double? screwPrice,
  }) {
    final costs = <double?>[
      calculateCost(sheetsArea, sheetPrice),
      if (profileLength > 0) calculateCost(profileLength, profilePrice),
      if (suspensionsCount > 0)
        calculateCost(suspensionsCount.toDouble(), suspensionPrice),
      if (screwsCount > 0) calculateCost(screwsCount.toDouble(), screwPrice),
    ];
    return sumCosts(costs);
  }
}
