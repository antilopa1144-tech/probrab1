// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор деревянного фасада (вагонка, планкен, блок-хаус).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 8242-88 "Детали профильные из древесины"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - boardWidth: ширина доски (см), по умолчанию 14
/// - boardLength: длина доски (м), по умолчанию 3
/// - perimeter: периметр здания (м), опционально
class CalculateWoodFacade extends BaseCalculator {
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
    final boardWidth = getInput(inputs, 'boardWidth', defaultValue: 14.0, minValue: 8.0, maxValue: 25.0);
    final boardLength = getInput(inputs, 'boardLength', defaultValue: 3.0, minValue: 2.0, maxValue: 6.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной доски в м²
    final boardArea = (boardWidth / 100) * boardLength;

    // Количество досок с запасом 10%
    final boardsNeeded = calculateUnitsNeeded(area, boardArea, marginPercent: 10.0);

    // Обрешётка (бруски 40×40 мм): шаг 50-60 см
    final battensCount = ceilToInt((perimeter / 4) / 0.55);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5);
    final battensLength = battensCount * wallHeight;

    // Угловые планки (внешние и внутренние)
    final cornersLength = addMargin(perimeter * 0.25, 5.0);

    // Антисептик для дерева: ~0.3 л/м²
    final antisepticNeeded = area * 0.3;

    // Лак/масло для фасада: ~0.15 л/м² на слой (2-3 слоя)
    final finishNeeded = area * 0.15 * 2.5;

    // Грунтовка для дерева: ~0.1 л/м²
    final primerNeeded = area * 0.1;

    // Крепёж: гвозди/саморезы ~8-10 шт на доску
    final fastenersNeeded = ceilToInt(boardsNeeded * 9);

    // Расчёт стоимости
    final boardPrice = findPrice(priceList, ['wood_facade', 'wood_board', 'lining_facade', 'siding_wood']);
    final battensPrice = findPrice(priceList, ['battens', 'timber', 'wood_strips']);
    final cornerPrice = findPrice(priceList, ['corner_wood_facade', 'corner', 'wood_corner']);
    final antisepticPrice = findPrice(priceList, ['antiseptic', 'wood_preservative']);
    final finishPrice = findPrice(priceList, ['varnish_facade', 'oil_facade', 'wood_finish']);
    final primerPrice = findPrice(priceList, ['primer_wood', 'wood_primer']);

    final costs = [
      calculateCost(boardsNeeded.toDouble(), boardPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(cornersLength, cornerPrice?.price),
      calculateCost(antisepticNeeded, antisepticPrice?.price),
      calculateCost(finishNeeded, finishPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'boardsNeeded': boardsNeeded.toDouble(),
        'battensLength': battensLength,
        'cornersLength': cornersLength,
        'antisepticNeeded': antisepticNeeded,
        'finishNeeded': finishNeeded,
        'primerNeeded': primerNeeded,
        'fastenersNeeded': fastenersNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
