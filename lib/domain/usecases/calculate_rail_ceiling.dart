import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор реечного потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - railWidth: ширина рейки (см), по умолчанию 10
/// - railLength: длина рейки (см), по умолчанию 300
/// - perimeter: периметр комнаты (м)
class CalculateRailCeiling implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final railWidth = inputs['railWidth'] ?? 10.0; // см
    final railLength = inputs['railLength'] ?? 300.0; // см
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной рейки в м²
    final railArea = (railWidth / 100) * (railLength / 100);

    // Количество реек с запасом 5%
    final railsNeeded = (area / railArea * 1.05).ceil();

    // Направляющие: периметр
    final guideLength = perimeter;

    // Подвесы: шаг 60 см
    final hangersNeeded = (perimeter / 0.6).ceil();

    // Уголки: периметр
    final cornerLength = perimeter;

    // Цены
    final railPrice = _findPrice(priceList, ['rail_ceiling', 'ceiling_rail'])?.price;
    final guidePrice = _findPrice(priceList, ['guide_rail', 'rail_guide'])?.price;
    final hangerPrice = _findPrice(priceList, ['hanger_rail', 'hanger'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_rail', 'corner'])?.price;

    double? totalPrice;
    if (railPrice != null) {
      totalPrice = railsNeeded * railPrice;
      if (guidePrice != null) {
        totalPrice = totalPrice + guideLength * guidePrice;
      }
      if (hangerPrice != null) {
        totalPrice = totalPrice + hangersNeeded * hangerPrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornerLength * cornerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'railsNeeded': railsNeeded.toDouble(),
        'guideLength': guideLength,
        'hangersNeeded': hangersNeeded.toDouble(),
        'cornerLength': cornerLength,
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

