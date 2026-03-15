// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './plaster_canonical_adapter.dart';

class CalculatePlaster extends BaseCalculator {
  bool _hasCanonicalInputs(Map<String, double> inputs) =>
      hasCanonicalPlasterInputs(inputs);

  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (_hasCanonicalInputs(inputs)) {
      return {
        'inputMode': inputs['inputMode'] ?? 0,
        'length': inputs['length'] ?? 5,
        'width': inputs['width'] ?? 4,
        'height': inputs['height'] ?? 2.7,
        'area': inputs['area'] ?? 50,
        'openingsArea': inputs['openingsArea'] ?? 5,
        'plasterType': inputs['plasterType'] ?? 0,
        'thickness': inputs['thickness'] ?? 15,
        'bagWeight': inputs['bagWeight'] ?? 30,
        'substrateType': inputs['substrateType'] ?? 1,
        'wallEvenness': inputs['wallEvenness'] ?? 1,
      };
    }

    final legacyType = getIntInput(
      inputs,
      'type',
      defaultValue: 1,
      minValue: 1,
      maxValue: 2,
    );
    return {
      'inputMode': 1.0,
      'area': inputs['area'] ?? 0,
      'openingsArea': 0.0,
      'plasterType': (legacyType - 1).toDouble(),
      'thickness': inputs['thickness'] ?? 10,
      'bagWeight': legacyType == 1 ? 30.0 : 25.0,
      'substrateType': inputs['substrateType'] ?? 1,
      'wallEvenness': inputs['wallEvenness'] ?? 1,
    };
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalPlaster(_normalizeInputs(inputs));
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final normalized = _normalizeInputs(inputs);
    final area = normalized['area'] ?? 0;
    if ((_hasCanonicalInputs(inputs) &&
            area <= 0 &&
            (normalized['length'] ?? 0) <= 0) ||
        (!_hasCanonicalInputs(inputs) && area <= 0)) {
      return positiveValueMessage('area');
    }
    if (area > 100000) return maxValueMessage('area', 100000, unit: 'м²');
    final thickness = normalized['thickness'] ?? 10;
    if (thickness > 100) return maxValueMessage('thickness', 100, unit: 'мм');
    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final normalized = _normalizeInputs(inputs);
    final contract = calculateCanonicalPlaster(normalized);
    final legacyType = getIntInput(
      inputs,
      'type',
      defaultValue: 1,
      minValue: 1,
      maxValue: 2,
    );
    final plasterKg = contract.totals['totalKg'] ?? 0;
    final plasterBags = _findMaterialPurchaseQty(
      contract,
      'Основное',
      nameFallback: 'штукатурка',
    );
    final primerNeeded = contract.totals['primerNeed'] ?? 0;
    final primerType = contract.totals['primerType'] ?? 1;
    final meshArea = contract.totals['meshArea'] ?? 0;
    final beacons = contract.totals['beacons'] ?? 0;
    final beaconSize = contract.totals['beaconSize'] ?? 10;
    final ruleSize = contract.totals['ruleSize'] ?? 1.5;

    final plasterPrice = legacyType == 1
        ? findPrice(priceList, ['plaster_gypsum', 'plaster', 'gypsum_plaster'])
        : findPrice(priceList, ['plaster_cement', 'cement_plaster', 'plaster']);
    final primerPrice = primerType == 2
        ? findPrice(priceList, ['betonkontakt', 'primer_contact', 'primer'])
        : findPrice(priceList, ['primer_deep', 'primer', 'primer_penetrating']);
    final meshPrice = findPrice(priceList, [
      'mesh',
      'plaster_mesh',
      'reinforcement_mesh',
    ]);
    final beaconPrice = findPrice(priceList, [
      'beacon',
      'beacon_plaster',
      'profile_beacon',
    ]);
    final bagWeight =
        contract.totals['bagWeight'] ?? (legacyType == 1 ? 30 : 25);

    final costs = [
      calculateCost(plasterBags.toDouble() * bagWeight, plasterPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (meshArea > 0) calculateCost(meshArea, meshPrice?.price),
      calculateCost(beacons, beaconPrice?.price),
    ];

    return createResult(
      values: {
        'plasterBags': plasterBags.toDouble(),
        'plasterKg': plasterKg,
        'bagWeight': bagWeight,
        'primerLiters': primerNeeded,
        'primerType': primerType,
        if (meshArea > 0) 'meshArea': meshArea,
        'beacons': beacons,
        'beaconSize': beaconSize,
        'ruleSize': ruleSize,
        if ((contract.totals['warningThickLayer'] ?? 0) > 0)
          'warningThickLayer': 1.0,
        if ((contract.totals['tipObryzg'] ?? 0) > 0) 'tipObryzg': 1.0,
      },
      totalPrice: sumCosts(costs),
      decimals: 1,
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'plaster-canonical',
    );
  }

  int _findMaterialPurchaseQty(
    CanonicalCalculatorContractResult contract,
    String categoryPart, {
    String? nameFallback,
  }) {
    for (final material in contract.materials) {
      if ((material.category ?? '').contains(categoryPart)) {
        return material.purchaseQty ?? 0;
      }
    }
    if (nameFallback != null) {
      for (final material in contract.materials) {
        if (material.name.toLowerCase().contains(nameFallback)) {
          return material.purchaseQty ?? 0;
        }
      }
    }
    return 0;
  }
}
