import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор деревянного фасада (вагонка, планкен, блок-хаус).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 8242-88 "Детали профильные из древесины"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - boardWidth: ширина доски (см), по умолчанию 14
/// - boardLength: длина доски (м), по умолчанию 3
/// - perimeter: периметр здания (м)
class CalculateWoodFacade implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final boardWidth = inputs['boardWidth'] ?? 14.0; // см
    final boardLength = inputs['boardLength'] ?? 3.0; // м
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной доски в м²
    final boardArea = (boardWidth / 100) * boardLength;

    // Количество досок с запасом 10%
    final boardsNeeded = (area / boardArea * 1.1).ceil();

    // Уголки: периметр
    final cornersLength = perimeter;

    // Лак/масло для фасада: ~0.15 л/м² на слой (обычно 2-3 слоя)
    final finishNeeded = area * 0.15 * 2.5;

    // Крепёж: гвозди/саморезы, ~8 шт на доску
    final fastenersNeeded = boardsNeeded * 8;

    // Цены
    final boardPrice = _findPrice(priceList, ['wood_facade', 'wood_board', 'lining_facade'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_wood_facade', 'corner'])?.price;
    final finishPrice = _findPrice(priceList, ['varnish_facade', 'oil_facade'])?.price;

    double? totalPrice;
    if (boardPrice != null) {
      totalPrice = boardsNeeded * boardPrice;
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornersLength * cornerPrice;
      }
      if (finishPrice != null) {
        totalPrice = totalPrice + finishNeeded * finishPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'boardsNeeded': boardsNeeded.toDouble(),
        'cornersLength': cornersLength,
        'finishNeeded': finishNeeded,
        'fastenersNeeded': fastenersNeeded.toDouble(),
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

