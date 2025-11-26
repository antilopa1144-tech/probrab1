import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор плитки / керамогранита.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 6787-2001 "Плитки керамические для полов"
///
/// Поля:
/// - area: площадь (м²)
/// - tileWidth: ширина плитки (см)
/// - tileHeight: высота плитки (см)
/// - jointWidth: ширина шва (мм), по умолчанию 3
class CalculateTile implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final tileWidth = inputs['tileWidth'] ?? 30.0; // см
    final tileHeight = inputs['tileHeight'] ?? 30.0; // см
    final jointWidth = inputs['jointWidth'] ?? 3.0; // мм

    // Площадь одной плитки в м²
    final tileArea = (tileWidth / 100) * (tileHeight / 100);

    // Количество плиток с запасом 10% (СНиП 3.04.01-87)
    final tilesNeeded = (area / tileArea * 1.1).ceil();

    // Затирка: расход ~1.5 кг/м² на 1 мм шва
    final groutNeeded = area * 1.5 * (jointWidth / 10);

    // Клей: расход ~4 кг/м² для плитки
    final glueNeeded = area * 4.0;

    // Крестики: ~4 шт на плитку
    final crossesNeeded = tilesNeeded * 4;

    // Цены
    final tilePrice = _findPrice(priceList, ['tile', 'tile_ceramic', 'tile_porcelain'])?.price;
    final groutPrice = _findPrice(priceList, ['grout', 'grout_tile'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_tile', 'glue'])?.price;

    double? totalPrice;
    if (tilePrice != null && groutPrice != null && gluePrice != null) {
      totalPrice = tilesNeeded * tilePrice +
          groutNeeded * groutPrice +
          glueNeeded * gluePrice;
    } else if (tilePrice != null) {
      totalPrice = tilesNeeded * tilePrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
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

