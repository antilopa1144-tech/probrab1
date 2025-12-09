// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор мягкой кровли (битумная черепица).
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 30547-97 "Рулонные кровельные и гидроизоляционные материалы"
///
/// Поля:
/// - area: площадь кровли (м²) - проекционная
/// - slope: уклон крыши (градусы), по умолчанию 30
/// - ridgeLength: длина конька (м), опционально
/// - valleyLength: длина ендов (м), опционально
/// - perimeter: периметр кровли (м), опционально
class CalculateSoftRoofing extends BaseCalculator {
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
    final slope = getInput(inputs, 'slope', defaultValue: 30.0, minValue: 0.0, maxValue: 60.0);
    
    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area));
    final valleyLength = inputs['valleyLength'] ?? (perimeter * 0.1);

    // Учитываем уклон
    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Площадь упаковки черепицы (стандарт: 3 м² полезной площади на упаковку)
    const packArea = 3.0;

    // Количество упаковок с запасом 10%
    final packsNeeded = calculateUnitsNeeded(realArea, packArea, marginPercent: 10.0);

    // Подкладочный ковёр: полная площадь кровли + 10% нахлёст
    final underlaymentArea = addMargin(realArea, 10.0);

    // Коньково-карнизная черепица: конёк + карнизы
    final ridgeStripLength = ridgeLength + perimeter;

    // Ендовый ковёр: длина ендов + 10%
    final valleyCarpetLength = addMargin(valleyLength, 10.0);

    // Кровельные гвозди: ~10-15 шт на м²
    final nailsNeeded = ceilToInt(realArea * 12);

    // Битумная мастика: ~0.5 кг/м² (для проклейки)
    final masticNeeded = realArea * 0.5;

    // ОSB/фанера для основания: площадь кровли
    final deckingArea = realArea * 1.05;

    // Капельники (карнизные/фронтонные планки): периметр
    final dripEdgeLength = perimeter;

    // Вентиляционные элементы: 1 шт на 50-60 м²
    final ventilationsNeeded = ceilToInt(realArea / 55);

    // Расчёт стоимости
    final roofingPrice = findPrice(priceList, ['soft_roofing', 'bitumen_tile', 'roofing_soft', 'shingles']);
    final underlaymentPrice = findPrice(priceList, ['underlayment_roof', 'roof_underlayment', 'roofing_felt']);
    final ridgeStripPrice = findPrice(priceList, ['ridge_strip', 'ridge_soft', 'starter_strip']);
    final valleyPrice = findPrice(priceList, ['valley_soft', 'valley_carpet', 'valley']);
    final masticPrice = findPrice(priceList, ['mastic_roof', 'mastic', 'bitumen_adhesive']);
    final deckingPrice = findPrice(priceList, ['osb', 'plywood', 'roof_deck']);
    final dripEdgePrice = findPrice(priceList, ['drip_edge', 'eave_strip']);
    final ventilationPrice = findPrice(priceList, ['ventilation', 'roof_vent']);

    final costs = [
      calculateCost(packsNeeded.toDouble(), roofingPrice?.price),
      calculateCost(underlaymentArea, underlaymentPrice?.price),
      calculateCost(ridgeStripLength, ridgeStripPrice?.price),
      if (valleyCarpetLength > 0) calculateCost(valleyCarpetLength, valleyPrice?.price),
      calculateCost(masticNeeded, masticPrice?.price),
      calculateCost(deckingArea, deckingPrice?.price),
      calculateCost(dripEdgeLength, dripEdgePrice?.price),
      calculateCost(ventilationsNeeded.toDouble(), ventilationPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'realArea': realArea,
        'packsNeeded': packsNeeded.toDouble(),
        'rollsNeeded': packsNeeded.toDouble(),
        'underlaymentArea': underlaymentArea,
        'ridgeStripLength': ridgeStripLength,
        if (valleyCarpetLength > 0) 'valleyCarpetLength': valleyCarpetLength,
        'nailsNeeded': nailsNeeded.toDouble(),
        'masticNeeded': masticNeeded,
        'deckingArea': deckingArea,
        'dripEdgeLength': dripEdgeLength,
        'ventilationsNeeded': ventilationsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
