import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор кровли из металлочерепицы.
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 24045-2010 "Профили стальные листовые гнутые"
///
/// Поля:
/// - area: площадь кровли (м²)
/// - slope: уклон крыши (градусы), по умолчанию 30
/// - sheetWidth: ширина листа (м), по умолчанию 1.18
/// - sheetLength: длина листа (м), по умолчанию 2.5
class CalculateRoofingMetal implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final slope = inputs['slope'] ?? 30.0; // градусы
    final sheetWidth = inputs['sheetWidth'] ?? 1.18; // м
    final sheetLength = inputs['sheetLength'] ?? 2.5; // м

    // Площадь одного листа
    final sheetArea = sheetWidth * sheetLength;

    // Учитываем уклон: реальная площадь больше проекции
    final slopeFactor = 1 / cos(slope * pi / 180);
    final realArea = area * slopeFactor;

    // Количество листов с запасом 10%
    final sheetsNeeded = (realArea / sheetArea * 1.1).ceil();

    // Конёк: примерная длина (если не указана)
    final ridgeLength = inputs['ridgeLength'] ?? sqrt(area);

    // Ендовы: если не указаны, считаем 0
    final valleyLength = inputs['valleyLength'] ?? 0.0;

    // Карнизные планки: периметр
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area));
    final eaveLength = perimeter;

    // Торцевые планки: если не указаны, считаем 2 стороны
    final endLength = inputs['endLength'] ?? (2 * sqrt(area));

    // Саморезы: ~8 шт на м²
    final screwsNeeded = (realArea * 8).ceil();

    // Гидроизоляция: площадь кровли
    final waterproofingArea = realArea * 1.1; // +10% нахлёст

    // Цены
    final sheetPrice = _findPrice(priceList, ['metal_tile', 'roofing_metal', 'metal_roof'])?.price;
    final ridgePrice = _findPrice(priceList, ['ridge', 'ridge_metal'])?.price;
    final valleyPrice = _findPrice(priceList, ['valley', 'valley_metal'])?.price;
    final eavePrice = _findPrice(priceList, ['eave', 'eave_metal'])?.price;
    final endPrice = _findPrice(priceList, ['end_strip', 'end_metal'])?.price;
    final waterproofingPrice = _findPrice(priceList, ['waterproofing_roof', 'roof_membrane'])?.price;

    double? totalPrice;
    if (sheetPrice != null) {
      totalPrice = sheetsNeeded * sheetPrice;
      if (ridgePrice != null) {
        totalPrice = totalPrice + ridgeLength * ridgePrice;
      }
      if (valleyPrice != null && valleyLength > 0) {
        totalPrice = totalPrice + valleyLength * valleyPrice;
      }
      if (eavePrice != null) {
        totalPrice = totalPrice + eaveLength * eavePrice;
      }
      if (endPrice != null) {
        totalPrice = totalPrice + endLength * endPrice;
      }
      if (waterproofingPrice != null) {
        totalPrice = totalPrice + waterproofingArea * waterproofingPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'realArea': realArea,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'ridgeLength': ridgeLength,
        'valleyLength': valleyLength,
        'eaveLength': eaveLength,
        'endLength': endLength,
        'screwsNeeded': screwsNeeded.toDouble(),
        'waterproofingArea': waterproofingArea,
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

