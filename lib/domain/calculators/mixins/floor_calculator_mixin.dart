import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Миксин для калькуляторов полов.
///
/// Предоставляет общую функциональность для расчёта полов:
/// - Расчёт площади пола
/// - Расчёт количества материалов с учётом запаса
/// - Расчёт стоимости материалов
///
/// ## Пример использования:
///
/// ```dart
/// class CalculateLaminate extends BaseCalculator with FloorCalculatorMixin {
///   @override
///   CalculatorResult calculate(
///     Map<String, double> inputs,
///     List<PriceItem> priceList,
///   ) {
///     final area = getInput(inputs, 'area', minValue: 0.1);
///     final laminateArea = calculateFloorArea(area);
///     final boardsNeeded = calculateBoardsNeeded(laminateArea, 0.2);
///     // ...
///   }
/// }
/// ```
mixin FloorCalculatorMixin on BaseCalculator {
  /// Расчёт площади пола с учётом проёмов.
  ///
  /// - [totalArea]: общая площадь пола (м²)
  /// - [openingsArea]: площадь проёмов (м²), по умолчанию 0
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateFloorArea(
    double totalArea, {
    double openingsArea = 0.0,
    double marginPercent = 10.0,
  }) {
    final usefulArea = calculateUsefulArea(totalArea, doorsArea: openingsArea);
    return addMargin(usefulArea, marginPercent);
  }

  /// Расчёт количества досок/панелей для пола.
  ///
  /// - [area]: площадь покрытия (м²)
  /// - [boardArea]: площадь одной доски/панели (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculateBoardsNeeded(
    double area,
    double boardArea, {
    double marginPercent = 10.0,
  }) {
    return calculateUnitsNeeded(area, boardArea, marginPercent: marginPercent);
  }

  /// Расчёт количества упаковок материала.
  ///
  /// - [totalQuantity]: общее требуемое количество (м² или шт)
  /// - [packageSize]: размер упаковки (м² или шт)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  int calculatePackagesNeeded(
    double totalQuantity,
    double packageSize, {
    double marginPercent = 10.0,
  }) {
    return calculateUnitsNeeded(
      totalQuantity,
      packageSize,
      marginPercent: marginPercent,
    );
  }

  /// Расчёт подложки для пола.
  ///
  /// - [area]: площадь пола (м²)
  /// - [marginPercent]: процент запаса, по умолчанию 10%
  double calculateUnderlaymentArea(double area, {double marginPercent = 10.0}) {
    return addMargin(area, marginPercent);
  }

  /// Расчёт плинтуса для пола.
  ///
  /// - [perimeter]: периметр помещения (м)
  /// - [marginPercent]: процент запаса, по умолчанию 5%
  double calculatePlinthLength(double perimeter, {double marginPercent = 5.0}) {
    if (perimeter <= 0) return 0;
    return addMargin(perimeter, marginPercent);
  }

  /// Расчёт стоимости материалов для пола.
  ///
  /// - [mainMaterialArea]: площадь основного материала (м²)
  /// - [mainMaterialPrice]: цена основного материала за м²
  /// - [underlaymentArea]: площадь подложки (м²)
  /// - [underlaymentPrice]: цена подложки за м²
  /// - [plinthLength]: длина плинтуса (м)
  /// - [plinthPrice]: цена плинтуса за м
  double? calculateFloorCost({
    required double mainMaterialArea,
    double? mainMaterialPrice,
    double underlaymentArea = 0.0,
    double? underlaymentPrice,
    double plinthLength = 0.0,
    double? plinthPrice,
  }) {
    final costs = <double?>[
      calculateCost(mainMaterialArea, mainMaterialPrice),
      if (underlaymentArea > 0)
        calculateCost(underlaymentArea, underlaymentPrice),
      if (plinthLength > 0) calculateCost(plinthLength, plinthPrice),
    ];
    return sumCosts(costs);
  }
}
