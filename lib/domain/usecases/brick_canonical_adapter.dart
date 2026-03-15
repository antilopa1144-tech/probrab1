import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class BrickPackagingRules {
  final String unit;
  final double packageSize;

  const BrickPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class BrickMaterialRules {
  final double mortarLossFactor;
  final double cementKgPerM3;
  final double cementBagKg;
  final double sandM3PerM3Mortar;
  final double meshJointMm;
  final double meshOverlapFactor;
  final double plasticizerLPerM3;
  final double flexibleTiesPerM2;
  final int flexibleTiesWallThicknessThreshold;

  const BrickMaterialRules({
    required this.mortarLossFactor,
    required this.cementKgPerM3,
    required this.cementBagKg,
    required this.sandM3PerM3Mortar,
    required this.meshJointMm,
    required this.meshOverlapFactor,
    required this.plasticizerLPerM3,
    required this.flexibleTiesPerM2,
    required this.flexibleTiesWallThicknessThreshold,
  });
}

class BrickWarningRules {
  final int nonLoadBearingWallThickness;
  final int manualMixGradeThreshold;

  const BrickWarningRules({
    required this.nonLoadBearingWallThickness,
    required this.manualMixGradeThreshold,
  });
}

class BrickCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final Map<int, Map<int, int>> bricksPerSqm;
  final Map<int, Map<int, double>> mortarPerSqm;
  final Map<int, int> wallThicknessMm;
  final Map<int, int> brickHeightMm;
  final Map<int, double> conditionsMultiplier;
  final Map<int, double> wasteCoeffs;
  final BrickPackagingRules packagingRules;
  final BrickMaterialRules materialRules;
  final BrickWarningRules warningRules;

  const BrickCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.bricksPerSqm,
    required this.mortarPerSqm,
    required this.wallThicknessMm,
    required this.brickHeightMm,
    required this.conditionsMultiplier,
    required this.wasteCoeffs,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const BrickCanonicalSpec brickCanonicalSpecV1 = BrickCanonicalSpec(
  calculatorId: 'brick',
  formulaVersion: 'brick-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'wallWidth', unit: 'm', defaultValue: 5, min: 0.5, max: 50),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 3, min: 0.5, max: 10),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 15, min: 1, max: 500),
    CanonicalInputField(key: 'brickType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'wallThickness', defaultValue: 1, min: 0, max: 3),
    CanonicalInputField(key: 'workingConditions', defaultValue: 1, min: 1, max: 4),
    CanonicalInputField(key: 'wasteMode', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  bricksPerSqm: {
    0: {0: 51, 1: 102, 2: 153, 3: 204},
    1: {0: 39, 1: 78, 2: 117, 3: 156},
    2: {0: 26, 1: 52, 2: 78, 3: 104},
  },
  mortarPerSqm: {
    0: {0: 0.019, 1: 0.023, 2: 0.034, 3: 0.045},
    1: {0: 0.016, 1: 0.020, 2: 0.029, 3: 0.038},
    2: {0: 0.013, 1: 0.017, 2: 0.024, 3: 0.031},
  },
  wallThicknessMm: {0: 120, 1: 250, 2: 380, 3: 510},
  brickHeightMm: {0: 65, 1: 88, 2: 138},
  conditionsMultiplier: {1: 1.0, 2: 1.05, 3: 1.10, 4: 1.08},
  wasteCoeffs: {0: 1.05, 1: 1.10, 2: 1.03},
  packagingRules: BrickPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: BrickMaterialRules(
    mortarLossFactor: 1.12,
    cementKgPerM3: 400,
    cementBagKg: 50,
    sandM3PerM3Mortar: 1.2,
    meshJointMm: 10,
    meshOverlapFactor: 1.1,
    plasticizerLPerM3: 0.5,
    flexibleTiesPerM2: 4,
    flexibleTiesWallThicknessThreshold: 2,
  ),
  warningRules: BrickWarningRules(
    nonLoadBearingWallThickness: 0,
    manualMixGradeThreshold: 5,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _brickTypeLabels = {
  0: 'Кирпич одинарный (65 мм)',
  1: 'Кирпич полуторный (88 мм)',
  2: 'Кирпич двойной (138 мм)',
};

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(BrickCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveArea(BrickCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final wallWidth = math.max(0.5, inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 5)).toDouble();
    final wallHeight = math.max(0.5, inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 3)).toDouble();
    return {
      'inputMode': 0.0,
      'area': _roundValue(wallWidth * wallHeight, 3),
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
    };
  }
  final area = math.max(1, inputs['area'] ?? _defaultFor(spec, 'area', 15)).toDouble();
  final wallWidth = (inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 5)).toDouble();
  final wallHeight = (inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 3)).toDouble();
  return {
    'inputMode': 1.0,
    'area': _roundValue(area, 3),
    'wallWidth': wallWidth,
    'wallHeight': wallHeight,
  };
}

Map<String, double> _keyFactors(BrickCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(BrickCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalBrick(
  Map<String, double> inputs, {
  BrickCanonicalSpec spec = brickCanonicalSpecV1,
}) {
  final areaInfo = _resolveArea(spec, inputs);
  final area = areaInfo['area']!;
  final wallWidth = areaInfo['wallWidth']!;
  final wallHeight = areaInfo['wallHeight']!;

  final brickType = (inputs['brickType'] ?? _defaultFor(spec, 'brickType', 0)).round().clamp(0, 2);
  final wallThickness = (inputs['wallThickness'] ?? _defaultFor(spec, 'wallThickness', 1)).round().clamp(0, 3);
  final workingConditions = (inputs['workingConditions'] ?? _defaultFor(spec, 'workingConditions', 1)).round().clamp(1, 4);
  final wasteMode = (inputs['wasteMode'] ?? _defaultFor(spec, 'wasteMode', 0)).round().clamp(0, 2);

  final bricksPerSqm = (spec.bricksPerSqm[brickType]?[wallThickness] ?? 102).toDouble();
  final mortarPerSqm = spec.mortarPerSqm[brickType]?[wallThickness] ?? 0.023;
  final brickHeightMm = (spec.brickHeightMm[brickType] ?? 65).toDouble();
  final conditionsMultiplier = spec.conditionsMultiplier[workingConditions] ?? 1.0;
  final wasteCoeff = spec.wasteCoeffs[wasteMode] ?? 1.05;

  final baseBricksNeeded = area * bricksPerSqm * wasteCoeff;

  final mortarVolume = _roundValue(area * mortarPerSqm * spec.materialRules.mortarLossFactor * conditionsMultiplier, 6);
  final cementKg = _roundValue(mortarVolume * spec.materialRules.cementKgPerM3, 3);
  final cementBags = cementKg > 0 ? (cementKg / spec.materialRules.cementBagKg).ceil() : 0;
  final sandM3 = _roundValue(mortarVolume * spec.materialRules.sandM3PerM3Mortar, 3);

  final totalRows = (wallHeight * 1000 / (brickHeightMm + spec.materialRules.meshJointMm)).ceil();
  final meshInterval = wallThickness == 0 ? 3 : 5;
  final meshLayers = (totalRows / meshInterval).ceil();
  final meshArea = _roundValue((meshLayers * wallWidth * spec.materialRules.meshOverlapFactor * 10).ceil() / 10, 3);

  final plasticizerL = _roundValue((mortarVolume * spec.materialRules.plasticizerLPerM3 * 10).ceil() / 10, 3);

  final flexibleTies = wallThickness >= spec.materialRules.flexibleTiesWallThicknessThreshold
      ? (area * spec.materialRules.flexibleTiesPerM2).ceil()
      : 0;

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseBricksNeeded * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'brick-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'brickType:$brickType',
        'wallThickness:$wallThickness',
        'wasteMode:$wasteMode',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (wallThickness == spec.warningRules.nonLoadBearingWallThickness) {
    warnings.add('Толщина стены в 0.5 кирпича (120 мм) — только для ненесущих перегородок');
  }
  if (cementBags >= spec.warningRules.manualMixGradeThreshold) {
    warnings.add('Большой объём раствора — ручное замешивание будет затруднено, рекомендуется бетономешалка');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickTypeLabels[brickType] ?? 'Кирпич',
      quantity: _roundValue(recScenario.exactNeed, 6),
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceil().toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Цемент М400 (${spec.materialRules.cementBagKg.toInt()} кг)',
      quantity: cementBags.toDouble(),
      unit: 'мешков',
      withReserve: cementBags.toDouble(),
      purchaseQty: cementBags,
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Песок строительный',
      quantity: _roundValue(sandM3, 3),
      unit: 'м³',
      withReserve: _roundValue((sandM3 * 10).ceil() / 10, 3),
      purchaseQty: sandM3.ceil(),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Кладочная сетка',
      quantity: _roundValue(meshArea, 3),
      unit: 'м²',
      withReserve: meshArea.ceil().toDouble(),
      purchaseQty: meshArea.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Пластификатор',
      quantity: _roundValue(plasticizerL, 3),
      unit: 'л',
      withReserve: _roundValue(plasticizerL, 1),
      purchaseQty: plasticizerL.ceil(),
      category: 'Раствор',
    ),
  ];

  if (wallThickness >= spec.materialRules.flexibleTiesWallThicknessThreshold) {
    materials.add(CanonicalMaterialResult(
      name: 'Гибкие связи',
      quantity: flexibleTies.toDouble(),
      unit: 'шт',
      withReserve: flexibleTies.toDouble(),
      purchaseQty: flexibleTies,
      category: 'Крепёж',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': areaInfo['inputMode']!,
      'wallWidth': _roundValue(wallWidth, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'brickType': brickType.toDouble(),
      'wallThickness': wallThickness.toDouble(),
      'wallThicknessMm': (spec.wallThicknessMm[wallThickness] ?? 250).toDouble(),
      'workingConditions': workingConditions.toDouble(),
      'wasteMode': wasteMode.toDouble(),
      'wasteCoeff': wasteCoeff,
      'bricksPerSqm': bricksPerSqm,
      'mortarPerSqm': mortarPerSqm,
      'conditionsMultiplier': conditionsMultiplier,
      'bricksNeeded': _roundValue(recScenario.exactNeed, 3),
      'mortarVolume': mortarVolume,
      'cementKg': cementKg,
      'cementBags': cementBags.toDouble(),
      'sandM3': sandM3,
      'totalRows': totalRows.toDouble(),
      'meshInterval': meshInterval.toDouble(),
      'meshLayers': meshLayers.toDouble(),
      'meshArea': meshArea,
      'plasticizerL': plasticizerL,
      'flexibleTies': flexibleTies.toDouble(),
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
