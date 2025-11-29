import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор потолочной плитки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - tileSize: размер плитки (см), по умолчанию 50 (50×50 см)
class CalculateCeilingTiles extends BaseCalculator {
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
    final tileSize = getInput(inputs, 'tileSize', defaultValue: 50.0, minValue: 30.0, maxValue: 100.0);

    // Площадь одной плитки в м²
    final tileArea = calculateTileArea(tileSize, tileSize);

    // Количество плиток с запасом 10%
    final tilesNeeded = calculateUnitsNeeded(area, tileArea, marginPercent: 10.0);

    // Клей для потолочной плитки: ~0.4-0.5 кг/м²
    final glueNeeded = area * 0.45;

    // Грунтовка: ~0.1 л/м²
    final primerNeeded = area * 0.1;

    // Потолочные плинтусы (багеты): периметр + 5%
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final plinthLength = addMargin(perimeter, 5.0);

    // Клей для багетов: ~0.3 кг на 10 м.п.
    final plinthGlueNeeded = plinthLength * 0.03;

    // Шпаклёвка для заделки швов: ~0.2 кг/м²
    final puttyNeeded = area * 0.2;

    // Краска (если плитка под покраску): ~0.12 л/м² в 2 слоя
    final isPaintable = getIntInput(inputs, 'paintable', defaultValue: 0, minValue: 0, maxValue: 1);
    final paintNeeded = isPaintable > 0 ? area * 0.12 * 2 : 0.0;

    // Расчёт стоимости
    final tilePrice = findPrice(priceList, ['ceiling_tile', 'tile_ceiling', 'polystyrene_tile']);
    final gluePrice = findPrice(priceList, ['glue_tile', 'glue', 'tile_adhesive']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_ceiling']);
    final plinthPrice = findPrice(priceList, ['plinth_ceiling', 'ceiling_molding', 'cornice']);
    final plinthGluePrice = findPrice(priceList, ['glue_plinth', 'glue']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish']);
    final paintPrice = isPaintable > 0 ? findPrice(priceList, ['paint_ceiling', 'paint']) : null;

    final costs = [
      calculateCost(tilesNeeded.toDouble(), tilePrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(plinthGlueNeeded, plinthGluePrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      if (isPaintable > 0) calculateCost(paintNeeded, paintPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'tilesNeeded': tilesNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
        'plinthLength': plinthLength,
        'plinthGlueNeeded': plinthGlueNeeded,
        'puttyNeeded': puttyNeeded,
        if (isPaintable > 0) 'paintNeeded': paintNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
