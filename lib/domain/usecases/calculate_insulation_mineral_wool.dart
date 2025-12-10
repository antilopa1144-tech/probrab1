// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор утепления минеральной ватой.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 9573-2012 "Плиты из минеральной ваты"
///
/// Поля:
/// - area: площадь утепления (м²)
/// - thickness: толщина утеплителя (мм), по умолчанию 100
/// - density: плотность (кг/м³), по умолчанию 50
class CalculateInsulationMineralWool extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 100;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (thickness < 50 || thickness > 300) return 'Толщина должна быть от 50 до 300 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 100.0, minValue: 50.0, maxValue: 300.0);
    final density = getInput(inputs, 'density', defaultValue: 50.0, minValue: 30.0, maxValue: 200.0);

    // Объём утеплителя в м³
    final volume = calculateVolume(area, thickness);

    // Площадь одного рулона/плиты (стандарт: 0.6×1.2 м = 0.72 м²)
    final sheetArea = 0.72;

    // Количество плит/рулонов с запасом 5%
    final sheetsNeeded = calculateUnitsNeeded(area, sheetArea, marginPercent: 5.0);

    // Вес утеплителя
    final weight = volume * density;

    // Пароизоляция: площадь + 10% на нахлёсты и загибы
    final vaporBarrierArea = addMargin(area, 10.0);

    // Гидроизоляция/ветрозащита (для наружного утепления): площадь + 10%
    final windBarrierArea = addMargin(area, 10.0);

    // Крепёж: дюбели-грибки, ~5-6 шт/м²
    final fastenersNeeded = ceilToInt(area * 5);

    // Соединительная лента для пароизоляции: по швам
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);
    final tapeNeeded = perimeter * 1.5; // +50% на стыки

    // Деревянная/металлическая обрешётка (опционально): зависит от конструкции
    final battensLength = getInput(inputs, 'battens', defaultValue: 0.0);

    // Расчёт стоимости
    final woolPrice = findPrice(priceList, [
      'mineral_wool', 
      'wool_insulation', 
      'insulation_wool',
      'rockwool',
      'stone_wool'
    ]);
    final vaporBarrierPrice = findPrice(priceList, [
      'vapor_barrier', 
      'film_vapor', 
      'barrier_membrane'
    ]);
    final windBarrierPrice = findPrice(priceList, [
      'wind_barrier', 
      'membrane_wind', 
      'windproof_membrane'
    ]);
    final fastenerPrice = findPrice(priceList, [
      'fastener_insulation', 
      'dowel_umbrella', 
      'mushroom_dowel'
    ]);
    final tapePrice = findPrice(priceList, ['tape', 'joining_tape', 'sealing_tape']);
    final battensPrice = findPrice(priceList, ['battens', 'timber', 'wood_strips']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), woolPrice?.price),
      calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(windBarrierArea, windBarrierPrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      if (battensLength > 0) calculateCost(battensLength, battensPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'density': density,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'weight': weight,
        'vaporBarrierArea': vaporBarrierArea,
        'windBarrierArea': windBarrierArea,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'tapeNeeded': tapeNeeded,
        if (battensLength > 0) 'battensLength': battensLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
