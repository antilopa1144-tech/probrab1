import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор листовых материалов (ОСБ/фанера) с крепежом.
///
/// Поля:
/// - area: площадь покрытия (м²)
/// - sheetLength: длина листа (м)
/// - sheetWidth: ширина листа (м)
/// - reserve: запас (%) по умолчанию 10
/// - screwsPerM2: саморезов на м² (шт), по умолчанию 20
class CalculateSheetingOsbPlywood extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final reservePercent =
        getInput(inputs, 'reserve', defaultValue: 10.0, minValue: 0.0, maxValue: 30.0);

    final sheetLength =
        getInput(inputs, 'sheetLength', defaultValue: 2.5, minValue: 1.0, maxValue: 3.6);
    final sheetWidth =
        getInput(inputs, 'sheetWidth', defaultValue: 1.25, minValue: 0.5, maxValue: 1.5);
    final screwsPerM2 =
        getInput(inputs, 'screwsPerM2', defaultValue: 20.0, minValue: 0.0, maxValue: 80.0);

    final materialArea = addMargin(area, reservePercent);
    final sheetArea = sheetLength * sheetWidth;
    final sheetsNeeded = ceilToInt(safeDivide(materialArea, sheetArea));
    final screwsNeeded = ceilToInt(materialArea * screwsPerM2);

    final sheetPrice = findPrice(priceList, ['osb', 'plywood', 'sheet_material']);
    final screwPrice = findPrice(priceList, ['screws', 'screws_wood', 'fasteners']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(screwsNeeded.toDouble(), screwPrice?.price),
    ];

    return createResult(
      values: {
        'materialArea': roundBulk(materialArea),
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
        'reserve': reservePercent,
      },
      totalPrice: sumCosts(costs),
    );
  }
}

