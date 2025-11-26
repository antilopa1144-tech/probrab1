import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор декоративной штукатурки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - thickness: толщина слоя (мм), по умолчанию 2 (для венецианки)
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateDecorativePlaster implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 2.0; // мм
    final windowsArea = inputs['windowsArea'] ?? 0;
    final doorsArea = inputs['doorsArea'] ?? 0;

    // Полезная площадь
    final usefulArea = (area - windowsArea - doorsArea).clamp(0.0, double.infinity);

    // Расход штукатурки: ~1.5 кг/м² на 1 мм толщины (для декоративной)
    final consumptionPerMm = 1.5; // кг/м²·мм
    final plasterNeeded = usefulArea * consumptionPerMm * thickness * 1.1; // +10% запас

    // Грунтовка глубокого проникновения: 0.15 кг/м²
    final primerNeeded = usefulArea * 0.15 * 1.1;

    // Цены
    final plasterPrice = _findPrice(priceList, ['plaster_decor', 'plaster_venetian', 'plaster_texture'])?.price;
    final primerPrice = _findPrice(priceList, ['primer_deep', 'primer'])?.price;

    double? totalPrice;
    if (plasterPrice != null && primerPrice != null) {
      totalPrice = plasterNeeded * plasterPrice + primerNeeded * primerPrice;
    } else if (plasterPrice != null) {
      totalPrice = plasterNeeded * plasterPrice;
    }

    return CalculatorResult(
      values: {
        'usefulArea': usefulArea,
        'plasterNeeded': plasterNeeded,
        'primerNeeded': primerNeeded,
        'thickness': thickness,
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

