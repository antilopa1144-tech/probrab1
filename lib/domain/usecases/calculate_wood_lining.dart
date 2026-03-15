// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

class CalculateWoodLining extends BaseCalculator {
  static const _liningDimensions = {
    1: {'width': 88.0, 'length': 3.0},
    2: {'width': 96.0, 'length': 2.5},
    3: {'width': 140.0, 'length': 2.0},
    4: {'width': 140.0, 'length': 3.0},
  };

  static const _fasteningPerM2 = {1: 20, 2: 25, 3: 20};

  static const _finishConsumption = {1: 0.15, 2: 0.12, 3: 0.10, 4: 0.10};

  bool _hasScreenInputs(Map<String, double> inputs) {
    return inputs.containsKey('inputMode') ||
        inputs.containsKey('length') ||
        inputs.containsKey('width');
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    if (_hasScreenInputs(inputs)) {
      final area = _resolveScreenArea(inputs);
      if (area <= 0) return positiveValueMessage('area');
      if (area > 1000) return maxValueMessage('area', 1000);
      return null;
    }

    final area = inputs['area'] ?? 0;
    if (area <= 0) return positiveValueMessage('area');
    if (area > 1000) return maxValueMessage('area', 1000);
    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasScreenInputs(inputs)) {
      return _calculateScreenPath(inputs, priceList);
    }
    return _calculateLegacyPath(inputs, priceList);
  }

  CalculatorResult _calculateScreenPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = _resolveScreenArea(inputs);
    final height = getInput(
      inputs,
      'height',
      defaultValue: 2.5,
      minValue: 1.5,
      maxValue: 5.0,
    );
    final perimeter = _resolveScreenPerimeter(inputs, area);
    final liningType = ((inputs['liningType'] ?? 0).round().clamp(0, 3)) + 1;
    final mountingDirection =
        ((inputs['mountingDirection'] ?? 0).round().clamp(0, 2)) + 1;
    final fasteningType =
        ((inputs['fasteningType'] ?? 0).round().clamp(0, 2)) + 1;
    final reserve = getInput(
      inputs,
      'reserve',
      defaultValue: 10.0,
      minValue: 5.0,
      maxValue: 20.0,
    );
    final useInsulation = (inputs['useInsulation'] ?? 0) > 0 ? 1 : 0;
    final useVaporBarrier = (inputs['useVaporBarrier'] ?? 0) > 0 ? 1 : 0;
    final useAntiseptic = (inputs['useAntiseptic'] ?? 1) > 0 ? 1 : 0;
    final useFinish = (inputs['useFinish'] ?? 0) > 0 ? 1 : 0;
    final finishType = ((inputs['finishType'] ?? 0).round().clamp(0, 3)) + 1;

    final liningArea = area * (1 + reserve / 100);
    final dimensions = _liningDimensions[liningType]!;
    final boardWidth = dimensions['width']! / 1000;
    final boardLength = dimensions['length']!;
    final boardAreaM2 = boardLength * boardWidth;
    final liningPieces = (liningArea / boardAreaM2).ceil();

    const battenStep = 0.5;
    double battenLength;
    if (mountingDirection == 1) {
      final battenCount = (height / battenStep).ceil();
      battenLength = battenCount * perimeter * 1.1;
    } else if (mountingDirection == 2) {
      final battenCount = (perimeter / battenStep).ceil();
      battenLength = battenCount * height * 1.1;
    } else {
      final battenCount = (perimeter / battenStep).ceil();
      battenLength = battenCount * height * 1.3;
    }

    final fasteners = (liningArea * (_fasteningPerM2[fasteningType] ?? 20))
        .ceil();
    const antisepticConsumption = 0.2;
    const antisepticMargin = 1.1;
    final antiseptic = useAntiseptic == 1
        ? area * antisepticConsumption * antisepticMargin
        : 0.0;
    final finishConsumption = _finishConsumption[finishType] ?? 0.15;
    final finish = useFinish == 1 ? area * finishConsumption * 1.1 : 0.0;
    final insulation = useInsulation == 1 ? area * 1.1 : 0.0;
    final vaporBarrier = useVaporBarrier == 1 ? area * 1.2 : 0.0;
    const vaporBarrierWeightPerM2 = 0.15;
    final vaporBarrierWeight = vaporBarrier * vaporBarrierWeightPerM2;

    final liningPrice = findPrice(priceList, [
      'wood_lining',
      'lining',
      'vagónka',
      'eurovakonka',
    ]);
    final battenPrice = findPrice(priceList, ['batten', 'reyка', 'brus_40x20']);
    final fasteningPrice = findPrice(priceList, [
      fasteningType == 1
          ? 'klyaymer'
          : fasteningType == 2
          ? 'nail_finish'
          : 'screw_wood',
      'fastener',
    ]);
    final antisepticPrice = findPrice(priceList, [
      'antiseptic',
      'wood_antiseptic',
      'impregnation',
    ]);
    final finishPrice = findPrice(priceList, [
      finishType == 1
          ? 'varnish'
          : finishType == 2
          ? 'wood_oil'
          : finishType == 3
          ? 'wax'
          : 'stain',
      'wood_finish',
    ]);
    final insulationPrice = findPrice(priceList, [
      'mineral_wool',
      'insulation',
      'rockwool',
    ]);
    final vaporBarrierPrice = findPrice(priceList, [
      'vapor_barrier',
      'paroizolyatsiya',
      'membrane',
    ]);

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
        'liningBoardWidth': dimensions['width']!,
        'liningBoardLength': dimensions['length']!,
        'perimeter': perimeter,
        'height': height,
        'reserve': reserve,
        'finishType': finishType.toDouble(),
        'antisepticConsumption': antisepticConsumption,
        'finishConsumption': finishConsumption,
        'vaporBarrierWeightPerM2': vaporBarrierWeightPerM2,
        if (useAntiseptic == 1) 'antiseptic': antiseptic,
        if (useFinish == 1) 'finish': finish,
        if (useInsulation == 1) 'insulation': insulation,
        if (useVaporBarrier == 1) 'vaporBarrier': vaporBarrier,
        if (useVaporBarrier == 1) 'vaporBarrierWeight': vaporBarrierWeight,
      },
      totalPrice: sumCosts([
        calculateCost(liningArea, liningPrice?.price),
        calculateCost(battenLength, battenPrice?.price),
        calculateCost(fasteners.toDouble(), fasteningPrice?.price),
        if (useAntiseptic == 1)
          calculateCost(antiseptic, antisepticPrice?.price),
        if (useFinish == 1) calculateCost(finish, finishPrice?.price),
        if (useInsulation == 1)
          calculateCost(insulation, insulationPrice?.price),
        if (useVaporBarrier == 1)
          calculateCost(vaporBarrier, vaporBarrierPrice?.price),
      ]),
      decimals: 1,
    );
  }

  CalculatorResult _calculateLegacyPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1, maxValue: 1000.0);
    final height = getInput(
      inputs,
      'height',
      defaultValue: 2.5,
      minValue: 1.5,
      maxValue: 5.0,
    );
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final liningType = getIntInput(
      inputs,
      'liningType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 4,
    );
    final mountingDirection = getIntInput(
      inputs,
      'mountingDirection',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final fasteningType = getIntInput(
      inputs,
      'fasteningType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final reserve = getInput(
      inputs,
      'reserve',
      defaultValue: 10.0,
      minValue: 5.0,
      maxValue: 20.0,
    );
    final useInsulation = getIntInput(
      inputs,
      'useInsulation',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final useVaporBarrier = getIntInput(
      inputs,
      'useVaporBarrier',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final useAntiseptic = getIntInput(
      inputs,
      'useAntiseptic',
      defaultValue: 1,
      minValue: 0,
      maxValue: 1,
    );
    final useFinish = getIntInput(
      inputs,
      'useFinish',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final finishType = getIntInput(
      inputs,
      'finishType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 4,
    );

    final liningArea = area * (1 + reserve / 100);
    final dimensions = _liningDimensions[liningType]!;
    final boardWidth = dimensions['width']! / 1000;
    final boardLength = dimensions['length']!;
    final boardAreaM2 = boardLength * boardWidth;
    final liningPieces = (liningArea / boardAreaM2).ceil();

    const battenStep = 0.5;
    double battenLength;
    double battenMargin;

    if (mountingDirection == 1) {
      battenMargin = 1.1;
      final battenCount = (height / battenStep).ceil();
      battenLength = battenCount * perimeter * battenMargin;
    } else if (mountingDirection == 2) {
      battenMargin = 1.1;
      final battenCount = (perimeter / battenStep).ceil();
      battenLength = battenCount * height * battenMargin;
    } else {
      battenMargin = 1.3;
      final battenCount = (perimeter / battenStep).ceil();
      battenLength = battenCount * height * battenMargin;
    }

    final fasteningPerM2 = _fasteningPerM2[fasteningType] ?? 20;
    final fasteners = (liningArea * fasteningPerM2).ceil();
    final antisepticConsumption = 0.2;
    final antiseptic = useAntiseptic == 1
        ? area * antisepticConsumption * 1.1
        : 0.0;
    final finishConsumption = _finishConsumption[finishType] ?? 0.15;
    final finish = useFinish == 1 ? area * finishConsumption * 1.1 : 0.0;
    final insulation = useInsulation == 1 ? area * 1.1 : 0.0;
    final vaporBarrier = useVaporBarrier == 1 ? area * 1.2 : 0.0;

    final liningPrice = findPrice(priceList, [
      'wood_lining',
      'lining',
      'vagónka',
      'eurovakonka',
    ]);
    final battenPrice = findPrice(priceList, ['batten', 'reyка', 'brus_40x20']);
    final fasteningPrice = findPrice(priceList, [
      fasteningType == 1
          ? 'klyaymer'
          : fasteningType == 2
          ? 'nail_finish'
          : 'screw_wood',
      'fastener',
    ]);
    final antisepticPrice = findPrice(priceList, [
      'antiseptic',
      'wood_antiseptic',
      'impregnation',
    ]);
    final finishPrice = findPrice(priceList, [
      finishType == 1
          ? 'varnish'
          : finishType == 2
          ? 'wood_oil'
          : finishType == 3
          ? 'wax'
          : 'stain',
      'wood_finish',
    ]);
    final insulationPrice = findPrice(priceList, [
      'mineral_wool',
      'insulation',
      'rockwool',
    ]);
    final vaporBarrierPrice = findPrice(priceList, [
      'vapor_barrier',
      'paroizolyatsiya',
      'membrane',
    ]);

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
      totalPrice: sumCosts([
        calculateCost(liningArea, liningPrice?.price),
        calculateCost(battenLength, battenPrice?.price),
        calculateCost(fasteners.toDouble(), fasteningPrice?.price),
        if (useAntiseptic == 1)
          calculateCost(antiseptic, antisepticPrice?.price),
        if (useFinish == 1) calculateCost(finish, finishPrice?.price),
        if (useInsulation == 1)
          calculateCost(insulation, insulationPrice?.price),
        if (useVaporBarrier == 1)
          calculateCost(vaporBarrier, vaporBarrierPrice?.price),
      ]),
      decimals: 1,
    );
  }

  double _resolveScreenArea(Map<String, double> inputs) {
    final inputMode = (inputs['inputMode'] ?? 0).round();
    if (inputMode == 1) {
      final length = getInput(
        inputs,
        'length',
        defaultValue: 5.0,
        minValue: 0.1,
        maxValue: 50.0,
      );
      final width = getInput(
        inputs,
        'width',
        defaultValue: 4.0,
        minValue: 0.1,
        maxValue: 50.0,
      );
      final height = getInput(
        inputs,
        'height',
        defaultValue: 2.5,
        minValue: 1.5,
        maxValue: 5.0,
      );
      return 2 * (length + width) * height;
    }
    return getInput(
      inputs,
      'area',
      defaultValue: 20.0,
      minValue: 0.1,
      maxValue: 1000.0,
    );
  }

  double _resolveScreenPerimeter(Map<String, double> inputs, double area) {
    final inputMode = (inputs['inputMode'] ?? 0).round();
    if (inputMode == 1) {
      final length = getInput(
        inputs,
        'length',
        defaultValue: 5.0,
        minValue: 0.1,
        maxValue: 50.0,
      );
      final width = getInput(
        inputs,
        'width',
        defaultValue: 4.0,
        minValue: 0.1,
        maxValue: 50.0,
      );
      return 2 * (length + width);
    }
    return estimatePerimeter(area);
  }
}
