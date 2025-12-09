// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ковролина.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - rollWidth: ширина рулона (м), по умолчанию 4.0
/// - rollLength: длина рулона (м), по умолчанию 25.0
/// - perimeter: периметр комнаты (м), опционально
class CalculateCarpet extends BaseCalculator {
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
    final rollWidth = getInput(inputs, 'rollWidth', defaultValue: 4.0, minValue: 2.0, maxValue: 5.0);
    final rollLength = getInput(inputs, 'rollLength', defaultValue: 25.0, minValue: 10.0, maxValue: 50.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь рулона
    final rollArea = rollWidth * rollLength;

    // Количество рулонов с запасом 10%
    final rollsNeeded = calculateUnitsNeeded(area, rollArea, marginPercent: 10.0);

    // Плинтус: периметр + 5%
    final plinthLength = addMargin(perimeter, 5.0);

    // Клей для ковролина: ~0.5-0.7 кг/м² (для больших площадей)
    final glueNeeded = area * 0.6;

    // Двухсторонний скотч (альтернатива): периметр + диагонали (20%)
    final tapeNeeded = perimeter * 1.2;

    // Подложка для ковролина: площадь пола + 5%
    final underlayArea = addMargin(area, 5.0);

    // Грипперные рейки (для натяжного способа): периметр
    final gripperLength = perimeter;

    // Стыковочные планки для порогов: обычно 1-2 шт
    final thresholdsNeeded = getIntInput(inputs, 'thresholds', defaultValue: 1, minValue: 0, maxValue: 10);

    // Расчёт стоимости
    final carpetPrice = findPrice(priceList, ['carpet', 'carpet_roll', 'carpeting']);
    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_carpet', 'baseboard']);
    final gluePrice = findPrice(priceList, ['glue_carpet', 'glue', 'carpet_adhesive']);
    final tapePrice = findPrice(priceList, ['tape_double', 'double_sided_tape', 'carpet_tape']);
    final underlayPrice = findPrice(priceList, ['underlay', 'underlay_carpet', 'carpet_padding']);
    final gripperPrice = findPrice(priceList, ['gripper', 'tack_strip']);
    final thresholdPrice = findPrice(priceList, ['threshold', 'transition_strip']);

    final costs = [
      calculateCost(rollsNeeded.toDouble(), carpetPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      calculateCost(underlayArea, underlayPrice?.price),
      calculateCost(gripperLength, gripperPrice?.price),
      calculateCost(thresholdsNeeded.toDouble(), thresholdPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'rollsNeeded': rollsNeeded.toDouble(),
        'plinthLength': plinthLength,
        'glueNeeded': glueNeeded,
        'tapeNeeded': tapeNeeded,
        'underlayArea': underlayArea,
        'gripperLength': gripperLength,
        'thresholdsNeeded': thresholdsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
