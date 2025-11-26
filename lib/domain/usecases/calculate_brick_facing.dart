import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор облицовочного кирпича.
///
/// Нормативы:
/// - СНиП 3.03.01-87 "Несущие и ограждающие конструкции"
/// - ГОСТ 530-2012 "Кирпич и камень керамические"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - thickness: толщина стены (кирпичей), по умолчанию 0.5 (полкирпича)
/// - windowsArea: площадь окон (м²), по умолчанию 0
/// - doorsArea: площадь дверей (м²), по умолчанию 0
class CalculateBrickFacing implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 0.5; // в кирпичах
    final windowsArea = inputs['windowsArea'] ?? 0;
    final doorsArea = inputs['doorsArea'] ?? 0;

    // Полезная площадь (без проёмов)
    final usefulArea = area - windowsArea - doorsArea;

    // Количество кирпичей на 1 м² (для облицовки обычно полкирпича)
    final bricksPerM2 = thickness == 0.5 ? 61.5 : 128.0;

    // Количество кирпичей с запасом 5%
    final bricksNeeded = (usefulArea * bricksPerM2 * 1.05).ceil();

    // Раствор: ~0.02 м³ на 1 м² для полкирпича
    final mortarVolume = usefulArea * 0.02 * thickness * 1.1;

    // Цемент и песок для раствора (пропорция 1:3)
    final cementNeeded = mortarVolume * 400; // кг
    final sandNeeded = mortarVolume * 1200; // кг

    // Армирующая сетка: через каждые 5 рядов
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final wallHeight = inputs['wallHeight'] ?? 2.5;
    final rows = (wallHeight / 0.065).ceil(); // высота кирпича 65 мм
    final reinforcementRows = (rows / 5).ceil();
    final reinforcementLength = reinforcementRows * perimeter;

    // Цены
    final brickPrice = _findPrice(priceList, ['brick_facing', 'brick_red', 'brick_ceramic'])?.price;
    final cementPrice = _findPrice(priceList, ['cement', 'cement_bag'])?.price;
    final sandPrice = _findPrice(priceList, ['sand', 'sand_construction'])?.price;
    final reinforcementPrice = _findPrice(priceList, ['rebar', 'rebar_4mm'])?.price;

    double? totalPrice;
    if (brickPrice != null) {
      totalPrice = bricksNeeded * brickPrice;
      if (cementPrice != null && sandPrice != null) {
        totalPrice = totalPrice + 
            (cementNeeded / 50) * cementPrice + // мешки по 50 кг
            (sandNeeded / 1000) * sandPrice; // тонны
      }
      if (reinforcementPrice != null) {
        totalPrice = totalPrice + reinforcementLength * reinforcementPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'bricksNeeded': bricksNeeded.toDouble(),
        'mortarVolume': mortarVolume,
        'cementNeeded': cementNeeded,
        'sandNeeded': sandNeeded,
        'reinforcementLength': reinforcementLength,
      },
      totalPrice: totalPrice,
    );
  }

  PriceItem? _findPrice(List<PriceItem> priceList, List<String> skus) {
    for (final sku in skus) {
      try {
        return priceList.firstWhere((item) => item.sku == sku);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}

