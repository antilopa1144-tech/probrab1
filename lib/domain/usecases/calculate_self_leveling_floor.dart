import 'dart:math' as math;

import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './self_leveling_canonical_adapter.dart';

class CalculateSelfLevelingFloor extends BaseCalculator {
  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (hasCanonicalSelfLevelingInputs(inputs)) {
      return Map<String, double>.from(inputs);
    }
    return normalizeLegacySelfLevelingInputs(inputs);
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalSelfLeveling(_normalizeInputs(inputs));
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final normalized = _normalizeInputs(inputs);
    final inputMode = (normalized['inputMode'] ?? 0).toInt();
    if (inputMode == 0) {
      final length = normalized['length'] ?? 0;
      final width = normalized['width'] ?? 0;
      if (length <= 0) return positiveValueMessage('length');
      if (width <= 0) return positiveValueMessage('width');
    } else {
      if ((normalized['area'] ?? 0) <= 0) return positiveValueMessage('area');
    }

    final thickness = normalized['thickness'] ?? 10.0;
    if (thickness < 3 || thickness > 100) {
      return rangeMessage('thickness', 3, 100, unit: 'мм');
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonical(inputs);
    final area = contract.totals['area'] ?? 0;
    if (area <= 0) {
      throw CalculationException.invalidInput('self_leveling_floor', 'Площадь должна быть > 0');
    }

    final mixNeededKg = contract.totals['totalKg'] ?? 0;
    final primerNeededLiters = contract.totals['primerNeededLiters'] ?? 0;
    final damperTapeLengthMeters =
        contract.totals['damperTapeLengthMeters'] ?? 0;
    final spikeRollerArea = (inputs['spikeRollerArea'] ?? 50.0).clamp(
      1.0,
      1000.0,
    );
    final spikeRollers = math.max(1, (area / spikeRollerArea).ceil());
    final spikeShoesCount = ((inputs['spikeShoesCount'] ?? 1.0).round()).clamp(
      1,
      9999,
    );

    final mixPrice = findPrice(priceList, [
      'self_leveling',
      'self_leveling_floor',
      'leveling_compound',
      'floor_leveler',
    ]);
    final primerPrice = findPrice(priceList, [
      'primer',
      'primer_deep',
      'primer_penetrating',
    ]);
    final damperTapePrice = findPrice(priceList, [
      'damper_tape',
      'tape_edge',
      'expansion_tape',
    ]);

    return createResult(
      values: {
        'area': area,
        'thickness': contract.totals['thickness'] ?? 10,
        'mixNeededKg': mixNeededKg,
        'bagsNeeded': contract.totals['bagsNeeded'] ?? 0,
        'bagWeight': contract.totals['bagWeight'] ?? 25,
        'mixtureType': contract.totals['mixtureType'] ?? 0,
        'primerNeededLiters': primerNeededLiters,
        'damperTapeLengthMeters': damperTapeLengthMeters,
        'damperTapeRolls': contract.totals['damperTapeRolls'] ?? 0,
        'spikeRollers': spikeRollers.toDouble(),
        'spikeShoesCount': spikeShoesCount.toDouble(),
      },
      totalPrice: sumCosts([
        calculateCost(mixNeededKg, mixPrice?.price),
        calculateCost(primerNeededLiters, primerPrice?.price),
        calculateCost(damperTapeLengthMeters, damperTapePrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'self-leveling-canonical',
    );
  }
}
