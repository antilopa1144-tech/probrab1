// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор линолеума.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 18108-80 "Линолеум поливинилхлоридный"
///
/// Поля:
/// - area: площадь пола (м²)
/// - rollWidth: ширина рулона (м), по умолчанию 3.0
/// - rollLength: длина рулона (м), по умолчанию 30.0
/// - overlap: нахлёст (см), по умолчанию 5
/// - perimeter: периметр комнаты (м), опционально
class CalculateLinoleum extends BaseCalculator {
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
    final rollWidth = getInput(inputs, 'rollWidth', defaultValue: 3.0, minValue: 1.5, maxValue: 5.0);
    final rollLength = getInput(inputs, 'rollLength', defaultValue: 30.0, minValue: 10.0, maxValue: 50.0);
    final overlap = getInput(inputs, 'overlap', defaultValue: 5.0, minValue: 0.0, maxValue: 15.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь рулона
    final rollArea = rollWidth * rollLength;

    // Количество рулонов с учётом нахлёста и запаса
    final areaWithOverlap = addMargin(area, overlap + 10.0);
    final rollsNeeded = calculateUnitsNeeded(areaWithOverlap, rollArea, marginPercent: 0.0);

    // Плинтус: периметр + 5% на подрезку
    final plinthLength = perimeter;

    // Клей (если используется): ~0.3-0.5 кг/м²
    final glueNeeded = area * 0.3;

    // Двухсторонний скотч (альтернатива клею): периметр + диагонали
    final tapeNeeded = perimeter * 1.3;

    // Грунтовка для основания: ~0.1 л/м²
    final primerNeeded = area * 0.1;

    // Фанера для выравнивания (если нужна): площадь пола
    final plywoodArea = getInput(inputs, 'plywoodNeeded', defaultValue: 0.0);

    // Расчёт стоимости
    final linoleumPrice = findPrice(priceList, ['linoleum', 'linoleum_pvc', 'vinyl_flooring']);
    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_linoleum', 'baseboard']);
    final gluePrice = findPrice(priceList, ['glue_linoleum', 'glue', 'flooring_adhesive']);
    final tapePrice = findPrice(priceList, ['tape_double', 'double_sided_tape']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final plywoodPrice = findPrice(priceList, ['plywood', 'plywood_sheet']);

    final costs = [
      calculateCost(rollsNeeded.toDouble(), linoleumPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      plywoodArea > 0 ? calculateCost(plywoodArea, plywoodPrice?.price) : null,
    ];

    return createResult(
      values: {
        'area': area,
        'rollsNeeded': rollsNeeded.toDouble(),
        'plinthLength': plinthLength,
        'glueNeeded': glueNeeded,
        'tapeNeeded': tapeNeeded,
        'primerNeeded': primerNeeded,
        if (plywoodArea > 0) 'plywoodArea': plywoodArea,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
