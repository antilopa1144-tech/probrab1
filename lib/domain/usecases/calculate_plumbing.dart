import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор сантехники (трубы, фитинги).
///
/// Нормативы:
/// - СНиП 2.04.01-85 "Внутренний водопровод и канализация зданий"
/// - ГОСТ 32415-2013 "Трубы напорные из термопластов"
///
/// Поля:
/// - rooms: количество санузлов, по умолчанию 1
/// - points: количество точек подключения, опционально
/// - pipeLength: длина трубопровода (м), опционально
class CalculatePlumbing extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final rooms = inputs['rooms'] ?? 1;
    if (rooms < 0) return 'Количество санузлов не может быть отрицательным';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final rooms = getIntInput(inputs, 'rooms', defaultValue: 1, minValue: 0, maxValue: 10);
    
    // Точки подключения: раковина, унитаз, душ/ванна на санузел
    final pointsDefault = rooms * 3;
    final points = getIntInput(inputs, 'points', defaultValue: pointsDefault, minValue: 0, maxValue: 50);

    // Трубы: ~5 м на точку (холодная + горячая вода + канализация)
    final pipeLengthDefault = points * 5.0;
    final pipeLength = getInput(inputs, 'pipeLength', defaultValue: pipeLengthDefault, minValue: 0.0);

    // Труба холодной воды: 50% от общей
    final coldWaterLength = pipeLength * 0.5;

    // Труба горячей воды: 35% от общей
    final hotWaterLength = pipeLength * 0.35;

    // Канализационная труба: 15% от общей
    final sewerLength = pipeLength * 0.15;

    // Фитинги (уголки, тройники, муфты): ~3-4 шт на точку
    final fittingsNeeded = points * 3;

    // Краны шаровые: по количеству точек
    final ballValvesNeeded = points;

    // Смесители: раковина и душ (не унитаз)
    final mixersNeeded = ceilToInt(points * 0.65);

    // Унитаз: 1 на санузел
    final toiletsNeeded = rooms;

    // Раковина: 1 на санузел
    final sinksNeeded = rooms;

    // Душ/ванна: 1 на санузел
    final showersNeeded = rooms;

    // Сифоны: для раковины и душа
    final siphonsNeeded = mixersNeeded;

    // Расчёт стоимости
    final coldPipePrice = findPrice(priceList, ['pipe_water', 'pipe', 'pipe_pvc', 'cold_water_pipe']);
    final hotPipePrice = findPrice(priceList, ['pipe_hot', 'hot_water_pipe']);
    final sewerPipePrice = findPrice(priceList, ['pipe_sewer', 'sewer_pipe', 'waste_pipe']);
    final fittingPrice = findPrice(priceList, ['fitting', 'fitting_pvc']);
    final ballValvePrice = findPrice(priceList, ['valve', 'ball_valve', 'tap']);
    final mixerPrice = findPrice(priceList, ['mixer', 'faucet', 'tap_mixer']);
    final toiletPrice = findPrice(priceList, ['toilet', 'toilet_bowl', 'wc']);
    final sinkPrice = findPrice(priceList, ['sink', 'washbasin', 'basin']);
    final showerPrice = findPrice(priceList, ['shower', 'shower_cabin', 'bathtub']);
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
