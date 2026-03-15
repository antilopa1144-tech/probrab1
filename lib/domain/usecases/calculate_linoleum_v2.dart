import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './linoleum_canonical_adapter.dart';

class CalculateLinoleumV2 extends BaseCalculator {
  static const double rollLength = 25.0;

  Map<String, double> _toCanonicalInputs(Map<String, double> inputs) {
    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'] ?? 0;
    final roomLength = inputs['roomLength'] ?? 0;
    final hasRoomDimensions = roomWidth > 0 && roomLength > 0;

    final canonical = <String, double>{
      'rollWidth': (inputs['rollWidth'] ?? 3.0).toDouble(),
      'needTape': ((inputs['needTape'] ?? 1) > 0 ? 1 : 0).toDouble(),
      'needPlinth': ((inputs['needPlinth'] ?? 1) > 0 ? 1 : 0).toDouble(),
      'needGlue': ((inputs['withGlue'] ?? inputs['needGlue'] ?? 0) > 0 ? 1 : 0)
          .toDouble(),
      'hasPattern': ((inputs['hasPattern'] ?? 0) > 0 ? 1 : 0).toDouble(),
      'patternRepeatCm':
          (inputs['patternRepeatCm'] ?? inputs['patternRepeat'] ?? 30)
              .toDouble(),
    };

    if (hasRoomDimensions) {
      canonical['inputMode'] = 0.0;
      canonical['length'] = roomLength.toDouble();
      canonical['width'] = roomWidth.toDouble();
    } else if (area > 0) {
      canonical['inputMode'] = 1.0;
      canonical['area'] = area.toDouble();
      canonical['roomWidth'] = roomWidth > 0
          ? roomWidth.toDouble()
          : math.sqrt(area);
      if ((inputs['perimeter'] ?? 0) > 0) {
        canonical['perimeter'] = inputs['perimeter']!.toDouble();
      }
    }

    return canonical;
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'] ?? 0;
    final roomLength = inputs['roomLength'] ?? 0;
    if (area <= 0 && !(roomWidth > 0 && roomLength > 0)) {
      return areaOrRoomDimensionsRequiredMessage();
    }
    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonicalLinoleum(_toCanonicalInputs(inputs));
    final area = contract.totals['area'] ?? 0;
    final roomWidth = contract.totals['roomWidth'] ?? math.sqrt(area);
    final roomLength = contract.totals['roomLength'] ?? math.sqrt(area);
    final rollWidth = contract.totals['rollWidth'] ?? 3.0;
    final linearMeters = contract.totals['linearMeters'] ?? 0;
    final areaWithWaste = contract.totals['totalCoverageArea'] ?? 0;
    final rollLengthValue = (inputs['rollLength'] ?? rollLength).toDouble();
    final rollsNeeded = rollLengthValue > 0
        ? linearMeters / rollLengthValue
        : 0.0;
    final needTape = (inputs['needTape'] ?? 1) > 0;
    final needPlinth = (inputs['needPlinth'] ?? 1) > 0;
    final tapeLength = needTape ? (contract.totals['tapeLength'] ?? 0) : 0.0;
    final plinthLength = needPlinth
        ? (contract.totals['plinthLengthRaw'] ?? 0)
        : 0.0;
    final plinthPieces = needPlinth
        ? (contract.totals['plinthPieces'] ?? 0)
        : 0.0;

    final linoleumPrice = findPrice(priceList, ['linoleum', 'линолеум']);
    final tapePrice = findPrice(priceList, ['tape', 'double_tape', 'скотч']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус']);

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'areaWithWaste': areaWithWaste,
        'rollWidth': rollWidth,
        'rollLength': rollLengthValue,
        'rollsNeeded': rollsNeeded,
        'linearMeters': linearMeters,
        'needTape': needTape ? 1.0 : 0.0,
        'tapeLength': tapeLength,
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'plinthLength': plinthLength,
        'plinthPieces': plinthPieces,
        'hasPattern': (contract.totals['hasPattern'] ?? 0),
        'patternRepeatCm': (contract.totals['patternRepeatCm'] ?? 0),
      },
      totalPrice: sumCosts([
        calculateCost(areaWithWaste, linoleumPrice?.price),
        calculateCost(tapeLength, tapePrice?.price),
        calculateCost(plinthPieces, plinthPrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'linoleum-canonical-v2',
    );
  }
}
