import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор водостоков.
///
/// Нормативы:
/// - СНиП II-26-76 "Кровли"
/// - ГОСТ 7623-84 "Водосточные системы"
///
/// Поля:
/// - perimeter: периметр крыши (м)
/// - downpipes: количество водосточных труб, по умолчанию 0 (автоматически)
/// - pipeHeight: высота трубы (м), по умолчанию 3.0
class CalculateGutters implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final perimeter = inputs['perimeter'] ?? 0;
    final pipeHeight = inputs['pipeHeight'] ?? 3.0; // м

    // Желоб: периметр крыши
    final gutterLength = perimeter;

    // Водосточные трубы: если не указано, считаем 1 труба на 10 м периметра
    final downpipesCount = (inputs['downpipes'] ?? (perimeter / 10).ceil()).round();
    final downpipeLength = downpipesCount * pipeHeight;

    // Углы желоба: обычно 4 угла на дом
    final corners = (inputs['corners'] ?? 4).round();

    // Заглушки: 2 на каждый желоб
    final endCaps = 2;

    // Воронки: по количеству труб
    final funnels = downpipesCount;

    // Колена: обычно 2 на трубу (верх и низ)
    final elbows = downpipesCount * 2;

    // Крепления: ~1 шт на 0.6 м желоба, ~1 шт на 1 м трубы
    final gutterBrackets = (gutterLength / 0.6).ceil();
    final pipeBrackets = downpipeLength.ceil();

    // Цены
    final gutterPrice = _findPrice(priceList, ['gutter', 'gutter_metal'])?.price;
    final downpipePrice = _findPrice(priceList, ['downpipe', 'pipe_water'])?.price;
    final cornerPrice = _findPrice(priceList, ['gutter_corner', 'corner_gutter'])?.price;
    final endCapPrice = _findPrice(priceList, ['end_cap', 'cap_gutter'])?.price;
    final funnelPrice = _findPrice(priceList, ['funnel', 'funnel_water'])?.price;
    final elbowPrice = _findPrice(priceList, ['elbow', 'elbow_pipe'])?.price;
    final bracketPrice = _findPrice(priceList, ['bracket_gutter', 'bracket'])?.price;

    double? totalPrice;
    if (gutterPrice != null) {
      totalPrice = gutterLength * gutterPrice;
      if (downpipePrice != null) {
        totalPrice = totalPrice + downpipeLength * downpipePrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + corners * cornerPrice;
      }
      if (endCapPrice != null) {
        totalPrice = totalPrice + endCaps * endCapPrice;
      }
      if (funnelPrice != null) {
        totalPrice = totalPrice + funnels * funnelPrice;
      }
      if (elbowPrice != null) {
        totalPrice = totalPrice + elbows * elbowPrice;
      }
      if (bracketPrice != null) {
        totalPrice = totalPrice + (gutterBrackets + pipeBrackets) * bracketPrice;
      }
    }

    return CalculatorResult(
      values: {
        'gutterLength': gutterLength,
        'downpipesCount': downpipesCount.toDouble(),
        'downpipeLength': downpipeLength,
        'corners': corners.toDouble(),
        'endCaps': endCaps.toDouble(),
        'funnels': funnels.toDouble(),
        'elbows': elbows.toDouble(),
        'gutterBrackets': gutterBrackets.toDouble(),
        'pipeBrackets': pipeBrackets.toDouble(),
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

