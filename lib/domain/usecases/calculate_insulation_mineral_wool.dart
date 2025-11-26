import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор утепления минеральной ватой.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 9573-2012 "Плиты из минеральной ваты"
///
/// Поля:
/// - area: площадь утепления (м²)
/// - thickness: толщина утеплителя (мм), по умолчанию 100
/// - density: плотность (кг/м³), по умолчанию 50
class CalculateInsulationMineralWool implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 100.0; // мм
    final density = inputs['density'] ?? 50.0; // кг/м³

    // Объём утеплителя в м³
    final volume = area * (thickness / 1000);

    // Площадь одного рулона/плиты (стандарт: 0.6×1.2 м = 0.72 м²)
    final sheetArea = 0.72; // м²

    // Количество плит/рулонов с запасом 5%
    final sheetsNeeded = (area / sheetArea * 1.05).ceil();

    // Вес утеплителя
    final weight = volume * density;

    // Пароизоляция: площадь + 10% нахлёст
    final vaporBarrierArea = area * 1.1;

    // Крепёж: дюбели-грибки, ~5 шт/м²
    final fastenersNeeded = (area * 5).ceil();

    // Цены
    final woolPrice = _findPrice(priceList, ['mineral_wool', 'wool_insulation', 'insulation_wool'])?.price;
    final vaporBarrierPrice = _findPrice(priceList, ['vapor_barrier', 'film_vapor'])?.price;
    final fastenerPrice = _findPrice(priceList, ['fastener_insulation', 'dowel_umbrella'])?.price;

    double? totalPrice;
    if (woolPrice != null) {
      totalPrice = sheetsNeeded * woolPrice;
      if (vaporBarrierPrice != null) {
        totalPrice = totalPrice + vaporBarrierArea * vaporBarrierPrice;
      }
      if (fastenerPrice != null) {
        totalPrice = totalPrice + fastenersNeeded * fastenerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'weight': weight,
        'vaporBarrierArea': vaporBarrierArea,
        'fastenersNeeded': fastenersNeeded.toDouble(),
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

