// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './laminate_canonical_adapter.dart';

class CalculateLaminate extends BaseCalculator {
  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (hasCanonicalLaminateInputs(inputs)) {
      return Map<String, double>.from(inputs);
    }
    return normalizeLegacyLaminateInputs(inputs);
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalLaminate(_normalizeInputs(inputs));
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final normalized = _normalizeInputs(inputs);
    final inputMode = (normalized['inputMode'] ?? 1).toInt();
    if (inputMode == 0) {
      final length = normalized['length'] ?? 0;
      final width = normalized['width'] ?? 0;
      if (length <= 0) return positiveValueMessage('length');
      if (width <= 0) return positiveValueMessage('width');
    } else {
      final area = normalized['area'] ?? 0;
      if (area <= 0) return positiveValueMessage('area');
    }

    final packArea = normalized['packArea'] ?? 0;
    if (packArea < 0.5 || packArea > 5) {
      return rangeMessage('packArea', 0.5, 5, unit: 'м²');
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

    final laminatePrice = findPrice(priceList, ['laminate', 'laminate_pack']);
    final underlayPrice = findPrice(priceList, [
      'underlay',
      'underlay_3mm',
      'underlay',
    ]);
    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_laminate']);
    final vaporBarrierPrice = findPrice(priceList, [
      'vapor_barrier',
      'film_pe',
    ]);
    final thresholdPrice = findPrice(priceList, [
      'threshold',
      'threshold_laminate',
    ]);

    final packsNeeded = contract.totals['packsNeeded'] ?? 0;
    final underlayArea = contract.totals['underlayArea'] ?? 0;
    final plinthLength = contract.totals['plinthLength'] ?? 0;
    final vaporBarrierArea = contract.totals['vaporBarrierArea'] ?? 0;
    final doorThresholds = contract.totals['doorThresholds'] ?? 0;

    return createResult(
      values: {
        'area': area,
        'packsNeeded': packsNeeded,
        'underlayArea': underlayArea,
        'underlayRolls': contract.totals['underlaymentRolls'] ?? 0,
        'plinthLength': plinthLength,
        'wedgesNeeded': contract.totals['wedgesNeeded'] ?? 0,
        'vaporBarrierArea': vaporBarrierArea,
        'doorThresholds': doorThresholds,
        'laminateClass': contract.totals['laminateClass'] ?? 32,
        'laminateThickness': contract.totals['laminateThickness'] ?? 8,
        'wastePercent': contract.totals['wastePercent'] ?? 0,
        'plinthPieces': contract.totals['plinthPieces'] ?? 0,
        'innerCorners': contract.totals['innerCorners'] ?? 0,
        'plinthConnectors': contract.totals['plinthConnectors'] ?? 0,
      },
      totalPrice: sumCosts([
        calculateCost(packsNeeded, laminatePrice?.price),
        calculateCost(underlayArea, underlayPrice?.price),
        calculateCost(plinthLength, plinthPrice?.price),
        calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
        calculateCost(doorThresholds, thresholdPrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'laminate-canonical',
    );
  }
}
