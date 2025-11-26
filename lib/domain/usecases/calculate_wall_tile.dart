import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор плитки на стены (не ванная).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 6787-2001 "Плитки керамические для полов"
///
/// Поля:
/// - area: площадь стен (м²)
/// - tileWidth: ширина плитки (см), по умолчанию 30
/// - tileHeight: высота плитки (см), по умолчанию 30
/// - jointWidth: ширина шва (мм), по умолчанию 3
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateWallTile implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final tileWidth = inputs['tileWidth'] ?? 30.0; // см
    final tileHeight = inputs['tileHeight'] ?? 30.0; // см
    final jointWidth = inputs['jointWidth'] ?? 3.0; // мм
    final windowsArea = inputs['windowsArea'] ?? 0;
    final doorsArea = inputs['doorsArea'] ?? 0;

    final usefulArea = area - windowsArea - doorsArea;

    // Площадь одной плитки в м²
    final tileArea = (tileWidth / 100) * (tileHeight / 100);

    // Количество плиток с запасом 10%
    final tilesNeeded = (usefulArea / tileArea * 1.1).ceil();

    // Затирка: расход ~1.5 кг/м² на 1 мм шва
    final groutNeeded = usefulArea * 1.5 * (jointWidth / 10);

    // Клей: расход ~4 кг/м² для плитки
    final glueNeeded = usefulArea * 4.0;

    // Крестики: ~4 шт на плитку
    final crossesNeeded = tilesNeeded * 4;

    // Цены
    final tilePrice = _findPrice(priceList, ['tile', 'tile_ceramic', 'tile_wall'])?.price;
    final groutPrice = _findPrice(priceList, ['grout', 'grout_tile'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_tile', 'glue'])?.price;

    double? totalPrice;
    if (tilePrice != null) {
      totalPrice = tilesNeeded * tilePrice;
      if (groutPrice != null) {
        totalPrice = totalPrice + groutNeeded * groutPrice;
      }
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'tilesNeeded': tilesNeeded.toDouble(),
        'groutNeeded': groutNeeded,
        'glueNeeded': glueNeeded,
        'crossesNeeded': crossesNeeded.toDouble(),
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

