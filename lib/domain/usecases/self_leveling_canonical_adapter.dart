import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'logistics_buffer': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.03},
  'packaging_rounding': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.02},
};

bool hasCanonicalSelfLevelingInputs(Map<String, double> inputs) {
  return (inputs.containsKey('mixtureType') || inputs.containsKey('consumptionOverride')) && !inputs.containsKey('consumption');
}

Map<String, double> normalizeLegacySelfLevelingInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final hasDimensions = (inputs['length'] ?? 0) > 0 && (inputs['width'] ?? 0) > 0;
  if (!normalized.containsKey('inputMode')) {
    normalized['inputMode'] = hasDimensions ? 0.0 : 1.0;
  }
  if ((inputs['consumption'] ?? 0) > 0 && !normalized.containsKey('consumptionOverride')) {
    normalized['consumptionOverride'] = inputs['consumption']!.toDouble();
  }
  normalized['mixtureType'] = (inputs['mixtureType'] ?? 0).toDouble();
  normalized['bagWeight'] = (inputs['bagWeight'] ?? 25).toDouble();
  return normalized;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(1, inputs['length'] ?? defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(1, inputs['width'] ?? defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': roundValue(length * width, 3),
      'perimeter': roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(0.1, inputs['area'] ?? defaultFor(spec, 'area', 20)).toDouble();
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'perimeter': roundValue(_estimatePerimeter(area), 3),
  };
}

Map<String, dynamic> _resolveMixtureType(SpecReader spec, Map<String, double> inputs) {
  final mixtureType = (inputs['mixtureType'] ?? defaultFor(spec, 'mixtureType', 0)).round().clamp(0, 2);
  return spec.normativeList('mixture_types').firstWhere(
    (item) => (item['id'] as num).toInt() == mixtureType,
    orElse: () => spec.normativeList('mixture_types').first,
  );
}

double _resolveBagWeight(SpecReader spec, Map<String, double> inputs) {
  final bagWeight = (inputs['bagWeight'] ?? defaultFor(spec, 'bagWeight', 25)).toDouble();
  return bagWeight <= 20 ? 20 : 25;
}

double _resolveConsumption(SpecReader spec, Map<String, dynamic> mixtureType, Map<String, double> inputs) {
  final override = math.max(0, inputs['consumptionOverride'] ?? defaultFor(spec, 'consumptionOverride', 0)).toDouble();
  return override > 0 ? override : (mixtureType['base_kg_per_m2_mm'] as num).toDouble();
}

CanonicalCalculatorContractResult calculateCanonicalSelfLeveling(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(selfLevelingSpecData);

  final normalized = hasCanonicalSelfLevelingInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacySelfLevelingInputs(inputs);
  final work = _resolveArea(spec, normalized);
  final thickness = (normalized['thickness'] ?? defaultFor(spec, 'thickness', 10)).clamp(3, 100).toDouble();
  final mixtureType = _resolveMixtureType(spec, normalized);
  final bagWeight = _resolveBagWeight(spec, normalized);
  final consumptionKgPerM2Mm = _resolveConsumption(spec, mixtureType, normalized) * spec.materialRule<num>('reserve_factor').toDouble();
  final baseExactNeed = work['area']! * thickness * consumptionKgPerM2Mm;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeed * multiplier, 6);
    final bags = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = roundValue(bags * bagWeight, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'mixture:${mixtureType['key'] as String}',
        'packaging:self-leveling-bag-${bagWeight.toInt()}${spec.packagingRule<String>('unit')}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'self-leveling-bag-${bagWeight.toInt()}${spec.packagingRule<String>('unit')}',
        packageSize: bagWeight,
        packagesCount: bags,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final primerLiters = roundValue(work['area']! * spec.materialRule<num>('primer_l_per_m2').toDouble(), 6);
  final primerCans = math.max(1, (primerLiters / spec.packagingRule<num>('primer_can_l').toDouble()).ceil());
  final tapeLength = roundValue(work['perimeter']!, 6);
  final tapeRolls = math.max(1, (tapeLength / spec.packagingRule<num>('tape_roll_m').toDouble()).ceil());

  final warnings = <String>[];
  if (thickness < spec.materialRule<num>('leveling_min_thickness_mm').toDouble() && (mixtureType['id'] as num).toInt() == 0) {
    warnings.add('Минимальная толщина выравнивающей смеси — 5 мм. Для тонкого слоя используйте финишную смесь');
  }
  if (thickness > spec.materialRule<num>('finish_max_thickness_mm').toDouble() && (mixtureType['id'] as num).toInt() != 0) {
    warnings.add('Для больших перепадов (> 30 мм) используйте выравнивающую базовую смесь');
  }
  if (work['area']! > spec.materialRule<num>('deformation_joint_area_threshold_m2').toDouble()) {
    warnings.add('При площади > 30 м² необходимо устройство деформационных швов');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${mixtureType['label'] as String} (мешки ${bagWeight.toInt()} кг)',
        quantity: roundValue(recScenario.exactNeed / bagWeight, 6),
        unit: 'мешков',
        withReserve: recScenario.buyPlan.packagesCount.toDouble(),
        purchaseQty: recScenario.buyPlan.packagesCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка глубокого проникновения (${spec.packagingRule<num>('primer_can_l').toInt()} л)',
        quantity: primerLiters,
        unit: 'л',
        withReserve: primerCans * spec.packagingRule<num>('primer_can_l').toDouble(),
        purchaseQty: primerCans.toInt(),
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента (рулон ${spec.packagingRule<num>('tape_roll_m').toInt()} м)',
        quantity: roundValue(tapeLength / spec.packagingRule<num>('tape_roll_m').toDouble(), 6),
        unit: 'рулонов',
        withReserve: tapeRolls.toDouble(),
        purchaseQty: tapeRolls.toInt(),
        category: 'Подготовка',
      ),
    ],
    totals: {
      'area': work['area']!,
      'perimeter': work['perimeter']!,
      'inputMode': work['inputMode']!,
      'thickness': roundValue(thickness, 3),
      'mixtureType': (mixtureType['id'] as num).toInt().toDouble(),
      'bagWeight': bagWeight,
      'consumptionKgPerM2Mm': roundValue(consumptionKgPerM2Mm, 6),
      'totalKg': roundValue(recScenario.exactNeed, 6),
      'bagsNeeded': recScenario.buyPlan.packagesCount.toDouble(),
      'primerNeededLiters': primerLiters,
      'primerCans': primerCans.toDouble(),
      'damperTapeLengthMeters': tapeLength,
      'damperTapeRolls': tapeRolls.toDouble(),
      'minExactNeedKg': scenarios['MIN']!.exactNeed,
      'recExactNeedKg': recScenario.exactNeed,
      'maxExactNeedKg': scenarios['MAX']!.exactNeed,
      'minPurchaseKg': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseKg': recScenario.purchaseQuantity,
      'maxPurchaseKg': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
