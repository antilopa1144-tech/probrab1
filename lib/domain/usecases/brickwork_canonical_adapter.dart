import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class BrickworkPackagingRules {
  final String unit;
  final int packageSize;

  const BrickworkPackagingRules({required this.unit, required this.packageSize});
}

class BrickworkMaterialRules {
  final Map<int, Map<int, int>> bricksPerSqm;
  final Map<int, double> mortarPerM3;
  final Map<int, int> wallThicknessMm;
  final Map<int, int> brickHeights;
  final Map<int, int> bricksPerPallet;
  final double blockReserve;
  final double mortarDensity;
  final double mortarBagKg;

  const BrickworkMaterialRules({
    required this.bricksPerSqm,
    required this.mortarPerM3,
    required this.wallThicknessMm,
    required this.brickHeights,
    required this.bricksPerPallet,
    required this.blockReserve,
    required this.mortarDensity,
    required this.mortarBagKg,
  });
}

class BrickworkWarningRules {
  final int nonLoadBearingWallThickness;
  final double armorBeltHeightThreshold;
  final int armorBeltWallThicknessThreshold;

  const BrickworkWarningRules({
    required this.nonLoadBearingWallThickness,
    required this.armorBeltHeightThreshold,
    required this.armorBeltWallThicknessThreshold,
  });
}

class BrickworkCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final BrickworkPackagingRules packagingRules;
  final BrickworkMaterialRules materialRules;
  final BrickworkWarningRules warningRules;

  const BrickworkCanonicalSpec({
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

const BrickworkCanonicalSpec brickworkCanonicalSpecV1 = BrickworkCanonicalSpec(
  calculatorId: 'brickwork',
  formulaVersion: 'brickwork-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'wallLength', unit: 'm', defaultValue: 10, min: 1, max: 100),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 1, max: 5),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 27, min: 1, max: 500),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 5, min: 0, max: 50),
    CanonicalInputField(key: 'brickFormat', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'wallThickness', defaultValue: 1, min: 0, max: 3),
    CanonicalInputField(key: 'mortarJoint', unit: 'mm', defaultValue: 10, min: 8, max: 15),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: BrickworkPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: BrickworkMaterialRules(
    bricksPerSqm: {
      0: {0: 51, 1: 102, 2: 153, 3: 204},
      1: {0: 39, 1: 78, 2: 117, 3: 156},
      2: {0: 26, 1: 52, 2: 78, 3: 104},
    },
    mortarPerM3: {0: 0.221, 1: 0.195, 2: 0.166},
    wallThicknessMm: {0: 120, 1: 250, 2: 380, 3: 510},
    brickHeights: {0: 65, 1: 88, 2: 138},
    bricksPerPallet: {0: 480, 1: 352, 2: 176},
    blockReserve: 1.05,
    mortarDensity: 1700,
    mortarBagKg: 50,
  ),
  warningRules: BrickworkWarningRules(
    nonLoadBearingWallThickness: 0,
    armorBeltHeightThreshold: 3,
    armorBeltWallThicknessThreshold: 2,
  ),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _brickFormatLabels = {
  0: 'Кирпич одинарный (65 мм)',
  1: 'Кирпич полуторный (88 мм)',
  2: 'Кирпич двойной (138 мм)',
};

/* ─── helpers ─── */

bool hasCanonicalBrickworkInputs(Map<String, double> inputs) {
  return inputs.containsKey('brickFormat') ||
      inputs.containsKey('mortarJoint') ||
      inputs.containsKey('openingsArea');
}

Map<String, double> normalizeLegacyBrickworkInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final hasDimensions = (inputs['wallLength'] ?? 0) > 0 && (inputs['wallHeight'] ?? 0) > 0;
  if (!normalized.containsKey('inputMode')) {
    normalized['inputMode'] = hasDimensions ? 0.0 : 1.0;
  }
  normalized['brickFormat'] = (inputs['brickFormat'] ?? inputs['brickType'] ?? 0).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 1).toDouble();
  normalized['mortarJoint'] = (inputs['mortarJoint'] ?? 10).toDouble();
  normalized['openingsArea'] = (inputs['openingsArea'] ?? 5).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(BrickworkCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(BrickworkCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(BrickworkCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalBrickwork(
  Map<String, double> inputs, {
  BrickworkCanonicalSpec spec = brickworkCanonicalSpecV1,
}) {
  final normalized = hasCanonicalBrickworkInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBrickworkInputs(inputs);

  final inputMode = (normalized['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  double wallLength;
  double wallHeight;
  double wallArea;

  if (inputMode == 0) {
    wallLength = math.max(1, math.min(100, (normalized['wallLength'] ?? _defaultFor(spec, 'wallLength', 10)).toDouble()));
    wallHeight = math.max(1, math.min(5, (normalized['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble()));
    wallArea = _roundValue(wallLength * wallHeight, 3);
  } else {
    wallArea = math.max(1, math.min(500, (normalized['area'] ?? _defaultFor(spec, 'area', 27)).toDouble()));
    wallLength = (normalized['wallLength'] ?? _defaultFor(spec, 'wallLength', 10)).toDouble();
    wallHeight = (normalized['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble();
  }

  final openingsArea = math.max(0.0, math.min(50.0, (normalized['openingsArea'] ?? _defaultFor(spec, 'openingsArea', 5)).toDouble()));
  final brickFormat = (normalized['brickFormat'] ?? _defaultFor(spec, 'brickFormat', 0)).round().clamp(0, 2);
  final wallThicknessIdx = (normalized['wallThickness'] ?? _defaultFor(spec, 'wallThickness', 1)).round().clamp(0, 3);
  final mortarJoint = math.max(8.0, math.min(15.0, (normalized['mortarJoint'] ?? _defaultFor(spec, 'mortarJoint', 10)).toDouble()));

  // Area
  final netArea = math.max(0.0, wallArea - openingsArea);

  // Bricks
  final baseBricks = (spec.materialRules.bricksPerSqm[brickFormat]?[wallThicknessIdx] ?? 102).toDouble();
  final jointCoeff = mortarJoint == 10 ? 1.0 : (10 / mortarJoint) * 0.97 + 0.03;
  final bricksPerSqm = baseBricks * jointCoeff;
  final totalBricks = netArea * bricksPerSqm;
  final bricksWithReserve = (totalBricks * spec.materialRules.blockReserve).ceil();

  // Mortar
  final wallThicknessMm = (spec.materialRules.wallThicknessMm[wallThicknessIdx] ?? 250).toDouble();
  final wallVolume = _roundValue(netArea * (wallThicknessMm / 1000), 6);
  final mortarCoeff = spec.materialRules.mortarPerM3[brickFormat] ?? 0.221;
  final mortarM3 = _roundValue(wallVolume * mortarCoeff, 6);
  final mortarKg = _roundValue(mortarM3 * spec.materialRules.mortarDensity, 3);
  final mortarBags = (mortarKg / spec.materialRules.mortarBagKg).ceil();

  // Mesh
  final brickH = (spec.materialRules.brickHeights[brickFormat] ?? 65).toDouble();
  final rowHeight = (brickH + mortarJoint) / 1000;
  final totalRows = (wallHeight / rowHeight).ceil();
  final meshRows = (totalRows / 5).floor();
  final meshArea = _roundValue(wallLength * (wallThicknessMm / 1000) * meshRows, 3);

  // Lintels
  final openingsCount = (openingsArea / 2).ceil();
  final lintelsPerOpening = wallThicknessIdx >= 1 ? 2 : 1;
  final totalLintels = openingsCount * lintelsPerOpening;

  // Pallets
  final bricksPerPallet = spec.materialRules.bricksPerPallet[brickFormat] ?? 480;
  final pallets = (bricksWithReserve / bricksPerPallet).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(bricksWithReserve * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'brickFormat:$brickFormat',
        'wallThickness:$wallThicknessIdx',
        'mortarJoint:${mortarJoint.round()}',
        'packaging:brickwork-piece',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'brickwork-piece',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (wallThicknessIdx == spec.warningRules.nonLoadBearingWallThickness) {
    warnings.add('Толщина стены в 0.5 кирпича (120 мм) — только для ненесущих перегородок');
  }
  if (wallThicknessIdx >= spec.warningRules.armorBeltWallThicknessThreshold &&
      wallHeight > spec.warningRules.armorBeltHeightThreshold) {
    warnings.add('При толщине стены 1.5+ кирпича и высоте более 3 м необходим армопояс');
  }
  if (brickFormat == 2 && wallThicknessIdx == 0) {
    warnings.add('Двойной кирпич в полкирпича (120 мм) — нестандартное решение, проверьте проект');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickFormatLabels[brickFormat] ?? 'Кирпич',
      quantity: _roundValue(totalBricks, 3),
      unit: 'шт',
      withReserve: bricksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Поддоны кирпича',
      quantity: pallets.toDouble(),
      unit: 'шт',
      withReserve: pallets.toDouble(),
      purchaseQty: pallets,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Раствор кладочный (${spec.materialRules.mortarBagKg.round()} кг)',
      quantity: mortarBags.toDouble(),
      unit: 'мешков',
      withReserve: mortarBags.toDouble(),
      purchaseQty: mortarBags,
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Кладочная сетка',
      quantity: meshArea,
      unit: 'м²',
      withReserve: meshArea.ceilToDouble(),
      purchaseQty: meshArea.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Перемычки (ЖБ)',
      quantity: totalLintels.toDouble(),
      unit: 'шт',
      withReserve: totalLintels.toDouble(),
      purchaseQty: totalLintels,
      category: 'Проёмы',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': inputMode.toDouble(),
      'wallLength': _roundValue(wallLength, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'wallArea': _roundValue(wallArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'netArea': _roundValue(netArea, 3),
      'brickFormat': brickFormat.toDouble(),
      'wallThicknessIdx': wallThicknessIdx.toDouble(),
      'wallThicknessMm': wallThicknessMm,
      'mortarJoint': mortarJoint,
      'baseBricks': baseBricks,
      'jointCoeff': _roundValue(jointCoeff, 6),
      'bricksPerSqm': _roundValue(bricksPerSqm, 3),
      'totalBricks': _roundValue(totalBricks, 3),
      'bricksWithReserve': bricksWithReserve.toDouble(),
      'wallVolume': wallVolume,
      'mortarCoeff': mortarCoeff,
      'mortarM3': mortarM3,
      'mortarKg': mortarKg,
      'mortarBags': mortarBags.toDouble(),
      'brickH': brickH,
      'rowHeight': _roundValue(rowHeight, 4),
      'totalRows': totalRows.toDouble(),
      'meshRows': meshRows.toDouble(),
      'meshArea': meshArea,
      'openingsCount': openingsCount.toDouble(),
      'lintelsPerOpening': lintelsPerOpening.toDouble(),
      'totalLintels': totalLintels.toDouble(),
      'pallets': pallets.toDouble(),
      'minExactNeedBricks': scenarios['MIN']!.exactNeed,
      'recExactNeedBricks': recScenario.exactNeed,
      'maxExactNeedBricks': scenarios['MAX']!.exactNeed,
      'minPurchaseBricks': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseBricks': recScenario.purchaseQuantity,
      'maxPurchaseBricks': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
