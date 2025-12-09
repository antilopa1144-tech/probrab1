// ignore_for_file: prefer_const_declarations
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
/// - area: площадь стен (м²)
/// - thickness: толщина слоя (мм), по умолчанию 10
/// - type: тип (1=гипсовая, 2=цементная), по умолчанию 1
/// - perimeter: периметр комнаты (м), опционально
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
      minValue: 0.0,
      maxValue: 100.0,
    );
    final type = getIntInput(inputs, 'type', defaultValue: 1, minValue: 1, maxValue: 2);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Расход штукатурки на 10 мм слоя:
    // - Гипсовая: 8-9 кг/м²
    // - Цементная: 14-17 кг/м²
    final consumptionPer10mm = type == 1 ? 8.5 : 15.5; // кг/м²

    // Общий расход с учётом толщины и запаса 10%
    final plasterNeeded = area * consumptionPer10mm * (thickness / 10) * 1.1;
    final plasterVolume = calculateVolume(area, thickness);

    // Грунтовка глубокого проникновения: ~0.2 л/м²
    final primerNeeded = area * 0.2;

    // Штукатурная сетка (при толщине > 20 мм): площадь покрытия
    final meshArea = thickness > 20 ? area : 0.0;

    // Маяки профильные: шаг установки 1.2-1.5 м
    // Количество зависит от периметра и высоты стен
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 2.0, maxValue: 4.0);
    final beaconsCount = ceilToInt(perimeter / 1.5);
    final beaconsLength = beaconsCount * wallHeight;

    // Угловой профиль (для наружных углов): по факту
    final cornerProfileLength = getInput(inputs, 'corners', defaultValue: 0.0);

    // Правило алюминиевое: 1-2 шт
    const rulesNeeded = 1;

    // Вода для замешивания (информативно): ~0.6 л на кг для гипсовой, ~0.2 л для цементной
    final waterPerKg = type == 1 ? 0.6 : 0.2;
    final waterNeeded = plasterNeeded * waterPerKg;

    // Расчёт стоимости
    final plasterPrice = type == 1
        ? findPrice(priceList, ['plaster_gypsum', 'plaster', 'gypsum_plaster'])
        : findPrice(priceList, ['plaster_cement', 'cement_plaster', 'plaster']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_penetrating']);
    final meshPrice = findPrice(priceList, ['mesh', 'plaster_mesh', 'reinforcement_mesh']);
    final beaconPrice = findPrice(priceList, ['beacon', 'beacon_plaster', 'profile_beacon']);
    final cornerProfilePrice = findPrice(priceList, ['profile_corner', 'corner_bead']);

    final costs = [
      calculateCost(plasterNeeded, plasterPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (meshArea > 0) calculateCost(meshArea, meshPrice?.price),
      calculateCost(beaconsLength, beaconPrice?.price),
      if (cornerProfileLength > 0) calculateCost(cornerProfileLength, cornerProfilePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'volume': plasterVolume,
        'plasterNeeded': plasterNeeded,
        'primerNeeded': primerNeeded,
        'thickness': thickness,
        if (meshArea > 0) 'meshArea': meshArea,
        'beaconsCount': beaconsCount.toDouble(),
        'beaconsLength': beaconsLength,
        if (cornerProfileLength > 0) 'cornerProfileLength': cornerProfileLength,
        'rulesNeeded': rulesNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts(costs),
      decimals: 3,
    );
  }
}
