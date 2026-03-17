import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const Map<int, String> _fenceTypeLabels = {
  0: 'Профнастил',
  1: 'Сетка-рабица',
  2: 'Деревянный штакетник',
};


bool hasCanonicalFenceInputs(Map<String, double> inputs) {
  return inputs.containsKey('fenceType') ||
      inputs.containsKey('postStep') ||
      inputs.containsKey('fenceHeight');
}

Map<String, double> normalizeLegacyFenceInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['fenceLength'] = (inputs['fenceLength'] ?? 50).toDouble();
  normalized['fenceHeight'] = (inputs['fenceHeight'] ?? 2).toDouble();
  normalized['fenceType'] = (inputs['fenceType'] ?? 0).toDouble();
  normalized['postStep'] = (inputs['postStep'] ?? 2.5).toDouble();
  normalized['gatesCount'] = (inputs['gatesCount'] ?? 1).toDouble();
  normalized['wicketsCount'] = (inputs['wicketsCount'] ?? 1).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalFence(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(fenceSpecData);

  final normalized = hasCanonicalFenceInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFenceInputs(inputs);

  final fenceLength = math.max(5.0, math.min(500.0, (normalized['fenceLength'] ?? defaultFor(spec, 'fenceLength', 50)).toDouble()));
  final fenceHeight = math.max(1.0, math.min(3.0, (normalized['fenceHeight'] ?? defaultFor(spec, 'fenceHeight', 2)).toDouble()));
  final fenceType = (normalized['fenceType'] ?? defaultFor(spec, 'fenceType', 0)).round().clamp(0, 2);
  final postStep = math.max(2.0, math.min(3.0, (normalized['postStep'] ?? defaultFor(spec, 'postStep', 2.5)).toDouble()));
  final gatesCount = (normalized['gatesCount'] ?? defaultFor(spec, 'gatesCount', 1)).round().clamp(0, 5);
  final wicketsCount = (normalized['wicketsCount'] ?? defaultFor(spec, 'wicketsCount', 1)).round().clamp(0, 5);

  // Common geometry
  final netLength = math.max(1.0, fenceLength - gatesCount * spec.materialRule<num>('gate_width').toDouble() - wicketsCount * spec.materialRule<num>('wicket_width').toDouble());
  final postsCount = (netLength / postStep).ceil() + 1 + gatesCount * 2 + wicketsCount * 2;
  final lagsPerSpan = fenceHeight > 2 ? 3 : 2;
  final lagSpans = (netLength / postStep).ceil();
  final lagsCount = lagSpans * lagsPerSpan;
  final postLength = roundValue(fenceHeight + spec.materialRule<num>('post_burial_m').toDouble(), 2);

  // Concrete for posts
  final concrete = roundValue(postsCount * spec.materialRule<num>('post_concrete_m3').toDouble(), 3);

  // Caps for posts
  final caps = (postsCount * spec.materialRule<num>('caps_reserve').toDouble()).ceil();

  // Type-specific covering
  var sheets = 0;
  var screws = 0;
  var screwPacks = 0;
  var primerCans = 0;
  var rolls = 0;
  var wireLength = 0.0;
  var slats = 0;
  var antisepticCans = 0;

  if (fenceType == 0) {
    // Profnastil
    sheets = (netLength / spec.materialRule<num>('profnastil_useful_width').toDouble() * spec.materialRule<num>('profnastil_reserve').toDouble()).ceil();
    screws = (sheets * spec.materialRule<num>('profnastil_screws_per_sheet').toDouble()).ceil();
    screwPacks = (screws / 250 * 10).ceil(); // кг (4.8×35: 250 шт/кг), *10 for rounding
    primerCans = (fenceLength / spec.materialRule<num>('primer_spray_m_per_can').toDouble()).ceil();
  } else if (fenceType == 1) {
    // Rabica
    rolls = (netLength / spec.materialRule<num>('rabica_roll_m').toDouble()).ceil();
    wireLength = roundValue(netLength * lagsPerSpan * spec.materialRule<num>('tension_wire_reserve').toDouble(), 2);
  } else {
    // Wooden slats
    slats = (netLength / (spec.materialRule<num>('slat_width').toDouble() + spec.materialRule<num>('slat_gap').toDouble()) * spec.materialRule<num>('slat_reserve').toDouble()).ceil();
    antisepticCans = (netLength * fenceHeight * 2 * spec.materialRule<num>('antiseptic_l_per_m2').toDouble() / spec.materialRule<num>('antiseptic_can_l').toDouble()).ceil();
  }

  // Scenarios
  final basePrimary = fenceType == 0 ? sheets : fenceType == 1 ? rolls : slats;
  final packageLabel = fenceType == 0
      ? 'profnastil-sheet'
      : fenceType == 1
          ? 'rabica-roll-10m'
          : 'wooden-slat';
  final packageUnit = fenceType == 0 ? 'шт' : fenceType == 1 ? 'рулонов' : 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'fenceType:$fenceType',
        'postStep:${postStep.toStringAsFixed(1)}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (gatesCount > spec.warningRule<num>('reinforced_post_gate_threshold').toDouble()) {
    warnings.add('При наличии ворот рекомендуются усиленные столбы 80×80 или 100×100 мм');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Столбы 60×60 мм ($postLength м)',
      quantity: postsCount.toDouble(),
      unit: 'шт',
      withReserve: postsCount.toDouble(),
      purchaseQty: postsCount.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Лаги 40×20 мм',
      quantity: lagsCount.toDouble(),
      unit: 'шт',
      withReserve: lagsCount.toDouble(),
      purchaseQty: lagsCount.toDouble(),
      category: 'Каркас',
    ),
  ];

  if (fenceType == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_fenceTypeLabels[0]} ($fenceHeight м)',
        quantity: recScenario.exactNeed,
        unit: 'шт',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil().toDouble(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы кровельные',
        quantity: screwPacks / 10,
        unit: 'кг',
        withReserve: screwPacks / 10,
        purchaseQty: (screwPacks / 10).ceil().toDouble(),
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Грунт-спрей для срезов',
        quantity: primerCans.toDouble(),
        unit: 'баллонов',
        withReserve: primerCans.toDouble(),
        purchaseQty: primerCans.toDouble(),
        category: 'Защита',
      ),
    ]);
  } else if (fenceType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_fenceTypeLabels[1]} ($fenceHeight м, рулон ${spec.materialRule<num>('rabica_roll_m').toDouble().round()} м)',
        quantity: recScenario.exactNeed,
        unit: 'рулонов',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil().toDouble(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Проволока натяжная',
        quantity: wireLength,
        unit: 'м',
        withReserve: wireLength,
        purchaseQty: wireLength.ceil().toDouble(),
        category: 'Крепёж',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_fenceTypeLabels[2]} ($fenceHeight м)',
        quantity: recScenario.exactNeed,
        unit: 'шт',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil().toDouble(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Антисептик (${spec.materialRule<num>('antiseptic_can_l').toDouble().round()} л)',
        quantity: antisepticCans.toDouble(),
        unit: 'канистр',
        withReserve: antisepticCans.toDouble(),
        purchaseQty: antisepticCans.toDouble(),
        category: 'Защита',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Бетон для столбов',
      quantity: concrete,
      unit: 'м³',
      withReserve: concrete,
      purchaseQty: (concrete * 10).ceil().toDouble(),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Заглушки для столбов',
      quantity: caps.toDouble(),
      unit: 'шт',
      withReserve: caps.toDouble(),
      purchaseQty: caps.toDouble(),
      category: 'Каркас',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'fenceLength': roundValue(fenceLength, 3),
      'fenceHeight': roundValue(fenceHeight, 3),
      'fenceType': fenceType.toDouble(),
      'postStep': roundValue(postStep, 2),
      'gatesCount': gatesCount.toDouble(),
      'wicketsCount': wicketsCount.toDouble(),
      'netLength': roundValue(netLength, 3),
      'postsCount': postsCount.toDouble(),
      'lagsPerSpan': lagsPerSpan.toDouble(),
      'lagSpans': lagSpans.toDouble(),
      'lagsCount': lagsCount.toDouble(),
      'postLength': postLength,
      'concrete': concrete,
      'caps': caps.toDouble(),
      'sheets': sheets.toDouble(),
      'screws': screws.toDouble(),
      'screwPacks': screwPacks / 10,
      'primerCans': primerCans.toDouble(),
      'rolls': rolls.toDouble(),
      'wireLength': wireLength,
      'slats': slats.toDouble(),
      'antisepticCans': antisepticCans.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': recScenario.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': recScenario.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
