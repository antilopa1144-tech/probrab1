import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

const SelfLevelingCanonicalSpec selfLevelingCanonicalSpecV1 = SelfLevelingCanonicalSpec(
  calculatorId: 'self-leveling',
  formulaVersion: 'self-leveling-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 50),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 50),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 1000),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 10, min: 3, max: 100),
    CanonicalInputField(key: 'mixtureType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'consumptionOverride', unit: 'kg/m2/mm', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'bagWeight', unit: 'kg', defaultValue: 25, min: 20, max: 25),
  ],
  enabledFactors: ['geometry_complexity', 'waste_factor', 'logistics_buffer', 'packaging_rounding'],
  mixtureTypes: [
    SelfLevelingMixtureTypeSpec(id: 0, key: 'leveling', label: 'Выравнивающая смесь', baseKgPerM2Mm: 1.6),
    SelfLevelingMixtureTypeSpec(id: 1, key: 'finish', label: 'Финишная смесь', baseKgPerM2Mm: 1.4),
    SelfLevelingMixtureTypeSpec(id: 2, key: 'fast', label: 'Быстросхватывающаяся смесь', baseKgPerM2Mm: 1.8),
  ],
  packagingRules: SelfLevelingPackagingRules(unit: 'кг', primerCanL: 5, tapeRollM: 25),
  materialRules: SelfLevelingMaterialRules(
    reserveFactor: 1.05,
    primerLPerM2: 0.15,
    levelingMinThicknessMm: 5,
    finishMaxThicknessMm: 30,
    deformationJointAreaThresholdM2: 30,
  ),
  warningRules: SelfLevelingWarningRules(largeAreaThresholdM2: 30),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'logistics_buffer': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.03},
  'packaging_rounding': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.02},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

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

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(SelfLevelingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveArea(SelfLevelingCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(1, inputs['length'] ?? _defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(1, inputs['width'] ?? _defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': _roundValue(length * width, 3),
      'perimeter': _roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(0.1, inputs['area'] ?? _defaultFor(spec, 'area', 20)).toDouble();
  return {
    'inputMode': 1.0,
    'area': _roundValue(area, 3),
    'perimeter': _roundValue(_estimatePerimeter(area), 3),
  };
}

SelfLevelingMixtureTypeSpec _resolveMixtureType(SelfLevelingCanonicalSpec spec, Map<String, double> inputs) {
  final mixtureType = (inputs['mixtureType'] ?? _defaultFor(spec, 'mixtureType', 0)).round().clamp(0, 2);
  return spec.mixtureTypes.firstWhere(
    (item) => item.id == mixtureType,
    orElse: () => spec.mixtureTypes.first,
  );
}

double _resolveBagWeight(SelfLevelingCanonicalSpec spec, Map<String, double> inputs) {
  final bagWeight = (inputs['bagWeight'] ?? _defaultFor(spec, 'bagWeight', 25)).toDouble();
  return bagWeight <= 20 ? 20 : 25;
}

double _resolveConsumption(SelfLevelingCanonicalSpec spec, SelfLevelingMixtureTypeSpec mixtureType, Map<String, double> inputs) {
  final override = math.max(0, inputs['consumptionOverride'] ?? _defaultFor(spec, 'consumptionOverride', 0)).toDouble();
  return override > 0 ? override : mixtureType.baseKgPerM2Mm;
}

double _scenarioMultiplier(SelfLevelingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

Map<String, double> _keyFactors(SelfLevelingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

CanonicalCalculatorContractResult calculateCanonicalSelfLeveling(
  Map<String, double> inputs, {
  SelfLevelingCanonicalSpec spec = selfLevelingCanonicalSpecV1,
}) {
  final normalized = hasCanonicalSelfLevelingInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacySelfLevelingInputs(inputs);
  final work = _resolveArea(spec, normalized);
  final thickness = (normalized['thickness'] ?? _defaultFor(spec, 'thickness', 10)).clamp(3, 100).toDouble();
  final mixtureType = _resolveMixtureType(spec, normalized);
  final bagWeight = _resolveBagWeight(spec, normalized);
  final consumptionKgPerM2Mm = _resolveConsumption(spec, mixtureType, normalized) * spec.materialRules.reserveFactor;
  final baseExactNeed = work['area']! * thickness * consumptionKgPerM2Mm;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeed * multiplier, 6);
    final bags = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = _roundValue(bags * bagWeight, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'mixture:${mixtureType.key}',
        'packaging:self-leveling-bag-${bagWeight.toInt()}${spec.packagingRules.unit}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'self-leveling-bag-${bagWeight.toInt()}${spec.packagingRules.unit}',
        packageSize: bagWeight,
        packagesCount: bags,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final primerLiters = _roundValue(work['area']! * spec.materialRules.primerLPerM2, 6);
  final primerCans = math.max(1, (primerLiters / spec.packagingRules.primerCanL).ceil());
  final tapeLength = _roundValue(work['perimeter']!, 6);
  final tapeRolls = math.max(1, (tapeLength / spec.packagingRules.tapeRollM).ceil());

  final warnings = <String>[];
  if (thickness < spec.materialRules.levelingMinThicknessMm && mixtureType.id == 0) {
    warnings.add('Минимальная толщина выравнивающей смеси — 5 мм. Для тонкого слоя используйте финишную смесь');
  }
  if (thickness > spec.materialRules.finishMaxThicknessMm && mixtureType.id != 0) {
    warnings.add('Для больших перепадов (> 30 мм) используйте выравнивающую базовую смесь');
  }
  if (work['area']! > spec.materialRules.deformationJointAreaThresholdM2) {
    warnings.add('При площади > 30 м² необходимо устройство деформационных швов');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${mixtureType.label} (мешки ${bagWeight.toInt()} кг)',
        quantity: _roundValue(recScenario.exactNeed / bagWeight, 6),
        unit: 'мешков',
        withReserve: recScenario.buyPlan.packagesCount.toDouble(),
        purchaseQty: recScenario.buyPlan.packagesCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка глубокого проникновения (${spec.packagingRules.primerCanL.toInt()} л)',
        quantity: primerLiters,
        unit: 'л',
        withReserve: primerCans * spec.packagingRules.primerCanL,
        purchaseQty: primerCans,
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента (рулон ${spec.packagingRules.tapeRollM.toInt()} м)',
        quantity: _roundValue(tapeLength / spec.packagingRules.tapeRollM, 6),
        unit: 'рулонов',
        withReserve: tapeRolls.toDouble(),
        purchaseQty: tapeRolls,
        category: 'Подготовка',
      ),
    ],
    totals: {
      'area': work['area']!,
      'perimeter': work['perimeter']!,
      'inputMode': work['inputMode']!,
      'thickness': _roundValue(thickness, 3),
      'mixtureType': mixtureType.id.toDouble(),
      'bagWeight': bagWeight,
      'consumptionKgPerM2Mm': _roundValue(consumptionKgPerM2Mm, 6),
      'totalKg': _roundValue(recScenario.exactNeed, 6),
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
