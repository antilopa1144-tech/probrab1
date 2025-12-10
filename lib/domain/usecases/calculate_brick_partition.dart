// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор перегородок из кирпича.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 530-2012 "Кирпич и камень керамические"
///
/// Поля:
/// - area: площадь перегородки (м²)
/// - thickness: толщина стены (в кирпичах), по умолчанию 0.5 (полкирпича)
/// - height: высота перегородки (м), по умолчанию 2.5
class CalculateBrickPartition extends BaseCalculator {
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
    final thickness = getInput(inputs, 'thickness', defaultValue: 0.5, minValue: 0.5, maxValue: 2.0);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);

    // Количество кирпичей на 1 м² стены (с учётом швов)
    // 0.5 кирпича (120 мм): ~61.5 шт/м²
    // 1.0 кирпич (250 мм): ~128 шт/м²
    // 1.5 кирпича (380 мм): ~189 шт/м²
    // 2.0 кирпича (510 мм): ~256 шт/м²
    final bricksPerM2 = thickness == 0.5 ? 61.5 
        : (thickness == 1.0 ? 128.0 
        : (thickness == 1.5 ? 189.0 
        : 256.0));

    // Количество кирпичей с запасом 5% (на бой и подрезку)
    final bricksNeeded = ceilToInt(area * bricksPerM2 * 1.05);

    // Объём кладки
    final wallThickness = thickness == 0.5 ? 0.12 : (thickness * 0.25);
    final volume = calculateVolume(area, wallThickness);

    // Раствор: ~0.02-0.025 м³ на 1 м² кладки на каждые 0.5 кирпича толщины
    final mortarPerM2 = 0.022 * (thickness / 0.5);
    final mortarVolume = area * mortarPerM2 * 1.05; // +5%

    // Цемент и песок для раствора (пропорция 1:3-4, берём 1:3.5)
    // Расход цемента: ~350-400 кг/м³ раствора
    final cementNeeded = mortarVolume * 375; // кг
    final sandNeeded = mortarVolume * 1.5; // м³ (или ~2250 кг)

    // Армирующая сетка: каждые 4-5 рядов (или каждые 0.6-0.8 м высоты)
    final meshRows = ceilToInt(wallHeight / 0.7);
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);
    final meshLength = meshRows * perimeter;

    // Грунтовка (перед штукатуркой): ~0.15 л/м² с двух сторон
    final primerNeeded = area * 0.15 * 2;

    // Штукатурка: ~15 кг/м² с двух сторон (слой ~10-12 мм на сторону)
    final plasterNeeded = area * 15 * 2;

    // Расчёт стоимости
    final brickPrice = findPrice(priceList, ['brick', 'brick_red', 'brick_ceramic', 'building_brick']);
    final cementPrice = findPrice(priceList, ['cement', 'cement_bag', 'portland_cement']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction', 'masonry_sand']);
    final meshPrice = findPrice(priceList, ['mesh', 'reinforcement_mesh', 'masonry_mesh']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final plasterPrice = findPrice(priceList, ['plaster', 'plaster_cement']);

    final costs = [
      calculateCost(bricksNeeded.toDouble(), brickPrice?.price),
      calculateCost(cementNeeded / 50, cementPrice?.price), // мешки по 50 кг
      calculateCost(sandNeeded, sandPrice?.price), // м³ или тонны
      calculateCost(meshLength, meshPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(plasterNeeded, plasterPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'bricksNeeded': bricksNeeded.toDouble(),
        'volume': volume,
        'mortarVolume': mortarVolume,
        'cementNeeded': cementNeeded,
        'sandNeeded': sandNeeded,
        'meshLength': meshLength,
        'primerNeeded': primerNeeded,
        'plasterNeeded': plasterNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
