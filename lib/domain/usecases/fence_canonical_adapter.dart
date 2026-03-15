import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class FencePackagingRules {
  final String unit;
  final int packageSize;

  const FencePackagingRules({required this.unit, required this.packageSize});
}

class FenceMaterialRules {
  final double postBurialM;
  final double profnastilUsefulWidth;
  final double profnastilReserve;
  final int profnastilScrewsPerSheet;
  final int screwsPack;
  final double primerSprayMPerCan;
  final double postConcreteM3;
  final double capsReserve;
  final double rabicaRollM;
  final double tensionWireReserve;
  final double slatWidth;
  final double slatGap;
  final double slatReserve;
  final double antisepticLPerM2;
  final double antisepticCanL;
  final double gateWidth;
  final double wicketWidth;

  const FenceMaterialRules({
    required this.postBurialM,
    required this.profnastilUsefulWidth,
    required this.profnastilReserve,
    required this.profnastilScrewsPerSheet,
    required this.screwsPack,
    required this.primerSprayMPerCan,
    required this.postConcreteM3,
    required this.capsReserve,
    required this.rabicaRollM,
    required this.tensionWireReserve,
    required this.slatWidth,
    required this.slatGap,
    required this.slatReserve,
    required this.antisepticLPerM2,
    required this.antisepticCanL,
    required this.gateWidth,
    required this.wicketWidth,
  });
}

class FenceWarningRules {
  final int reinforcedPostGateThreshold;

  const FenceWarningRules({required this.reinforcedPostGateThreshold});
}

class FenceCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FencePackagingRules packagingRules;
  final FenceMaterialRules materialRules;
  final FenceWarningRules warningRules;

  const FenceCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── spec instance ─── */

const FenceCanonicalSpec fenceCanonicalSpecV1 = FenceCanonicalSpec(
  calculatorId: 'fence',
  formulaVersion: 'fence-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'fenceLength', unit: 'm', defaultValue: 50, min: 5, max: 500),
    CanonicalInputField(key: 'fenceHeight', unit: 'm', defaultValue: 2, min: 1, max: 3),
    CanonicalInputField(key: 'fenceType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'postStep', unit: 'm', defaultValue: 2.5, min: 2.0, max: 3.0),
    CanonicalInputField(key: 'gatesCount', defaultValue: 1, min: 0, max: 5),
    CanonicalInputField(key: 'wicketsCount', defaultValue: 1, min: 0, max: 5),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: FencePackagingRules(unit: 'шт', packageSize: 1),
  materialRules: FenceMaterialRules(
    postBurialM: 0.9,
    profnastilUsefulWidth: 1.15,
    profnastilReserve: 1.02,
    profnastilScrewsPerSheet: 7,
    screwsPack: 200,
    primerSprayMPerCan: 20,
    postConcreteM3: 0.03,
    capsReserve: 1.05,
    rabicaRollM: 10,
    tensionWireReserve: 1.05,
    slatWidth: 0.1,
    slatGap: 0.03,
    slatReserve: 1.05,
    antisepticLPerM2: 0.15,
    antisepticCanL: 5,
    gateWidth: 4,
    wicketWidth: 1,
  ),
  warningRules: FenceWarningRules(reinforcedPostGateThreshold: 0),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _fenceTypeLabels = {
  0: 'Профнастил',
  1: 'Сетка-рабица',
  2: 'Деревянный штакетник',
};

/* ─── helpers ─── */

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

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FenceCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FenceCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FenceCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalFence(
  Map<String, double> inputs, {
  FenceCanonicalSpec spec = fenceCanonicalSpecV1,
}) {
  final normalized = hasCanonicalFenceInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFenceInputs(inputs);

  final fenceLength = math.max(5.0, math.min(500.0, (normalized['fenceLength'] ?? _defaultFor(spec, 'fenceLength', 50)).toDouble()));
  final fenceHeight = math.max(1.0, math.min(3.0, (normalized['fenceHeight'] ?? _defaultFor(spec, 'fenceHeight', 2)).toDouble()));
  final fenceType = (normalized['fenceType'] ?? _defaultFor(spec, 'fenceType', 0)).round().clamp(0, 2);
  final postStep = math.max(2.0, math.min(3.0, (normalized['postStep'] ?? _defaultFor(spec, 'postStep', 2.5)).toDouble()));
  final gatesCount = (normalized['gatesCount'] ?? _defaultFor(spec, 'gatesCount', 1)).round().clamp(0, 5);
  final wicketsCount = (normalized['wicketsCount'] ?? _defaultFor(spec, 'wicketsCount', 1)).round().clamp(0, 5);

  // Common geometry
  final netLength = math.max(1.0, fenceLength - gatesCount * spec.materialRules.gateWidth - wicketsCount * spec.materialRules.wicketWidth);
  final postsCount = (netLength / postStep).ceil() + 1 + gatesCount * 2 + wicketsCount * 2;
  final lagsPerSpan = fenceHeight > 2 ? 3 : 2;
  final lagSpans = (netLength / postStep).ceil();
  final lagsCount = lagSpans * lagsPerSpan;
  final postLength = _roundValue(fenceHeight + spec.materialRules.postBurialM, 2);

  // Concrete for posts
  final concrete = _roundValue(postsCount * spec.materialRules.postConcreteM3, 3);

  // Caps for posts
  final caps = (postsCount * spec.materialRules.capsReserve).ceil();

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
    sheets = (netLength / spec.materialRules.profnastilUsefulWidth * spec.materialRules.profnastilReserve).ceil();
    screws = (sheets * spec.materialRules.profnastilScrewsPerSheet).ceil();
    screwPacks = (screws / spec.materialRules.screwsPack).ceil();
    primerCans = (fenceLength / spec.materialRules.primerSprayMPerCan).ceil();
  } else if (fenceType == 1) {
    // Rabica
    rolls = (netLength / spec.materialRules.rabicaRollM).ceil();
    wireLength = _roundValue(netLength * lagsPerSpan * spec.materialRules.tensionWireReserve, 2);
  } else {
    // Wooden slats
    slats = (netLength / (spec.materialRules.slatWidth + spec.materialRules.slatGap) * spec.materialRules.slatReserve).ceil();
    antisepticCans = (netLength * fenceHeight * 2 * spec.materialRules.antisepticLPerM2 / spec.materialRules.antisepticCanL).ceil();
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
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'fenceType:$fenceType',
        'postStep:${postStep.toStringAsFixed(1)}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
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
  if (gatesCount > spec.warningRules.reinforcedPostGateThreshold) {
    warnings.add('При наличии ворот рекомендуются усиленные столбы 80×80 или 100×100 мм');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Столбы 60×60 мм ($postLength м)',
      quantity: postsCount.toDouble(),
      unit: 'шт',
      withReserve: postsCount.toDouble(),
      purchaseQty: postsCount,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Лаги 40×20 мм',
      quantity: lagsCount.toDouble(),
      unit: 'шт',
      withReserve: lagsCount.toDouble(),
      purchaseQty: lagsCount,
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
        purchaseQty: recScenario.exactNeed.ceil(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы кровельные (упаковка ${spec.materialRules.screwsPack} шт)',
        quantity: screws.toDouble(),
        unit: 'шт',
        withReserve: (screwPacks * spec.materialRules.screwsPack).toDouble(),
        purchaseQty: screwPacks,
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Грунт-спрей для срезов',
        quantity: primerCans.toDouble(),
        unit: 'баллонов',
        withReserve: primerCans.toDouble(),
        purchaseQty: primerCans,
        category: 'Защита',
      ),
    ]);
  } else if (fenceType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_fenceTypeLabels[1]} ($fenceHeight м, рулон ${spec.materialRules.rabicaRollM.round()} м)',
        quantity: recScenario.exactNeed,
        unit: 'рулонов',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Проволока натяжная',
        quantity: wireLength,
        unit: 'м',
        withReserve: wireLength,
        purchaseQty: wireLength.ceil(),
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
        purchaseQty: recScenario.exactNeed.ceil(),
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Антисептик (${spec.materialRules.antisepticCanL.round()} л)',
        quantity: antisepticCans.toDouble(),
        unit: 'канистр',
        withReserve: antisepticCans.toDouble(),
        purchaseQty: antisepticCans,
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
      purchaseQty: (concrete * 10).ceil(),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Заглушки для столбов',
      quantity: caps.toDouble(),
      unit: 'шт',
      withReserve: caps.toDouble(),
      purchaseQty: caps,
      category: 'Каркас',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'fenceLength': _roundValue(fenceLength, 3),
      'fenceHeight': _roundValue(fenceHeight, 3),
      'fenceType': fenceType.toDouble(),
      'postStep': _roundValue(postStep, 2),
      'gatesCount': gatesCount.toDouble(),
      'wicketsCount': wicketsCount.toDouble(),
      'netLength': _roundValue(netLength, 3),
      'postsCount': postsCount.toDouble(),
      'lagsPerSpan': lagsPerSpan.toDouble(),
      'lagSpans': lagSpans.toDouble(),
      'lagsCount': lagsCount.toDouble(),
      'postLength': postLength,
      'concrete': concrete,
      'caps': caps.toDouble(),
      'sheets': sheets.toDouble(),
      'screws': screws.toDouble(),
      'screwPacks': screwPacks.toDouble(),
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
