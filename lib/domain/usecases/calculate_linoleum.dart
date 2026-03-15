import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './linoleum_canonical_adapter.dart';

class CalculateLinoleum extends BaseCalculator {
  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (hasCanonicalLinoleumInputs(inputs)) {
      return Map<String, double>.from(inputs);
    }
    return normalizeLegacyLinoleumInputs(inputs);
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalLinoleum(_normalizeInputs(inputs));
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
      final area = normalized['area'] ?? 0;
      final roomWidth = normalized['roomWidth'] ?? 0;
      if (area <= 0) return positiveValueMessage('area');
      if (roomWidth <= 0) return positiveValueMessage('roomWidth');
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
      return createResult(values: {'error': 1.0});
    }

    final linoleumAreaNeeded = contract.totals['totalCoverageArea'] ?? 0;
    final linearMeters = contract.totals['linearMeters'] ?? 0;
    final cutsNeeded = contract.totals['stripsNeeded'] ?? 0;
    final cutLength = contract.totals['stripLengthBase'] ?? 0;
    final plinthLength = contract.totals['plinthLengthWithReserve'] ?? 0;
    final plinthPieces = contract.totals['plinthPieces'] ?? 0;
    final glueNeededKg = contract.totals['glueNeededKg'] ?? 0;
    final coldWeldingTubes = contract.totals['coldWeldingTubes'] ?? 0;

    final linoleumPrice = findPrice(priceList, [
      'linoleum',
      'linoleum_pvc',
      'vinyl_flooring',
    ]);
    final plinthPrice = findPrice(priceList, [
      'plinth',
      'plinth_linoleum',
      'baseboard',
    ]);
    final gluePrice = findPrice(priceList, [
      'glue_linoleum',
      'glue',
      'flooring_adhesive',
    ]);
    final coldWeldingPrice = findPrice(priceList, [
      'cold_welding',
      'linoleum_welding',
    ]);

    return createResult(
      values: {
        'area': area,
        'linoleumAreaNeeded': linoleumAreaNeeded,
        'linearMeters': linearMeters,
        'rollWidth': contract.totals['rollWidth'] ?? 3.0,
        'cutsNeeded': cutsNeeded,
        'cutLength': cutLength,
        if (coldWeldingTubes > 0) 'coldWeldingTubes': coldWeldingTubes,
        if (glueNeededKg > 0) 'glueNeededKg': glueNeededKg,
        if (plinthLength > 0) 'plinthLengthMeters': plinthLength,
        if (plinthPieces > 0) 'plinthPieces': plinthPieces,
        if ((contract.totals['tapeLength'] ?? 0) > 0)
          'tapeLength': contract.totals['tapeLength'] ?? 0,
      },
      totalPrice: sumCosts([
        calculateCost(linoleumAreaNeeded, linoleumPrice?.price),
        plinthLength > 0
            ? calculateCost(plinthLength, plinthPrice?.price)
            : null,
        glueNeededKg > 0 ? calculateCost(glueNeededKg, gluePrice?.price) : null,
        coldWeldingTubes > 0
            ? calculateCost(coldWeldingTubes, coldWeldingPrice?.price)
            : null,
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'linoleum-canonical',
    );
  }
}
