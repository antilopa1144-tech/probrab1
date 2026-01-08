import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор паркета.
///
/// Рассчитывает количество паркета, подложки, плинтуса и клея
/// с учётом способа укладки и типа паркета.
///
/// Поля:
/// - area: площадь пола (м²)
/// - pattern: способ укладки (0=прямой, 1=диагональный, 2=ёлочка)
/// - packArea: площадь одной упаковки (м²)
/// - needUnderlay: нужна ли подложка (0/1)
/// - needPlinth: нужен ли плинтус (0/1)
/// - needGlue: нужен ли клей (0/1)
/// - roomWidth: ширина комнаты (м), опционально
/// - roomLength: длина комнаты (м), опционально
class CalculateParquetV2 extends BaseCalculator {
  /// Процент отходов по способу укладки
  static const Map<int, double> wastePercent = {
    0: 5.0,   // Прямой
    1: 15.0,  // Диагональный
    2: 20.0,  // Ёлочка
  };

  /// Длина плинтуса (м)
  static const double plinthLength = 2.5;

  /// Запас подложки (%)
  static const double underlayMargin = 10.0;

  /// Ширина дверного проёма (м)
  static const double doorWidth = 0.9;

  /// Расход клея (л/м²)
  static const double glueConsumption = 0.25;

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
    final pattern = getIntInput(inputs, 'pattern', defaultValue: 0, minValue: 0, maxValue: 2);
    final packArea = getInput(inputs, 'packArea', defaultValue: 2.0, minValue: 0.5, maxValue: 5.0);
    final needUnderlay = getIntInput(inputs, 'needUnderlay', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needPlinth = getIntInput(inputs, 'needPlinth', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needGlue = getIntInput(inputs, 'needGlue', defaultValue: 0, minValue: 0, maxValue: 1) == 1;

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

    // Отходы
    final waste = wastePercent[pattern]!;
    final areaWithWaste = area * (1 + waste / 100);

    // Упаковки паркета
    final packsNeeded = (areaWithWaste / packArea).ceil();

    // Подложка
    final underlayArea = needUnderlay ? area * (1 + underlayMargin / 100) : 0.0;

    // Плинтус
    double plinthTotalLength = 0;
    int plinthPieces = 0;
    if (needPlinth) {
      plinthTotalLength = 2 * (roomWidth + roomLength) - doorWidth;
      plinthPieces = (plinthTotalLength / plinthLength).ceil();
    }

    // Клей
    final glueLiters = needGlue ? area * glueConsumption : 0.0;

    // Расчёт стоимости
    final parquetPrice = findPrice(priceList, ['parquet', 'parquet_pack', 'паркет']);
    final underlayPrice = findPrice(priceList, ['underlay', 'underlay_roll', 'подложка']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус']);
    final gluePrice = findPrice(priceList, ['glue', 'parquet_glue', 'клей']);

    final costs = [
      calculateCost(packsNeeded.toDouble(), parquetPrice?.price),
      calculateCost(underlayArea / 10, underlayPrice?.price), // рулон = 10 м²
      calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
      calculateCost(glueLiters, gluePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'pattern': pattern.toDouble(),
        'wastePercent': waste,
        'areaWithWaste': areaWithWaste,
        'packArea': packArea,
        'packsNeeded': packsNeeded.toDouble(),
        'needUnderlay': needUnderlay ? 1.0 : 0.0,
        'underlayArea': underlayArea,
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'plinthLength': plinthTotalLength,
        'plinthPieces': plinthPieces.toDouble(),
        'needGlue': needGlue ? 1.0 : 0.0,
        'glueLiters': glueLiters,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
