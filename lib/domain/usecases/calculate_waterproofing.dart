import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор гидроизоляции ванной комнаты.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - СП 28.13330.2017 "Защита строительных конструкций от коррозии"
///
/// Поля:
/// - floorArea: площадь пола (м²)
/// - wallHeight: высота обработки стен (м), по умолчанию 0.3
/// - perimeter: периметр ванной (м)
class CalculateWaterproofing implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final floorArea = inputs['floorArea'] ?? 0;
    final wallHeight = inputs['wallHeight'] ?? 0.3; // м
    final perimeter = inputs['perimeter'] ?? 0;

    // Площадь гидроизоляции: пол + стены на высоту
    final wallArea = perimeter * wallHeight;
    final totalArea = floorArea + wallArea;

    // Расход материала: ~2 кг/м² для обмазочной гидроизоляции
    final materialNeeded = totalArea * 2.0 * 1.1; // +10% запас

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = totalArea * 0.2 * 1.1;

    // Армирующая лента для углов: периметр
    final tapeLength = perimeter;

    // Цены
    final materialPrice = _findPrice(priceList, ['waterproofing', 'waterproofing_bathroom', 'waterproofing_coating'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_waterproofing'])?.price;
    final tapePrice = _findPrice(priceList, ['tape_waterproofing', 'tape_armor'])?.price;

    double? totalPrice;
    if (materialPrice != null) {
      totalPrice = materialNeeded * materialPrice;
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
      if (tapePrice != null) {
        totalPrice = totalPrice + tapeLength * tapePrice;
      }
    }

    return CalculatorResult(
      values: {
        'floorArea': floorArea,
        'wallArea': wallArea,
        'totalArea': totalArea,
        'materialNeeded': materialNeeded,
        'primerNeeded': primerNeeded,
        'tapeLength': tapeLength,
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

