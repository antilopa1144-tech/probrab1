import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор покраски потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 28196-89 "Краски водно-дисперсионные"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - layers: количество слоёв (обычно 2)
/// - consumption: расход краски (кг/м²), по умолчанию 0.12 (для потолка меньше)
class CalculateCeilingPaint implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 2).round();
    final consumption = inputs['consumption'] ?? 0.12; // кг/м² для потолка

    // Расход краски с учётом слоёв и запаса 10%
    final paintNeeded = area * consumption * layers * 1.1;

    // Грунтовка: расход 0.1 кг/м², один слой
    final primerNeeded = area * 0.1 * 1.1;

    // Цены
    final paintPrice = _findPrice(priceList, ['paint_ceiling', 'paint', 'paint_water_disp'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;

    double? totalPrice;
    if (paintPrice != null && primerPrice != null) {
      totalPrice = paintNeeded * paintPrice + primerNeeded * primerPrice;
    } else if (paintPrice != null) {
      totalPrice = paintNeeded * paintPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'paintNeeded': paintNeeded,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
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

