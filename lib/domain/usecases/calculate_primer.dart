import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор грунтовки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - layers: количество слоёв, по умолчанию 1
/// - type: тип (1=обычная, 2=глубокого проникновения), по умолчанию 1
class CalculatePrimer implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 1).round();
    final type = (inputs['type'] ?? 1).round();

    // Расход грунтовки: обычная ~0.1 л/м², глубокого проникновения ~0.15 л/м²
    final consumptionPerM2 = type == 1 ? 0.1 : 0.15; // л/м²

    // Общий расход с учётом слоёв и запаса 10%
    final primerNeeded = area * consumptionPerM2 * layers * 1.1;

    // Валики: обычно 2-3 шт
    final rollersNeeded = 2;

    // Кювета: 1 шт
    final traysNeeded = 1;

    // Цены
    final primerPrice = type == 1
        ? _findPrice(priceList, ['primer', 'primer_standard'])?.price
        : _findPrice(priceList, ['primer_deep', 'primer'])?.price;

    double? totalPrice;
    if (primerPrice != null) {
      totalPrice = primerNeeded * primerPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        'rollersNeeded': rollersNeeded.toDouble(),
        'traysNeeded': traysNeeded.toDouble(),
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

