import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор шумоизоляции.
///
/// Нормативы:
/// - СНиП 23-03-2003 "Защита от шума"
/// - ГОСТ 23499-2009 "Материалы и изделия звукопоглощающие"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - thickness: толщина материала (мм), по умолчанию 50
/// - type: тип (1=минвата, 2=пенополиуретан), по умолчанию 1
class CalculateSoundInsulation implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 50.0; // мм
    final type = (inputs['insulationType'] ?? 1).round();

    // Площадь одного листа/плиты
    final sheetArea = type == 1 ? 0.72 : 0.5; // м²

    // Количество листов с запасом 5%
    final sheetsNeeded = (area / sheetArea * 1.05).ceil();

    // Объём материала
    final volume = area * (thickness / 1000);

    // Крепёж: дюбели или скобы
    final fastenersNeeded = (area * 4).ceil();

    // Цены
    final insulationPrice = type == 1
        ? _findPrice(priceList, ['mineral_wool', 'wool_insulation'])?.price
        : _findPrice(priceList, ['foam_pu', 'foam_sound'])?.price;
    final fastenerPrice = _findPrice(priceList, ['fastener_insulation', 'dowel'])?.price;

    double? totalPrice;
    if (insulationPrice != null) {
      totalPrice = sheetsNeeded * insulationPrice;
      if (fastenerPrice != null) {
        totalPrice = totalPrice + fastenersNeeded * fastenerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
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

