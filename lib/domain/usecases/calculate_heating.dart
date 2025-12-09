// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

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
class CalculateHeating extends BaseCalculator {
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
    final ceilingHeight = getInput(inputs, 'ceilingHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);

    // Объём помещения
    final volume = area * ceilingHeight;

    // Тепловая мощность: 100 Вт/м² (средняя полоса России)
    final totalPower = area * 100; // Вт

    // Радиаторы: 1 секция на 1.8-2.0 м² (при мощности секции ~180 Вт)
    final sectionsPerM2 = 0.55; // ~1 секция на 1.8 м²
    final totalSections = ceilToInt(area * sectionsPerM2);
    final radiatorsNeeded = rooms; // количество радиаторов
    final sectionsPerRadiator = ceilToInt(totalSections / rooms);

    // Трубы подачи и обратки: ~10-12 м на комнату
    final pipeLength = rooms * 10.0;

    // Фитинги (уголки, тройники, муфты): ~5 шт на комнату
    final fittingsNeeded = rooms * 5;

    // Краны шаровые: по 2 на радиатор (подача и обратка)
    final ballValvesNeeded = rooms * 2;

    // Терморегуляторы: 1 на радиатор
    final thermostatsNeeded = rooms;

    // Кронштейны для радиаторов: ~2 шт на радиатор
    final bracketsNeeded = rooms * 2;

    // Котёл (если автономное отопление): 1 шт
    final boilerNeeded = getIntInput(inputs, 'boiler', defaultValue: 0, minValue: 0, maxValue: 1);

    // Расширительный бак: 1 шт
    final expansionTankNeeded = boilerNeeded > 0 ? 1 : 0;

    // Насос циркуляционный: 1 шт
    final pumpNeeded = boilerNeeded > 0 ? 1 : 0;

    // Расчёт стоимости
    final radiatorPrice = findPrice(priceList, ['radiator', 'radiator_section', 'heating_radiator']);
    final pipePrice = findPrice(priceList, ['pipe_heating', 'pipe', 'heating_pipe']);
    final fittingPrice = findPrice(priceList, ['fitting_heating', 'fitting']);
    final ballValvePrice = findPrice(priceList, ['valve_heating', 'valve', 'ball_valve']);
    final thermostatPrice = findPrice(priceList, ['thermostat_heating', 'thermostat', 'thermostatic_head']);
    final bracketPrice = findPrice(priceList, ['bracket_radiator', 'bracket']);
    final boilerPrice = findPrice(priceList, ['boiler', 'heating_boiler']);
    final tankPrice = findPrice(priceList, ['tank_expansion', 'expansion_tank']);
    final pumpPrice = findPrice(priceList, ['pump_circulation', 'circulation_pump']);

    final costs = [
      calculateCost(totalSections.toDouble(), radiatorPrice?.price),
      calculateCost(pipeLength, pipePrice?.price),
      calculateCost(fittingsNeeded.toDouble(), fittingPrice?.price),
      calculateCost(ballValvesNeeded.toDouble(), ballValvePrice?.price),
      calculateCost(thermostatsNeeded.toDouble(), thermostatPrice?.price),
      calculateCost(bracketsNeeded.toDouble(), bracketPrice?.price),
      if (boilerNeeded > 0) calculateCost(boilerNeeded.toDouble(), boilerPrice?.price),
      if (expansionTankNeeded > 0) calculateCost(expansionTankNeeded.toDouble(), tankPrice?.price),
      if (pumpNeeded > 0) calculateCost(pumpNeeded.toDouble(), pumpPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'volume': volume,
        'totalPower': totalPower,
        'totalSections': totalSections.toDouble(),
        'radiatorsNeeded': radiatorsNeeded.toDouble(),
        'sectionsPerRadiator': sectionsPerRadiator.toDouble(),
        'pipeLength': pipeLength,
        'fittingsNeeded': fittingsNeeded.toDouble(),
        'ballValvesNeeded': ballValvesNeeded.toDouble(),
        'valvesNeeded': ballValvesNeeded.toDouble(),
        'thermostatsNeeded': thermostatsNeeded.toDouble(),
        'bracketsNeeded': bracketsNeeded.toDouble(),
        if (boilerNeeded > 0) 'boilerNeeded': boilerNeeded.toDouble(),
        if (expansionTankNeeded > 0) 'expansionTankNeeded': expansionTankNeeded.toDouble(),
        if (pumpNeeded > 0) 'pumpNeeded': pumpNeeded.toDouble(),
        'rooms': rooms.toDouble(),
        'ceilingHeight': ceilingHeight,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
