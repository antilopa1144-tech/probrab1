// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Тип кровельного материала
enum RoofingType {
  metalTile,      // Металлочерепица
  softRoofing,    // Мягкая кровля (битумная черепица)
  profiledSheet,  // Профнастил
  ondulin,        // Ондулин
  slate,          // Шифер
  ceramicTile,    // Керамическая черепица
}

/// Единый калькулятор кровли.
///
/// Объединяет расчёты для всех типов кровельных материалов:
/// - Металлочерепица
/// - Мягкая кровля (битумная черепица)
/// - Профнастил
/// - Ондулин
/// - Шифер
/// - Керамическая черепица
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 24045-2010 "Профили стальные листовые гнутые"
/// - ГОСТ 30547-97 "Рулонные кровельные и гидроизоляционные материалы"
///
/// Поля:
/// - roofingType: тип кровельного материала (0-5)
/// - area: площадь кровли (м²) - проекционная
/// - slope: уклон крыши (градусы), по умолчанию 30
/// - ridgeLength: длина конька (м), опционально
/// - valleyLength: длина ендов (м), опционально
/// - sheetWidth: ширина листа (м), для листовых материалов
/// - sheetLength: длина листа (м), для листовых материалов
class CalculateUnifiedRoofing extends BaseCalculator {
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
    final roofingTypeIndex = getIntInput(
      inputs,
      'roofingType',
      defaultValue: 0,
      minValue: 0,
      maxValue: RoofingType.values.length - 1,
    );
    final roofingType = RoofingType.values[roofingTypeIndex];

    return switch (roofingType) {
      RoofingType.metalTile => _calculateMetalTile(inputs, priceList),
      RoofingType.softRoofing => _calculateSoftRoofing(inputs, priceList),
      RoofingType.profiledSheet => _calculateProfiledSheet(inputs, priceList),
      RoofingType.ondulin => _calculateOndulin(inputs, priceList),
      RoofingType.slate => _calculateSlate(inputs, priceList),
      RoofingType.ceramicTile => _calculateCeramicTile(inputs, priceList),
    };
  }

  /// Расчёт металлочерепицы
  CalculatorResult _calculateMetalTile(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final slope = getInput(inputs, 'slope', defaultValue: 30.0, minValue: 5.0, maxValue: 60.0);
    final sheetWidth = getInput(inputs, 'sheetWidth', defaultValue: 1.18, minValue: 0.5, maxValue: 2.0);
    final sheetLength = getInput(inputs, 'sheetLength', defaultValue: 2.5, minValue: 1.0, maxValue: 8.0);

    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    final effectiveWidth = sheetWidth * 0.92;
    final sheetArea = effectiveWidth * sheetLength;
    final sheetsNeeded = calculateUnitsNeeded(realArea, sheetArea, marginPercent: 10.0);

    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);
    final valleyLength = inputs['valleyLength'] ?? 0.0;
    final perimeter = _getPerimeter(inputs, area);
    final endLength = inputs['endLength'] ?? (2 * sqrt(area));

    final snowGuardsNeeded = ceilToInt(perimeter / 3.5);
    final screwsNeeded = realArea * 8;
    final waterproofingArea = addMargin(realArea, 10.0);
    final battensLength = realArea / 0.35 * 1.05;
    final counterBattensLength = realArea / (sheetWidth / slopeFactor) * 1.05;

    final sheetPrice = findPrice(priceList, ['metal_tile', 'roofing_metal', 'metal_roof']);
    final ridgePrice = findPrice(priceList, ['ridge', 'ridge_metal']);
    final valleyPrice = findPrice(priceList, ['valley', 'valley_metal']);
    final snowGuardPrice = findPrice(priceList, ['snow_guard', 'snow_barrier']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing_roof', 'roof_membrane']);
    final battensPrice = findPrice(priceList, ['battens', 'roofing_battens']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(ridgeLength, ridgePrice?.price),
      if (valleyLength > 0) calculateCost(valleyLength, valleyPrice?.price),
      calculateCost(snowGuardsNeeded.toDouble(), snowGuardPrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
    ];

    return createResult(
      values: {
        'roofingType': 0,
        'area': area,
        'realArea': realArea,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        if (valleyLength > 0) 'valleyLength': valleyLength,
        'endLength': endLength,
        'snowGuardsNeeded': snowGuardsNeeded.toDouble(),
        'screwsNeeded': screwsNeeded,
        'waterproofingArea': waterproofingArea,
        'battensLength': battensLength,
        'counterBattensLength': counterBattensLength,
      },
      totalPrice: sumCosts(costs),
      calculatorId: 'roofing_unified',
    );
  }

  /// Расчёт мягкой кровли
  CalculatorResult _calculateSoftRoofing(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final slope = getInput(inputs, 'slope', defaultValue: 30.0, minValue: 12.0, maxValue: 60.0);

    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);
    final perimeter = _getPerimeter(inputs, area);
    final valleyLength = inputs['valleyLength'] ?? (perimeter * 0.1);

    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    const packArea = 3.0;
    final packsNeeded = calculateUnitsNeeded(realArea, packArea, marginPercent: 10.0);
    final underlaymentArea = addMargin(realArea, 10.0);
    final ridgeStripLength = ridgeLength + perimeter;
    final valleyCarpetLength = addMargin(valleyLength, 10.0);
    final nailsNeeded = ceilToInt(realArea * 12);
    final masticNeeded = realArea * 0.5;
    final deckingArea = realArea * 1.05;
    final dripEdgeLength = perimeter;
    final ventilationsNeeded = ceilToInt(realArea / 55);

    final roofingPrice = findPrice(priceList, ['soft_roofing', 'bitumen_tile', 'shingles']);
    final underlaymentPrice = findPrice(priceList, ['underlayment_roof', 'roof_underlayment']);
    final ridgeStripPrice = findPrice(priceList, ['ridge_strip', 'ridge_soft']);
    final valleyPrice = findPrice(priceList, ['valley_soft', 'valley_carpet']);
    final masticPrice = findPrice(priceList, ['mastic_roof', 'mastic']);
    final deckingPrice = findPrice(priceList, ['osb', 'plywood']);
    final dripEdgePrice = findPrice(priceList, ['drip_edge', 'eave_strip']);

    final costs = [
      calculateCost(packsNeeded.toDouble(), roofingPrice?.price),
      calculateCost(underlaymentArea, underlaymentPrice?.price),
      calculateCost(ridgeStripLength, ridgeStripPrice?.price),
      if (valleyCarpetLength > 0) calculateCost(valleyCarpetLength, valleyPrice?.price),
      calculateCost(masticNeeded, masticPrice?.price),
      calculateCost(deckingArea, deckingPrice?.price),
      calculateCost(dripEdgeLength, dripEdgePrice?.price),
    ];

    return createResult(
      values: {
        'roofingType': 1,
        'area': area,
        'realArea': realArea,
        'packsNeeded': packsNeeded.toDouble(),
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
      calculatorId: 'roofing_unified',
    );
  }

  /// Расчёт профнастила
  CalculatorResult _calculateProfiledSheet(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final slope = getInput(inputs, 'slope', defaultValue: 15.0, minValue: 8.0, maxValue: 45.0);
    final sheetWidth = getInput(inputs, 'sheetWidth', defaultValue: 1.1, minValue: 0.8, maxValue: 1.5);
    final sheetLength = getInput(inputs, 'sheetLength', defaultValue: 3.0, minValue: 1.5, maxValue: 12.0);

    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    final effectiveWidth = sheetWidth * 0.95; // меньше потерь чем у металлочерепицы
    final sheetArea = effectiveWidth * sheetLength;
    final sheetsNeeded = calculateUnitsNeeded(realArea, sheetArea, marginPercent: 10.0);

    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    final screwsNeeded = realArea * 7; // меньше саморезов чем для металлочерепицы
    final waterproofingArea = addMargin(realArea, 10.0);
    final battensLength = realArea / 0.5 * 1.05; // шаг обрешетки 500мм

    final sheetPrice = findPrice(priceList, ['profiled_sheet', 'corrugated_sheet', 'профнастил']);
    final ridgePrice = findPrice(priceList, ['ridge', 'ridge_metal']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing_roof', 'roof_membrane']);
    final battensPrice = findPrice(priceList, ['battens', 'roofing_battens']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(ridgeLength, ridgePrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
    ];

    return createResult(
      values: {
        'roofingType': 2,
        'area': area,
        'realArea': realArea,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        'screwsNeeded': screwsNeeded,
        'waterproofingArea': waterproofingArea,
        'battensLength': battensLength,
      },
      totalPrice: sumCosts(costs),
      calculatorId: 'roofing_unified',
    );
  }

  /// Расчёт ондулина
  CalculatorResult _calculateOndulin(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final slope = getInput(inputs, 'slope', defaultValue: 15.0, minValue: 5.0, maxValue: 45.0);

    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Стандартный лист ондулина: 2.0 x 0.95 м, полезная площадь ~1.6 м²
    const sheetArea = 1.6;
    final sheetsNeeded = calculateUnitsNeeded(realArea, sheetArea, marginPercent: 15.0);

    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    final nailsNeeded = sheetsNeeded * 20; // 20 гвоздей на лист
    final ridgeElements = ceilToInt(ridgeLength / 0.85); // коньковые элементы 0.85м

    final sheetPrice = findPrice(priceList, ['ondulin', 'ondulina', 'bitumen_sheet']);
    final ridgePrice = findPrice(priceList, ['ridge_ondulin', 'ridge']);
    final nailsPrice = findPrice(priceList, ['ondulin_nails', 'roofing_nails']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(ridgeElements.toDouble(), ridgePrice?.price),
      calculateCost(nailsNeeded.toDouble(), nailsPrice?.price),
    ];

    return createResult(
      values: {
        'roofingType': 3,
        'area': area,
        'realArea': realArea,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        'ridgeElements': ridgeElements.toDouble(),
        'nailsNeeded': nailsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
      calculatorId: 'roofing_unified',
    );
  }

  /// Расчёт шифера
  CalculatorResult _calculateSlate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final slope = getInput(inputs, 'slope', defaultValue: 25.0, minValue: 12.0, maxValue: 45.0);

    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Стандартный лист шифера: 1.75 x 1.13 м, полезная площадь ~1.5 м²
    const sheetArea = 1.5;
    final sheetsNeeded = calculateUnitsNeeded(realArea, sheetArea, marginPercent: 10.0);

    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    final nailsNeeded = sheetsNeeded * 6; // 6 гвоздей на лист

    final sheetPrice = findPrice(priceList, ['slate', 'шифер', 'asbestos_cement']);
    final ridgePrice = findPrice(priceList, ['ridge_slate', 'ridge']);
    final nailsPrice = findPrice(priceList, ['slate_nails', 'roofing_nails']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(ridgeLength, ridgePrice?.price),
      calculateCost(nailsNeeded.toDouble(), nailsPrice?.price),
    ];

    return createResult(
      values: {
        'roofingType': 4,
        'area': area,
        'realArea': realArea,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        'nailsNeeded': nailsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
      calculatorId: 'roofing_unified',
    );
  }

  /// Расчёт керамической черепицы
  CalculatorResult _calculateCeramicTile(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final slope = getInput(inputs, 'slope', defaultValue: 30.0, minValue: 22.0, maxValue: 60.0);

    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Керамическая черепица: ~10-15 шт на м²
    const tilesPerSqm = 12.0;
    final tilesNeeded = ceilToInt(realArea * tilesPerSqm * 1.05); // 5% запас на бой

    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    // Коньковые элементы: ~3 шт на м.п.
    final ridgeTiles = ceilToInt(ridgeLength * 3);

    // Гидроизоляция
    final waterproofingArea = addMargin(realArea, 10.0);

    // Обрешетка: шаг 30-35 см
    final battensLength = realArea / 0.32 * 1.05;

    final tilePrice = findPrice(priceList, ['ceramic_tile', 'roof_tile', 'clay_tile']);
    final ridgePrice = findPrice(priceList, ['ridge_ceramic', 'ridge']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing_roof', 'roof_membrane']);
    final battensPrice = findPrice(priceList, ['battens', 'roofing_battens']);

    final costs = [
      calculateCost(tilesNeeded.toDouble(), tilePrice?.price),
      calculateCost(ridgeTiles.toDouble(), ridgePrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
    ];

    return createResult(
      values: {
        'roofingType': 5,
        'area': area,
        'realArea': realArea,
        'tilesNeeded': tilesNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        'ridgeTiles': ridgeTiles.toDouble(),
        'waterproofingArea': waterproofingArea,
        'battensLength': battensLength,
      },
      totalPrice: sumCosts(costs),
      calculatorId: 'roofing_unified',
    );
  }

  double _getPerimeter(Map<String, double> inputs, double area) {
    if (inputs['perimeter'] != null && inputs['perimeter']! > 0) {
      return getInput(inputs, 'perimeter', minValue: 0.1);
    }
    return estimatePerimeter(area);
  }
}
