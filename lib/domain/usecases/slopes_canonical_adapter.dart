import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class SlopesPackagingRules {
  final String unit;
  final int packageSize;

  const SlopesPackagingRules({required this.unit, required this.packageSize});
}

class SlopesMaterialRules {
  final double panelM2;
  final double gklM2;
  final double plasterKgPerM2;
  final double puttyKgPerM2;
  final double primerLPerM2;
  final double cornerProfileM;
  final double fProfileM;
  final double panelReserve;
  final double plasterReserve;
  final double puttyReserve;
  final double gklReserve;
  final double primerReserve;

  const SlopesMaterialRules({
    required this.panelM2,
    required this.gklM2,
    required this.plasterKgPerM2,
    required this.puttyKgPerM2,
    required this.primerLPerM2,
    required this.cornerProfileM,
    required this.fProfileM,
    required this.panelReserve,
    required this.plasterReserve,
    required this.puttyReserve,
    required this.gklReserve,
    required this.primerReserve,
  });
}

class SlopesWarningRules {
  final int wideSlopeThresholdMm;
  final int bulkOpeningThreshold;

  const SlopesWarningRules({required this.wideSlopeThresholdMm, required this.bulkOpeningThreshold});
}

class SlopesCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final Map<int, List<int>> openingDims;
  final SlopesPackagingRules packagingRules;
  final SlopesMaterialRules materialRules;
  final SlopesWarningRules warningRules;

  const SlopesCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.openingDims,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── spec instance ─── */

const SlopesCanonicalSpec slopesCanonicalSpecV1 = SlopesCanonicalSpec(
  calculatorId: 'slopes',
  formulaVersion: 'slopes-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'openingCount', defaultValue: 5, min: 1, max: 30),
    CanonicalInputField(key: 'openingType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'slopeWidth', unit: 'mm', defaultValue: 350, min: 150, max: 500),
    CanonicalInputField(key: 'finishType', defaultValue: 0, min: 0, max: 3),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  openingDims: {0: [1200, 1400, 3], 1: [900, 1200, 3], 2: [800, 2000, 2], 3: [900, 2000, 3]},
  packagingRules: SlopesPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: SlopesMaterialRules(
    panelM2: 3.6,
    gklM2: 3.0,
    plasterKgPerM2: 12,
    puttyKgPerM2: 1.2,
    primerLPerM2: 0.15,
    cornerProfileM: 3,
    fProfileM: 3,
    panelReserve: 1.12,
    plasterReserve: 1.1,
    puttyReserve: 1.1,
    gklReserve: 1.12,
    primerReserve: 1.15,
  ),
  warningRules: SlopesWarningRules(wideSlopeThresholdMm: 400, bulkOpeningThreshold: 15),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _openingTypeLabels = {
  0: 'Окно 1200\u00d71400 (3 стороны)',
  1: 'Окно 900\u00d71200 (3 стороны)',
  2: 'Дверь 800\u00d72000 (2 стороны)',
  3: 'Балконная дверь 900\u00d72000 (3 стороны)',
};

const Map<int, String> _finishTypeLabels = {
  0: 'Сэндвич-панели ПВХ',
  1: 'ПВХ-панели',
  2: 'Штукатурка',
  3: 'ГКЛ',
};

/* ─── helpers ─── */

bool hasCanonicalSlopesInputs(Map<String, double> inputs) {
  return inputs.containsKey('openingType') ||
      inputs.containsKey('openingCount') ||
      inputs.containsKey('finishType');
}

Map<String, double> normalizeLegacySlopesInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['openingCount'] = (inputs['openingCount'] ?? 5).toDouble();
  normalized['openingType'] = (inputs['openingType'] ?? 0).toDouble();
  normalized['slopeWidth'] = (inputs['slopeWidth'] ?? 350).toDouble();
  normalized['finishType'] = (inputs['finishType'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(SlopesCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(SlopesCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(SlopesCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalSlopes(
  Map<String, double> inputs, {
  SlopesCanonicalSpec spec = slopesCanonicalSpecV1,
}) {
  final normalized = hasCanonicalSlopesInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacySlopesInputs(inputs);

  final openingCount = (normalized['openingCount'] ?? _defaultFor(spec, 'openingCount', 5)).round().clamp(1, 30);
  final openingType = (normalized['openingType'] ?? _defaultFor(spec, 'openingType', 0)).round().clamp(0, 3);
  final slopeWidth = (normalized['slopeWidth'] ?? _defaultFor(spec, 'slopeWidth', 350)).round().clamp(150, 500);
  final finishType = (normalized['finishType'] ?? _defaultFor(spec, 'finishType', 0)).round().clamp(0, 3);

  // Opening geometry
  final dims = spec.openingDims[openingType] ?? [1200, 1400, 3];
  final openW = dims[0];
  final openH = dims[1];
  final sides = dims[2];

  // slopePerim: for 3-sided = top + 2*sides; for 2-sided = 2*sides only
  double slopePerim;
  if (sides == 3) {
    slopePerim = (2 * openH + openW) / 1000;
  } else {
    slopePerim = (2 * openH) / 1000;
  }
  final slopeArea = slopePerim * (slopeWidth / 1000);
  final totalArea = _roundValue(slopeArea * openingCount, 4);
  final totalPerim = _roundValue(slopePerim * openingCount, 4);

  // Finish-type-specific materials
  var panelCount = 0;
  var fProfilePcs = 0;
  var foamCans = 0;
  var plasterBags = 0;
  var puttyBagsPlaster = 0;
  var cornerPcs = 0;
  var gklSheets = 0;
  var screwsGKL = 0;
  var puttyBagsGKL = 0;

  if (finishType == 0 || finishType == 1) {
    // Sandwich PVC / PVC panel
    panelCount = (totalArea * spec.materialRules.panelReserve / spec.materialRules.panelM2).ceil();
    fProfilePcs = (totalPerim * 1.1 / spec.materialRules.fProfileM).ceil();
    foamCans = (totalPerim / 5).ceil();
  } else if (finishType == 2) {
    // Plaster
    plasterBags = (totalArea * spec.materialRules.plasterKgPerM2 * spec.materialRules.plasterReserve / 25).ceil();
    puttyBagsPlaster = (totalArea * spec.materialRules.puttyKgPerM2 * spec.materialRules.puttyReserve / 25).ceil();
    cornerPcs = (totalPerim / spec.materialRules.cornerProfileM).ceil();
  } else {
    // GKL
    gklSheets = (totalArea * spec.materialRules.gklReserve / spec.materialRules.gklM2).ceil();
    screwsGKL = (gklSheets * 20 * 1.05).ceil();
    puttyBagsGKL = (totalArea * spec.materialRules.puttyKgPerM2 * spec.materialRules.puttyReserve / 25).ceil();
  }

  // Common materials
  final sealantTubes = (totalPerim / 5).ceil();
  final primerCans = (totalArea * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / 10).ceil();

  // Scenarios
  int basePrimary;
  String packageLabel;
  String packageUnit;

  if (finishType == 0 || finishType == 1) {
    basePrimary = panelCount;
    packageLabel = 'sandwich-panel';
    packageUnit = 'шт';
  } else if (finishType == 2) {
    basePrimary = plasterBags;
    packageLabel = 'plaster-bag-25kg';
    packageUnit = 'мешков';
  } else {
    basePrimary = gklSheets;
    packageLabel = 'gkl-sheet';
    packageUnit = 'листов';
  }

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
        'openingType:$openingType',
        'finishType:$finishType',
        'slopeWidth:$slopeWidth',
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
  if (slopeWidth >= spec.warningRules.wideSlopeThresholdMm) {
    warnings.add('Широкие откосы — рекомендуется дополнительное утепление');
  }
  if (openingCount > spec.warningRules.bulkOpeningThreshold) {
    warnings.add('Большое количество проёмов — рассмотрите оптовую закупку');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[];

  if (finishType == 0 || finishType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_finishTypeLabels[finishType]}',
        quantity: recScenario.exactNeed,
        unit: 'шт',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'F-профиль (${spec.materialRules.fProfileM.round()} м)',
        quantity: fProfilePcs.toDouble(),
        unit: 'шт',
        withReserve: fProfilePcs.toDouble(),
        purchaseQty: fProfilePcs,
        category: 'Профиль',
      ),
      CanonicalMaterialResult(
        name: 'Монтажная пена',
        quantity: foamCans.toDouble(),
        unit: 'баллонов',
        withReserve: foamCans.toDouble(),
        purchaseQty: foamCans,
        category: 'Монтаж',
      ),
    ]);
  } else if (finishType == 2) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Штукатурка (мешки 25 кг)',
        quantity: recScenario.exactNeed,
        unit: 'мешков',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (мешки 25 кг)',
        quantity: puttyBagsPlaster.toDouble(),
        unit: 'мешков',
        withReserve: puttyBagsPlaster.toDouble(),
        purchaseQty: puttyBagsPlaster,
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Уголок перфорированный',
        quantity: cornerPcs.toDouble(),
        unit: 'шт',
        withReserve: cornerPcs.toDouble(),
        purchaseQty: cornerPcs,
        category: 'Профиль',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ГКЛ для откосов',
        quantity: recScenario.exactNeed,
        unit: 'листов',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы для ГКЛ',
        quantity: screwsGKL.toDouble(),
        unit: 'шт',
        withReserve: screwsGKL.toDouble(),
        purchaseQty: screwsGKL,
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (мешки 25 кг)',
        quantity: puttyBagsGKL.toDouble(),
        unit: 'мешков',
        withReserve: puttyBagsGKL.toDouble(),
        purchaseQty: puttyBagsGKL,
        category: 'Отделка',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealantTubes.toDouble(),
      unit: 'шт',
      withReserve: sealantTubes.toDouble(),
      purchaseQty: sealantTubes,
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра 10 л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Грунтовка',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'openingCount': openingCount.toDouble(),
      'openingType': openingType.toDouble(),
      'slopeWidth': slopeWidth.toDouble(),
      'finishType': finishType.toDouble(),
      'openW': openW.toDouble(),
      'openH': openH.toDouble(),
      'sides': sides.toDouble(),
      'slopePerim': _roundValue(slopePerim, 4),
      'slopeArea': _roundValue(slopeArea, 4),
      'totalArea': totalArea,
      'totalPerim': totalPerim,
      'panelCount': panelCount.toDouble(),
      'fProfilePcs': fProfilePcs.toDouble(),
      'foamCans': foamCans.toDouble(),
      'plasterBags': plasterBags.toDouble(),
      'puttyBagsPlaster': puttyBagsPlaster.toDouble(),
      'cornerPcs': cornerPcs.toDouble(),
      'gklSheets': gklSheets.toDouble(),
      'screwsGKL': screwsGKL.toDouble(),
      'puttyBagsGKL': puttyBagsGKL.toDouble(),
      'sealantTubes': sealantTubes.toDouble(),
      'primerCans': primerCans.toDouble(),
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
