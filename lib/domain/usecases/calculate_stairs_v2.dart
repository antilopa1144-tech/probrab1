import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор лестницы.
///
/// Рассчитывает параметры лестницы: ступени, косоуры, перила.
///
/// Поля:
/// - floorHeight: высота этажа (м)
/// - stairsWidth: ширина лестницы (м)
/// - stairsType: тип лестницы (0 - прямая, 1 - Г-образная, 2 - П-образная)
/// - needRailing: нужны ли перила (0/1)
/// - needBothSides: перила с обеих сторон (0/1)
class CalculateStairsV2 extends BaseCalculator {
  /// Оптимальная высота ступени (м)
  static const double optimalStepHeight = 0.17;

  /// Формула удобства: 2h + d = comfort (м)
  static const double comfortFormula = 0.62;

  /// Минимальная глубина ступени (м)
  static const double minStepDepth = 0.25;

  /// Максимальная глубина ступени (м)
  static const double maxStepDepth = 0.35;

  /// Минимальная высота ступени для комфорта (м)
  static const double minComfortStepHeight = 0.15;

  /// Максимальная высота ступени для комфорта (м)
  static const double maxComfortStepHeight = 0.20;

  /// Запас на длину косоура (%)
  static const double stringerWastePercent = 10.0;

  /// Дополнительная длина перил на верхнюю площадку (м)
  static const double railingExtra = 0.5;

  /// Коэффициенты длины по типу лестницы
  static const Map<int, double> lengthCoefficients = {
    0: 1.0,   // прямая
    1: 0.75,  // Г-образная (с площадкой)
    2: 0.55,  // П-образная (компактнее)
  };

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final floorHeight = inputs['floorHeight'] ?? 0;
    if (floorHeight <= 0) {
      return 'Высота этажа должна быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final floorHeight = getInput(inputs, 'floorHeight', defaultValue: 2.8, minValue: 2.0, maxValue: 6.0);
    final stairsWidth = getInput(inputs, 'stairsWidth', defaultValue: 0.9, minValue: 0.6, maxValue: 1.5);
    final stairsType = getIntInput(inputs, 'stairsType', defaultValue: 0, minValue: 0, maxValue: 2);
    final needRailing = getIntInput(inputs, 'needRailing', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needBothSides = getIntInput(inputs, 'needBothSides', defaultValue: 0, minValue: 0, maxValue: 1) == 1;

    // Количество ступеней (оптимальная высота ~17 см)
    final stepsCount = (floorHeight / optimalStepHeight).ceil();

    // Фактическая высота ступени
    final stepHeight = floorHeight / stepsCount;

    // Глубина ступени по формуле удобства: 2h + d = 62 см
    final calculatedDepth = comfortFormula - 2 * stepHeight;
    final stepDepth = calculatedDepth.clamp(minStepDepth, maxStepDepth);

    // Длина лестницы с учётом типа
    final lengthCoef = lengthCoefficients[stairsType] ?? 1.0;
    final stairsLength = stepsCount * stepDepth * lengthCoef;

    // Количество косоуров: при ширине > 1.2м добавляется центральный (3-й)
    final stringerCount = stairsWidth > 1.2 ? 3 : 2;

    // Длина косоура по теореме Пифагора + запас
    final stringerLength = math.sqrt(floorHeight * floorHeight + stairsLength * stairsLength) *
        (1 + stringerWastePercent / 100);

    // Перила
    double railingLength = 0;
    if (needRailing) {
      railingLength = stairsLength + railingExtra;
      if (needBothSides) {
        railingLength *= 2;
      }
    }

    // Проверка комфортности
    final isComfortable = stepHeight >= minComfortStepHeight && stepHeight <= maxComfortStepHeight;

    // Расчёт стоимости
    final stepsPrice = findPrice(priceList, ['step', 'ступень', 'stairs_step']);
    final stringerPrice = findPrice(priceList, ['stringer', 'косоур', 'stairs_stringer']);
    final railingPrice = findPrice(priceList, ['railing', 'перила', 'stairs_railing']);

    final costs = [
      calculateCost(stepsCount.toDouble(), stepsPrice?.price),
      calculateCost(stringerLength * stringerCount, stringerPrice?.price),
      if (needRailing) calculateCost(railingLength, railingPrice?.price),
    ];

    return createResult(
      values: {
        'floorHeight': floorHeight,
        'stairsWidth': stairsWidth,
        'stairsType': stairsType.toDouble(),
        'needRailing': needRailing ? 1.0 : 0.0,
        'needBothSides': needBothSides ? 1.0 : 0.0,
        'stepsCount': stepsCount.toDouble(),
        'stepHeight': stepHeight,
        'stepDepth': stepDepth,
        'stairsLength': stairsLength,
        'stringerLength': stringerLength,
        'stringerCount': stringerCount.toDouble(),
        'railingLength': railingLength,
        'isComfortable': isComfortable ? 1.0 : 0.0,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
