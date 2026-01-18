import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор линолеума.
///
/// Рассчитывает количество линолеума, двустороннего скотча и плинтуса.
///
/// Поля:
/// - area: площадь пола (м²)
/// - rollWidth: ширина рулона (м), 2-5 м
/// - needTape: нужен ли двусторонний скотч (0/1)
/// - needPlinth: нужен ли плинтус (0/1)
/// - roomWidth: ширина комнаты (м), опционально
/// - roomLength: длина комнаты (м), опционально
class CalculateLinoleumV2 extends BaseCalculator {
  /// Запас материала (%)
  static const double wastePercent = 10.0;

  /// Длина рулона (м.п.)
  static const double rollLength = 25.0;

  /// Длина плинтуса (м)
  static const double plinthLength = 2.5;

  /// Ширина дверного проёма (м)
  static const double doorWidth = 0.9;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];

    if (area <= 0 && (roomWidth == null || roomLength == null)) {
      return 'Необходимо указать площадь или размеры комнаты';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final rollWidth = getInput(inputs, 'rollWidth', defaultValue: 3.0, minValue: 2.0, maxValue: 5.0);
    final needTape = getIntInput(inputs, 'needTape', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needPlinth = getIntInput(inputs, 'needPlinth', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Площадь и размеры комнаты
    double area;
    double roomWidth;
    double roomLength;
    final inputArea = getInput(inputs, 'area', defaultValue: 0);
    if (inputArea > 0) {
      area = inputArea;
      // Приближённый расчёт размеров из площади (квадратная комната)
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    } else {
      roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30);
      roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 30);
      area = roomWidth * roomLength;
    }

    // Площадь с запасом
    final areaWithWaste = area * (1 + wastePercent / 100);

    // Погонные метры: площадь с запасом / ширина рулона
    final linearMeters = areaWithWaste / rollWidth;

    // Количество рулонов
    final rollArea = rollWidth * rollLength;
    final rollsNeeded = areaWithWaste / rollArea;

    // Двусторонний скотч: периметр + швы
    double tapeLength = 0;
    if (needTape) {
      // Периметр + один шов по длине комнаты
      tapeLength = 2 * (roomWidth + roomLength) + roomLength;
    }

    // Плинтус
    double plinthTotalLength = 0;
    int plinthPieces = 0;
    if (needPlinth) {
      plinthTotalLength = 2 * (roomWidth + roomLength) - doorWidth;
      plinthPieces = (plinthTotalLength / plinthLength).ceil();
    }

    // Расчёт стоимости
    final linoleumPrice = findPrice(priceList, ['linoleum', 'линолеум']);
    final tapePrice = findPrice(priceList, ['tape', 'double_tape', 'скотч']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус']);

    final costs = [
      calculateCost(areaWithWaste, linoleumPrice?.price),
      calculateCost(tapeLength, tapePrice?.price),
      calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'wastePercent': wastePercent,
        'areaWithWaste': areaWithWaste,
        'rollWidth': rollWidth,
        'rollLength': rollLength,
        'rollsNeeded': rollsNeeded,
        'linearMeters': linearMeters,
        'needTape': needTape ? 1.0 : 0.0,
        'tapeLength': tapeLength,
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'plinthLength': plinthTotalLength,
        'plinthPieces': plinthPieces.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
