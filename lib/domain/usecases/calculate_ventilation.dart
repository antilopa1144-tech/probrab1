import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор вентиляции.
///
/// Нормативы:
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
/// - СП 60.13330.2016 "Отопление, вентиляция и кондиционирование воздуха"
///
/// Поля:
/// - area: площадь помещения (м²)
/// - rooms: количество комнат, по умолчанию 1
/// - ceilingHeight: высота потолков (м), по умолчанию 2.5
class CalculateVentilation implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final rooms = (inputs['rooms'] ?? 1).round();
    final ceilingHeight = inputs['ceilingHeight'] ?? 2.5; // м

    // Объём помещения
    final volume = area * ceilingHeight;

    // Воздухообмен: 3 м³/ч на м² (для жилых помещений)
    final airExchange = area * 3.0; // м³/ч

    // Вентиляционные каналы: ~1 на комнату
    final ductsNeeded = rooms;

    // Решётки: по количеству комнат
    final grillesNeeded = rooms * 2; // приточная и вытяжная

    // Вентиляторы: для кухни и ванной
    final fansNeeded = (rooms * 0.3).ceil(); // примерно 30% комнат

    // Воздуховоды: ~5 м на комнату
    final ductLength = rooms * 5.0;

    // Цены
    final ductPrice = _findPrice(priceList, ['ventilation_duct', 'duct'])?.price;
    final grillePrice = _findPrice(priceList, ['ventilation_grille', 'grille'])?.price;
    final fanPrice = _findPrice(priceList, ['ventilation_fan', 'fan'])?.price;

    double? totalPrice;
    if (ductPrice != null) {
      totalPrice = ductLength * ductPrice;
      if (grillePrice != null) {
        totalPrice = totalPrice + grillesNeeded * grillePrice;
      }
      if (fanPrice != null) {
        totalPrice = totalPrice + fansNeeded * fanPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'airExchange': airExchange,
        'ductsNeeded': ductsNeeded.toDouble(),
        'grillesNeeded': grillesNeeded.toDouble(),
        'fansNeeded': fansNeeded.toDouble(),
        'ductLength': ductLength,
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

