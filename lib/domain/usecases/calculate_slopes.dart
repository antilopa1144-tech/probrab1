import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор откосов.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - windows: количество окон, по умолчанию 1
/// - windowWidth: ширина окна (м), по умолчанию 1.5
/// - windowHeight: высота окна (м), по умолчанию 1.4
/// - slopeWidth: ширина откоса (м), по умолчанию 0.3
class CalculateSlopes implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final windows = (inputs['windows'] ?? 1).round();
    final windowWidth = inputs['windowWidth'] ?? 1.5; // м
    final windowHeight = inputs['windowHeight'] ?? 1.4; // м
    final slopeWidth = inputs['slopeWidth'] ?? 0.3; // м

    // Периметр одного окна
    final windowPerimeter = (windowWidth + windowHeight) * 2;

    // Площадь откосов: периметр × ширина × количество окон
    final slopeArea = windowPerimeter * slopeWidth * windows;

    // Шпаклёвка: ~1.5 кг/м²
    final puttyNeeded = slopeArea * 1.5;

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = slopeArea * 0.2;

    // Краска: ~0.12 л/м² на слой (2 слоя)
    final paintNeeded = slopeArea * 0.12 * 2;

    // Уголки: периметр окон
    final cornerLength = windowPerimeter * windows;

    // Цены
    final puttyPrice = _findPrice(priceList, ['putty', 'putty_finish'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;
    final paintPrice = _findPrice(priceList, ['paint', 'paint_white'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_slope', 'corner'])?.price;

    double? totalPrice;
    if (puttyPrice != null) {
      totalPrice = puttyNeeded * puttyPrice;
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
      if (paintPrice != null) {
        totalPrice = totalPrice + paintNeeded * paintPrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornerLength * cornerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'windows': windows.toDouble(),
        'slopeArea': slopeArea,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'paintNeeded': paintNeeded,
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

