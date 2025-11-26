import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор шпаклёвки (старт/финиш).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - layers: количество слоёв, по умолчанию 2
/// - type: тип (1=старт, 2=финиш), по умолчанию 1
class CalculatePutty implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 2).round();
    final type = (inputs['type'] ?? 1).round(); // 1=старт, 2=финиш

    // Расход шпаклёвки: старт ~1.5 кг/м², финиш ~0.8 кг/м²
    final consumptionPerM2 = type == 1 ? 1.5 : 0.8; // кг/м²

    // Общий расход с учётом слоёв и запаса 10%
    final puttyNeeded = area * consumptionPerM2 * layers * 1.1;

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = area * 0.2 * 1.1;

    // Шпатели: обычно 2-3 шт
    final spatulasNeeded = 3;

    // Цены
    final puttyPrice = type == 1
        ? _findPrice(priceList, ['putty_start', 'putty'])?.price
        : _findPrice(priceList, ['putty_finish', 'putty'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;

    double? totalPrice;
    if (puttyPrice != null) {
      totalPrice = puttyNeeded * puttyPrice;
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        'spatulasNeeded': spatulasNeeded.toDouble(),
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

