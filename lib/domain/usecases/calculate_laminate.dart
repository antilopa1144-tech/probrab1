import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор ламината.
///
/// Нормативы:
/// - ГОСТ 32304-2013 "Ламинат напольный"
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - packArea: площадь в упаковке (м²), по умолчанию 2.0
/// - underlayThickness: толщина подложки (мм), по умолчанию 3
class CalculateLaminate implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final packArea = inputs['packArea'] ?? 2.0; // стандартная упаковка

    // Количество упаковок ламината с запасом 5% (ГОСТ 32304-2013)
    final packsNeeded = (area / packArea * 1.05).ceil();

    // Подложка: площадь = площадь пола + 10% на подрезку
    final underlayArea = area * 1.1;

    // Плинтус: примерный периметр комнаты (приблизительно)
    // Если периметр не указан, оцениваем как 4 * sqrt(area)
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final plinthLength = perimeter;

    // Клинья для зазора: ~4 шт на метр плинтуса
    final wedgesNeeded = (plinthLength * 4).ceil();

    // Цены
    final laminatePrice = _findPrice(priceList, ['laminate', 'laminate_pack'])?.price;
    final underlayPrice = _findPrice(priceList, ['underlay', 'underlay_3mm'])?.price;
    final plinthPrice = _findPrice(priceList, ['plinth', 'plinth_laminate'])?.price;

    double? totalPrice;
    if (laminatePrice != null && underlayPrice != null && plinthPrice != null) {
      totalPrice = packsNeeded * laminatePrice +
          underlayArea * underlayPrice +
          plinthLength * plinthPrice;
    } else if (laminatePrice != null && underlayPrice != null) {
      totalPrice = packsNeeded * laminatePrice + underlayArea * underlayPrice;
    } else if (laminatePrice != null) {
      totalPrice = packsNeeded * laminatePrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'packsNeeded': packsNeeded.toDouble(),
        'underlayArea': underlayArea,
        'plinthLength': plinthLength,
        'wedgesNeeded': wedgesNeeded.toDouble(),
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

