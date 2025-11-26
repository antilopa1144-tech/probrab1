import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор обшивки стен ГВЛ.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - layers: количество слоёв ГВЛ, по умолчанию 1
/// - height: высота стен (м), по умолчанию 2.5
class CalculateGvlWall implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 1).round();
    final wallHeight = inputs['height'] ?? 2.5; // м

    // Площадь одного листа ГВЛ (стандарт 1.2×2.5 м = 3 м²)
    final sheetArea = 3.0; // м²

    // Количество листов с запасом 10%
    final sheetsNeeded = (area / sheetArea * layers * 1.1).ceil();

    // Периметр комнаты
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Профиль: стоечный и направляющий
    final studsCount = (perimeter / 0.6).ceil();
    final studsLength = studsCount * wallHeight;
    final guideLength = perimeter * 2; // верх и низ

    // Подвесы: шаг 60 см
    final hangersNeeded = (perimeter / 0.6).ceil();

    // Саморезы: ~30 шт на лист
    final screwsNeeded = sheetsNeeded * 30;

    // Шпаклёвка: ~1.5 кг/м² на слой
    final puttyNeeded = area * layers * 1.5;

    // Цены
    final gvlPrice = _findPrice(priceList, ['gvl', 'gvl_sheet'])?.price;
    final studPrice = _findPrice(priceList, ['profile_stud', 'stud_profile'])?.price;
    final guidePrice = _findPrice(priceList, ['profile_guide', 'guide_profile'])?.price;
    final hangerPrice = _findPrice(priceList, ['hanger', 'hanger_wall'])?.price;
    final puttyPrice = _findPrice(priceList, ['putty', 'putty_finish'])?.price;

    double? totalPrice;
    if (gvlPrice != null && studPrice != null && guidePrice != null && hangerPrice != null) {
      final basePrice = sheetsNeeded * gvlPrice +
          studsLength * studPrice +
          guideLength * guidePrice +
          hangersNeeded * hangerPrice;
      if (puttyPrice != null) {
        totalPrice = basePrice + puttyNeeded * puttyPrice;
      } else {
        totalPrice = basePrice;
      }
    } else if (gvlPrice != null) {
      totalPrice = sheetsNeeded * gvlPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'studsLength': studsLength,
        'guideLength': guideLength,
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

