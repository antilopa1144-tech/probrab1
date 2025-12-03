import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор водостоков.
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 7623-84 "Водосточные системы"
///
/// Поля:
/// - perimeter: периметр крыши (м)
/// - downpipes: количество водосточных труб, по умолчанию 0 (автоматически)
/// - pipeHeight: высота трубы (м), по умолчанию 3.0
/// - corners: количество углов, опционально
class CalculateGutters extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final perimeter = inputs['perimeter'] ?? 0;
    if (perimeter < 0) return 'Периметр должен быть неотрицательным';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final perimeter = getInput(inputs, 'perimeter', defaultValue: 0.0, minValue: 0.0);
    final pipeHeight = getInput(inputs, 'pipeHeight', defaultValue: 3.0, minValue: 2.0, maxValue: 10.0);

    // Желоб: периметр крыши + 3% на подрезку
    final gutterLength = perimeter;

    // Водосточные трубы: 1 труба на 10-12 м периметра
    final defaultDownpipes = perimeter > 0 ? ceilToInt(perimeter / 10) : 0;
    final downpipesCount = getIntInput(inputs, 'downpipes', 
        defaultValue: defaultDownpipes, 
        minValue: 0, 
        maxValue: 20);
    final downpipeLength = downpipesCount * pipeHeight;

    // Углы желоба: обычно 4-8 углов на дом
    final corners = getIntInput(inputs, 'corners', defaultValue: 4, minValue: 0, maxValue: 20);

    // Соединители желоба: 1 шт на 3 м.п.
    final connectorsNeeded = ceilToInt(gutterLength / 3);

    // Заглушки желоба: обычно 2 (левая и правая)
    final endCaps = 2;

    // Воронки (приемники воды): по количеству труб
    final funnels = downpipesCount;

    // Колена трубы: обычно 2-3 на трубу (верх и низ)
    final elbows = downpipesCount * 2;

    // Тройники/отводы: если нужны, по факту
    final teesNeeded = getIntInput(inputs, 'tees', defaultValue: 0, minValue: 0, maxValue: 10);

    // Крепления желоба: ~1 шт на 50-60 см
    final gutterBrackets = gutterLength > 0 ? ceilToInt(gutterLength / 0.6) : 0;

    // Крепления трубы: ~1 шт на 1-1.5 м
    final pipeBrackets = ceilToInt(downpipeLength / 1.0);

    // Ревизии (для прочистки): 1 шт на трубу
    final revisionsNeeded = downpipesCount;

    // Сливные отводы: по количеству труб
    final drainsNeeded = downpipesCount;

    // Расчёт стоимости
    final gutterPrice = findPrice(priceList, ['gutter', 'gutter_metal', 'rain_gutter']);
    final downpipePrice = findPrice(priceList, ['downpipe', 'pipe_water', 'downspout']);
    final cornerPrice = findPrice(priceList, ['gutter_corner', 'corner_gutter', 'gutter_angle']);
    final connectorPrice = findPrice(priceList, ['connector_gutter', 'gutter_joiner']);
    final endCapPrice = findPrice(priceList, ['end_cap', 'cap_gutter', 'gutter_stopper']);
    final funnelPrice = findPrice(priceList, ['funnel', 'funnel_water', 'outlet']);
    final elbowPrice = findPrice(priceList, ['elbow', 'elbow_pipe', 'pipe_bend']);
    final gutterBracketPrice = findPrice(priceList, ['bracket_gutter', 'bracket', 'gutter_hanger']);
    final pipeBracketPrice = findPrice(priceList, ['bracket_pipe', 'pipe_clip']);
    final drainPrice = findPrice(priceList, ['drain', 'drain_outlet']);

    final costs = [
      calculateCost(gutterLength, gutterPrice?.price),
      calculateCost(downpipeLength, downpipePrice?.price),
      if (corners > 0) calculateCost(corners.toDouble(), cornerPrice?.price),
      calculateCost(connectorsNeeded.toDouble(), connectorPrice?.price),
      calculateCost(endCaps.toDouble(), endCapPrice?.price),
      calculateCost(funnels.toDouble(), funnelPrice?.price),
      calculateCost(elbows.toDouble(), elbowPrice?.price),
      calculateCost(gutterBrackets.toDouble(), gutterBracketPrice?.price),
      calculateCost(pipeBrackets.toDouble(), pipeBracketPrice?.price),
      calculateCost(drainsNeeded.toDouble(), drainPrice?.price),
    ];

    return createResult(
      values: {
        'gutterLength': gutterLength,
        'downpipesCount': downpipesCount.toDouble(),
        'downpipeLength': downpipeLength,
        'pipeHeight': pipeHeight,
        if (corners > 0) 'corners': corners.toDouble(),
        'connectorsNeeded': connectorsNeeded.toDouble(),
        'endCaps': endCaps.toDouble(),
        'funnels': funnels.toDouble(),
        'elbows': elbows.toDouble(),
        if (teesNeeded > 0) 'teesNeeded': teesNeeded.toDouble(),
        'gutterBrackets': gutterBrackets.toDouble(),
        'pipeBrackets': pipeBrackets.toDouble(),
        'revisionsNeeded': revisionsNeeded.toDouble(),
        'drainsNeeded': drainsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
