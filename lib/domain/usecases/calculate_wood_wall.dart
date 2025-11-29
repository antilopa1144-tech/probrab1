import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор вагонки / бруса на стены.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 8242-88 "Детали профильные из древесины"
///
/// Поля:
/// - area: площадь стен (м²)
/// - boardWidth: ширина доски (см), по умолчанию 10
/// - boardLength: длина доски (м), по умолчанию 3
/// - perimeter: периметр комнаты (м), опционально
class CalculateWoodWall extends BaseCalculator {
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
    final boardWidth = getInput(inputs, 'boardWidth', defaultValue: 10.0, minValue: 5.0, maxValue: 20.0);
    final boardLength = getInput(inputs, 'boardLength', defaultValue: 3.0, minValue: 2.0, maxValue: 6.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной доски в м²
    final boardArea = (boardWidth / 100) * boardLength;

    // Количество досок с запасом 10%
    final boardsNeeded = calculateUnitsNeeded(area, boardArea, marginPercent: 10.0);

    // Обрешётка (бруски 40×40 мм): шаг 50-60 см
    final battensCount = ceilToInt((perimeter / 4) / 0.55);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);
    final battensLength = battensCount * wallHeight;

    // Плинтус напольный: по периметру
    final plinthLength = addMargin(perimeter, 3.0);

    // Уголки (внутренние и наружные): по факту
    final cornersLength = addMargin(perimeter * 0.25, 5.0);

    // Потолочный плинтус: по периметру
    final ceilingPlinthLength = addMargin(perimeter, 3.0);

    // Антисептик для дерева: ~0.3 л/м² (для защиты)
    final antisepticNeeded = area * 0.3;

    // Лак/масло для финишной отделки: ~0.1 л/м² на слой (2-3 слоя)
    final finishLayers = 2;
    final finishNeeded = area * 0.1 * finishLayers;

    // Грунтовка для дерева: ~0.1 л/м²
    final primerNeeded = area * 0.1;

    // Крепёж: гвозди/саморезы ~8-10 шт на доску
    final fastenersNeeded = ceilToInt(boardsNeeded * 9);

    // Кляймеры (для вагонки евро): альтернатива гвоздям
    final clampsNeeded = ceilToInt(boardsNeeded * 5);

    // Расчёт стоимости
    final boardPrice = findPrice(priceList, ['wood_wall', 'wood_board', 'lining', 'clapboard']);
    final battensPrice = findPrice(priceList, ['battens', 'timber', 'wood_strips']);
    final plinthPrice = findPrice(priceList, ['plinth_wood', 'plinth', 'wood_baseboard']);
    final cornerPrice = findPrice(priceList, ['corner_wood', 'corner', 'wood_corner']);
    final ceilingPlinthPrice = findPrice(priceList, ['plinth_ceiling', 'ceiling_molding']);
    final antisepticPrice = findPrice(priceList, ['antiseptic', 'wood_preservative']);
    final finishPrice = findPrice(priceList, ['varnish_wood', 'oil_wood', 'wood_finish']);
    final primerPrice = findPrice(priceList, ['primer_wood', 'wood_primer']);

    final costs = [
      calculateCost(boardsNeeded.toDouble(), boardPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(cornersLength, cornerPrice?.price),
      calculateCost(ceilingPlinthLength, ceilingPlinthPrice?.price),
      calculateCost(antisepticNeeded, antisepticPrice?.price),
      calculateCost(finishNeeded, finishPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'boardsNeeded': boardsNeeded.toDouble(),
        'battensLength': battensLength,
        'plinthLength': plinthLength,
        'cornersLength': cornersLength,
        'ceilingPlinthLength': ceilingPlinthLength,
        'antisepticNeeded': antisepticNeeded,
        'finishNeeded': finishNeeded,
        'finishLayers': finishLayers.toDouble(),
        'primerNeeded': primerNeeded,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'clampsNeeded': clampsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
