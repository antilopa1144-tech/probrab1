import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор отопления (радиаторы, трубы).
///
/// Нормативы:
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
/// - ГОСТ 31311-2005 "Приборы отопительные"
///
/// Поля:
/// - area: площадь помещения (м²)
/// - rooms: количество комнат, по умолчанию 1
/// - ceilingHeight: высота потолков (м), по умолчанию 2.5
class CalculateHeating implements CalculatorUseCase {
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

    // Тепловая мощность: 100 Вт на м² (для средней полосы)
    final totalPower = area * 100; // Вт

    // Радиаторы: 1 секция на 2 м² (при высоте потолка 2.5 м)
    final sectionsPerRoom = (area / rooms / 2).ceil();
    final totalSections = sectionsPerRoom * rooms;

    // Трубы: ~10 м на комнату
    final pipeLength = rooms * 10.0;

    // Фитинги: ~5 шт на комнату
    final fittingsNeeded = rooms * 5;

    // Краны: по количеству радиаторов
    final valvesNeeded = rooms * 2; // вход и выход

    // Терморегуляторы: по количеству радиаторов
    final thermostatsNeeded = rooms;

    // Цены
    final radiatorPrice = _findPrice(priceList, ['radiator', 'radiator_section'])?.price;
    final pipePrice = _findPrice(priceList, ['pipe_heating', 'pipe'])?.price;
    final fittingPrice = _findPrice(priceList, ['fitting_heating', 'fitting'])?.price;
    final valvePrice = _findPrice(priceList, ['valve_heating', 'valve'])?.price;
    final thermostatPrice = _findPrice(priceList, ['thermostat_heating', 'thermostat'])?.price;

    double? totalPrice;
    if (radiatorPrice != null) {
      totalPrice = totalSections * radiatorPrice;
      if (pipePrice != null) {
        totalPrice = totalPrice + pipeLength * pipePrice;
      }
      if (fittingPrice != null) {
        totalPrice = totalPrice + fittingsNeeded * fittingPrice;
      }
      if (valvePrice != null) {
        totalPrice = totalPrice + valvesNeeded * valvePrice;
      }
      if (thermostatPrice != null) {
        totalPrice = totalPrice + thermostatsNeeded * thermostatPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'totalPower': totalPower,
        'totalSections': totalSections.toDouble(),
        'pipeLength': pipeLength,
        'fittingsNeeded': fittingsNeeded.toDouble(),
        'valvesNeeded': valvesNeeded.toDouble(),
        'thermostatsNeeded': thermostatsNeeded.toDouble(),
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

