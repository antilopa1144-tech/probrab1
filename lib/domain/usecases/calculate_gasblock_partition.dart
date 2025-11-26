import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор перегородок из газоблока / пеноблока.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 31359-2007 "Бетоны ячеистые автоклавного твердения"
///
/// Поля:
/// - area: площадь перегородки (м²)
/// - blockWidth: ширина блока (см), по умолчанию 20
/// - blockLength: длина блока (см), по умолчанию 60
/// - blockHeight: высота блока (см), по умолчанию 25
/// - height: высота перегородки (м), по умолчанию 2.5
class CalculateGasblockPartition implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final blockWidth = inputs['blockWidth'] ?? 20.0; // см
    final blockLength = inputs['blockLength'] ?? 60.0; // см
    final blockHeight = inputs['blockHeight'] ?? 25.0; // см
    final wallHeight = inputs['height'] ?? 2.5; // м

    // Площадь одного блока в м²
    final blockArea = (blockLength / 100) * (blockHeight / 100);

    // Количество блоков с запасом 5%
    final blocksNeeded = (area / blockArea * 1.05).ceil();

    // Клей для газоблока: ~25 кг/м³
    final volume = area * (blockWidth / 100);
    final glueNeeded = volume * 25.0 * 1.1; // +10% запас

    // Армирование: арматура через каждые 3 ряда
    final rows = (wallHeight / (blockHeight / 100)).ceil();
    final reinforcementRows = (rows / 3).ceil();
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final reinforcementLength = reinforcementRows * perimeter;

    // Цены
    final blockPrice = _findPrice(priceList, ['gasblock', 'gas_block', 'foam_block'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_gasblock', 'glue_block'])?.price;
    final reinforcementPrice = _findPrice(priceList, ['rebar', 'rebar_6mm'])?.price;

    double? totalPrice;
    if (blockPrice != null) {
      totalPrice = blocksNeeded * blockPrice;
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (reinforcementPrice != null) {
        totalPrice = totalPrice + reinforcementLength * reinforcementPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'blocksNeeded': blocksNeeded.toDouble(),
        'volume': volume,
        'glueNeeded': glueNeeded,
        'reinforcementLength': reinforcementLength,
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

