import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ламината.
///
/// Рассчитывает количество ламината, подложки и плинтуса
/// с учётом способа укладки и площади помещения.
///
/// Нормативы:
/// - СП 29.13330.2011 "Полы"
///
/// Поля:
/// - area: площадь пола (м²)
/// - pattern: способ укладки (0=прямой, 1=диагональный)
/// - packArea: площадь одной упаковки (м²)
/// - needUnderlay: нужна ли подложка (0/1)
/// - needPlinth: нужен ли плинтус (0/1)
/// - roomWidth: ширина комнаты (м), опционально
/// - roomLength: длина комнаты (м), опционально
class CalculateLaminateV2 extends BaseCalculator {
  /// Процент отходов по способу укладки
  static const Map<int, double> wastePercent = {
    0: 5.0,   // Прямой
    1: 15.0,  // Диагональный
  };

  /// Площадь рулона подложки (м²)
  static const double underlayRollArea = 10.0;

  /// Длина плинтуса (м)
  static const double plinthLength = 2.5;

  /// Запас подложки (%)
  static const double underlayMargin = 10.0;

  /// Ширина дверного проёма (м)
  static const double doorWidth = 1.0;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];

    // Нужна либо площадь, либо размеры комнаты
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
    final pattern = getIntInput(inputs, 'pattern', defaultValue: 0, minValue: 0, maxValue: 1);
    final packArea = getInput(inputs, 'packArea', defaultValue: 2.4, minValue: 1.0, maxValue: 5.0);
    final needUnderlay = getIntInput(inputs, 'needUnderlay', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needPlinth = getIntInput(inputs, 'needPlinth', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Площадь: либо напрямую, либо из размеров комнаты
    double area;
    double roomWidth = 0;
    double roomLength = 0;
    final inputArea = getInput(inputs, 'area', defaultValue: 0);
    if (inputArea > 0) {
      area = inputArea;
    } else {
      roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30);
      roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 30);
      area = roomWidth * roomLength;
    }

    // Отходы
    final waste = wastePercent[pattern]!;
    final areaWithWaste = area * (1 + waste / 100);

    // Упаковки ламината
    final packsNeeded = (areaWithWaste / packArea).ceil();

    // Подложка
    double underlayArea = 0;
    int underlayRolls = 0;
    if (needUnderlay) {
      underlayArea = area * (1 + underlayMargin / 100);
      underlayRolls = (underlayArea / underlayRollArea).ceil();
    }

    // Плинтус
    double plinthTotalLength = 0;
    int plinthPieces = 0;
    if (needPlinth) {
      if (roomWidth > 0 && roomLength > 0) {
        // Периметр минус дверной проём
        plinthTotalLength = 2 * (roomWidth + roomLength) - doorWidth;
      } else {
        // Приближённый периметр из площади (квадратная комната)
        final side = area > 0 ? math.sqrt(area) : 0.0;
        plinthTotalLength = 4 * side - doorWidth;
      }
      plinthPieces = (plinthTotalLength / plinthLength).ceil();
    }

    // Расчёт стоимости
    final laminatePrice = findPrice(priceList, ['laminate', 'laminate_pack', 'ламинат']);
    final underlayPrice = findPrice(priceList, ['underlay', 'underlay_roll', 'подложка']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус']);

    final costs = [
      calculateCost(packsNeeded.toDouble(), laminatePrice?.price),
      calculateCost(underlayRolls.toDouble(), underlayPrice?.price),
      calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'pattern': pattern.toDouble(),
        'wastePercent': waste,
        'areaWithWaste': areaWithWaste,
        'packArea': packArea,
        'packsNeeded': packsNeeded.toDouble(),
        'needUnderlay': needUnderlay ? 1.0 : 0.0,
        'underlayArea': underlayArea,
        'underlayRolls': underlayRolls.toDouble(),
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'plinthLength': plinthTotalLength,
        'plinthPieces': plinthPieces.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
