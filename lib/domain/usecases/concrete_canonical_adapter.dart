import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

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

// ─── Detection & normalization ───

bool hasCanonicalConcreteInputs(Map<String, double> inputs) {
  final hasVolume = inputs.containsKey('concreteVolume') ||
      (inputs.containsKey('area') && inputs.containsKey('thickness'));
  if (!hasVolume) return false;
  const canonicalKeys = ['concreteGrade', 'manualMix', 'reserve'];
  return canonicalKeys.any(inputs.containsKey);
}

Map<String, double> normalizeLegacyConcreteInputs(Map<String, double> inputs) {
  return {
    'inputMode': (inputs['inputMode'] ?? 0).round().clamp(0, 1).toDouble(),
    'concreteVolume': math.max(0.1, inputs['concreteVolume'] ?? 5).toDouble(),
    'concreteGrade': (inputs['concreteGrade'] ?? 3).round().clamp(1, 7).toDouble(),
    'manualMix': (inputs['manualMix'] ?? 0).round().clamp(0, 1).toDouble(),
    'reserve': (inputs['reserve'] ?? 10).clamp(0, 50).toDouble(),
    'area': math.max(0.1, inputs['area'] ?? 20).toDouble(),
    'thickness': (inputs['thickness'] ?? 200).clamp(50, 1000).toDouble(),
  };
}

// ─── Helpers ───

Map<String, double> _resolveVolume(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 1) {
    final area = math.max(0.1, inputs['area'] ?? defaultFor(spec, 'area', 20));
    final thickness = (inputs['thickness'] ?? defaultFor(spec, 'thickness', 200)).clamp(50.0, 1000.0).toDouble();
    return {'inputMode': 1, 'sourceVolume': roundValue(area * (thickness / 1000), 6)};
  }
  return {
    'inputMode': 0,
    'sourceVolume': roundValue(
      math.max(0.1, inputs['concreteVolume'] ?? defaultFor(spec, 'concreteVolume', 5)),
      6,
    ),
  };
}

Map<String, dynamic> _resolveProportions(SpecReader spec, int grade) {
  final proportions = spec.normativeList('proportions');
  for (final p in proportions) {
    if ((p['grade'] as num).toInt() == grade) return p;
  }
  return proportions.length > 2 ? proportions[2] : proportions.first;
}

Map<String, dynamic> _pickPackage(double exactNeed, double stepSize, String unit) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = roundValue(count * stepSize, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': roundValue(purchase - exactNeed, 6),
    'label': 'concrete-$stepSize$unit',
  };
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalConcrete(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(concreteSpecData);

  final volume = _resolveVolume(spec, inputs);
  final sourceVolume = volume['sourceVolume']!;
  final inputMode = volume['inputMode']!;
  final concreteGrade = (inputs['concreteGrade'] ?? defaultFor(spec, 'concreteGrade', 3)).round().clamp(1, 7);
  final manualMix = (inputs['manualMix'] ?? defaultFor(spec, 'manualMix', 0)).round() == 1 ? 1 : 0;
  final reserve = (inputs['reserve'] ?? defaultFor(spec, 'reserve', 10)).clamp(0.0, 50.0).toDouble();
  final proportions = _resolveProportions(spec, concreteGrade);
  final gradeLabel = _gradeLabels[concreteGrade] ?? _gradeLabels[3]!;

  final cementKgPerM3 = (proportions['cement_kg'] as num).toDouble();
  final sandM3PerM3 = (proportions['sand_m3'] as num).toDouble();
  final gravelM3PerM3 = (proportions['gravel_m3'] as num).toDouble();
  final waterLPerM3 = (proportions['water_l'] as num).toDouble();

  final totalVolume = roundValue(sourceVolume * (1 + reserve / 100), 6);

  // Waterproofing
  final estimatedThickness = spec.materialRule<num>('estimated_slab_thickness_m', 0.2).toDouble();
  final topSurfaceArea = roundValue(totalVolume / estimatedThickness, 6);
  final perimeterEst = roundValue(math.sqrt(topSurfaceArea) * 4, 6);
  final waterproofArea = roundValue(perimeterEst * estimatedThickness, 6);
  final masticKgPerM2 = spec.materialRule<num>('waterproof_mastic_kg_per_m2', 1.0).toDouble();
  final waterproofReserve = spec.materialRule<num>('waterproof_reserve_factor', 1.15).toDouble();
  final masticKg = roundValue(waterproofArea * masticKgPerM2 * waterproofReserve, 6);
  final masticBucketKg = spec.packagingRule<num>('mastic_bucket_kg', 20).toDouble();
  final masticBuckets = (masticKg / masticBucketKg).ceil();

  // Film
  final filmReserve = spec.materialRule<num>('film_reserve_factor', 1.1).toDouble();
  final filmArea = roundValue(topSurfaceArea * filmReserve, 6);
  final filmRollM2 = spec.packagingRule<num>('film_roll_m2', 30).toDouble();
  final filmRolls = (filmArea / filmRollM2).ceil();

  // Manual mix
  var cementKg = 0.0;
  var cementBags = 0;
  var sandM3 = 0.0;
  var gravelM3 = 0.0;
  var waterL = 0.0;
  final cementBagKg = spec.packagingRule<num>('cement_bag_kg', 50).toDouble();

  if (manualMix == 1) {
    cementKg = roundValue(totalVolume * cementKgPerM3, 6);
    cementBags = (cementKg / cementBagKg).ceil();
    sandM3 = roundValue(totalVolume * sandM3PerM3 * spec.materialRule<num>('sand_reserve_factor', 1.05).toDouble(), 6);
    gravelM3 = roundValue(totalVolume * gravelM3PerM3 * spec.materialRule<num>('gravel_reserve_factor', 1.05).toDouble(), 6);
    waterL = roundValue(totalVolume * waterLPerM3, 6);
  }

  // Scenarios
  final volumeStepM3 = spec.packagingRule<num>('volume_step_m3', 0.1).toDouble();
  final unit = spec.packagingRule<String>('unit', 'м³');
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(totalVolume * multiplier, 6);
    final package = _pickPackage(exactNeed, volumeStepM3, unit);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'grade:$concreteGrade',
        'manual_mix:$manualMix',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  final smallVolumeThreshold = spec.warningRule<num>('small_volume_threshold_m3', 0.5).toDouble();
  final manualMixMaxGrade = spec.warningRule<num>('manual_mix_max_grade', 5).toInt();
  if (sourceVolume < smallVolumeThreshold) {
    warnings.add('Малый объём бетона — перерасход на замес и доставку может быть значительным');
  }
  if (concreteGrade >= manualMixMaxGrade && manualMix == 1) {
    warnings.add('Бетон высоких марок сложно замешивать вручную — рекомендуется заводской бетон');
  }

  // Materials
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
        name: 'Цемент М400 (${cementBagKg.toInt()} кг)',
        quantity: roundValue(cementKg, 3),
        unit: 'кг',
        withReserve: roundValue(cementBags * cementBagKg, 3),
        purchaseQty: cementBags.toInt(),
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Песок строительный',
        quantity: roundValue(sandM3, 3),
        unit: 'м³',
        withReserve: roundValue(sandM3, 3),
        purchaseQty: sandM3.ceil(),
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Щебень',
        quantity: roundValue(gravelM3, 3),
        unit: 'м³',
        withReserve: roundValue(gravelM3, 3),
        purchaseQty: gravelM3.ceil(),
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Вода',
        quantity: roundValue(waterL, 3),
        unit: 'л',
        withReserve: roundValue(waterL, 3),
        purchaseQty: waterL.ceil(),
        category: 'Компоненты',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Мастика гидроизоляционная (${masticBucketKg.toInt()} кг)',
      quantity: roundValue(masticKg, 3),
      unit: 'кг',
      withReserve: roundValue(masticBuckets * masticBucketKg, 3),
      purchaseQty: masticBuckets.toInt(),
      category: 'Гидроизоляция',
    ),
    CanonicalMaterialResult(
      name: 'Плёнка полиэтиленовая (${filmRollM2.toInt()} м²)',
      quantity: roundValue(filmArea, 3),
      unit: 'м²',
      withReserve: roundValue(filmRolls * filmRollM2, 3),
      purchaseQty: filmRolls.toInt(),
      category: 'Гидроизоляция',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'sourceVolume': roundValue(sourceVolume, 3),
      'totalVolume': roundValue(totalVolume, 3),
      'inputMode': inputMode,
      'concreteGrade': concreteGrade.toDouble(),
      'manualMix': manualMix.toDouble(),
      'reserve': roundValue(reserve, 3),
      'gradeIndex': concreteGrade.toDouble(),
      'cementKgPerM3': cementKgPerM3,
      'sandM3PerM3': sandM3PerM3,
      'gravelM3PerM3': gravelM3PerM3,
      'waterLPerM3': waterLPerM3,
      'topSurfaceArea': roundValue(topSurfaceArea, 3),
      'perimeterEst': roundValue(perimeterEst, 3),
      'waterproofArea': roundValue(waterproofArea, 3),
      'masticKg': roundValue(masticKg, 3),
      'masticBuckets': masticBuckets.toDouble(),
      'filmArea': roundValue(filmArea, 3),
      'filmRolls': filmRolls.toDouble(),
      'cementKg': roundValue(cementKg, 3),
      'cementBags': cementBags.toDouble(),
      'sandM3': roundValue(sandM3, 3),
      'gravelM3': roundValue(gravelM3, 3),
      'waterL': roundValue(waterL, 3),
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
