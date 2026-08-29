import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<int, String> _gradeLabels = {
  1: 'М100 (В7.5)',
  2: 'М150 (В12.5)',
  3: 'М200 (В15)',
  4: 'М250 (В20)',
  5: 'М300 (В22.5)',
  6: 'М350 (В25)',
  7: 'М400 (В30)',
};

bool hasCanonicalConcreteInputs(Map<String, double> inputs) {
  final hasVolume =
      inputs.containsKey('concreteVolume') ||
      (inputs.containsKey('area') && inputs.containsKey('thickness'));
  if (!hasVolume) return false;
  const canonicalKeys = [
    'concreteGrade',
    'manualMix',
    'readyMixOrderStepM3',
    'reserve',
  ];
  return canonicalKeys.any(inputs.containsKey);
}

Map<String, double> normalizeLegacyConcreteInputs(Map<String, double> inputs) {
  return {
    'inputMode': (inputs['inputMode'] ?? 0).round().clamp(0, 1).toDouble(),
    'concreteVolume': math.max(0.1, inputs['concreteVolume'] ?? 5).toDouble(),
    'concreteGrade': (inputs['concreteGrade'] ?? 3)
        .round()
        .clamp(1, 7)
        .toDouble(),
    'manualMix': (inputs['manualMix'] ?? 0).round().clamp(0, 1).toDouble(),
    'readyMixOrderStepM3': inputs['readyMixOrderStepM3'] ?? 0.1,
    'reserve': (inputs['reserve'] ?? 5).clamp(0, 20).toDouble(),
    'area': math.max(0.1, inputs['area'] ?? 20).toDouble(),
    'thickness': (inputs['thickness'] ?? 200).clamp(50, 1000).toDouble(),
  };
}

Map<String, double> _resolveVolume(
  SpecReader spec,
  Map<String, double> inputs,
) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0))
      .round();
  if (inputMode == 1) {
    final area = math.max(0.1, inputs['area'] ?? defaultFor(spec, 'area', 20));
    final thickness =
        (inputs['thickness'] ?? defaultFor(spec, 'thickness', 200))
            .clamp(50.0, 1000.0)
            .toDouble();
    return {
      'inputMode': 1,
      'sourceVolume': roundValue(area * (thickness / 1000), 6),
    };
  }
  return {
    'inputMode': 0,
    'sourceVolume': roundValue(
      math.max(
        0.1,
        inputs['concreteVolume'] ?? defaultFor(spec, 'concreteVolume', 5),
      ),
      6,
    ),
  };
}

List<Map<String, dynamic>> _planningProportions(SpecReader spec) {
  final planningMix = spec.raw['planning_mix'] as Map<String, dynamic>;
  return (planningMix['proportions'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
}

Map<String, dynamic> _resolveProportions(SpecReader spec, int grade) {
  final proportions = _planningProportions(spec);
  return proportions.firstWhere(
    (item) => (item['grade'] as num).toInt() == grade,
    orElse: () => proportions[2],
  );
}

double _roundUpToStep(double value, double step) {
  return roundValue(((value - 1e-12) / step).ceil() * step, 6);
}

Map<String, dynamic> _pickPackage(
  double exactNeed,
  double stepSize,
  String unit,
  String label,
) {
  final count = exactNeed > 0 ? ((exactNeed - 1e-12) / stepSize).ceil() : 0;
  final purchase = roundValue(count * stepSize, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': roundValue(purchase - exactNeed, 6),
    'label': label,
    'unit': unit,
  };
}

CanonicalCalculatorContractResult calculateCanonicalConcrete(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(concreteSpecData);
  final volume = _resolveVolume(spec, inputs);
  final sourceVolume = volume['sourceVolume']!;
  final inputMode = volume['inputMode']!;
  final concreteGrade =
      (inputs['concreteGrade'] ?? defaultFor(spec, 'concreteGrade', 3))
          .round()
          .clamp(1, 7);
  final manualMix =
      (inputs['manualMix'] ?? defaultFor(spec, 'manualMix', 0)).round() == 1
      ? 1
      : 0;
  final requestedOrderStep =
      inputs['readyMixOrderStepM3'] ??
      defaultFor(spec, 'readyMixOrderStepM3', 0.1);
  final allowedOrderSteps = (spec.packagingRule<List<dynamic>>(
    'allowed_ready_mix_order_steps_m3',
    const [0.1],
  )).map((item) => (item as num).toDouble()).toList();
  final readyMixOrderStepM3 = allowedOrderSteps.contains(requestedOrderStep)
      ? requestedOrderStep
      : allowedOrderSteps.first;
  final reserve = (inputs['reserve'] ?? defaultFor(spec, 'reserve', 5))
      .clamp(0.0, 20.0)
      .toDouble();
  final proportions = _resolveProportions(spec, concreteGrade);
  final gradeLabel = _gradeLabels[concreteGrade] ?? _gradeLabels[3]!;

  final cementKgPerM3 = (proportions['cement_kg'] as num).toDouble();
  final sandM3PerM3 = (proportions['sand_m3'] as num).toDouble();
  final gravelM3PerM3 = (proportions['gravel_m3'] as num).toDouble();
  final waterLPerM3 = (proportions['water_l'] as num).toDouble();
  final totalVolume = roundValue(sourceVolume * (1 + reserve / 100), 6);
  final scenarioPolicy =
      spec.raw['scenario_policy'] as Map<String, dynamic>? ?? const {};
  final recommendedMaxReserve = math.max(
    0.0,
    (scenarioPolicy['recommended_max_reserve_percent'] as num? ?? 10)
        .toDouble(),
  );

  var cementKg = 0.0;
  var cementBags = 0;
  var sandM3 = 0.0;
  var gravelM3 = 0.0;
  var waterL = 0.0;
  final cementBagKg = spec.packagingRule<num>('cement_bag_kg', 50).toDouble();
  final aggregateOrderStepM3 = spec
      .packagingRule<num>('aggregate_order_step_m3', 0.1)
      .toDouble();

  if (manualMix == 1) {
    cementKg = roundValue(totalVolume * cementKgPerM3, 6);
    cementBags = (cementKg / cementBagKg).ceil();
    sandM3 = roundValue(totalVolume * sandM3PerM3, 6);
    gravelM3 = roundValue(totalVolume * gravelM3PerM3, 6);
    waterL = roundValue(totalVolume * waterLPerM3, 6);
  }

  final scenarioPurchaseStep = manualMix == 1 ? 0.001 : readyMixOrderStepM3;
  final unit = spec.packagingRule<String>('unit', 'м³');
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final scenarioReserve = scenarioName == 'MIN'
        ? 0.0
        : scenarioName == 'MAX'
        ? math.max(reserve, recommendedMaxReserve)
        : reserve;
    final reserveMultiplier = 1 + scenarioReserve / 100;
    final exactNeed = roundValue(sourceVolume * reserveMultiplier, 6);
    final package = _pickPackage(
      exactNeed,
      scenarioPurchaseStep,
      unit,
      manualMix == 1
          ? 'calculated-concrete-yield'
          : 'ready-mix-step-$readyMixOrderStepM3$unit',
    );

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'grade:$concreteGrade',
        'manual_mix:$manualMix',
        'reserve_percent:$scenarioReserve',
        'scenario_policy:explicit_concrete_reserve',
        'mix_table_status:project_estimate_not_mix_design',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        'reserve_percent': roundValue(scenarioReserve, 3),
        'field_multiplier': roundValue(reserveMultiplier, 6),
        'ready_mix_order_step_m3': manualMix == 1 ? 0 : readyMixOrderStepM3,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: unit,
      ),
    );
  }

  final warnings = <String>[];
  final smallVolumeThreshold = spec
      .warningRule<num>('small_volume_threshold_m3', 0.5)
      .toDouble();
  final manualMixMaxGrade = spec
      .warningRule<num>('manual_mix_max_grade', 5)
      .toInt();
  if (sourceVolume < smallVolumeThreshold) {
    warnings.add(
      'Малый объём бетона — перерасход на замес и доставку может быть значительным',
    );
  }
  if (concreteGrade >= manualMixMaxGrade && manualMix == 1) {
    warnings.add(
      'Бетон высоких марок сложно замешивать вручную — рекомендуется заводской бетон',
    );
  }
  if (manualMix == 1) {
    warnings.add(
      'Компоненты рассчитаны как предварительная закупочная оценка, а не рецепт: рабочий состав и воду подбирают по фактическим материалам и проверяют по ГОСТ 27006-2019',
    );
  }

  final recScenario = scenarios['REC']!;
  final materials = <CanonicalMaterialResult>[];
  if (manualMix == 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Бетон $gradeLabel',
        quantity: sourceVolume,
        unit: 'м³',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        category: 'Основное',
      ),
    );
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Цемент М400 (${cementBagKg.toInt()} кг)',
        quantity: roundValue(cementKg, 3),
        unit: 'кг',
        withReserve: roundValue(cementBags * cementBagKg, 3),
        purchaseQty: (cementBags * cementBagKg).toDouble(),
        packageInfo: {
          'count': cementBags,
          'size': cementBagKg,
          'packageUnit': 'мешков',
        },
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Песок строительный',
        quantity: roundValue(sandM3, 3),
        unit: 'м³',
        withReserve: roundValue(sandM3, 3),
        purchaseQty: _roundUpToStep(sandM3, aggregateOrderStepM3),
        category: 'Компоненты',
      ),
      CanonicalMaterialResult(
        name: 'Щебень',
        quantity: roundValue(gravelM3, 3),
        unit: 'м³',
        withReserve: roundValue(gravelM3, 3),
        purchaseQty: _roundUpToStep(gravelM3, aggregateOrderStepM3),
        category: 'Компоненты',
      ),
    ]);
  }

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
      'readyMixOrderStepM3': readyMixOrderStepM3,
      'reserve': roundValue(reserve, 3),
      'gradeIndex': concreteGrade.toDouble(),
      'cementKgPerM3': cementKgPerM3,
      'sandM3PerM3': sandM3PerM3,
      'gravelM3PerM3': gravelM3PerM3,
      'waterLPerM3': waterLPerM3,
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
