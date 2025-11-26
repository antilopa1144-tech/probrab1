import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор плитки для ванной комнаты.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 6787-2001 "Плитки керамические для полов"
///
/// Поля:
/// - wallArea: площадь стен (м²)
/// - floorArea: площадь пола (м²)
/// - tileWidth: ширина плитки (см), по умолчанию 30
/// - tileHeight: высота плитки (см), по умолчанию 30
/// - jointWidth: ширина шва (мм), по умолчанию 3
class CalculateBathroomTile implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final wallArea = inputs['wallArea'] ?? 0;
    final floorArea = inputs['floorArea'] ?? 0;
    final tileWidth = inputs['tileWidth'] ?? 30.0; // см
    final tileHeight = inputs['tileHeight'] ?? 30.0; // см
    final jointWidth = inputs['jointWidth'] ?? 3.0; // мм

    final totalArea = wallArea + floorArea;

    // Площадь одной плитки в м²
    final tileArea = (tileWidth / 100) * (tileHeight / 100);

    // Количество плиток с запасом 10%
    final wallTiles = (wallArea / tileArea * 1.1).ceil();
    final floorTiles = (floorArea / tileArea * 1.1).ceil();
    final totalTiles = wallTiles + floorTiles;

    // Затирка: расход ~1.5 кг/м² на 1 мм шва
    final groutNeeded = totalArea * 1.5 * (jointWidth / 10);

    // Клей: расход ~4 кг/м² для плитки
    final glueNeeded = totalArea * 4.0;

    // Крестики: ~4 шт на плитку
    final crossesNeeded = totalTiles * 4;

    // Гидроизоляция: площадь пола + 30 см на стены
    final waterproofingArea = floorArea + (wallArea * 0.3);

    // Цены
    final tilePrice = _findPrice(priceList, ['tile_bathroom', 'tile', 'tile_ceramic'])?.price;
    final groutPrice = _findPrice(priceList, ['grout', 'grout_tile'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_tile', 'glue'])?.price;
    final waterproofingPrice = _findPrice(priceList, ['waterproofing', 'waterproofing_bathroom'])?.price;

    double? totalPrice;
    if (tilePrice != null) {
      totalPrice = totalTiles * tilePrice;
      if (groutPrice != null) {
        totalPrice = totalPrice + groutNeeded * groutPrice;
      }
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (waterproofingPrice != null) {
        totalPrice = totalPrice + waterproofingArea * waterproofingPrice;
      }
    }

    return CalculatorResult(
      values: {
        'wallArea': wallArea,
        'floorArea': floorArea,
        'totalTiles': totalTiles.toDouble(),
        'groutNeeded': groutNeeded,
        'glueNeeded': glueNeeded,
        'crossesNeeded': crossesNeeded.toDouble(),
        'waterproofingArea': waterproofingArea,
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

