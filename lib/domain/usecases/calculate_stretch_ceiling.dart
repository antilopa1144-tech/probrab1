import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор натяжного потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - perimeter: периметр комнаты (м)
/// - corners: количество углов, по умолчанию 4
class CalculateStretchCeiling implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final corners = (inputs['corners'] ?? 4).round();

    // Полотно: площадь + запас 10% на подрезку
    final canvasArea = area * 1.1;

    // Багет: периметр + запас 5%
    final baguetteLength = perimeter * 1.05;

    // Углы: количество углов
    final cornersNeeded = corners;

    // Люстра/светильники: если не указано, считаем 1
    final fixtures = (inputs['fixtures'] ?? 1).round();

    // Цены
    final canvasPrice = _findPrice(priceList, ['ceiling_stretch', 'ceiling_canvas'])?.price;
    final baguettePrice = _findPrice(priceList, ['baguette', 'baguette_ceiling'])?.price;

    double? totalPrice;
    if (canvasPrice != null && baguettePrice != null) {
      totalPrice = canvasArea * canvasPrice + baguetteLength * baguettePrice;
    } else if (canvasPrice != null) {
      totalPrice = canvasArea * canvasPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'canvasArea': canvasArea,
        'baguetteLength': baguetteLength,
        'cornersNeeded': cornersNeeded.toDouble(),
        'fixtures': fixtures.toDouble(),
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

