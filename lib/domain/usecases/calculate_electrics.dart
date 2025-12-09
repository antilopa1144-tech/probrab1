// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор электрики (проводка).
///
/// Нормативы:
/// - СП 256.1325800.2016 "Электроустановки жилых и общественных зданий"
/// - ГОСТ Р 50571.7.701-2013 "Электроустановки зданий"
///
/// Поля:
/// - area: площадь помещения (м²)
/// - rooms: количество комнат, по умолчанию 1
/// - sockets: количество розеток, опционально
/// - switches: количество выключателей, опционально
class CalculateElectrics extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final rooms = getIntInput(inputs, 'rooms', defaultValue: 1, minValue: 1, maxValue: 20);

    // Розетки: 1 на 4 м² (норма) + дополнительные
    final socketsDefault = ceilToInt(area / 4);
    final sockets = getIntInput(inputs, 'sockets', defaultValue: socketsDefault, minValue: 1, maxValue: 100);

    // Выключатели: 1-2 на комнату
    final switchesDefault = ceilToInt(rooms * 1.5);
    final switches = getIntInput(inputs, 'switches', defaultValue: switchesDefault, minValue: 1, maxValue: 50);

    // Провод ВВГнг-LS 3×2.5: ~3 м на розетку, ~2 м на выключатель + 20%
    final wireLength = addMargin((sockets * 3.0 + switches * 2.0), 20.0);

    // Кабель-каналы/гофра: ~50% от длины провода
    final cableChannelLength = wireLength * 0.5;

    // Автоматы (выключатели): 1 на группу (освещение, розетки, крупные потребители)
    final circuitBreakersNeeded = rooms + 1;

    // Распределительная коробка: 1 на комнату
    final junctionBoxesNeeded = rooms;

    // Электрощит: 1 на квартиру/дом
    final electricalPanelsNeeded = 1;

    // УЗО: по количеству линий
    final rcdNeeded = ceilToInt(circuitBreakersNeeded / 2);

    // Светильники: 1-2 на комнату
    final lightsNeeded = rooms * 2;

    // Расчёт стоимости
    final wirePrice = findPrice(priceList, ['wire', 'cable', 'wire_electrical', 'vvgng']);
    final socketPrice = findPrice(priceList, ['socket', 'socket_electrical', 'outlet']);
    final switchPrice = findPrice(priceList, ['switch', 'switch_electrical', 'light_switch']);
    final cableChannelPrice = findPrice(priceList, ['cable_channel', 'channel', 'conduit']);
    final breakerPrice = findPrice(priceList, ['circuit_breaker', 'breaker', 'mcb']);
    final junctionBoxPrice = findPrice(priceList, ['junction_box', 'box_electrical']);
    final panelPrice = findPrice(priceList, ['panel_electrical', 'distribution_board']);
    final rcdPrice = findPrice(priceList, ['rcd', 'residual_current_device']);

    final costs = [
      calculateCost(wireLength, wirePrice?.price),
      calculateCost(sockets.toDouble(), socketPrice?.price),
      calculateCost(switches.toDouble(), switchPrice?.price),
      calculateCost(cableChannelLength, cableChannelPrice?.price),
      calculateCost(circuitBreakersNeeded.toDouble(), breakerPrice?.price),
      calculateCost(junctionBoxesNeeded.toDouble(), junctionBoxPrice?.price),
      calculateCost(electricalPanelsNeeded.toDouble(), panelPrice?.price),
      calculateCost(rcdNeeded.toDouble(), rcdPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'rooms': rooms.toDouble(),
        'sockets': sockets.toDouble(),
        'switches': switches.toDouble(),
        'wireLength': wireLength,
        'cableChannelLength': cableChannelLength,
        'circuitBreakersNeeded': circuitBreakersNeeded.toDouble(),
        'junctionBoxesNeeded': junctionBoxesNeeded.toDouble(),
        'circuitBreakers': circuitBreakersNeeded.toDouble(),
        'junctionBoxes': junctionBoxesNeeded.toDouble(),
        'electricalPanelsNeeded': electricalPanelsNeeded.toDouble(),
        'rcdNeeded': rcdNeeded.toDouble(),
        'lightsNeeded': lightsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
