import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор мягкой кровли (битумная черепица).
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 30547-97 "Рулонные кровельные и гидроизоляционные материалы"
///
/// Поля:
/// - area: площадь кровли (м²)
/// - slope: уклон крыши (градусы), по умолчанию 30
/// - ridgeLength: длина конька (м)
class CalculateSoftRoofing implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final slope = inputs['slope'] ?? 30.0; // градусы
    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    // Учитываем уклон
    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Площадь одного рулона (стандарт: 1×10 м = 10 м²)
    final rollArea = 10.0; // м²

    // Количество рулонов с запасом 10%
    final rollsNeeded = (realArea / rollArea * 1.1).ceil();

    // Подкладочный ковёр: площадь кровли
    final underlaymentArea = realArea * 1.1;

    // Коньково-карнизная полоса: длина конька
    final ridgeStripLength = ridgeLength;

    // Ендовый ковёр: если не указан, считаем 10% от периметра
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final valleyLength = inputs['valleyLength'] ?? (perimeter * 0.1);

    // Гвозди: ~10 шт на м²
    final nailsNeeded = (realArea * 10).ceil();

    // Мастика: ~0.5 кг/м²
    final masticNeeded = realArea * 0.5;

    // Цены
    final roofingPrice = _findPrice(priceList, ['soft_roofing', 'bitumen_tile', 'roofing_soft'])?.price;
    final underlaymentPrice = _findPrice(priceList, ['underlayment_roof', 'roof_underlayment'])?.price;
    final ridgeStripPrice = _findPrice(priceList, ['ridge_strip', 'ridge_soft'])?.price;
    final valleyPrice = _findPrice(priceList, ['valley_soft', 'valley'])?.price;
    final masticPrice = _findPrice(priceList, ['mastic_roof', 'mastic'])?.price;

    double? totalPrice;
    if (roofingPrice != null) {
      totalPrice = rollsNeeded * roofingPrice;
      if (underlaymentPrice != null) {
        totalPrice = totalPrice + underlaymentArea * underlaymentPrice;
      }
      if (ridgeStripPrice != null) {
        totalPrice = totalPrice + ridgeStripLength * ridgeStripPrice;
      }
      if (valleyPrice != null && valleyLength > 0) {
        totalPrice = totalPrice + valleyLength * valleyPrice;
      }
      if (masticPrice != null) {
        totalPrice = totalPrice + masticNeeded * masticPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'realArea': realArea,
        'rollsNeeded': rollsNeeded.toDouble(),
        'underlaymentArea': underlaymentArea,
        'ridgeStripLength': ridgeStripLength,
        'valleyLength': valleyLength,
        'nailsNeeded': nailsNeeded.toDouble(),
        'masticNeeded': masticNeeded,
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

