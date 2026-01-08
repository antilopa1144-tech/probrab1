import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор водосточной системы.
///
/// Рассчитывает желоба, водосточные трубы, воронки, кронштейны, колена.
///
/// Поля:
/// - roofLength: длина крыши (м)
/// - roofWidth: ширина крыши (м)
/// - wallHeight: высота стены (м)
/// - downpipesCount: количество водосточных труб
/// - needHeating: нужен ли обогрев (0/1)
class CalculateGuttersV2 extends BaseCalculator {
  /// Запас на желоба (%)
  static const double gutterWastePercent = 5.0;

  /// Запас на водосточные трубы (%)
  static const double downpipeWastePercent = 10.0;

  /// Шаг кронштейнов для желобов (м)
  static const double bracketSpacing = 0.6;

  /// Шаг хомутов для труб (м)
  static const double downpipeBracketSpacing = 1.0;

  /// Количество внешних углов
  static const int cornersCount = 4;

  /// Колена на водосточную трубу (верхнее + нижнее)
  static const int elbowsPerDownpipe = 2;

  /// Дополнительные хомуты на трубу (верх + низ)
  static const int extraBracketsPerDownpipe = 2;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final roofLength = inputs['roofLength'] ?? 0;
    final roofWidth = inputs['roofWidth'] ?? 0;

    if (roofLength <= 0 || roofWidth <= 0) {
      return 'Размеры крыши должны быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final roofLength = getInput(inputs, 'roofLength', defaultValue: 10.0, minValue: 1.0, maxValue: 100.0);
    final roofWidth = getInput(inputs, 'roofWidth', defaultValue: 8.0, minValue: 1.0, maxValue: 50.0);
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 3.0, minValue: 2.0, maxValue: 15.0);
    final downpipesCount = getIntInput(inputs, 'downpipesCount', defaultValue: 4, minValue: 1, maxValue: 20);
    final needHeating = getIntInput(inputs, 'needHeating', defaultValue: 0, minValue: 0, maxValue: 1) == 1;

    // Периметр крыши
    final perimeter = 2 * (roofLength + roofWidth);

    // Длина желобов с запасом
    final gutterLength = perimeter * (1 + gutterWastePercent / 100);

    // Водосточные трубы
    final downpipeLength = downpipesCount * wallHeight * (1 + downpipeWastePercent / 100);

    // Воронки: по количеству водосточных труб
    final funnelsCount = downpipesCount;

    // Кронштейны для желобов: через 0.6 м
    final bracketsCount = (perimeter / bracketSpacing).ceil();

    // Хомуты для труб: через 1 м + верх и низ
    final downpipeBrackets = downpipesCount * ((wallHeight / downpipeBracketSpacing).ceil() + extraBracketsPerDownpipe);

    // Колена: 2 на каждую трубу
    final elbowsCount = downpipesCount * elbowsPerDownpipe;

    // Обогрев
    double heatingLength = 0;
    if (needHeating) {
      heatingLength = gutterLength + downpipeLength;
    }

    // Расчёт стоимости
    final gutterPrice = findPrice(priceList, ['gutter', 'желоб', 'gutters']);
    final downpipePrice = findPrice(priceList, ['downpipe', 'труба', 'pipe']);
    final cornerPrice = findPrice(priceList, ['corner', 'угол', 'gutter_corner']);
    final funnelPrice = findPrice(priceList, ['funnel', 'воронка', 'gutter_funnel']);
    final bracketPrice = findPrice(priceList, ['bracket', 'кронштейн', 'gutter_bracket']);
    final elbowPrice = findPrice(priceList, ['elbow', 'колено', 'gutter_elbow']);
    final heatingPrice = needHeating ? findPrice(priceList, ['heating', 'обогрев', 'gutter_heating']) : null;

    final costs = [
      calculateCost(gutterLength, gutterPrice?.price),
      calculateCost(downpipeLength, downpipePrice?.price),
      calculateCost(cornersCount.toDouble(), cornerPrice?.price),
      calculateCost(funnelsCount.toDouble(), funnelPrice?.price),
      calculateCost(bracketsCount.toDouble(), bracketPrice?.price),
      calculateCost(downpipeBrackets.toDouble(), bracketPrice?.price),
      calculateCost(elbowsCount.toDouble(), elbowPrice?.price),
      if (needHeating) calculateCost(heatingLength, heatingPrice?.price),
    ];

    return createResult(
      values: {
        'roofLength': roofLength,
        'roofWidth': roofWidth,
        'wallHeight': wallHeight,
        'downpipesCount': downpipesCount.toDouble(),
        'needHeating': needHeating ? 1.0 : 0.0,
        'perimeter': perimeter,
        'gutterLength': gutterLength,
        'downpipeLength': downpipeLength,
        'cornersCount': cornersCount.toDouble(),
        'funnelsCount': funnelsCount.toDouble(),
        'bracketsCount': bracketsCount.toDouble(),
        'downpipeBrackets': downpipeBrackets.toDouble(),
        'elbowsCount': elbowsCount.toDouble(),
        'heatingLength': heatingLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
