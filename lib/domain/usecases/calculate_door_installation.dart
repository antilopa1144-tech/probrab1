import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор установки дверей.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 475-2016 "Блоки дверные"
///
/// Поля:
/// - doors: количество дверей, по умолчанию 1
/// - doorWidth: ширина двери (м), по умолчанию 0.9
/// - doorHeight: высота двери (м), по умолчанию 2.1
class CalculateDoorInstallation implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final doors = (inputs['doors'] ?? 1).round();
    final doorWidth = inputs['doorWidth'] ?? 0.9; // м
    final doorHeight = inputs['doorHeight'] ?? 2.1; // м

    // Монтажная пена: ~1 баллон на дверь
    final foamNeeded = doors;

    // Наличники: периметр двери × количество
    final architravePerimeter = (doorWidth + doorHeight) * 2;
    final architraveLength = architravePerimeter * doors;

    // Коробка: по количеству дверей
    final framesNeeded = doors;

    // Петли: 2-3 шт на дверь
    final hingesNeeded = doors * 2;

    // Замки/ручки: по количеству дверей
    final locksNeeded = doors;

    // Цены
    final doorPrice = _findPrice(priceList, ['door', 'door_interior'])?.price;
    final foamPrice = _findPrice(priceList, ['foam_mounting', 'foam'])?.price;
    final architravePrice = _findPrice(priceList, ['architrave', 'door_architrave'])?.price;
    final framePrice = _findPrice(priceList, ['door_frame', 'frame'])?.price;
    final hingePrice = _findPrice(priceList, ['hinge', 'door_hinge'])?.price;
    final lockPrice = _findPrice(priceList, ['lock', 'door_lock'])?.price;

    double? totalPrice;
    if (doorPrice != null) {
      totalPrice = doors * doorPrice;
      if (foamPrice != null) {
        totalPrice = totalPrice + foamNeeded * foamPrice;
      }
      if (architravePrice != null) {
        totalPrice = totalPrice + architraveLength * architravePrice;
      }
      if (framePrice != null) {
        totalPrice = totalPrice + framesNeeded * framePrice;
      }
      if (hingePrice != null) {
        totalPrice = totalPrice + hingesNeeded * hingePrice;
      }
      if (lockPrice != null) {
        totalPrice = totalPrice + locksNeeded * lockPrice;
      }
    }

    return CalculatorResult(
      values: {
        'doors': doors.toDouble(),
        'foamNeeded': foamNeeded.toDouble(),
        'architraveLength': architraveLength,
        'framesNeeded': framesNeeded.toDouble(),
        'hingesNeeded': hingesNeeded.toDouble(),
        'locksNeeded': locksNeeded.toDouble(),
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

