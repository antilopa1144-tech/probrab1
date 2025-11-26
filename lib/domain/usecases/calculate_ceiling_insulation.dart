import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор утепления потолка.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 9573-2012 "Плиты из минеральной ваты"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - thickness: толщина утеплителя (мм), по умолчанию 100
/// - type: тип утеплителя (1=минвата, 2=пенопласт), по умолчанию 1
class CalculateCeilingInsulation implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['insulationThickness'] ?? 100.0; // мм
    final type = (inputs['insulationType'] ?? 1).round();

    // Площадь одного листа/плиты
    final sheetArea = type == 1 ? 0.72 : 0.5; // м²

    // Количество листов с запасом 5%
    final sheetsNeeded = (area / sheetArea * 1.05).ceil();

    // Объём утеплителя
    final volume = area * (thickness / 1000);

    // Пароизоляция: площадь + 10% нахлёст
    final vaporBarrierArea = area * 1.1;

    // Крепёж: дюбели или скобы, ~4 шт/м²
    final fastenersNeeded = (area * 4).ceil();

    // Цены
    final insulationPrice = type == 1
        ? _findPrice(priceList, ['mineral_wool', 'wool_insulation'])?.price
        : _findPrice(priceList, ['foam', 'foam_insulation'])?.price;
    final vaporBarrierPrice = _findPrice(priceList, ['vapor_barrier', 'film_vapor'])?.price;
    final fastenerPrice = _findPrice(priceList, ['fastener_insulation', 'dowel_umbrella'])?.price;

    double? totalPrice;
    if (insulationPrice != null) {
      totalPrice = sheetsNeeded * insulationPrice;
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

