import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec instance ─── */

const DrywallCeilingCanonicalSpec drywallCeilingCanonicalSpecV1 = DrywallCeilingCanonicalSpec(
  calculatorId: 'drywall-ceiling',
  formulaVersion: 'drywall-ceiling-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 20),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 200),
    CanonicalInputField(key: 'layers', defaultValue: 1, min: 1, max: 2),
    CanonicalInputField(key: 'profileStep', unit: 'mm', defaultValue: 600, min: 400, max: 600),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: DrywallCeilingPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: DrywallCeilingMaterialRules(
    sheetArea: 3.0,
    sheetReserve: 1.10,
    profileReserve: 1.05,
    crossStep: 1.2,
    suspensionStep: 0.7,
    screwsPerSheet: 23,
    screwsPerKg: 1000,
    screwReserve: 1.05,
    clopPerSusp: 2,
    clopPerCrab: 4,
    dowelStep: 0.5,
    serpyankaCoeff: 1.2,
    serpyankaReserve: 1.1,
    serpyankaRoll: 45,
    puttyKgPerM: 0.25,
    puttyBag: 25,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCan: 10,
    profileLength: 3,
  ),
  warningRules: DrywallCeilingWarningRules(deformationJointAreaThresholdM2: 50),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(DrywallCeilingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(DrywallCeilingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(DrywallCeilingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalDrywallCeiling(
  Map<String, double> inputs, {
  DrywallCeilingCanonicalSpec spec = drywallCeilingCanonicalSpecV1,
}) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final length = (inputs['length'] ?? _defaultFor(spec, 'length', 5)).clamp(1.0, 20.0);
  final width = (inputs['width'] ?? _defaultFor(spec, 'width', 4)).clamp(1.0, 20.0);
  final areaInput = (inputs['area'] ?? _defaultFor(spec, 'area', 20)).clamp(1.0, 200.0);
  final layersRaw = (inputs['layers'] ?? _defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final profileStepRaw = inputs['profileStep'] ?? _defaultFor(spec, 'profileStep', 600);
  final profileStep = profileStepRaw <= 400 ? 400.0 : 600.0;

  // Area
  final area = inputMode == 0 ? _roundValue(length * width, 3) : areaInput;

  // Sheets
  final sheets = (area * layers / spec.materialRules.sheetArea * spec.materialRules.sheetReserve).ceil();

  // Profiles
  final mainProfileRows = (width / (profileStep / 1000)).ceil();
  final mainM = mainProfileRows * length;
  final crossRows = (length / spec.materialRules.crossStep).ceil();
  final crossM = crossRows * width;
  final totalProfileM = (mainM + crossM) * spec.materialRules.profileReserve;
  final ppPcs = (totalProfileM / spec.materialRules.profileLength).ceil();

  final effectiveLength = inputMode == 0 ? length : math.sqrt(area);
  final effectiveWidth = inputMode == 0 ? width : math.sqrt(area);
  final pnM = 2 * (effectiveLength + effectiveWidth) * spec.materialRules.profileReserve;
  final pnPcs = (pnM / spec.materialRules.profileLength).ceil();

  // Suspensions & crabs
  final suspCount = mainProfileRows * (length / spec.materialRules.suspensionStep).ceil();
  final crabCount = mainProfileRows * crossRows;

  // Screws
  final screwsGKL = sheets * spec.materialRules.screwsPerSheet;
  final screwsKg = (screwsGKL * spec.materialRules.screwReserve / spec.materialRules.screwsPerKg * 10).ceil() / 10;

  // Clop screws
  final clopCount = suspCount * spec.materialRules.clopPerSusp + crabCount * spec.materialRules.clopPerCrab;

  // Dowels
  final dowelCount = suspCount * 2 + (pnM / spec.materialRules.dowelStep).ceil();

  // Serpyanka
  final serpM = (area * spec.materialRules.serpyankaCoeff * spec.materialRules.serpyankaReserve).ceil();
  final serpRolls = (serpM / spec.materialRules.serpyankaRoll).ceil();

  // Putty
  final puttyKg = (serpM * spec.materialRules.puttyKgPerM).ceil();
  final puttyBags = (puttyKg / spec.materialRules.puttyBag).ceil();

  // Primer
  final primerL = area * spec.materialRules.primerLPerM2;
  final primerCans = (primerL * spec.materialRules.primerReserve / spec.materialRules.primerCan).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(sheets * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'layers:$layers',
        'profileStep:$profileStep',
        'packaging:gkl-ceiling-${spec.packagingRules.packageSize}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'gkl-ceiling-${spec.packagingRules.packageSize}',
        packageSize: spec.packagingRules.packageSize.toDouble(),
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (layers == 2) {
    warnings.add('Второй слой ГКЛ монтируется со смещением 400 мм');
  }
  if (area > spec.warningRules.deformationJointAreaThresholdM2) {
    warnings.add('Площадь более 50 м\u00b2 — предусмотрите деформационные швы');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ГКЛ листы',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПП 60\u00d727 3м',
      quantity: ppPcs.toDouble(),
      unit: 'шт',
      withReserve: ppPcs.toDouble(),
      purchaseQty: ppPcs,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПН 27\u00d728 3м',
      quantity: pnPcs.toDouble(),
      unit: 'шт',
      withReserve: pnPcs.toDouble(),
      purchaseQty: pnPcs,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Подвесы прямые',
      quantity: suspCount.toDouble(),
      unit: 'шт',
      withReserve: suspCount.toDouble(),
      purchaseQty: suspCount,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Крабы (соединители)',
      quantity: crabCount.toDouble(),
      unit: 'шт',
      withReserve: crabCount.toDouble(),
      purchaseQty: crabCount,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы 3.5\u00d725 (кг)',
      quantity: screwsKg,
      unit: 'кг',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы-клопы',
      quantity: clopCount.toDouble(),
      unit: 'шт',
      withReserve: clopCount.toDouble(),
      purchaseQty: clopCount,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбели',
      quantity: dowelCount.toDouble(),
      unit: 'шт',
      withReserve: dowelCount.toDouble(),
      purchaseQty: dowelCount,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Серпянка 45м',
      quantity: serpRolls.toDouble(),
      unit: 'рулонов',
      withReserve: serpRolls.toDouble(),
      purchaseQty: serpRolls,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка Knauf Fugen 25кг',
      quantity: puttyBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyBags.toDouble(),
      purchaseQty: puttyBags,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка 10л',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Отделка',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'length': inputMode == 0 ? _roundValue(length, 3) : 0.0,
      'width': inputMode == 0 ? _roundValue(width, 3) : 0.0,
      'layers': layers.toDouble(),
      'profileStep': profileStep,
      'sheets': sheets.toDouble(),
      'mainProfileRows': mainProfileRows.toDouble(),
      'mainM': _roundValue(mainM, 3),
      'crossRows': crossRows.toDouble(),
      'crossM': _roundValue(crossM, 3),
      'totalProfileM': _roundValue(totalProfileM, 3),
      'ppPcs': ppPcs.toDouble(),
      'pnM': _roundValue(pnM, 3),
      'pnPcs': pnPcs.toDouble(),
      'suspCount': suspCount.toDouble(),
      'crabCount': crabCount.toDouble(),
      'screwsGKL': screwsGKL.toDouble(),
      'screwsKg': screwsKg,
      'clopCount': clopCount.toDouble(),
      'dowelCount': dowelCount.toDouble(),
      'serpM': serpM.toDouble(),
      'serpRolls': serpRolls.toDouble(),
      'puttyKg': puttyKg.toDouble(),
      'puttyBags': puttyBags.toDouble(),
      'primerL': _roundValue(primerL, 3),
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
