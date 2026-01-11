// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор вагонки.
///
/// Нормативы:
/// - ГОСТ 8242-88 "Детали профильные из древесины"
/// - СП 64.13330.2017 "Деревянные конструкции"
///
/// Поля:
/// - area: площадь стен (м²)
/// - height: высота стен (м), по умолчанию 2.5
/// - perimeter: периметр комнаты (м), опционально
/// - liningType: тип вагонки (1=стандарт, 2=евро, 3=блок-хаус, 4=имитация бруса)
/// - mountingDirection: направление монтажа (1=вертикально, 2=горизонтально, 3=диагонально)
/// - fasteningType: тип крепления (1=кляймеры, 2=гвозди, 3=саморезы)
/// - reserve: запас материала (%), по умолчанию 10
/// - useInsulation: использовать утеплитель (0 или 1)
/// - useVaporBarrier: использовать пароизоляцию (0 или 1)
/// - useAntiseptic: использовать антисептик (0 или 1)
/// - useFinish: использовать финишное покрытие (0 или 1)
/// - finishType: тип финиша (1=лак, 2=масло, 3=воск, 4=морилка)
class CalculateWoodLining extends BaseCalculator {
  // Размеры вагонки по типам (ширина в мм, длина в м)
  static const _liningDimensions = {
    1: {'width': 88.0, 'length': 3.0}, // стандарт
    2: {'width': 96.0, 'length': 2.5}, // евро
    3: {'width': 140.0, 'length': 2.0}, // блок-хаус
    4: {'width': 140.0, 'length': 3.0}, // имитация бруса
  };

  // Крепёж на м² по типу
  static const _fasteningPerM2 = {
    1: 20, // кляймеры
    2: 25, // гвозди
    3: 20, // саморезы
  };

  // Расход финишного покрытия (л/м²)
  static const _finishConsumption = {
    1: 0.15, // лак
    2: 0.12, // масло
    3: 0.10, // воск
    4: 0.10, // морилка
  };

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (area > 1000) return 'Площадь превышает допустимый максимум';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1, maxValue: 1000.0);
    final height = getInput(inputs, 'height', defaultValue: 2.5, minValue: 1.5, maxValue: 5.0);
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    final liningType = getIntInput(inputs, 'liningType', defaultValue: 1, minValue: 1, maxValue: 4);
    final mountingDirection = getIntInput(inputs, 'mountingDirection', defaultValue: 1, minValue: 1, maxValue: 3);
    final fasteningType = getIntInput(inputs, 'fasteningType', defaultValue: 1, minValue: 1, maxValue: 3);
    final reserve = getInput(inputs, 'reserve', defaultValue: 10.0, minValue: 5.0, maxValue: 20.0);

    final useInsulation = getIntInput(inputs, 'useInsulation', defaultValue: 0, minValue: 0, maxValue: 1);
    final useVaporBarrier = getIntInput(inputs, 'useVaporBarrier', defaultValue: 0, minValue: 0, maxValue: 1);
    final useAntiseptic = getIntInput(inputs, 'useAntiseptic', defaultValue: 1, minValue: 0, maxValue: 1);
    final useFinish = getIntInput(inputs, 'useFinish', defaultValue: 0, minValue: 0, maxValue: 1);
    final finishType = getIntInput(inputs, 'finishType', defaultValue: 1, minValue: 1, maxValue: 4);

    // Вагонка с запасом
    final liningArea = area * (1 + reserve / 100);
    final dimensions = _liningDimensions[liningType]!;
    final boardWidth = dimensions['width']! / 1000; // в метрах
    final boardLength = dimensions['length']!;
    final boardAreaM2 = boardLength * boardWidth;
    final liningPieces = (liningArea / boardAreaM2).ceil();

    // Обрешётка
    final battenStep = 0.5; // шаг обрешётки 0.5 м
    double battenLength;
    double battenMargin;

    if (mountingDirection == 1) {
      // Вертикальный монтаж: горизонтальная обрешётка
      battenMargin = 1.1;
      final battenCount = (height / battenStep).ceil();
      battenLength = battenCount * perimeter * battenMargin;
    } else if (mountingDirection == 2) {
      // Горизонтальный монтаж: вертикальная обрешётка
      battenMargin = 1.1;
      final battenCount = (perimeter / battenStep).ceil();
      battenLength = battenCount * height * battenMargin;
    } else {
      // Диагональный монтаж: увеличенный расход
      battenMargin = 1.3;
      final battenCount = (perimeter / battenStep).ceil();
      battenLength = battenCount * height * battenMargin;
    }

    // Крепёж
    final fasteningPerM2 = _fasteningPerM2[fasteningType] ?? 20;
    final fasteners = (liningArea * fasteningPerM2).ceil();

    // Антисептик (0.2 л/м² с запасом 10%)
    final antisepticConsumption = 0.2;
    final antiseptic = useAntiseptic == 1 ? area * antisepticConsumption * 1.1 : 0.0;

    // Финишное покрытие
    final finishConsumption = _finishConsumption[finishType] ?? 0.15;
    final finish = useFinish == 1 ? area * finishConsumption * 1.1 : 0.0;

    // Утеплитель (с запасом 10%)
    final insulation = useInsulation == 1 ? area * 1.1 : 0.0;

    // Пароизоляция (с запасом 20% на нахлёсты)
    final vaporBarrier = useVaporBarrier == 1 ? area * 1.2 : 0.0;

    // Расчёт стоимости
    final liningPrice = findPrice(priceList, ['wood_lining', 'lining', 'vagónka', 'eurovakonka']);
    final battenPrice = findPrice(priceList, ['batten', 'reyка', 'brus_40x20']);
    final fasteningPrice = findPrice(priceList, [
      fasteningType == 1 ? 'klyaymer' : fasteningType == 2 ? 'nail_finish' : 'screw_wood',
      'fastener'
    ]);
    final antisepticPrice = findPrice(priceList, ['antiseptic', 'wood_antiseptic', 'impregnation']);
    final finishPrice = findPrice(priceList, [
      finishType == 1 ? 'varnish' : finishType == 2 ? 'wood_oil' : finishType == 3 ? 'wax' : 'stain',
      'wood_finish'
    ]);
    final insulationPrice = findPrice(priceList, ['mineral_wool', 'insulation', 'rockwool']);
    final vaporBarrierPrice = findPrice(priceList, ['vapor_barrier', 'paroizolyatsiya', 'membrane']);

    final costs = [
      calculateCost(liningArea, liningPrice?.price),
      calculateCost(battenLength, battenPrice?.price),
      calculateCost(fasteners.toDouble(), fasteningPrice?.price),
      if (useAntiseptic == 1) calculateCost(antiseptic, antisepticPrice?.price),
      if (useFinish == 1) calculateCost(finish, finishPrice?.price),
      if (useInsulation == 1) calculateCost(insulation, insulationPrice?.price),
      if (useVaporBarrier == 1) calculateCost(vaporBarrier, vaporBarrierPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'liningArea': liningArea,
        'liningPieces': liningPieces.toDouble(),
        'battenLength': battenLength,
        'fasteners': fasteners.toDouble(),
        'liningType': liningType.toDouble(),
        'mountingDirection': mountingDirection.toDouble(),
        'fasteningType': fasteningType.toDouble(),
        if (useAntiseptic == 1) 'antiseptic': antiseptic,
        if (useFinish == 1) 'finish': finish,
        if (useInsulation == 1) 'insulation': insulation,
        if (useVaporBarrier == 1) 'vaporBarrier': vaporBarrier,
      },
      totalPrice: sumCosts(costs),
      decimals: 1,
    );
  }
}
