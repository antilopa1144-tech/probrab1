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
/// - СП 71.13330.2017 "Изоляционные и отделочные покрытия"
///
/// Учитывает тип основания, ровность стен, автодобавление сетки.
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
    final area = getInput(inputs, 'area', minValue: 0.1, maxValue: 100000.0);
    final thickness = getInput(inputs, 'thickness', defaultValue: 10.0, minValue: 5.0, maxValue: 100.0);
    final type = getIntInput(inputs, 'type', defaultValue: 1, minValue: 1, maxValue: 2);
    final substrateType = getIntInput(inputs, 'substrateType', defaultValue: 1, minValue: 1, maxValue: 5);
    final wallEvenness = getIntInput(inputs, 'wallEvenness', defaultValue: 1, minValue: 1, maxValue: 3);

    // Базовый расход на 10 мм слоя (кг/м²):
    // Гипсовая (Ротбанд и аналоги): 8.5 кг/м²
    // Цементная (ЦПС): 17.0 кг/м²
    final baseConsumption = type == 1 ? 8.5 : 17.0;

    // Множитель по типу основания:
    // 1 - бетон: поверхность гладкая, адгезия средняя -> 1.0
    // 2 - новый кирпич: шероховатый, впитывает умеренно -> 1.15
    // 3 - старый кирпич: пористый, неровный, впитывает сильно -> 1.3
    // 4 - газоблок: сильно впитывает влагу -> 1.25
    // 5 - пенобетон: пористый, средне впитывает -> 1.2
    final substrateMultiplier = switch (substrateType) {
      2 => 1.15,
      3 => 1.30,
      4 => 1.25,
      5 => 1.20,
      _ => 1.0, // бетон
    };

    // Множитель по ровности стен:
    // 1 - ровная (<5мм/м): минимум подрезки -> 1.0
    // 2 - неровная (5-10мм/м): средний перерасход -> 1.15
    // 3 - очень неровная (>10мм/м): сильный перерасход -> 1.3
    final evennessMultiplier = switch (wallEvenness) {
      2 => 1.15,
      3 => 1.30,
      _ => 1.0,
    };

    // Общий расход с учётом всех факторов + 10% запас на потери
    final plasterKg = area * baseConsumption * (thickness / 10) * substrateMultiplier * evennessMultiplier * 1.1;

    // Вес мешка: гипсовая 30 кг, цементная 25 кг
    final bagWeight = type == 1 ? 30.0 : 25.0;
    final plasterBags = (plasterKg / bagWeight).ceil();

    // Грунтовка зависит от типа основания:
    // Бетон -> бетоноконтакт 0.3 кг/м² (густая, дорогая)
    // Кирпич/газоблок/пенобетон -> глубокого проникновения 0.1 л/м²
    final double primerRate;
    final int primerType; // 1=глубокого проникновения, 2=бетоноконтакт
    if (substrateType == 1) {
      primerRate = 0.3; // бетоноконтакт кг/м²
      primerType = 2;
    } else {
      primerRate = 0.1; // глубокого проникновения л/м²
      primerType = 1;
    }
    final primerNeeded = (area * primerRate * 1.1).ceil(); // +10% запас

    // Маяки: размер зависит от толщины слоя
    // <15мм -> 6мм маяки
    // 15-30мм -> 10мм маяки
    // >30мм -> 10мм маяки + армирующая сетка
    final beaconSizeMm = thickness < 15 ? 6 : 10;

    // Количество маяков: на каждые 2.5 м² нужен ~1 маяк по 3 м
    final beaconsCount = math.max(2, (area / 2.5).ceil());

    // Армирующая сетка: обязательна при толщине >30мм
    final needsMesh = thickness > 30;
    final meshArea = needsMesh ? area * 1.1 : 0.0; // +10% нахлёст

    // Правило: рекомендуемый размер
    const ruleSizeM = 1.5;

    // Расчёт стоимости
    final plasterPrice = type == 1
        ? findPrice(priceList, ['plaster_gypsum', 'plaster', 'gypsum_plaster'])
        : findPrice(priceList, ['plaster_cement', 'cement_plaster', 'plaster']);
    final primerPrice = primerType == 2
        ? findPrice(priceList, ['betonkontakt', 'primer_contact', 'primer'])
        : findPrice(priceList, ['primer_deep', 'primer', 'primer_penetrating']);
    final meshPrice = findPrice(priceList, ['mesh', 'plaster_mesh', 'reinforcement_mesh']);
    final beaconPrice = findPrice(priceList, ['beacon', 'beacon_plaster', 'profile_beacon']);

    final costs = [
      calculateCost(plasterBags.toDouble() * bagWeight, plasterPrice?.price),
      calculateCost(primerNeeded.toDouble(), primerPrice?.price),
      if (meshArea > 0) calculateCost(meshArea, meshPrice?.price),
      calculateCost(beaconsCount.toDouble(), beaconPrice?.price),
    ];

    return createResult(
      values: {
        'plasterBags': plasterBags.toDouble(),
        'plasterKg': plasterKg,
        'primerLiters': primerNeeded.toDouble(),
        'primerType': primerType.toDouble(),
        if (meshArea > 0) 'meshArea': meshArea,
        'beacons': beaconsCount.toDouble(),
        'beaconSize': beaconSizeMm.toDouble(),
        'ruleSize': ruleSizeM,
        // Flags for conditional hints
        if (thickness > 40) 'warningThickLayer': 1.0,
        if (substrateType == 3 && wallEvenness == 3) 'tipObryzg': 1.0,
      },
      totalPrice: sumCosts(costs),
      decimals: 1,
    );
  }
}
