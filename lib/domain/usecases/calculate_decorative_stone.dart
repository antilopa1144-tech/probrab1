import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор декоративного камня.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - stoneWidth: ширина камня (см), по умолчанию 20
/// - stoneHeight: высота камня (см), по умолчанию 5
/// - thickness: толщина камня (см), по умолчанию 2
class CalculateDecorativeStone implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final stoneWidth = inputs['stoneWidth'] ?? 20.0; // см
    final stoneHeight = inputs['stoneHeight'] ?? 5.0; // см

    // Площадь одного камня в м²
    final stoneArea = (stoneWidth / 100) * (stoneHeight / 100);

    // Количество камней с запасом 15% (для подрезки)
    final stonesNeeded = (area / stoneArea * 1.15).ceil();

    // Клей: ~5 кг/м²
    final glueNeeded = area * 5.0;

    // Затирка: ~2 кг/м²
    final groutNeeded = area * 2.0;

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = area * 0.2;

    // Цены
    final stonePrice = _findPrice(priceList, ['stone_decorative', 'stone', 'stone_artificial'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_stone', 'glue'])?.price;
    final groutPrice = _findPrice(priceList, ['grout_stone', 'grout'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_stone'])?.price;

    double? totalPrice;
    if (stonePrice != null) {
      totalPrice = stonesNeeded * stonePrice;
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (groutPrice != null) {
        totalPrice = totalPrice + groutNeeded * groutPrice;
      }
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'stonesNeeded': stonesNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'groutNeeded': groutNeeded,
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

