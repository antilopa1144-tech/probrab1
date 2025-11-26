import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор кассетного потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - cassetteSize: размер кассеты (см), по умолчанию 60 (60×60 см)
/// - perimeter: периметр комнаты (м)
class CalculateCassetteCeiling implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final cassetteSize = inputs['cassetteSize'] ?? 60.0; // см
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной кассеты в м²
    final cassetteArea = (cassetteSize / 100) * (cassetteSize / 100);

    // Количество кассет с запасом 5%
    final cassettesNeeded = (area / cassetteArea * 1.05).ceil();

    // Профили: направляющие по периметру
    final guideLength = perimeter;

    // Подвесы: шаг 120 см
    final hangersNeeded = (area / (1.2 * 1.2)).ceil();

    // Цены
    final cassettePrice = _findPrice(priceList, ['cassette_ceiling', 'cassette'])?.price;
    final guidePrice = _findPrice(priceList, ['guide_cassette', 'guide'])?.price;
    final hangerPrice = _findPrice(priceList, ['hanger_cassette', 'hanger'])?.price;

    double? totalPrice;
    if (cassettePrice != null) {
      totalPrice = cassettesNeeded * cassettePrice;
      if (guidePrice != null) {
        totalPrice = totalPrice + guideLength * guidePrice;
      }
      if (hangerPrice != null) {
        totalPrice = totalPrice + hangersNeeded * hangerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'cassettesNeeded': cassettesNeeded.toDouble(),
        'guideLength': guideLength,
        'hangersNeeded': hangersNeeded.toDouble(),
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

