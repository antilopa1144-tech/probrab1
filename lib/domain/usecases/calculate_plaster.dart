import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор штукатурки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - thickness: толщина слоя (мм), по умолчанию 10
/// - type: тип (1=гипсовая, 2=цементная), по умолчанию 1
class CalculatePlaster implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 10.0; // мм
    final type = (inputs['type'] ?? 1).round(); // 1=гипсовая, 2=цементная

    // Расход штукатурки: ~8-10 кг/м² на 1 мм толщины
    final consumptionPerMm = type == 1 ? 8.5 : 10.0; // кг/м²·мм

    // Общий расход с запасом 10%
    final plasterNeeded = area * consumptionPerMm * (thickness / 10) * 1.1;

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = area * 0.2 * 1.1;

    // Маяки: ~1 шт на 1.5 м ширины стены
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final beaconsNeeded = (perimeter / 1.5).ceil();

    // Цены
    final plasterPrice = type == 1
        ? _findPrice(priceList, ['plaster_gypsum', 'plaster'])?.price
        : _findPrice(priceList, ['plaster_cement', 'plaster'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;
    final beaconPrice = _findPrice(priceList, ['beacon', 'beacon_plaster'])?.price;

    double? totalPrice;
    if (plasterPrice != null) {
      totalPrice = plasterNeeded * plasterPrice;
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
      if (beaconPrice != null) {
        totalPrice = totalPrice + beaconsNeeded * beaconPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'plasterNeeded': plasterNeeded,
        'primerNeeded': primerNeeded,
        'thickness': thickness,
        'beaconsNeeded': beaconsNeeded.toDouble(),
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

