import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор перегородок из ГКЛ.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - area: площадь перегородки (м²)
/// - layers: количество слоёв ГКЛ, по умолчанию 2
/// - height: высота перегородки (м), по умолчанию 2.5
class CalculateGklPartition implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final layers = (inputs['layers'] ?? 2).round();
    final height = inputs['height'] ?? 2.5; // м

    // Площадь одного листа ГКЛ (стандарт 1.2×2.5 м = 3 м²)
    final sheetArea = 3.0; // м²

    // Количество листов с запасом 10%
    final sheetsNeeded = (area / sheetArea * layers * 1.1).ceil();

    // Профиль: периметр перегородки
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    
    // Стоечный профиль: высота × количество стоек (шаг 60 см)
    final studsCount = (perimeter / 0.6).ceil();
    final studsLength = studsCount * height;

    // Направляющий профиль: периметр × 2 (верх и низ)
    final guideLength = perimeter * 2;

    // Саморезы: ~30 шт на лист
    final screwsNeeded = sheetsNeeded * 30;

    // Шпаклёвка: ~1.5 кг/м² на слой
    final puttyNeeded = area * layers * 1.5;

    // Цены
    final gklPrice = _findPrice(priceList, ['gkl', 'gkl_sheet', 'drywall'])?.price;
    final studPrice = _findPrice(priceList, ['profile_stud', 'stud_profile'])?.price;
    final guidePrice = _findPrice(priceList, ['profile_guide', 'guide_profile'])?.price;
    final puttyPrice = _findPrice(priceList, ['putty', 'putty_finish'])?.price;

    double? totalPrice;
    if (gklPrice != null && studPrice != null && guidePrice != null) {
      final basePrice = sheetsNeeded * gklPrice +
          studsLength * studPrice +
          guideLength * guidePrice;
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
        'studsLength': studsLength,
        'guideLength': guideLength,
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

