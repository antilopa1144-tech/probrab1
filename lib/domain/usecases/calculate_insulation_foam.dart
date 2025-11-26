import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор утепления пенопластом / ЭППС.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 15588-2014 "Плиты пенополистирольные"
///
/// Поля:
/// - area: площадь утепления (м²)
/// - thickness: толщина утеплителя (мм), по умолчанию 50
/// - density: плотность (кг/м³), по умолчанию 25 (пенопласт)
class CalculateInsulationFoam implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 50.0; // мм
    final density = inputs['density'] ?? 25.0; // кг/м³

    // Объём утеплителя в м³
    final volume = area * (thickness / 1000);

    // Площадь одного листа (стандарт: 1×0.5 м = 0.5 м²)
    final sheetArea = 0.5; // м²

    // Количество листов с запасом 5%
    final sheetsNeeded = (area / sheetArea * 1.05).ceil();

    // Вес утеплителя
    final weight = volume * density;

    // Клей для пенопласта: ~5 кг/м²
    final glueNeeded = area * 5.0;

    // Крепёж: дюбели-грибки, ~5 шт/м²
    final fastenersNeeded = (area * 5).ceil();

    // Армирующая сетка (для фасада): площадь + 10%
    final meshArea = area * 1.1;

    // Цены
    final foamPrice = _findPrice(priceList, ['foam', 'foam_insulation', 'eps', 'xps'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_foam', 'glue_insulation'])?.price;
    final fastenerPrice = _findPrice(priceList, ['fastener_insulation', 'dowel_umbrella'])?.price;
    final meshPrice = _findPrice(priceList, ['mesh_armor', 'mesh_facade'])?.price;

    double? totalPrice;
    if (foamPrice != null) {
      totalPrice = sheetsNeeded * foamPrice;
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (fastenerPrice != null) {
        totalPrice = totalPrice + fastenersNeeded * fastenerPrice;
      }
      if (meshPrice != null) {
        totalPrice = totalPrice + meshArea * meshPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'weight': weight,
        'glueNeeded': glueNeeded,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'meshArea': meshArea,
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

