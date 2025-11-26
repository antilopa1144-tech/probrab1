import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор линолеума.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 18108-80 "Линолеум поливинилхлоридный"
///
/// Поля:
/// - area: площадь пола (м²)
/// - rollWidth: ширина рулона (м), по умолчанию 3.0
/// - overlap: нахлёст (см), по умолчанию 5
class CalculateLinoleum implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final rollWidth = inputs['rollWidth'] ?? 3.0; // м
    final overlap = inputs['overlap'] ?? 5.0; // см

    // Площадь с учётом нахлёста и запаса 10%
    final areaWithOverlap = area * (1 + overlap / 100) * 1.1;

    // Длина рулона (если рулон стандартный 30 м)
    final rollLength = inputs['rollLength'] ?? 30.0; // м
    final rollArea = rollWidth * rollLength;

    // Количество рулонов
    final rollsNeeded = (areaWithOverlap / rollArea).ceil();

    // Плинтус: примерный периметр
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final plinthLength = perimeter;

    // Клей (если нужен): ~0.3 кг/м²
    final glueNeeded = area * 0.3;

    // Цены
    final linoleumPrice = _findPrice(priceList, ['linoleum', 'linoleum_pvc'])?.price;
    final plinthPrice = _findPrice(priceList, ['plinth', 'plinth_linoleum'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_linoleum', 'glue'])?.price;

    double? totalPrice;
    if (linoleumPrice != null && plinthPrice != null) {
      final basePrice = rollsNeeded * linoleumPrice + plinthLength * plinthPrice;
      if (gluePrice != null) {
        totalPrice = basePrice + glueNeeded * gluePrice;
      } else {
        totalPrice = basePrice;
      }
    } else if (linoleumPrice != null) {
      totalPrice = rollsNeeded * linoleumPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'rollsNeeded': rollsNeeded.toDouble(),
        'plinthLength': plinthLength,
        'glueNeeded': glueNeeded,
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

