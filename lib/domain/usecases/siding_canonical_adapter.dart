import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class SidingPackagingRules {
  final String unit;
  final int packageSize;

  const SidingPackagingRules({required this.unit, required this.packageSize});
}

class SidingMaterialRules {
  final Map<int, double> panelAreas;
  final double panelReserve;
  final double starterLength;
  final double jProfileLength;
  final double cornerLength;
  final double finishLength;
  final int screwsPerM2;
  final double screwReserve;
  final double battenStep;
  final double battenReserve;
  final double membraneRoll;
  final double membraneReserve;
  final double sealantPerPerim;
  final double starterReserve;
  final double jReserve;
  final double cornerReserve;

  const SidingMaterialRules({
    required this.panelAreas,
    required this.panelReserve,
    required this.starterLength,
    required this.jProfileLength,
    required this.cornerLength,
    required this.finishLength,
    required this.screwsPerM2,
    required this.screwReserve,
    required this.battenStep,
    required this.battenReserve,
    required this.membraneRoll,
    required this.membraneReserve,
    required this.sealantPerPerim,
    required this.starterReserve,
    required this.jReserve,
    required this.cornerReserve,
  });
}

class SidingWarningRules {
  final double largeNetAreaThresholdM2;
  final double highOpeningsRatio;

  const SidingWarningRules({required this.largeNetAreaThresholdM2, required this.highOpeningsRatio});
}

class SidingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final SidingPackagingRules packagingRules;
  final SidingMaterialRules materialRules;
  final SidingWarningRules warningRules;

  const SidingCanonicalSpec({
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

const SidingCanonicalSpec sidingCanonicalSpecV1 = SidingCanonicalSpec(
  calculatorId: 'siding',
  formulaVersion: 'siding-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'facadeArea', unit: 'm2', defaultValue: 100, min: 10, max: 1000),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 10, min: 0, max: 100),
    CanonicalInputField(key: 'perimeter', unit: 'm', defaultValue: 40, min: 10, max: 200),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 5, min: 2, max: 15),
    CanonicalInputField(key: 'sidingType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'exteriorCorners', defaultValue: 4, min: 0, max: 20),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: SidingPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: SidingMaterialRules(
    panelAreas: {0: 0.732, 1: 0.9, 2: 0.63},
    panelReserve: 1.10,
    starterLength: 3.66,
    jProfileLength: 3.66,
    cornerLength: 3.0,
    finishLength: 3.66,
    screwsPerM2: 12,
    screwReserve: 1.05,
    battenStep: 0.5,
    battenReserve: 1.05,
    membraneRoll: 75,
    membraneReserve: 1.15,
    sealantPerPerim: 15,
    starterReserve: 1.05,
    jReserve: 1.10,
    cornerReserve: 1.05,
  ),
  warningRules: SidingWarningRules(largeNetAreaThresholdM2: 300, highOpeningsRatio: 0.3),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _sidingTypeLabels = {
  0: 'Виниловый сайдинг (0.732 м\u00b2)',
  1: 'Металлический сайдинг (0.9 м\u00b2)',
  2: 'Фиброцементный сайдинг (0.63 м\u00b2)',
};

/* ─── helpers ─── */

bool hasCanonicalSidingInputs(Map<String, double> inputs) {
  return inputs.containsKey('sidingType') ||
      inputs.containsKey('facadeArea') ||
      inputs.containsKey('exteriorCorners');
}

Map<String, double> normalizeLegacySidingInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['facadeArea'] = (inputs['facadeArea'] ?? 100).toDouble();
  normalized['openingsArea'] = (inputs['openingsArea'] ?? 10).toDouble();
  normalized['perimeter'] = (inputs['perimeter'] ?? 40).toDouble();
  normalized['height'] = (inputs['height'] ?? 5).toDouble();
  normalized['sidingType'] = (inputs['sidingType'] ?? 0).toDouble();
  normalized['exteriorCorners'] = (inputs['exteriorCorners'] ?? 4).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(SidingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(SidingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(SidingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalSiding(
  Map<String, double> inputs, {
  SidingCanonicalSpec spec = sidingCanonicalSpecV1,
}) {
  final normalized = hasCanonicalSidingInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacySidingInputs(inputs);

  final facadeArea = (normalized['facadeArea'] ?? _defaultFor(spec, 'facadeArea', 100)).round().clamp(10, 1000);
  final openingsArea = (normalized['openingsArea'] ?? _defaultFor(spec, 'openingsArea', 10)).round().clamp(0, 100);
  final perimeter = (normalized['perimeter'] ?? _defaultFor(spec, 'perimeter', 40)).round().clamp(10, 200);
  final height = (normalized['height'] ?? _defaultFor(spec, 'height', 5)).round().clamp(2, 15);
  final sidingType = (normalized['sidingType'] ?? _defaultFor(spec, 'sidingType', 0)).round().clamp(0, 2);
  final exteriorCorners = (normalized['exteriorCorners'] ?? _defaultFor(spec, 'exteriorCorners', 4)).round().clamp(0, 20);

  // Panel area
  final panelArea = spec.materialRules.panelAreas[sidingType] ?? 0.732;

  // Formulas
  final netArea = facadeArea - openingsArea;
  final panels = (netArea / panelArea * spec.materialRules.panelReserve).ceil();
  final starter = ((perimeter + math.sqrt(openingsArea) * 4) / spec.materialRules.starterLength).ceil();
  final jProfile = ((math.sqrt(openingsArea) * 4 * 2 + perimeter) * spec.materialRules.jReserve / spec.materialRules.jProfileLength).ceil();
  final corners = (height * exteriorCorners * spec.materialRules.cornerReserve / spec.materialRules.cornerLength).ceil();
  final finish = (perimeter * spec.materialRules.starterReserve / spec.materialRules.finishLength).ceil();
  final screws = (netArea * spec.materialRules.screwsPerM2 * spec.materialRules.screwReserve).ceil();
  final battens = (netArea / spec.materialRules.battenStep * spec.materialRules.battenReserve).ceil();
  final membrane = (netArea * spec.materialRules.membraneReserve / spec.materialRules.membraneRoll).ceil();
  final sealant = (math.sqrt(netArea) * 4 / spec.materialRules.sealantPerPerim).ceil();

  // Scenarios
  const packageLabel = 'siding-panel';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(panels * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'sidingType:$sidingType',
        'exteriorCorners:$exteriorCorners',
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
  if (netArea > spec.warningRules.largeNetAreaThresholdM2) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку сайдинга');
  }
  if (openingsArea > facadeArea * spec.warningRules.highOpeningsRatio) {
    warnings.add('Большая площадь проёмов — проверьте количество доборных элементов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_sidingTypeLabels[sidingType]}',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Стартовая планка (${spec.materialRules.starterLength} м)',
      quantity: starter.toDouble(),
      unit: 'шт',
      withReserve: starter.toDouble(),
      purchaseQty: starter,
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'J-профиль (${spec.materialRules.jProfileLength} м)',
      quantity: jProfile.toDouble(),
      unit: 'шт',
      withReserve: jProfile.toDouble(),
      purchaseQty: jProfile,
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Наружный угол (${spec.materialRules.cornerLength} м)',
      quantity: corners.toDouble(),
      unit: 'шт',
      withReserve: corners.toDouble(),
      purchaseQty: corners,
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Финишная планка (${spec.materialRules.finishLength} м)',
      quantity: finish.toDouble(),
      unit: 'шт',
      withReserve: finish.toDouble(),
      purchaseQty: finish,
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы',
      quantity: screws.toDouble(),
      unit: 'шт',
      withReserve: screws.toDouble(),
      purchaseQty: screws,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Обрешётка (м.п.)',
      quantity: battens.toDouble(),
      unit: 'м.п.',
      withReserve: battens.toDouble(),
      purchaseQty: battens,
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Мембрана (${spec.materialRules.membraneRoll.round()} м\u00b2)',
      quantity: membrane.toDouble(),
      unit: 'рулонов',
      withReserve: membrane.toDouble(),
      purchaseQty: membrane,
      category: 'Изоляция',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealant.toDouble(),
      unit: 'шт',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant,
      category: 'Монтаж',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'facadeArea': facadeArea.toDouble(),
      'openingsArea': openingsArea.toDouble(),
      'perimeter': perimeter.toDouble(),
      'height': height.toDouble(),
      'sidingType': sidingType.toDouble(),
      'exteriorCorners': exteriorCorners.toDouble(),
      'panelArea': panelArea,
      'netArea': netArea.toDouble(),
      'panels': panels.toDouble(),
      'starter': starter.toDouble(),
      'jProfile': jProfile.toDouble(),
      'corners': corners.toDouble(),
      'finish': finish.toDouble(),
      'screws': screws.toDouble(),
      'battens': battens.toDouble(),
      'membrane': membrane.toDouble(),
      'sealant': sealant.toDouble(),
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
