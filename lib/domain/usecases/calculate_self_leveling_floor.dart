import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор наливного пола.
///
/// Нормативы:
/// - СНиП 2.03.13-88 "Полы"
/// - ГОСТ 31356-2007 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь пола (м²)
/// - thickness: толщина слоя (мм), по умолчанию 5
class CalculateSelfLevelingFloor implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 5.0; // мм

    // Расход наливного пола: ~1.5 кг/м² на 1 мм толщины
    final consumptionPerMm = 1.5; // кг/м²·мм
    final mixNeeded = area * consumptionPerMm * thickness * 1.1; // +10% запас

    // Грунтовка: 0.2 кг/м²
    final primerNeeded = area * 0.2 * 1.1;

    // Игольчатый валик для раскатки (обычно 1 шт)
    final rollersNeeded = 1;

    // Цены
    final mixPrice = _findPrice(priceList, ['self_leveling', 'self_leveling_floor', 'leveling_compound'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;

    double? totalPrice;
    if (mixPrice != null && primerPrice != null) {
      totalPrice = mixNeeded * mixPrice + primerNeeded * primerPrice;
    } else if (mixPrice != null) {
      totalPrice = mixNeeded * mixPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'mixNeeded': mixNeeded,
        'primerNeeded': primerNeeded,
        'thickness': thickness,
        'rollersNeeded': rollersNeeded.toDouble(),
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

