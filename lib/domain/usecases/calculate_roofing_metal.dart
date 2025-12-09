// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор кровли из металлочерепицы.
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 24045-2010 "Профили стальные листовые гнутые"
///
/// Поля:
/// - area: площадь кровли (м²) - проекционная
/// - slope: уклон крыши (градусы), по умолчанию 30
/// - sheetWidth: ширина листа (м), по умолчанию 1.18
/// - sheetLength: длина листа (м), по умолчанию 2.5
/// - ridgeLength: длина конька (м), опционально
/// - valleyLength: длина ендов (м), опционально
/// - perimeter: периметр кровли (м), опционально
class CalculateRoofingMetal extends BaseCalculator {
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
    final sheetWidth = getInput(inputs, 'sheetWidth', defaultValue: 1.18, minValue: 0.5, maxValue: 1.5);
    final sheetLength = getInput(inputs, 'sheetLength', defaultValue: 2.5, minValue: 0.5, maxValue: 8.0);

    // Учитываем уклон: реальная площадь больше проекции
    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Площадь одного листа (полезная с учётом нахлёста)
    final effectiveWidth = sheetWidth * 0.92; // полезная ширина ~92%
    final sheetArea = effectiveWidth * sheetLength;

    // Количество листов с запасом 10%
    final sheetsNeeded = calculateUnitsNeeded(realArea, sheetArea, marginPercent: 10.0);

    // Конёк (коньковая планка): по длине конька
    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    // Ендовы (внутренние углы): по длине ендов
    final valleyLength = inputs['valleyLength'] ?? 0.0;

    // Карнизные планки: по периметру
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area));
    final eaveLength = perimeter;

    // Торцевые (фронтонные) планки: торцы скатов
    final endLength = inputs['endLength'] ?? (2 * sqrt(area));

    // Снегозадержатели: 1 комплект на 3-4 м.п. ската
    final snowGuardsNeeded = ceilToInt(perimeter / 3.5);

    // Саморезы кровельные: ~8-10 шт на м²
    final screwsNeeded = realArea * 8;

    // Гидроизоляция (супердиффузионная мембрана): площадь кровли + 10% нахлёст
    final waterproofingArea = addMargin(realArea, 10.0);

    // Обрешётка (доска 25×100 мм): шаг зависит от профиля, обычно 350 мм
    final battensLength = realArea / 0.35 * 1.05; // ~2.86 м.п. на м²

    // Контробрешётка (брусок 50×50 мм): по длине стропил
    final counterBattensLength = realArea / (sheetWidth / slopeFactor) * 1.05;

    // Расчёт стоимости
    final sheetPrice = findPrice(priceList, ['metal_tile', 'roofing_metal', 'metal_roof', 'metal_roofing']);
    final ridgePrice = findPrice(priceList, ['ridge', 'ridge_metal', 'ridge_strip']);
    final valleyPrice = findPrice(priceList, ['valley', 'valley_metal', 'inner_valley']);
    final eavePrice = findPrice(priceList, ['eave', 'eave_strip', 'drip_edge']);
    final endPrice = findPrice(priceList, ['end_strip', 'gable_strip', 'trim']);
    final snowGuardPrice = findPrice(priceList, ['snow_guard', 'snow_barrier']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing_roof', 'roof_membrane', 'underlayment']);
    final battensPrice = findPrice(priceList, ['battens', 'roofing_battens', 'timber']);
    final counterBattensPrice = findPrice(priceList, ['counter_battens', 'battens']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(ridgeLength, ridgePrice?.price),
      if (valleyLength > 0) calculateCost(valleyLength, valleyPrice?.price),
      calculateCost(eaveLength, eavePrice?.price),
      calculateCost(endLength, endPrice?.price),
      calculateCost(snowGuardsNeeded.toDouble(), snowGuardPrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(counterBattensLength, counterBattensPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'realArea': realArea,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        if (valleyLength > 0) 'valleyLength': valleyLength,
        'eaveLength': eaveLength,
        'endLength': endLength,
        'snowGuardsNeeded': snowGuardsNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
        'waterproofingArea': waterproofingArea,
        'battensLength': battensLength,
        'counterBattensLength': counterBattensLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
