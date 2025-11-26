import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор перегородок из кирпича.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 530-2012 "Кирпич и камень керамические"
///
/// Поля:
/// - area: площадь перегородки (м²)
/// - thickness: толщина стены (кирпичей), по умолчанию 0.5 (полкирпича)
/// - height: высота перегородки (м), по умолчанию 2.5
class CalculateBrickPartition implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 0.5; // в кирпичах (0.5 = полкирпича, 1 = кирпич)

    // Количество кирпичей на 1 м² стены
    // Для полкирпича: 1 / (0.25 * 0.065) ≈ 61.5 шт/м²
    // Для кирпича: 1 / (0.12 * 0.065) ≈ 128 шт/м²
    final bricksPerM2 = thickness == 0.5 
        ? 61.5 
        : (thickness == 1.0 ? 128.0 : 61.5);

    // Количество кирпичей с запасом 5%
    final bricksNeeded = (area * bricksPerM2 * 1.05).ceil();

    // Раствор: ~0.02 м³ на 1 м² стены для полкирпича
    final mortarVolume = area * 0.02 * thickness * 1.1; // +10% запас

    // Цемент и песок для раствора (пропорция 1:3)
    final cementNeeded = mortarVolume * 400; // кг (примерно)
    final sandNeeded = mortarVolume * 1200; // кг

    // Цены
    final brickPrice = _findPrice(priceList, ['brick', 'brick_red', 'brick_ceramic'])?.price;
    final cementPrice = _findPrice(priceList, ['cement', 'cement_bag'])?.price;
    final sandPrice = _findPrice(priceList, ['sand', 'sand_construction'])?.price;

    double? totalPrice;
    if (brickPrice != null) {
      totalPrice = bricksNeeded * brickPrice;
      if (cementPrice != null && sandPrice != null) {
        totalPrice = totalPrice + 
            (cementNeeded / 50) * cementPrice + // мешки по 50 кг
            (sandNeeded / 1000) * sandPrice; // тонны
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'bricksNeeded': bricksNeeded.toDouble(),
        'mortarVolume': mortarVolume,
        'cementNeeded': cementNeeded,
        'sandNeeded': sandNeeded,
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

