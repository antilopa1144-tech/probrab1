// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор декоративного камня.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - stoneWidth: ширина камня (см), по умолчанию 20
/// - stoneHeight: высота камня (см), по умолчанию 5
/// - thickness: толщина камня (см), по умолчанию 2
class CalculateDecorativeStone extends BaseCalculator {
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
    final stoneWidth = getInput(inputs, 'stoneWidth', defaultValue: 20.0, minValue: 5.0, maxValue: 50.0);
    final stoneHeight = getInput(inputs, 'stoneHeight', defaultValue: 5.0, minValue: 2.0, maxValue: 30.0);

    // Площадь одного камня в м²
    final stoneArea = calculateTileArea(stoneWidth, stoneHeight);

    // Количество камней с запасом 15% (для подрезки и боя)
    final stonesNeeded = calculateUnitsNeeded(area, stoneArea, marginPercent: 15.0);

    // Клей для искусственного камня: 4-6 кг/м² (в среднем 5)
    final glueNeeded = area * 5.0;

    // Затирка для швов: ~1.5-2.5 кг/м² (зависит от ширины шва)
    final groutNeeded = area * 2.0;

    // Грунтовка: ~0.2 л/м²
    final primerNeeded = area * 0.2;

    // Гидрофобизатор (защитное покрытие): ~0.15 л/м²
    final hydrophobicNeeded = area * 0.15;

    // Армирующая сетка: площадь покрытия
    final meshArea = area;

    // Угловые элементы: по факту (опционально)
    final cornerElements = getIntInput(inputs, 'corners', defaultValue: 0, minValue: 0, maxValue: 100);

    // Расчёт стоимости
    final stonePrice = findPrice(priceList, [
      'stone_decorative', 
      'stone', 
      'stone_artificial',
      'facade_stone'
    ]);
    final gluePrice = findPrice(priceList, [
      'glue_stone', 
      'glue', 
      'adhesive_stone',
      'tile_adhesive'
    ]);
    final groutPrice = findPrice(priceList, [
      'grout_stone', 
      'grout', 
      'joint_filler'
    ]);
    final primerPrice = findPrice(priceList, ['primer', 'primer_stone', 'primer_adhesion']);
    final hydrophobicPrice = findPrice(priceList, [
      'hydrophobic', 
      'water_repellent', 
      'protective_coating'
    ]);
    final meshPrice = findPrice(priceList, ['mesh', 'fiberglass_mesh', 'reinforcement_mesh']);
    final cornerPrice = findPrice(priceList, ['corner_stone', 'corner_element']);

    final costs = [
      calculateCost(stonesNeeded.toDouble(), stonePrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(groutNeeded, groutPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(hydrophobicNeeded, hydrophobicPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      if (cornerElements > 0) calculateCost(cornerElements.toDouble(), cornerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'stonesNeeded': stonesNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'groutNeeded': groutNeeded,
        'primerNeeded': primerNeeded,
        'hydrophobicNeeded': hydrophobicNeeded,
        'meshArea': meshArea,
        if (cornerElements > 0) 'cornerElements': cornerElements.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
