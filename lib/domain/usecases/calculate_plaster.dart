// ignore_for_file: prefer_const_declarations
import 'dart:math' as math;
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор штукатурки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь стен (м²) - вводится напрямую
/// - thickness: толщина слоя (мм), по умолчанию 10
/// - type: тип (1=гипсовая, 2=цементная), по умолчанию 1
class CalculatePlaster extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 10;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (area > 100000) return 'Площадь превышает допустимый максимум';
    if (thickness < 0) return 'Толщина не может быть отрицательной';
    if (thickness > 100) return 'Толщина должна быть не более 100 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(
      inputs,
      'area',
      minValue: 0.1,
      maxValue: 100000.0,
    );
    final thickness = getInput(
      inputs,
      'thickness',
      defaultValue: 10.0,
      minValue: 5.0,
      maxValue: 100.0,
    );
    final type = getIntInput(inputs, 'type', defaultValue: 1, minValue: 1, maxValue: 2);

    // Расход штукатурки на 10 мм слоя:
    // - Гипсовая: 8-9 кг/м²
    // - Цементная: 14-17 кг/м²
    final consumptionPer10mm = type == 1 ? 8.5 : 15.5; // кг/м²

    // Общий расход с учётом толщины и запаса 10%
    final plasterKg = area * consumptionPer10mm * (thickness / 10) * 1.1;

    // Вес мешка: гипсовая обычно 30 кг, цементная 25 кг
    final bagWeight = type == 1 ? 30.0 : 25.0;
    final plasterBags = (plasterKg / bagWeight).ceil();

    // Бетонконтакт: ~0.3 л/м² (грунтовка для лучшей адгезии)
    final betonkontaktLiters = (area * 0.3 * 1.1).ceil(); // с запасом 10%

    // Штукатурная сетка (при толщине > 30 мм): площадь покрытия
    final meshArea = thickness > 30 ? area * 1.1 : 0.0; // с запасом

    // Маяки: размер зависит от толщины слоя
    // 6 мм - для слоя до 10 мм
    // 10 мм - для слоя 10-30 мм
    // Шаг установки 1.0-1.2 м (под правило 1.5 м)
    final beaconSizeMm = thickness <= 10 ? 6 : 10;

    // Примерный расчёт количества маяков:
    // На каждые 10 м² стен нужно ~4-5 маяков по 3 м
    final beaconsCount = math.max(2, (area / 2.5).ceil());

    // Правило: рекомендуемый размер
    // При шаге маяков 1.0-1.2 м нужно правило 1.5 м
    const ruleSizeM = 1.5;

    // Расчёт стоимости
    final plasterPrice = type == 1
        ? findPrice(priceList, ['plaster_gypsum', 'plaster', 'gypsum_plaster'])
        : findPrice(priceList, ['plaster_cement', 'cement_plaster', 'plaster']);
    final betonkontaktPrice = findPrice(priceList, ['betonkontakt', 'primer_contact', 'primer']);
    final meshPrice = findPrice(priceList, ['mesh', 'plaster_mesh', 'reinforcement_mesh']);
    final beaconPrice = findPrice(priceList, ['beacon', 'beacon_plaster', 'profile_beacon']);

    final costs = [
      calculateCost(plasterBags.toDouble() * bagWeight, plasterPrice?.price),
      calculateCost(betonkontaktLiters.toDouble(), betonkontaktPrice?.price),
      if (meshArea > 0) calculateCost(meshArea, meshPrice?.price),
      calculateCost(beaconsCount.toDouble() * 3, beaconPrice?.price), // маяки по 3 м
    ];

    return createResult(
      values: {
        'plasterBags': plasterBags.toDouble(),
        'plasterKg': plasterKg,
        'betonkontaktLiters': betonkontaktLiters.toDouble(),
        if (meshArea > 0) 'meshArea': meshArea,
        'beacons': beaconsCount.toDouble(),
        'beaconSize': beaconSizeMm.toDouble(),
        'ruleSize': ruleSizeM,
      },
      totalPrice: sumCosts(costs),
      decimals: 1,
    );
  }
}
