import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор электрики (проводка).
///
/// Нормативы:
/// - СП 256.1325800.2016 "Электроустановки жилых и общественных зданий"
/// - ГОСТ Р 50571.7.701-2013 "Электроустановки зданий"
///
/// Поля:
/// - area: площадь помещения (м²)
/// - rooms: количество комнат, по умолчанию 1
/// - sockets: количество розеток, по умолчанию 0 (автоматически)
/// - switches: количество выключателей, по умолчанию 0 (автоматически)
class CalculateElectrics implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final rooms = (inputs['rooms'] ?? 1).round();

    // Розетки: если не указано, считаем по норме (1 розетка на 4 м²)
    final sockets = (inputs['sockets'] ?? (area / 4).ceil()).round();

    // Выключатели: обычно 1-2 на комнату
    final switches = (inputs['switches'] ?? (rooms * 1.5).ceil()).round();

    // Провод: ~3 м на розетку, ~2 м на выключатель, +20% запас
    final wireLength = ((sockets * 3 + switches * 2) * 1.2).ceil();

    // Кабель-каналы: ~50% от длины провода
    final cableChannelLength = (wireLength * 0.5).ceil();

    // Автоматы: обычно 1 на комнату + общий
    final circuitBreakers = rooms + 1;

    // Распределительная коробка: 1 на комнату
    final junctionBoxes = rooms;

    // Цены
    final wirePrice = _findPrice(priceList, ['wire', 'cable', 'wire_electrical'])?.price;
    final socketPrice = _findPrice(priceList, ['socket', 'socket_electrical'])?.price;
    final switchPrice = _findPrice(priceList, ['switch', 'switch_electrical'])?.price;
    final cableChannelPrice = _findPrice(priceList, ['cable_channel', 'channel'])?.price;
    final breakerPrice = _findPrice(priceList, ['circuit_breaker', 'breaker'])?.price;
    final junctionBoxPrice = _findPrice(priceList, ['junction_box', 'box_electrical'])?.price;

    double? totalPrice;
    if (wirePrice != null) {
      totalPrice = wireLength * wirePrice;
      if (socketPrice != null) {
        totalPrice = totalPrice + sockets * socketPrice;
      }
      if (switchPrice != null) {
        totalPrice = totalPrice + switches * switchPrice;
      }
      if (cableChannelPrice != null) {
        totalPrice = totalPrice + cableChannelLength * cableChannelPrice;
      }
      if (breakerPrice != null) {
        totalPrice = totalPrice + circuitBreakers * breakerPrice;
      }
      if (junctionBoxPrice != null) {
        totalPrice = totalPrice + junctionBoxes * junctionBoxPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'rooms': rooms.toDouble(),
        'sockets': sockets.toDouble(),
        'switches': switches.toDouble(),
        'wireLength': wireLength.toDouble(),
        'cableChannelLength': cableChannelLength.toDouble(),
        'circuitBreakers': circuitBreakers.toDouble(),
        'junctionBoxes': junctionBoxes.toDouble(),
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

