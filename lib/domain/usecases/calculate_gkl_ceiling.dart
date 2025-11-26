import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор подвесного потолка из ГКЛ.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - layers: количество слоёв ГКЛ, по умолчанию 1
/// - height: высота потолка (м), для расчёта профилей
class CalculateGklCeiling implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 1).round();
    final ceilingHeight = inputs['ceilingHeight'] ?? 2.5; // м
    final dropHeight = inputs['dropHeight'] ?? 0.1; // м опускания

    // Площадь одного листа ГКЛ (стандарт 1.2×2.5 м = 3 м²)
    final sheetArea = 3.0; // м²

    // Количество листов с запасом 10%
    final sheetsNeeded = (area / sheetArea * layers * 1.1).ceil();

    // Периметр комнаты (приблизительно)
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Направляющий профиль: периметр
    final guideLength = perimeter;

    // Потолочный профиль: шаг 60 см
    final ceilingProfileCount = (perimeter / 0.6).ceil();
    final ceilingProfileLength = ceilingProfileCount * (ceilingHeight - dropHeight);

    // Подвесы: шаг 60 см по длине, 120 см по ширине
    final hangersNeeded = (area / (0.6 * 1.2)).ceil();

    // Саморезы: ~30 шт на лист
    final screwsNeeded = sheetsNeeded * 30;

    // Шпаклёвка: ~1.5 кг/м² на слой
    final puttyNeeded = area * layers * 1.5;

    // Цены
    final gklPrice = _findPrice(priceList, ['gkl', 'gkl_sheet', 'drywall'])?.price;
    final guidePrice = _findPrice(priceList, ['profile_guide', 'guide_profile'])?.price;
    final ceilingProfilePrice = _findPrice(priceList, ['profile_ceiling', 'ceiling_profile'])?.price;
    final hangerPrice = _findPrice(priceList, ['hanger', 'hanger_ceiling'])?.price;
    final puttyPrice = _findPrice(priceList, ['putty', 'putty_finish'])?.price;

    double? totalPrice;
    if (gklPrice != null && guidePrice != null && ceilingProfilePrice != null && hangerPrice != null) {
      final basePrice = sheetsNeeded * gklPrice +
          guideLength * guidePrice +
          ceilingProfileLength * ceilingProfilePrice +
          hangersNeeded * hangerPrice;
      if (puttyPrice != null) {
        totalPrice = basePrice + puttyNeeded * puttyPrice;
      } else {
        totalPrice = basePrice;
      }
    } else if (gklPrice != null) {
      totalPrice = sheetsNeeded * gklPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'guideLength': guideLength,
        'ceilingProfileLength': ceilingProfileLength,
        'hangersNeeded': hangersNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
        'puttyNeeded': puttyNeeded,
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

