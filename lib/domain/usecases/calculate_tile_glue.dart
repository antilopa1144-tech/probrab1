import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор плиточного клея.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь укладки (м²)
/// - tileSize: размер плитки (см), по умолчанию 30
/// - layerThickness: толщина слоя клея (мм), по умолчанию 5
class CalculateTileGlue implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final tileSize = inputs['tileSize'] ?? 30.0; // см
    final layerThickness = inputs['layerThickness'] ?? 5.0; // мм

    // Расход клея зависит от размера плитки и толщины слоя
    // Для плитки 30×30 см: ~4 кг/м² при слое 5 мм
    // Для большей плитки расход меньше
    final baseConsumption = 4.0; // кг/м²
    final sizeFactor = tileSize > 40 ? 0.9 : (tileSize < 20 ? 1.1 : 1.0);
    final thicknessFactor = layerThickness / 5.0;

    final consumptionPerM2 = baseConsumption * sizeFactor * thicknessFactor;

    // Общий расход с запасом 10%
    final glueNeeded = area * consumptionPerM2 * 1.1;

    // Зубчатый шпатель: обычно 1-2 шт
    final spatulasNeeded = 2;

    // Цены
    final gluePrice = _findPrice(priceList, ['glue_tile', 'tile_adhesive', 'glue'])?.price;

    double? totalPrice;
    if (gluePrice != null) {
      totalPrice = glueNeeded * gluePrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'glueNeeded': glueNeeded,
        'consumptionPerM2': consumptionPerM2,
        'spatulasNeeded': spatulasNeeded.toDouble(),
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

