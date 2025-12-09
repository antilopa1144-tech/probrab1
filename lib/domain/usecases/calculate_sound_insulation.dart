// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор шумоизоляции.
///
/// Нормативы:
/// - СНиП 23-03-2003 "Защита от шума"
/// - ГОСТ 23499-2009 "Материалы и изделия звукопоглощающие"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - thickness: толщина материала (мм), по умолчанию 50
/// - insulationType: тип (1=минвата, 2=пенополиуретан, 3=акустические панели), по умолчанию 1
class CalculateSoundInsulation extends BaseCalculator {
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
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 20.0, maxValue: 150.0);
    final type = getIntInput(inputs, 'insulationType', defaultValue: 1, minValue: 1, maxValue: 3);

    // Площадь одного листа/плиты (зависит от типа)
    final sheetArea = type == 1 ? 0.72 : (type == 2 ? 0.5 : 0.6);

    // Количество листов с запасом 5%
    final sheetsNeeded = calculateUnitsNeeded(area, sheetArea, marginPercent: 5.0);

    // Объём материала
    final volume = calculateVolume(area, thickness);

    // Крепёж: дюбели, скобы или клей
    final fastenersNeeded = ceilToInt(area * 4);

    // Звукоизоляционная мембрана (дополнительно): площадь + 5%
    final membraneArea = addMargin(area, 5.0);

    // Виброподвесы (для потолка): ~1 шт на 0.5 м²
    final vibroSuspensionsNeeded = type == 1 ? ceilToInt(area / 0.5) : 0;

    // Демпферная лента по периметру: периметр комнаты
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final damperTapeLength = perimeter;

    // Акустический герметик: для швов
    final sealantTubes = ceilToInt(perimeter / 10); // 1 туба на 10 м.п.

    // Каркас (профили) для облицовки: зависит от конструкции
    final profileLength = getInput(inputs, 'profiles', defaultValue: 0.0);

    // Расчёт стоимости
    final insulationPrice = type == 1
        ? findPrice(priceList, ['mineral_wool', 'wool_insulation', 'acoustic_wool'])
        : (type == 2 
            ? findPrice(priceList, ['foam_pu', 'foam_sound', 'polyurethane_foam'])
            : findPrice(priceList, ['panel_acoustic', 'acoustic_panel', 'sound_panel']));
    final fastenerPrice = findPrice(priceList, ['fastener_insulation', 'dowel', 'anchor']);
    final membranePrice = findPrice(priceList, [
      'membrane_sound', 
      'acoustic_membrane', 
      'sound_barrier_membrane'
    ]);
    final vibroSuspensionPrice = findPrice(priceList, [
      'suspension_vibro', 
      'vibro_suspension', 
      'anti_vibration_hanger'
    ]);
    final damperTapePrice = findPrice(priceList, ['tape_damper', 'damper_tape', 'sealing_tape']);
    final sealantPrice = findPrice(priceList, ['sealant_acoustic', 'acoustic_sealant', 'sealant']);
    final profilePrice = findPrice(priceList, ['profile', 'metal_profile']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), insulationPrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      calculateCost(membraneArea, membranePrice?.price),
      if (vibroSuspensionsNeeded > 0) calculateCost(vibroSuspensionsNeeded.toDouble(), vibroSuspensionPrice?.price),
      calculateCost(damperTapeLength, damperTapePrice?.price),
      calculateCost(sealantTubes.toDouble(), sealantPrice?.price),
      if (profileLength > 0) calculateCost(profileLength, profilePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'membraneArea': membraneArea,
        if (vibroSuspensionsNeeded > 0) 'vibroSuspensionsNeeded': vibroSuspensionsNeeded.toDouble(),
        'damperTapeLength': damperTapeLength,
        'sealantTubes': sealantTubes.toDouble(),
        if (profileLength > 0) 'profileLength': profileLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
