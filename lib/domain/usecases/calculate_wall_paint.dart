import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор покраски стен.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 28196-89 "Краски водно-дисперсионные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - layers: количество слоёв (обычно 2)
/// - consumption: расход краски (кг/м²), по умолчанию 0.15 (СНиП)
/// - windowsArea: площадь окон (м²) - вычитается из общей площади
/// - doorsArea: площадь дверей (м²) - вычитается из общей площади
class CalculateWallPaint implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 2).round();
    final consumption = inputs['consumption'] ?? 0.15; // кг/м² по СНиП
    final windowsArea = inputs['windowsArea'] ?? 0;
    final doorsArea = inputs['doorsArea'] ?? 0;

    // Полезная площадь (за вычетом проёмов)
    final usefulArea = (area - windowsArea - doorsArea).clamp(0.0, double.infinity);

    // Расход краски с учётом слоёв и запаса 10% (СНиП 3.04.01-87)
    final paintNeeded = usefulArea * consumption * layers * 1.1;

    // Грунтовка: расход 0.1 кг/м², один слой
    final primerNeeded = usefulArea * 0.1 * 1.1;

    // Цены из прайса
    final paintPrice = _findPrice(priceList, ['paint_wall', 'paint', 'paint_water_disp'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;

    double? totalPrice;
    if (paintPrice != null && primerPrice != null) {
      totalPrice = paintNeeded * paintPrice + primerNeeded * primerPrice;
    } else if (paintPrice != null) {
      totalPrice = paintNeeded * paintPrice;
    }

    return CalculatorResult(
      values: {
        'usefulArea': usefulArea,
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

