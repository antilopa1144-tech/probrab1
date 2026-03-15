// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор сантехники (трубы, фитинги).
///
/// Legacy path:
/// - rooms: количество санузлов
/// - points: количество точек подключения, опционально
/// - pipeLength: общая длина трубопровода, опционально
///
/// Screen path:
/// - bathroomsCount / toiletsCount / kitchensCount
/// - avgPipeLength
/// - needHotWater
class CalculatePlumbing extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final rooms = inputs['rooms'] ?? 1;
    final bathroomsCount = inputs['bathroomsCount'] ?? 0;
    final toiletsCount = inputs['toiletsCount'] ?? 0;
    final kitchensCount = inputs['kitchensCount'] ?? 0;
    if (rooms < 0) return nonNegativeValueMessage('rooms');
    if (bathroomsCount < 0) return nonNegativeValueMessage('bathroomsCount');
    if (toiletsCount < 0) return nonNegativeValueMessage('toiletsCount');
    if (kitchensCount < 0) return nonNegativeValueMessage('kitchensCount');

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final hasScreenCounts =
        inputs.containsKey('bathroomsCount') ||
        inputs.containsKey('toiletsCount') ||
        inputs.containsKey('kitchensCount');

    final bathroomsCount = getIntInput(
      inputs,
      'bathroomsCount',
      defaultValue: 1,
      minValue: 0,
      maxValue: 20,
    );
    final toiletsCount = getIntInput(
      inputs,
      'toiletsCount',
      defaultValue: 1,
      minValue: 0,
      maxValue: 20,
    );
    final kitchensCount = getIntInput(
      inputs,
      'kitchensCount',
      defaultValue: 1,
      minValue: 0,
      maxValue: 20,
    );
    final avgPipeLength = getInput(
      inputs,
      'avgPipeLength',
      defaultValue: 5.0,
      minValue: 0.0,
      maxValue: 50.0,
    );
    final needHotWater =
        getIntInput(inputs, 'needHotWater', defaultValue: 1) != 0;

    final rooms = hasScreenCounts
        ? bathroomsCount + toiletsCount + kitchensCount
        : getIntInput(
            inputs,
            'rooms',
            defaultValue: 1,
            minValue: 0,
            maxValue: 20,
          );

    final points = hasScreenCounts
        ? (bathroomsCount * 4) + (toiletsCount * 2) + (kitchensCount * 3)
        : getIntInput(
            inputs,
            'points',
            defaultValue: rooms * 3,
            minValue: 0,
            maxValue: 200,
          );

    final pipeLength = hasScreenCounts
        ? points * avgPipeLength
        : getInput(
            inputs,
            'pipeLength',
            defaultValue: points * 5.0,
            minValue: 0.0,
            maxValue: 5000.0,
          );

    final coldWaterLength = hasScreenCounts
        ? points * avgPipeLength * 1.15
        : pipeLength * 0.5;
    final hotWaterLength = hasScreenCounts
        ? (needHotWater ? points * avgPipeLength * 0.8 * 1.15 : 0.0)
        : pipeLength * 0.35;
    final sewerLength = hasScreenCounts
        ? points * (avgPipeLength * 0.7) * 1.1
        : pipeLength * 0.15;

    final fittingsNeeded = hasScreenCounts ? points * 4 : points * 3;
    final ballValvesNeeded = hasScreenCounts
        ? (needHotWater ? points * 2 : points)
        : points;
    final mixersNeeded = hasScreenCounts
        ? bathroomsCount + toiletsCount + kitchensCount
        : ceilToInt(points * 0.65);
    final toiletsNeeded = hasScreenCounts
        ? bathroomsCount + toiletsCount
        : rooms;
    final sinksNeeded = hasScreenCounts
        ? bathroomsCount + toiletsCount + kitchensCount
        : rooms;
    final showersNeeded = hasScreenCounts ? bathroomsCount : rooms;
    final siphonsNeeded = hasScreenCounts
        ? (bathroomsCount * 2) + toiletsCount + kitchensCount
        : mixersNeeded;

    final coldPipePrice = findPrice(priceList, [
      'pipe_water',
      'pipe',
      'pipe_pvc',
      'cold_water_pipe',
    ]);
    final hotPipePrice = findPrice(priceList, ['pipe_hot', 'hot_water_pipe']);
    final sewerPipePrice = findPrice(priceList, [
      'pipe_sewer',
      'sewer_pipe',
      'waste_pipe',
    ]);
    final fittingPrice = findPrice(priceList, ['fitting', 'fitting_pvc']);
    final ballValvePrice = findPrice(priceList, ['valve', 'ball_valve', 'tap']);
    final mixerPrice = findPrice(priceList, ['mixer', 'faucet', 'tap_mixer']);
    final toiletPrice = findPrice(priceList, ['toilet', 'toilet_bowl', 'wc']);
    final sinkPrice = findPrice(priceList, ['sink', 'washbasin', 'basin']);
    final showerPrice = findPrice(priceList, [
      'shower',
      'shower_cabin',
      'bathtub',
    ]);
    final siphonPrice = findPrice(priceList, ['siphon', 'trap']);

    final costs = [
      calculateCost(coldWaterLength, coldPipePrice?.price),
      calculateCost(hotWaterLength, hotPipePrice?.price),
      calculateCost(sewerLength, sewerPipePrice?.price),
      calculateCost(fittingsNeeded.toDouble(), fittingPrice?.price),
      calculateCost(ballValvesNeeded.toDouble(), ballValvePrice?.price),
      calculateCost(mixersNeeded.toDouble(), mixerPrice?.price),
      calculateCost(toiletsNeeded.toDouble(), toiletPrice?.price),
      calculateCost(sinksNeeded.toDouble(), sinkPrice?.price),
      calculateCost(showersNeeded.toDouble(), showerPrice?.price),
      calculateCost(siphonsNeeded.toDouble(), siphonPrice?.price),
    ];

    return createResult(
      values: {
        'rooms': rooms.toDouble(),
        'bathroomsCount': bathroomsCount.toDouble(),
        'toiletsCount': toiletsCount.toDouble(),
        'kitchensCount': kitchensCount.toDouble(),
        'needHotWater': needHotWater ? 1.0 : 0.0,
        'avgPipeLength': avgPipeLength,
        'points': points.toDouble(),
        'pipeLength': pipeLength,
        'coldWaterLength': coldWaterLength,
        'hotWaterLength': hotWaterLength,
        'sewerLength': sewerLength,
        'fittingsNeeded': fittingsNeeded.toDouble(),
        'ballValvesNeeded': ballValvesNeeded.toDouble(),
        'tapsNeeded': ballValvesNeeded.toDouble(),
        'mixersNeeded': mixersNeeded.toDouble(),
        'toiletsNeeded': toiletsNeeded.toDouble(),
        'sinksNeeded': sinksNeeded.toDouble(),
        'showersNeeded': showersNeeded.toDouble(),
        'siphonsNeeded': siphonsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
