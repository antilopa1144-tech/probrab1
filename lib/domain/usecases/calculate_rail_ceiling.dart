import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор реечного потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - railWidth: ширина рейки (см), по умолчанию 10
/// - railLength: длина рейки (см), по умолчанию 300
/// - perimeter: периметр комнаты (м), опционально
class CalculateRailCeiling extends BaseCalculator {
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
    final railWidth = getInput(inputs, 'railWidth', defaultValue: 10.0, minValue: 5.0, maxValue: 20.0);
    final railLength = getInput(inputs, 'railLength', defaultValue: 300.0, minValue: 200.0, maxValue: 400.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной рейки в м²
    final railArea = calculateTileArea(railWidth, railLength);

    // Количество реек с запасом 5%
    final railsNeeded = calculateUnitsNeeded(area, railArea, marginPercent: 5.0);

    // Направляющие (траверсы, гребенки): по длине комнаты с шагом 120 см
    final guideCount = ceilToInt((perimeter / 4) / 1.2); // примерно
    final guideLength = guideCount * (perimeter / 4);

    // Подвесы: шаг 60-80 см вдоль направляющих
    final hangersNeeded = ceilToInt(perimeter / 0.6);

    // П-образный профиль (периметр): по периметру комнаты + 3%
    final cornerLength = perimeter;

    // Декоративные вставки (между рейками): зависит от типа
    final insertsLength = railsNeeded * (railLength / 100);

    // Расчёт стоимости
    final railPrice = findPrice(priceList, ['rail_ceiling', 'ceiling_rail', 'rail_panel']);
    final guidePrice = findPrice(priceList, ['guide_rail', 'rail_guide', 'stringer']);
    final hangerPrice = findPrice(priceList, ['hanger_rail', 'hanger', 'suspension']);
    final cornerPrice = findPrice(priceList, ['corner_rail', 'corner', 'trim_angle']);
    final insertPrice = findPrice(priceList, ['insert', 'decorative_insert']);

    final costs = [
      calculateCost(railsNeeded.toDouble(), railPrice?.price),
      calculateCost(guideLength, guidePrice?.price),
      calculateCost(hangersNeeded.toDouble(), hangerPrice?.price),
      calculateCost(cornerLength, cornerPrice?.price),
      calculateCost(insertsLength, insertPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'railsNeeded': railsNeeded.toDouble(),
        'guideLength': guideLength,
        'hangersNeeded': hangersNeeded.toDouble(),
        'cornerLength': cornerLength,
        'insertsLength': insertsLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
