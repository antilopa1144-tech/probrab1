import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

// ─── Concrete-specific spec classes (inline, not in canonical_calculator_contract.dart) ───

class ConcreteProportionSpec {
  final int grade;
  final String label;
  final double cementKg;
  final double sandM3;
  final double gravelM3;
  final double waterL;

  const ConcreteProportionSpec({
    required this.grade,
    required this.label,
    required this.cementKg,
    required this.sandM3,
    required this.gravelM3,
    required this.waterL,
  });
}

class ConcretePackagingRules {
  final String unit;
  final double volumeStepM3;
  final double cementBagKg;
  final double masticBucketKg;
  final double filmRollM2;

  const ConcretePackagingRules({
    required this.unit,
    required this.volumeStepM3,
    required this.cementBagKg,
    required this.masticBucketKg,
    required this.filmRollM2,
  });
}

class ConcreteMaterialRules {
  final double waterproofMasticKgPerM2;
  final double waterproofReserveFactor;
  final double filmReserveFactor;
  final double sandReserveFactor;
  final double gravelReserveFactor;
  final double estimatedSlabThicknessM;

  const ConcreteMaterialRules({
    required this.waterproofMasticKgPerM2,
    required this.waterproofReserveFactor,
    required this.filmReserveFactor,
    required this.sandReserveFactor,
    required this.gravelReserveFactor,
    required this.estimatedSlabThicknessM,
  });
}

class ConcreteWarningRules {
  final double smallVolumeThresholdM3;
  final int manualMixMaxGrade;

  const ConcreteWarningRules({
    required this.smallVolumeThresholdM3,
    required this.manualMixMaxGrade,
  });
}

class ConcreteCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<ConcreteProportionSpec> proportions;
  final ConcretePackagingRules packagingRules;
  final ConcreteMaterialRules materialRules;
  final ConcreteWarningRules warningRules;

  const ConcreteCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.proportions,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

// ─── Spec constant ───

const ConcreteCanonicalSpec concreteCanonicalSpecV1 = ConcreteCanonicalSpec(
  calculatorId: 'concrete',
  formulaVersion: 'concrete-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'concreteVolume', unit: 'm3', defaultValue: 5, min: 0.1, max: 500),
    CanonicalInputField(key: 'concreteGrade', defaultValue: 3, min: 1, max: 7),
    CanonicalInputField(key: 'manualMix', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'reserve', unit: '%', defaultValue: 10, min: 0, max: 50),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 0.1, max: 1000),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 200, min: 50, max: 1000),
  ],
  enabledFactors: [
    'geometry_complexity',
    'worker_skill',
    'waste_factor',
  ],
  proportions: [
    ConcreteProportionSpec(grade: 1, label: 'М100 (В7.5)', cementKg: 170, sandM3: 0.56, gravelM3: 0.88, waterL: 210),
    ConcreteProportionSpec(grade: 2, label: 'М150 (В12.5)', cementKg: 215, sandM3: 0.54, gravelM3: 0.86, waterL: 200),
    ConcreteProportionSpec(grade: 3, label: 'М200 (В15)', cementKg: 290, sandM3: 0.50, gravelM3: 0.82, waterL: 190),
    ConcreteProportionSpec(grade: 4, label: 'М250 (В20)', cementKg: 340, sandM3: 0.47, gravelM3: 0.80, waterL: 185),
    ConcreteProportionSpec(grade: 5, label: 'М300 (В22.5)', cementKg: 380, sandM3: 0.44, gravelM3: 0.78, waterL: 180),
    ConcreteProportionSpec(grade: 6, label: 'М350 (В25)', cementKg: 420, sandM3: 0.41, gravelM3: 0.76, waterL: 175),
    ConcreteProportionSpec(grade: 7, label: 'М400 (В30)', cementKg: 480, sandM3: 0.38, gravelM3: 0.73, waterL: 170),
  ],
  packagingRules: ConcretePackagingRules(
    unit: 'м³',
    volumeStepM3: 0.1,
    cementBagKg: 50,
    masticBucketKg: 20,
    filmRollM2: 30,
  ),
  materialRules: ConcreteMaterialRules(
    waterproofMasticKgPerM2: 1.0,
    waterproofReserveFactor: 1.15,
    filmReserveFactor: 1.1,
    sandReserveFactor: 1.05,
    gravelReserveFactor: 1.05,
    estimatedSlabThicknessM: 0.2,
  ),
  warningRules: ConcreteWarningRules(
    smallVolumeThresholdM3: 0.5,
    manualMixMaxGrade: 5,
  ),
);

// ─── Grade labels ───

const Map<int, String> _gradeLabels = {
  1: 'М100 (В7.5)',
  2: 'М150 (В12.5)',
  3: 'М200 (В15)',
  4: 'М250 (В20)',
  5: 'М300 (В22.5)',
  6: 'М350 (В25)',
  7: 'М400 (В30)',
};

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

// ─── Detection & normalization ───

bool hasCanonicalConcreteInputs(Map<String, double> inputs) {
  final hasVolume = inputs.containsKey('concreteVolume') ||
      (inputs.containsKey('area') && inputs.containsKey('thickness'));
  if (!hasVolume) return false;

  const canonicalKeys = [
    'concreteGrade',
    'manualMix',
    'reserve',
  ];
  return canonicalKeys.any(inputs.containsKey);
}

Map<String, double> normalizeLegacyConcreteInputs(Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? 0).round().clamp(0, 1);
  final concreteVolume = math.max(0.1, inputs['concreteVolume'] ?? 5);
  final concreteGrade = (inputs['concreteGrade'] ?? 3).round().clamp(1, 7);
  final manualMix = (inputs['manualMix'] ?? 0).round().clamp(0, 1);
  final reserve = (inputs['reserve'] ?? 10).clamp(0, 50);
  final area = math.max(0.1, inputs['area'] ?? 20);
  final thickness = (inputs['thickness'] ?? 200).clamp(50, 1000);

  return {
    'inputMode': inputMode.toDouble(),
    'concreteVolume': concreteVolume.toDouble(),
    'concreteGrade': concreteGrade.toDouble(),
    'manualMix': manualMix.toDouble(),
    'reserve': reserve.toDouble(),
    'area': area.toDouble(),
    'thickness': thickness.toDouble(),
  };
}

// ─── Helpers ───

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(ConcreteCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

ConcreteProportionSpec _resolveProportions(ConcreteCanonicalSpec spec, int grade) {
  for (final p in spec.proportions) {
    if (p.grade == grade) return p;
  }
  return spec.proportions[2]; // default to grade 3 (M200)
}

Map<String, double> _resolveVolume(ConcreteCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 1) {
    final area = math.max(0.1, inputs['area'] ?? _defaultFor(spec, 'area', 20));
    final thickness = (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 200)).clamp(50, 1000).toDouble();
    return {
      'inputMode': 1.0,
      'sourceVolume': _roundValue(area * (thickness / 1000), 6),
    };
  }
  return {
    'inputMode': 0.0,
    'sourceVolume': _roundValue(
      math.max(0.1, inputs['concreteVolume'] ?? _defaultFor(spec, 'concreteVolume', 5)),
      6,
    ),
  };
}

Map<String, double> _keyFactors(ConcreteCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(ConcreteCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

Map<String, dynamic> _pickPackage(double exactNeed, double stepSize, String unit) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = _roundValue(count * stepSize, 6);
  final leftover = _roundValue(purchase - exactNeed, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': leftover,
    'label': 'concrete-${stepSize}$unit',
  };
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalConcrete(
  Map<String, double> inputs, {
  ConcreteCanonicalSpec spec = concreteCanonicalSpecV1,
}) {
  final volume = _resolveVolume(spec, inputs);
  final sourceVolume = volume['sourceVolume']!;
  final inputMode = volume['inputMode']!;
  final concreteGrade = (inputs['concreteGrade'] ?? _defaultFor(spec, 'concreteGrade', 3)).round().clamp(1, 7);
  final manualMix = (inputs['manualMix'] ?? _defaultFor(spec, 'manualMix', 0)).round() == 1 ? 1 : 0;
  final reserve = (inputs['reserve'] ?? _defaultFor(spec, 'reserve', 10)).clamp(0, 50).toDouble();
  final proportions = _resolveProportions(spec, concreteGrade);
  final gradeLabel = _gradeLabels[concreteGrade] ?? _gradeLabels[3]!;

  final totalVolume = _roundValue(sourceVolume * (1 + reserve / 100), 6);

  // Waterproofing
  final estimatedThickness = spec.materialRules.estimatedSlabThicknessM;
  final topSurfaceArea = _roundValue(totalVolume / estimatedThickness, 6);
  final perimeterEst = _roundValue(math.sqrt(topSurfaceArea) * 4, 6);
  final waterproofArea = _roundValue(perimeterEst * estimatedThickness, 6);
  final masticKg = _roundValue(
    waterproofArea * spec.materialRules.waterproofMasticKgPerM2 * spec.materialRules.waterproofReserveFactor,
    6,
  );
  final masticBuckets = (masticKg / spec.packagingRules.masticBucketKg).ceil();

  // Film
  final filmArea = _roundValue(topSurfaceArea * spec.materialRules.filmReserveFactor, 6);
  final filmRolls = (filmArea / spec.packagingRules.filmRollM2).ceil();

  // Manual mix components
  var cementKg = 0.0;
  var cementBags = 0;
  var sandM3 = 0.0;
  var gravelM3 = 0.0;
  var waterL = 0.0;

  if (manualMix == 1) {
    cementKg = _roundValue(totalVolume * proportions.cementKg, 6);
    cementBags = (cementKg / spec.packagingRules.cementBagKg).ceil();
    sandM3 = _roundValue(totalVolume * proportions.sandM3 * spec.materialRules.sandReserveFactor, 6);
    gravelM3 = _roundValue(totalVolume * proportions.gravelM3 * spec.materialRules.gravelReserveFactor, 6);
    waterL = _roundValue(totalVolume * proportions.waterL, 6);
  }

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalVolume * multiplier, 6);
    final package = _pickPackage(exactNeed, spec.packagingRules.volumeStepM3, spec.packagingRules.unit);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'grade:${proportions.grade}',
        'manual_mix:$manualMix',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (sourceVolume < spec.warningRules.smallVolumeThresholdM3) {
    warnings.add('Малый объём бетона — перерасход на замес и доставку может быть значительным');
  }
  if (concreteGrade >= spec.warningRules.manualMixMaxGrade && manualMix == 1) {
    warnings.add('Бетон высоких марок сложно замешивать вручную — рекомендуется заводской бетон');
  }

  // Materials list
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон $gradeLabel',
      quantity: recScenario.exactNeed,
      unit: 'м³',
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: recScenario.buyPlan.packagesCount,
      category: 'Основное',
    ),
  ];

  if (manualMix == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Цемент М400 (${spec.packagingRules.cementBagKg.toInt()} кг)',
        quantity: _roundValue(cementKg, 3),
        unit: 'кг',
        withReserve: _roundValue(cementBags * spec.packagingRules.cementBagKg, 3),
        purchaseQty: cementBags,
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Песок строительный',
        quantity: _roundValue(sandM3, 3),
        unit: 'м³',
        withReserve: _roundValue(sandM3, 3),
        purchaseQty: sandM3.ceil(),
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Щебень',
        quantity: _roundValue(gravelM3, 3),
        unit: 'м³',
        withReserve: _roundValue(gravelM3, 3),
        purchaseQty: gravelM3.ceil(),
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Вода',
        quantity: _roundValue(waterL, 3),
        unit: 'л',
        withReserve: _roundValue(waterL, 3),
        purchaseQty: waterL.ceil(),
        category: 'Компоненты',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Мастика гидроизоляционная (${spec.packagingRules.masticBucketKg.toInt()} кг)',
      quantity: _roundValue(masticKg, 3),
      unit: 'кг',
      withReserve: _roundValue(masticBuckets * spec.packagingRules.masticBucketKg, 3),
      purchaseQty: masticBuckets,
      category: 'Гидроизоляция',
    ),
    CanonicalMaterialResult(
      name: 'Плёнка полиэтиленовая (${spec.packagingRules.filmRollM2.toInt()} м²)',
      quantity: _roundValue(filmArea, 3),
      unit: 'м²',
      withReserve: _roundValue(filmRolls * spec.packagingRules.filmRollM2, 3),
      purchaseQty: filmRolls,
      category: 'Гидроизоляция',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'sourceVolume': _roundValue(sourceVolume, 3),
      'totalVolume': _roundValue(totalVolume, 3),
      'inputMode': inputMode,
      'concreteGrade': concreteGrade.toDouble(),
      'manualMix': manualMix.toDouble(),
      'reserve': _roundValue(reserve, 3),
      'gradeIndex': concreteGrade.toDouble(),
      'cementKgPerM3': proportions.cementKg,
      'sandM3PerM3': proportions.sandM3,
      'gravelM3PerM3': proportions.gravelM3,
      'waterLPerM3': proportions.waterL,
      'topSurfaceArea': _roundValue(topSurfaceArea, 3),
      'perimeterEst': _roundValue(perimeterEst, 3),
      'waterproofArea': _roundValue(waterproofArea, 3),
      'masticKg': _roundValue(masticKg, 3),
      'masticBuckets': masticBuckets.toDouble(),
      'filmArea': _roundValue(filmArea, 3),
      'filmRolls': filmRolls.toDouble(),
      'cementKg': _roundValue(cementKg, 3),
      'cementBags': cementBags.toDouble(),
      'sandM3': _roundValue(sandM3, 3),
      'gravelM3': _roundValue(gravelM3, 3),
      'waterL': _roundValue(waterL, 3),
      'minExactNeedM3': scenarios['MIN']!.exactNeed,
      'recExactNeedM3': recScenario.exactNeed,
      'maxExactNeedM3': scenarios['MAX']!.exactNeed,
      'minPurchaseM3': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseM3': recScenario.purchaseQuantity,
      'maxPurchaseM3': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
