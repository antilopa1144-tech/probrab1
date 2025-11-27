import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор плитки для ванной комнаты.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 6787-2001 "Плитки керамические для полов"
///
/// Поля:
/// - wallArea: площадь стен (м²)
/// - floorArea: площадь пола (м²)
/// - tileWidth: ширина плитки (см), по умолчанию 30
/// - tileHeight: высота плитки (см), по умолчанию 30
/// - jointWidth: ширина шва (мм), по умолчанию 3
class CalculateBathroomTile extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final wallArea = inputs['wallArea'] ?? 0;
    final floorArea = inputs['floorArea'] ?? 0;

    if (wallArea <= 0 && floorArea <= 0) {
      return 'Должна быть указана площадь стен или пола';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final wallArea = getInput(inputs, 'wallArea', defaultValue: 0.0, minValue: 0.0);
    final floorArea = getInput(inputs, 'floorArea', defaultValue: 0.0, minValue: 0.0);
    final tileWidth = getInput(inputs, 'tileWidth', defaultValue: 30.0, minValue: 10.0, maxValue: 120.0);
    final tileHeight = getInput(inputs, 'tileHeight', defaultValue: 30.0, minValue: 10.0, maxValue: 120.0);
    final jointWidth = getInput(inputs, 'jointWidth', defaultValue: 3.0, minValue: 1.0, maxValue: 10.0);

    final totalArea = wallArea + floorArea;

    // Площадь одной плитки в м²
    final tileArea = calculateTileArea(tileWidth, tileHeight);

    // Количество плиток с запасом 10% для стен, 12% для пола (больше обрезков)
    final wallTiles = wallArea > 0 
        ? calculateUnitsNeeded(wallArea, tileArea, marginPercent: 10.0)
        : 0;
    final floorTiles = floorArea > 0 
        ? calculateUnitsNeeded(floorArea, tileArea, marginPercent: 12.0)
        : 0;
    final totalTiles = wallTiles + floorTiles;

    // Затирка: расход зависит от размера плитки и шва
    // Формула: (длина + ширина) / (длина × ширина) × ширина_шва × глубина × плотность
    final groutConsumption = ((tileWidth + tileHeight) / (tileWidth * tileHeight)) * 
                            jointWidth * 10 * 1.6; // глубина 10 мм, плотность 1.6
    final groutNeeded = totalArea * groutConsumption * 1.05;

    // Клей: расход 3-5 кг/м² (в среднем 4.2 кг/м²)
    final glueNeeded = totalArea * 4.2;

    // Грунтовка: ~0.15 л/м²
    final primerNeeded = totalArea * 0.15;

    // Крестики/СВП: ~4-6 шт на плитку
    final crossesNeeded = ceilToInt(totalTiles * 5);

    // Гидроизоляция: пол полностью + 30 см на стены
    final perimeter = inputs['perimeter'] ?? (floorArea > 0 ? estimatePerimeter(floorArea) : 0);
    final waterproofingArea = floorArea + (perimeter * 0.3);

    // Угловые профили (для внешних углов): по факту
    final cornerProfileLength = getInput(inputs, 'corners', defaultValue: 0.0);

    // Герметик (силиконовый): для швов в мокрых зонах
    final sealantTubes = ceilToInt(perimeter / 12); // 1 туба на ~12 м.п.

    // Расчёт стоимости
    final wallTilePrice = findPrice(priceList, ['tile_bathroom_wall', 'tile_wall', 'tile_ceramic']);
    final floorTilePrice = findPrice(priceList, ['tile_bathroom_floor', 'tile_floor', 'tile_ceramic_floor']);
    final groutPrice = findPrice(priceList, ['grout', 'grout_tile', 'joint_filler']);
    final gluePrice = findPrice(priceList, ['glue_tile', 'tile_adhesive', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_adhesion']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing', 'waterproofing_bathroom']);
    final sealantPrice = findPrice(priceList, ['sealant', 'silicone', 'bathroom_sealant']);

    final costs = [
      calculateCost(wallTiles.toDouble(), wallTilePrice?.price ?? floorTilePrice?.price),
      calculateCost(floorTiles.toDouble(), floorTilePrice?.price ?? wallTilePrice?.price),
      calculateCost(groutNeeded, groutPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(sealantTubes.toDouble(), sealantPrice?.price),
    ];

    return createResult(
      values: {
        'wallArea': wallArea,
        'floorArea': floorArea,
        'totalArea': totalArea,
        'wallTiles': wallTiles.toDouble(),
        'floorTiles': floorTiles.toDouble(),
        'totalTiles': totalTiles.toDouble(),
        'groutNeeded': groutNeeded,
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
        'crossesNeeded': crossesNeeded.toDouble(),
        'waterproofingArea': waterproofingArea,
        'sealantTubes': sealantTubes.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
