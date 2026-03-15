import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class FacadeBrickDimSpec {
  final int l;
  final int h;

  const FacadeBrickDimSpec({required this.l, required this.h});
}

class FacadeBrickPackagingRules {
  final String unit;
  final int packageSize;

  const FacadeBrickPackagingRules({required this.unit, required this.packageSize});
}

class FacadeBrickMaterialRules {
  final Map<int, FacadeBrickDimSpec> brickDims;
  final double brickReserve;
  final double masonryThickness;
  final double mortarVolumeCoeff;
  final double cementKgPerM3Mortar;
  final double cementBagKg;
  final double sandCoeff;
  final int tiesPerSqm;
  final double tiesReserve;
  final double hydroCoeff;
  final double hydroReserve;
  final double hydroRollM2;
  final double ventBoxStepM;
  final double groutKgPerM2;
  final double groutBagKg;
  final double hydrophobLPerM2;
  final double hydrophobReserve;
  final double hydrophobCanL;

  const FacadeBrickMaterialRules({
    required this.brickDims,
    required this.brickReserve,
    required this.masonryThickness,
    required this.mortarVolumeCoeff,
    required this.cementKgPerM3Mortar,
    required this.cementBagKg,
    required this.sandCoeff,
    required this.tiesPerSqm,
    required this.tiesReserve,
    required this.hydroCoeff,
    required this.hydroReserve,
    required this.hydroRollM2,
    required this.ventBoxStepM,
    required this.groutKgPerM2,
    required this.groutBagKg,
    required this.hydrophobLPerM2,
    required this.hydrophobReserve,
    required this.hydrophobCanL,
  });
}

class FacadeBrickWarningRules {
  final int clinkerMaxJointMm;
  final String ventGapNote;

  const FacadeBrickWarningRules({required this.clinkerMaxJointMm, required this.ventGapNote});
}

class FacadeBrickCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FacadeBrickPackagingRules packagingRules;
  final FacadeBrickMaterialRules materialRules;
  final FacadeBrickWarningRules warningRules;

  const FacadeBrickCanonicalSpec({
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

const FacadeBrickCanonicalSpec facadeBrickCanonicalSpecV1 = FacadeBrickCanonicalSpec(
  calculatorId: 'facade-brick',
  formulaVersion: 'facade-brick-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 80, min: 5, max: 1000),
    CanonicalInputField(key: 'brickType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'jointThickness', unit: 'mm', defaultValue: 10, min: 8, max: 12),
    CanonicalInputField(key: 'withTie', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: FacadeBrickPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: FacadeBrickMaterialRules(
    brickDims: {
      0: FacadeBrickDimSpec(l: 250, h: 65),
      1: FacadeBrickDimSpec(l: 250, h: 88),
      2: FacadeBrickDimSpec(l: 250, h: 138),
      3: FacadeBrickDimSpec(l: 250, h: 65),
    },
    brickReserve: 1.10,
    masonryThickness: 0.12,
    mortarVolumeCoeff: 0.23,
    cementKgPerM3Mortar: 430,
    cementBagKg: 50,
    sandCoeff: 1.4,
    tiesPerSqm: 5,
    tiesReserve: 1.05,
    hydroCoeff: 0.3,
    hydroReserve: 1.15,
    hydroRollM2: 10,
    ventBoxStepM: 2,
    groutKgPerM2: 0.35,
    groutBagKg: 25,
    hydrophobLPerM2: 0.2,
    hydrophobReserve: 1.1,
    hydrophobCanL: 5,
  ),
  warningRules: FacadeBrickWarningRules(
    clinkerMaxJointMm: 10,
    ventGapNote: '20-40mm vent gap required per SP 15.13330',
  ),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _brickTypeLabels = {
  0: 'Кирпич облицовочный одинарный (65 мм)',
  1: 'Кирпич облицовочный полуторный (88 мм)',
  2: 'Кирпич облицовочный двойной (138 мм)',
  3: 'Клинкерный кирпич (65 мм)',
};

const Map<int, String> _tieTypeLabels = {
  1: 'Связи стеклопластиковые',
  2: 'Связи нержавеющие',
};

/* ─── helpers ─── */

bool hasCanonicalFacadeBrickInputs(Map<String, double> inputs) {
  return inputs.containsKey('brickType') ||
      inputs.containsKey('jointThickness') ||
      inputs.containsKey('withTie');
}

Map<String, double> normalizeLegacyFacadeBrickInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 80).toDouble();
  normalized['brickType'] = (inputs['brickType'] ?? 0).toDouble();
  normalized['jointThickness'] = (inputs['jointThickness'] ?? 10).toDouble();
  normalized['withTie'] = (inputs['withTie'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FacadeBrickCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FacadeBrickCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FacadeBrickCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalFacadeBrick(
  Map<String, double> inputs, {
  FacadeBrickCanonicalSpec spec = facadeBrickCanonicalSpecV1,
}) {
  final normalized = hasCanonicalFacadeBrickInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFacadeBrickInputs(inputs);

  final area = math.max(5, math.min(1000, (normalized['area'] ?? _defaultFor(spec, 'area', 80)).toDouble()));
  final brickType = (normalized['brickType'] ?? _defaultFor(spec, 'brickType', 0)).round().clamp(0, 3);
  final jointThickness = math.max(8, math.min(12, (normalized['jointThickness'] ?? _defaultFor(spec, 'jointThickness', 10)).toDouble()));
  final withTie = (normalized['withTie'] ?? _defaultFor(spec, 'withTie', 0)).round().clamp(0, 2);

  // Bricks
  final dim = spec.materialRules.brickDims[brickType] ?? spec.materialRules.brickDims[0]!;
  final jointMm = jointThickness;
  final l = (dim.l + jointMm) / 1000;
  final h = (dim.h + jointMm) / 1000;
  final bricksPerM2 = _roundValue(1 / (l * h), 3);
  final totalBricks = _roundValue(area * bricksPerM2, 3);
  final bricksWithReserve = (totalBricks * spec.materialRules.brickReserve).ceil();

  // Mortar / cement / sand
  final masonryVolume = _roundValue(area * spec.materialRules.masonryThickness, 6);
  final mortarVolume = _roundValue(masonryVolume * spec.materialRules.mortarVolumeCoeff, 6);
  final cementBags = (mortarVolume * spec.materialRules.cementKgPerM3Mortar / spec.materialRules.cementBagKg).ceil();
  final sandM3 = _roundValue((mortarVolume * spec.materialRules.sandCoeff * 10).ceil() / 10, 1);

  // Ties
  final tiesCount = withTie > 0
      ? (area * spec.materialRules.tiesPerSqm * spec.materialRules.tiesReserve).ceil()
      : 0;

  // Hydro isolation
  final perimeterEst = _roundValue(math.sqrt(area) * 4, 3);
  final hydroArea = _roundValue(perimeterEst * spec.materialRules.hydroCoeff * spec.materialRules.hydroReserve, 3);
  final hydroRolls = (hydroArea / spec.materialRules.hydroRollM2).ceil();

  // Vent boxes
  final ventBoxes = (perimeterEst / spec.materialRules.ventBoxStepM).ceil();

  // Grout
  final groutBags = (area * spec.materialRules.groutKgPerM2 / spec.materialRules.groutBagKg).ceil();

  // Hydrophobizer
  final hydrophobCans = (area * spec.materialRules.hydrophobLPerM2 * spec.materialRules.hydrophobReserve / spec.materialRules.hydrophobCanL).ceil();

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
        'brickType:$brickType',
        'jointThickness:${jointThickness.round()}',
        'withTie:$withTie',
        'packaging:facade-brick-piece',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'facade-brick-piece',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (brickType == 3 && jointThickness > spec.warningRules.clinkerMaxJointMm) {
    warnings.add('Клинкерный кирпич обычно кладётся с швом 8–10 мм');
  }
  if (withTie == 0) {
    warnings.add('Облицовочная кладка должна иметь конструктивное крепление к основной стене (гибкие связи)');
  }
  warnings.add('Необходим вентиляционный зазор 20–40 мм между облицовкой и несущей стеной (СП 15.13330)');

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickTypeLabels[brickType] ?? 'Кирпич облицовочный',
      quantity: totalBricks,
      unit: 'шт',
      withReserve: bricksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Цемент М400 (${spec.materialRules.cementBagKg.round()} кг)',
      quantity: cementBags.toDouble(),
      unit: 'мешков',
      withReserve: cementBags.toDouble(),
      purchaseQty: cementBags,
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Песок строительный',
      quantity: sandM3,
      unit: 'м³',
      withReserve: sandM3,
      purchaseQty: sandM3.ceil(),
      category: 'Раствор',
    ),
  ];

  if (withTie > 0) {
    materials.add(CanonicalMaterialResult(
      name: _tieTypeLabels[withTie] ?? 'Связи гибкие',
      quantity: tiesCount.toDouble(),
      unit: 'шт',
      withReserve: tiesCount.toDouble(),
      purchaseQty: tiesCount,
      category: 'Крепёж',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Гидроизоляция рулонная',
      quantity: hydroArea,
      unit: 'м²',
      withReserve: (hydroRolls * spec.materialRules.hydroRollM2).toDouble(),
      purchaseQty: hydroRolls,
      category: 'Изоляция',
    ),
    CanonicalMaterialResult(
      name: 'Вентиляционные коробки',
      quantity: ventBoxes.toDouble(),
      unit: 'шт',
      withReserve: ventBoxes.toDouble(),
      purchaseQty: ventBoxes,
      category: 'Вентиляция',
    ),
    CanonicalMaterialResult(
      name: 'Затирка для швов (${spec.materialRules.groutBagKg.round()} кг)',
      quantity: groutBags.toDouble(),
      unit: 'мешков',
      withReserve: groutBags.toDouble(),
      purchaseQty: groutBags,
      category: 'Финишная',
    ),
    CanonicalMaterialResult(
      name: 'Гидрофобизатор (${spec.materialRules.hydrophobCanL.round()} л)',
      quantity: hydrophobCans.toDouble(),
      unit: 'канистр',
      withReserve: hydrophobCans.toDouble(),
      purchaseQty: hydrophobCans,
      category: 'Защита',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'brickType': brickType.toDouble(),
      'jointThickness': jointThickness,
      'withTie': withTie.toDouble(),
      'brickLengthM': _roundValue(l, 4),
      'brickHeightM': _roundValue(h, 4),
      'bricksPerM2': bricksPerM2,
      'totalBricks': totalBricks,
      'bricksWithReserve': bricksWithReserve.toDouble(),
      'masonryVolume': masonryVolume,
      'mortarVolume': mortarVolume,
      'cementBags': cementBags.toDouble(),
      'sandM3': sandM3,
      'tiesCount': tiesCount.toDouble(),
      'perimeterEst': perimeterEst,
      'hydroArea': hydroArea,
      'hydroRolls': hydroRolls.toDouble(),
      'ventBoxes': ventBoxes.toDouble(),
      'groutBags': groutBags.toDouble(),
      'hydrophobCans': hydrophobCans.toDouble(),
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
