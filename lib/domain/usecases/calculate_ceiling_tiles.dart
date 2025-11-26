import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор потолочной плитки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - tileSize: размер плитки (см), по умолчанию 50 (50×50 см)
class CalculateCeilingTiles implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final tileSize = inputs['tileSize'] ?? 50.0; // см

    // Площадь одной плитки в м²
    final tileArea = (tileSize / 100) * (tileSize / 100);

    // Количество плиток с запасом 10%
    final tilesNeeded = (area / tileArea * 1.1).ceil();

    // Клей: ~0.5 кг/м²
    final glueNeeded = area * 0.5;

    // Грунтовка: ~0.1 кг/м²
    final primerNeeded = area * 0.1;

    // Цены
    final tilePrice = _findPrice(priceList, ['ceiling_tile', 'tile_ceiling'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_tile', 'glue'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_ceiling'])?.price;

    double? totalPrice;
    if (tilePrice != null) {
      totalPrice = tilesNeeded * tilePrice;
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'tilesNeeded': tilesNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
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

