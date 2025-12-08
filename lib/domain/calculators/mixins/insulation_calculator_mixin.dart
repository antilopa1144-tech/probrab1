import '../../usecases/base_calculator.dart';

/// Миксин для калькуляторов утепления.
///
/// Предоставляет общую функциональность для расчёта утепления:
/// - Расчёт объёма утеплителя
/// - Расчёт количества листов/плит
/// - Расчёт пароизоляции и гидроизоляции
/// - Расчёт крепежа
///
/// ## Пример использования:
///
/// ```dart
/// class CalculateWallInsulation extends BaseCalculator with InsulationCalculatorMixin {
///   @override
///   CalculatorResult calculate(
///     Map<String, double> inputs,
///     List<PriceItem> priceList,
///   ) {
///     final area = getInput(inputs, 'area', minValue: 0.1);
///     final thickness = getInput(inputs, 'thickness', defaultValue: 100.0);
///     final volume = calculateInsulationVolume(area, thickness);
///     // ...
///   }
/// }
/// ```
mixin InsulationCalculatorMixin on BaseCalculator {
  /// Расчёт объёма утеплителя.
  ///
  /// - [area]: площадь утепления (м²)
  /// - [thickness]: толщина утеплителя (мм)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateInsulationVolume(
    double area,
    double thickness, {
    double marginPercent = 10.0,
  }) {
    final volume = calculateVolume(area, thickness);
    return addMargin(volume, marginPercent);
  }

  /// Расчёт количества листов/плит утеплителя.
  ///
  /// - [area]: площадь утепления (м²)
  /// - [sheetArea]: площадь одного листа (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculateInsulationSheetsNeeded(
    double area,
    double sheetArea, {
    double marginPercent = 10.0,
  }) {
    return calculateUnitsNeeded(area, sheetArea, marginPercent: marginPercent);
  }

  /// Расчёт площади пароизоляции.
  ///
  /// - [area]: площадь утепления (м²)
  /// - [marginPercent]: процент запаса на нахлёст, по умолчанию 15%
  double calculateVaporBarrierArea(double area, {double marginPercent = 15.0}) {
    return addMargin(area, marginPercent);
  }

  /// Расчёт площади гидроизоляции.
  ///
  /// - [area]: площадь утепления (м²)
  /// - [marginPercent]: процент запаса на нахлёст, по умолчанию 15%
  double calculateWaterproofingArea(
    double area, {
    double marginPercent = 15.0,
  }) {
    return addMargin(area, marginPercent);
  }

  /// Расчёт количества крепежа (дюбелей-грибков).
  ///
  /// - [area]: площадь утепления (м²)
  /// - [fastenerSpacing]: шаг крепежа (м), по умолчанию 0.5
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculateFastenersNeeded(
    double area, {
    double fastenerSpacing = 0.5,
    double marginPercent = 10.0,
  }) {
    if (area <= 0 || fastenerSpacing <= 0) return 0;
    // Количество крепежа = площадь / (шаг²)
    final count = (area / (fastenerSpacing * fastenerSpacing)).ceil();
    return addMargin(count.toDouble(), marginPercent).ceil();
  }

  /// Расчёт длины монтажной ленты.
  ///
  /// - [area]: площадь утепления (м²)
  /// - [tapePerM2]: метры ленты на м², по умолчанию 2.0
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateTapeLength(
    double area, {
    double tapePerM2 = 2.0,
    double marginPercent = 10.0,
  }) {
    if (area <= 0) return 0;
    final length = area * tapePerM2;
    return addMargin(length, marginPercent);
  }

  /// Расчёт веса утеплителя.
  ///
  /// - [volume]: объём утеплителя (м³)
  /// - [density]: плотность утеплителя (кг/м³)
  double calculateInsulationWeight(double volume, double density) {
    if (volume <= 0 || density <= 0) return 0;
    return volume * density;
  }

  /// Расчёт стоимости материалов для утепления.
  ///
  /// - [insulationVolume]: объём утеплителя (м³)
  /// - [insulationPrice]: цена утеплителя за м³
  /// - [vaporBarrierArea]: площадь пароизоляции (м²)
  /// - [vaporBarrierPrice]: цена пароизоляции за м²
  /// - [waterproofingArea]: площадь гидроизоляции (м²)
  /// - [waterproofingPrice]: цена гидроизоляции за м²
  /// - [fastenersCount]: количество крепежа
  /// - [fastenerPrice]: цена крепежа
  /// - [tapeLength]: длина ленты (м)
  /// - [tapePrice]: цена ленты за м
  double? calculateInsulationCost({
    required double insulationVolume,
    double? insulationPrice,
    double vaporBarrierArea = 0.0,
    double? vaporBarrierPrice,
    double waterproofingArea = 0.0,
    double? waterproofingPrice,
    int fastenersCount = 0,
    double? fastenerPrice,
    double tapeLength = 0.0,
    double? tapePrice,
  }) {
    final costs = <double?>[
      calculateCost(insulationVolume, insulationPrice),
      if (vaporBarrierArea > 0)
        calculateCost(vaporBarrierArea, vaporBarrierPrice),
      if (waterproofingArea > 0)
        calculateCost(waterproofingArea, waterproofingPrice),
      if (fastenersCount > 0)
        calculateCost(fastenersCount.toDouble(), fastenerPrice),
      if (tapeLength > 0) calculateCost(tapeLength, tapePrice),
    ];
    return sumCosts(costs);
  }
}
