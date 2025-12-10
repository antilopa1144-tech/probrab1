// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор утепления потолка.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 9573-2012 "Плиты из минеральной ваты"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - insulationThickness: толщина утеплителя (мм), по умолчанию 100
/// - insulationType: тип утеплителя (1=минвата, 2=пенопласт), по умолчанию 1
class CalculateCeilingInsulation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['insulationThickness'] ?? 100;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (thickness < 50 || thickness > 300) return 'Толщина утеплителя должна быть от 50 до 300 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final thickness = getInput(inputs, 'insulationThickness', defaultValue: 100.0, minValue: 50.0, maxValue: 300.0);
    final type = getIntInput(inputs, 'insulationType', defaultValue: 1, minValue: 1, maxValue: 2);

    // Площадь одного листа/плиты (зависит от типа)
    final sheetArea = type == 1 ? 0.72 : 0.5; // м² (минвата 0.6×1.2, пенопласт 0.5×1.0)

    // Количество листов с запасом 5%
    final sheetsNeeded = calculateUnitsNeeded(area, sheetArea, marginPercent: 5.0);

    // Объём утеплителя
    final volume = calculateVolume(area, thickness);

    // Пароизоляция: площадь + 10% на нахлёст
    final vaporBarrierArea = addMargin(area, 10.0);

    // Гидроизоляция (мембрана): площадь + 10%
    final hydroBarrierArea = addMargin(area, 10.0);

    // Крепёж: дюбели-грибки, ~5 шт/м² для минваты, ~4 шт/м² для пенопласта
    final fastenersPerM2 = 4;
    final fastenersNeeded = ceilToInt(area * fastenersPerM2);

    // Лента соединительная (для стыков плёнки): периметр + швы
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);
    final tapeNeeded = perimeter * 1.5;

    // Клей-пена (для пенопласта): ~1 баллон на 10 м²
    final foamNeeded = type == 2 ? ceilToInt(area / 10) : 0;

    // Металлизированная лента (для пароизоляции)
    final metalTapeNeeded = perimeter;

    // Расчёт стоимости
    final insulationPrice = type == 1
        ? findPrice(priceList, ['mineral_wool', 'wool_insulation', 'rockwool'])
        : findPrice(priceList, ['foam', 'foam_insulation', 'polystyrene', 'eps']);
    final vaporBarrierPrice = findPrice(priceList, ['vapor_barrier', 'film_vapor', 'barrier_membrane']);
    final hydroBarrierPrice = findPrice(priceList, ['hydro_barrier', 'waterproof_membrane']);
    final fastenerPrice = findPrice(priceList, ['fastener_insulation', 'dowel_umbrella', 'mushroom_dowel']);
    final tapePrice = findPrice(priceList, ['tape', 'joining_tape']);
    final foamPrice = type == 2 ? findPrice(priceList, ['foam_glue', 'adhesive_foam']) : null;
    final metalTapePrice = findPrice(priceList, ['tape_metal', 'aluminum_tape']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), insulationPrice?.price),
      calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(hydroBarrierArea, hydroBarrierPrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      if (type == 2) calculateCost(foamNeeded.toDouble(), foamPrice?.price),
      calculateCost(metalTapeNeeded, metalTapePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'insulationThickness': thickness,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'vaporBarrierArea': vaporBarrierArea,
        'hydroBarrierArea': hydroBarrierArea,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'tapeNeeded': tapeNeeded,
        if (type == 2) 'foamNeeded': foamNeeded.toDouble(),
        'metalTapeNeeded': metalTapeNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
