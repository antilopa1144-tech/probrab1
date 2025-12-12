// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор перегородок из газоблока / пеноблока.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 31359-2007 "Бетоны ячеистые автоклавного твердения"
///
/// Поля:
/// - area: площадь перегородки (м²)
/// - blockWidth: ширина блока (см), по умолчанию 10
/// - blockLength: длина блока (см), по умолчанию 60
/// - blockHeight: высота блока (см), по умолчанию 25
/// - height: высота перегородки (м), по умолчанию 2.5
class CalculateGasblockPartition extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) {
      final length = inputs['length'] ?? 0;
      final height = inputs['height'] ?? 0;
      if (length <= 0 || height <= 0) {
        return 'Площадь должна быть больше нуля';
      }
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    double area;
    if ((inputs['area'] ?? 0) > 0) {
      area = getInput(inputs, 'area', minValue: 0.1);
    } else {
      final length = getInput(inputs, 'length', minValue: 0.1);
      final height = getInput(inputs, 'height', defaultValue: 2.5, minValue: 0.1);
      area = length * height;
    }
    final blockWidth = getInput(inputs, 'blockWidth', defaultValue: 10.0, minValue: 7.5, maxValue: 20.0);
    final blockLength = getInput(inputs, 'blockLength', defaultValue: 60.0, minValue: 50.0, maxValue: 62.5);
    final blockHeight = getInput(inputs, 'blockHeight', defaultValue: 25.0, minValue: 20.0, maxValue: 30.0);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);

    // Площадь одного блока (по фасаду) в м²
    final blockFaceArea = (blockLength / 100) * (blockHeight / 100);

    // Количество блоков с запасом 5%
    final blocksNeeded = ceilToInt((area / blockFaceArea) * 1.05);

    // Объём кладки в м³
    final volume = calculateVolume(area, blockWidth * 10);

    // Клей для газоблока: ~25-30 кг/м³ (или ~1.5 кг/м² при толщине шва 2-3 мм)
    final glueNeeded = volume * 25 * 1.1; // +10%

    // Армирование: арматура через каждые 2-3 ряда (или каждый метр высоты)
    final rows = ceilToInt(wallHeight / (blockHeight / 100));
    final reinforcementRows = ceilToInt(rows / 3);
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);
    final reinforcementLength = reinforcementRows * perimeter * 2; // 2 прута

    // Грунтовка для газоблока (перед финишной отделкой): ~0.2 л/м² на 2 стороны
    final primerNeeded = area * 0.2 * 2;

    // Штукатурка: ~10 кг/м² с двух сторон (по 5 мм на сторону)
    final plasterNeeded = area * 10 * 2;

    // Сетка штукатурная: площадь с двух сторон
    final meshArea = area * 2 * 1.05;

    // Перемычки над проёмами: по факту
    final lintelsNeeded = getIntInput(inputs, 'lintels', defaultValue: 0, minValue: 0, maxValue: 20);

    // Расчёт стоимости
    final blockPrice = findPrice(priceList, ['gasblock', 'gas_block', 'foam_block', 'aerated_concrete']);
    final gluePrice = findPrice(priceList, ['glue_gasblock', 'glue_block', 'thin_bed_mortar']);
    final reinforcementPrice = findPrice(priceList, ['rebar', 'rebar_6mm', 'reinforcement_bar']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final plasterPrice = findPrice(priceList, ['plaster', 'plaster_gypsum']);
    final meshPrice = findPrice(priceList, ['mesh', 'plaster_mesh']);
    final lintelPrice = findPrice(priceList, ['lintel', 'concrete_lintel']);

    final costs = [
      calculateCost(blocksNeeded.toDouble(), blockPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(reinforcementLength, reinforcementPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(plasterNeeded, plasterPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      if (lintelsNeeded > 0) calculateCost(lintelsNeeded.toDouble(), lintelPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'blocksNeeded': blocksNeeded.toDouble(),
        'volume': volume,
        'glueNeeded': glueNeeded,
        'reinforcementLength': reinforcementLength,
        'primerNeeded': primerNeeded,
        'plasterNeeded': plasterNeeded,
        'meshArea': meshArea,
        if (lintelsNeeded > 0) 'lintelsNeeded': lintelsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
