import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор плитки на стены (не ванная).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 6787-2001 "Плитки керамические для полов"
///
/// Поля:
/// - area: площадь стен (м²)
/// - tileWidth: ширина плитки (см), по умолчанию 30
/// - tileHeight: высота плитки (см), по умолчанию 30
/// - jointWidth: ширина шва (мм), по умолчанию 3
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateWallTile extends BaseCalculator {
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
    final tileWidth = getInput(inputs, 'tileWidth', defaultValue: 30.0, minValue: 10.0, maxValue: 120.0);
    final tileHeight = getInput(inputs, 'tileHeight', defaultValue: 30.0, minValue: 10.0, maxValue: 120.0);
    final jointWidth = getInput(inputs, 'jointWidth', defaultValue: 3.0, minValue: 1.0, maxValue: 10.0);
    final windowsArea = getInput(inputs, 'windowsArea', defaultValue: 0.0, minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', defaultValue: 0.0, minValue: 0.0);

    final usefulArea = [area - windowsArea - doorsArea, 0].reduce((a, b) => a > b ? a : b);

    // Площадь одной плитки в м²
    final tileArea = calculateTileArea(tileWidth, tileHeight);

    // Количество плиток с запасом 10%
    final tilesNeeded = calculateUnitsNeeded(usefulArea, tileArea, marginPercent: 10.0);

    // Затирка: формула расчёта с учётом размера плитки
    final groutConsumption = 1.5 * (jointWidth / 10);
    final groutNeeded = usefulArea * groutConsumption;

    // Клей: расход 3-5 кг/м² (зависит от размера плитки)
    final glueConsumption = tileWidth > 60 || tileHeight > 60 ? 5.0 : 4.0;
    final glueNeeded = usefulArea * glueConsumption;

    // Грунтовка: ~0.15 л/м²
    final primerNeeded = usefulArea * 0.15;

    // Крестики/СВП: ~4-5 шт на плитку
    final crossesNeeded = tilesNeeded * 4;

    // Профили для углов: по факту
    final cornerProfileLength = getInput(inputs, 'cornerProfile', defaultValue: 0.0);

    // Затирка-герметик для углов: 1 туба на ~12 м.п.
    final sealantTubes = cornerProfileLength > 0 
        ? ceilToInt(cornerProfileLength / 12) 
        : 0;

    // Расчёт стоимости
    final tilePrice = findPrice(priceList, [
      'tile', 
      'tile_ceramic', 
      'tile_wall',
      'ceramic_tile'
    ]);
    final groutPrice = findPrice(priceList, ['grout', 'grout_tile', 'joint_filler']);
    final gluePrice = findPrice(priceList, ['glue_tile', 'tile_adhesive', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_adhesion']);
    final cornerProfilePrice = findPrice(priceList, ['profile_corner', 'trim_profile']);
    final sealantPrice = findPrice(priceList, ['sealant', 'silicone']);

    final costs = [
      calculateCost(tilesNeeded.toDouble(), tilePrice?.price),
      calculateCost(groutNeeded, groutPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (cornerProfileLength > 0) calculateCost(cornerProfileLength, cornerProfilePrice?.price),
      if (sealantTubes > 0) calculateCost(sealantTubes.toDouble(), sealantPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'tilesNeeded': tilesNeeded.toDouble(),
        'groutNeeded': groutNeeded,
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
        'crossesNeeded': crossesNeeded.toDouble(),
        if (cornerProfileLength > 0) 'cornerProfileLength': cornerProfileLength,
        if (sealantTubes > 0) 'sealantTubes': sealantTubes.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
