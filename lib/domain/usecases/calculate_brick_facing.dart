// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор облицовочного кирпича.
///
/// Нормативы:
/// - СНиП 3.03.01-87 "Несущие и ограждающие конструкции"
/// - ГОСТ 530-2012 "Кирпич и камень керамические"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - thickness: толщина стены (кирпичей), по умолчанию 0.5 (полкирпича)
/// - windowsArea: площадь окон (м²), опционально
/// - doorsArea: площадь дверей (м²), опционально
class CalculateBrickFacing extends BaseCalculator {
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
    final thickness = getInput(inputs, 'thickness', defaultValue: 0.5, minValue: 0.5, maxValue: 1.0);
    final windowsArea = getInput(inputs, 'windowsArea', defaultValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', defaultValue: 0.0);

    // Полезная площадь (за вычетом проёмов)
    final usefulArea = safeDivide(area - windowsArea - doorsArea, 1.0, defaultValue: area);

    // Количество кирпичей на 1 м² (для облицовки полкирпича)
    final bricksPerM2 = thickness == 0.5 ? 61.5 : 128.0;

    // Количество кирпичей с запасом 5%
    final bricksNeeded = calculateUnitsNeeded(usefulArea, 1.0 / bricksPerM2, marginPercent: 5.0);

    // Раствор: ~0.02 м³ на 1 м² для полкирпича
    final mortarPerM2 = 0.02 * thickness;
    final mortarVolume = usefulArea * mortarPerM2 * 1.05;

    // Цемент и песок для раствора (пропорция 1:3-4)
    final cementNeeded = mortarVolume * 375; // кг
    final sandNeeded = mortarVolume * 1.5; // м³

    // Армирующая сетка: каждые 4-5 рядов
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.5);
    final rows = ceilToInt(wallHeight / 0.065); // высота кирпича 65 мм
    final reinforcementRows = ceilToInt(rows / 5);
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final reinforcementLength = reinforcementRows * perimeter;

    // Гибкие связи (для крепления к основной стене): ~4 шт/м²
    final flexibleTiesNeeded = ceilToInt(usefulArea * 4);

    // Расчёт стоимости
    final brickPrice = findPrice(priceList, ['brick_facing', 'brick_red', 'brick_ceramic', 'facing_brick']);
    final cementPrice = findPrice(priceList, ['cement', 'cement_bag', 'portland_cement']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final reinforcementPrice = findPrice(priceList, ['rebar', 'rebar_4mm', 'mesh']);
    final flexibleTiesPrice = findPrice(priceList, ['tie_flexible', 'wall_tie']);

    final costs = [
      calculateCost(bricksNeeded.toDouble(), brickPrice?.price),
      calculateCost(cementNeeded / 50, cementPrice?.price),
      calculateCost(sandNeeded, sandPrice?.price),
      calculateCost(reinforcementLength, reinforcementPrice?.price),
      calculateCost(flexibleTiesNeeded.toDouble(), flexibleTiesPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'bricksNeeded': bricksNeeded.toDouble(),
        'mortarVolume': mortarVolume,
        'cementNeeded': cementNeeded,
        'sandNeeded': sandNeeded,
        'reinforcementLength': reinforcementLength,
        'flexibleTiesNeeded': flexibleTiesNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
