import '../../usecases/base_calculator.dart';

/// Миксин для калькуляторов стен.
///
/// Предоставляет общую функциональность для расчёта стен:
/// - Расчёт площади стен с учётом проёмов
/// - Расчёт количества материалов
/// - Расчёт стоимости материалов
///
/// ## Пример использования:
///
/// ```dart
/// class CalculateWallPaint extends BaseCalculator with WallCalculatorMixin {
///   @override
///   CalculatorResult calculate(
///     Map<String, double> inputs,
///     List<PriceItem> priceList,
///   ) {
///     final area = getInput(inputs, 'area', minValue: 0.1);
///     final usefulArea = calculateWallArea(area, windowsArea: 5.0);
///     // ...
///   }
/// }
/// ```
mixin WallCalculatorMixin on BaseCalculator {
  /// Расчёт площади стен с учётом проёмов.
  ///
  /// - [totalArea]: общая площадь стен (м²)
  /// - [windowsArea]: площадь окон (м²), по умолчанию 0
  /// - [doorsArea]: площадь дверей (м²), по умолчанию 0
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateWallArea(
    double totalArea, {
    double windowsArea = 0.0,
    double doorsArea = 0.0,
    double marginPercent = 10.0,
  }) {
    final usefulArea = calculateUsefulArea(
      totalArea,
      windowsArea: windowsArea,
      doorsArea: doorsArea,
    );
    return addMargin(usefulArea, marginPercent);
  }

  /// Расчёт количества рулонов обоев.
  ///
  /// - [area]: площадь стен (м²)
  /// - [rollArea]: площадь одного рулона (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 15%
  int calculateRollsNeeded(
    double area,
    double rollArea, {
    double marginPercent = 15.0,
  }) {
    return calculateUnitsNeeded(area, rollArea, marginPercent: marginPercent);
  }

  /// Расчёт количества банок краски.
  ///
  /// - [area]: площадь стен (м²)
  /// - [coverage]: покрытие одной банки (м²/л)
  /// - [layers]: количество слоёв, по умолчанию 2
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculatePaintNeeded(
    double area,
    double coverage, {
    int layers = 2,
    double marginPercent = 10.0,
  }) {
    if (area <= 0 || coverage <= 0) return 0;
    final totalArea = area * layers;
    final needed = totalArea / coverage;
    return addMargin(needed, marginPercent);
  }

  /// Расчёт количества плитки для стен.
  ///
  /// - [area]: площадь стен (м²)
  /// - [tileArea]: площадь одной плитки (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculateTilesNeeded(
    double area,
    double tileArea, {
    double marginPercent = 10.0,
  }) {
    return calculateUnitsNeeded(area, tileArea, marginPercent: marginPercent);
  }

  /// Расчёт количества штукатурки.
  ///
  /// - [area]: площадь стен (м²)
  /// - [thickness]: толщина слоя (мм)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculatePlasterNeeded(
    double area,
    double thickness, {
    double marginPercent = 10.0,
  }) {
    final volume = calculateVolume(area, thickness);
    return addMargin(volume, marginPercent);
  }

  /// Расчёт стоимости материалов для стен.
  ///
  /// - [mainMaterialArea]: площадь основного материала (м²)
  /// - [mainMaterialPrice]: цена основного материала за м²
  /// - [primerArea]: площадь грунтовки (м²)
  /// - [primerPrice]: цена грунтовки за м²
  /// - [adhesiveArea]: площадь клея (м²)
  /// - [adhesivePrice]: цена клея за м²
  double? calculateWallCost({
    required double mainMaterialArea,
    double? mainMaterialPrice,
    double primerArea = 0.0,
    double? primerPrice,
    double adhesiveArea = 0.0,
    double? adhesivePrice,
  }) {
    final costs = <double?>[
      calculateCost(mainMaterialArea, mainMaterialPrice),
      if (primerArea > 0) calculateCost(primerArea, primerPrice),
      if (adhesiveArea > 0) calculateCost(adhesiveArea, adhesivePrice),
    ];
    return sumCosts(costs);
  }
}
