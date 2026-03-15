import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class FastenersPackagingRules {
  final String unit;
  final double packageSize;

  const FastenersPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class FastenersMaterialRules {
  final Map<int, int> screwsPerUnit;
  final Map<int, int> baseStep;
  final Map<int, String> screwSizes;
  final Map<int, int> perKg;
  final Map<int, double> unitArea;
  final double screwReserve;
  final double klaymerMultiplier;
  final int frameScrewsPerUnit;
  final double frameScrewReserve;
  final double dubelStep;
  final double dubelReserve;
  final int bitsPerScrews;

  const FastenersMaterialRules({
    required this.screwsPerUnit,
    required this.baseStep,
    required this.screwSizes,
    required this.perKg,
    required this.unitArea,
    required this.screwReserve,
    required this.klaymerMultiplier,
    required this.frameScrewsPerUnit,
    required this.frameScrewReserve,
    required this.dubelStep,
    required this.dubelReserve,
    required this.bitsPerScrews,
  });
}

class FastenersWarningRules {
  final int bulkThreshold;

  const FastenersWarningRules({
    required this.bulkThreshold,
  });
}

class FastenersCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FastenersPackagingRules packagingRules;
  final FastenersMaterialRules materialRules;
  final FastenersWarningRules warningRules;

  const FastenersCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const FastenersCanonicalSpec fastenersCanonicalSpecV1 = FastenersCanonicalSpec(
  calculatorId: 'fasteners',
  formulaVersion: 'fasteners-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'materialType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'sheetCount', defaultValue: 10, min: 1, max: 200),
    CanonicalInputField(key: 'fastenerStep', unit: 'mm', defaultValue: 200, min: 150, max: 300),
    CanonicalInputField(key: 'withFrameScrews', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'withDubels', defaultValue: 0, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: FastenersPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: FastenersMaterialRules(
    screwsPerUnit: {0: 24, 1: 28, 2: 8, 3: 20},
    baseStep: {0: 250, 1: 200, 2: 200, 3: 200},
    screwSizes: {0: '3.5\u00d725', 1: '3.5\u00d735', 2: '4.8\u00d735', 3: 'klaimers'},
    perKg: {0: 1000, 1: 600, 2: 250, 3: 0},
    unitArea: {0: 3.0, 1: 3.125, 2: 1, 3: 1},
    screwReserve: 1.05,
    klaymerMultiplier: 1.5,
    frameScrewsPerUnit: 4,
    frameScrewReserve: 1.05,
    dubelStep: 0.5,
    dubelReserve: 1.05,
    bitsPerScrews: 500,
  ),
  warningRules: FastenersWarningRules(
    bulkThreshold: 100,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FastenersCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FastenersCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FastenersCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalFasteners(
  Map<String, double> inputs, {
  FastenersCanonicalSpec spec = fastenersCanonicalSpecV1,
}) {
  final materialType = (inputs['materialType'] ?? _defaultFor(spec, 'materialType', 0)).round().clamp(0, 3);
  final sheetCount = math.max(1, math.min(200, (inputs['sheetCount'] ?? _defaultFor(spec, 'sheetCount', 10)).round()));
  final fastenerStep = math.max(150, math.min(300, (inputs['fastenerStep'] ?? _defaultFor(spec, 'fastenerStep', 200)).round()));
  final withFrameScrews = (inputs['withFrameScrews'] ?? _defaultFor(spec, 'withFrameScrews', 0)).round() == 1 ? 1 : 0;
  final withDubels = (inputs['withDubels'] ?? _defaultFor(spec, 'withDubels', 0)).round() == 1 ? 1 : 0;

  // Formulas
  final baseStep = spec.materialRules.baseStep[materialType] ?? spec.materialRules.baseStep[0]!;
  final stepCoeff = baseStep / fastenerStep;
  final baseScrews = spec.materialRules.screwsPerUnit[materialType] ?? spec.materialRules.screwsPerUnit[0]!;
  final screwsPerUnit = (baseScrews * stepCoeff).ceil();
  var totalScrews = (sheetCount * screwsPerUnit * spec.materialRules.screwReserve).ceil();

  // Klaimers for paneling
  final klaimers = materialType == 3 ? (totalScrews * spec.materialRules.klaymerMultiplier).ceil() : 0;
  if (materialType == 3) {
    totalScrews = klaimers;
  }

  // Frame screws
  final frameScrews = withFrameScrews == 1
      ? (sheetCount * spec.materialRules.frameScrewsPerUnit * spec.materialRules.frameScrewReserve).ceil()
      : 0;

  // Dubels
  final dubels = withDubels == 1
      ? (sheetCount * 2 / spec.materialRules.dubelStep * spec.materialRules.dubelReserve).ceil()
      : 0;

  // Bits
  final bits = (totalScrews / spec.materialRules.bitsPerScrews).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalScrews * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'fastener-unit';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'materialType:$materialType',
        'fastenerStep:$fastenerStep',
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
  if (sheetCount > spec.warningRules.bulkThreshold) {
    warnings.add('Большой объём — рассмотрите оптовую упаковку');
  }
  if (materialType == 3) {
    warnings.add('Для вагонки используются кляймеры вместо саморезов');
  }

  final screwLabel = materialType == 3
      ? 'Кляймеры'
      : 'Саморезы ${spec.materialRules.screwSizes[materialType]}';

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: screwLabel,
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Крепёж',
    ),
  ];

  if (frameScrews > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Саморезы каркасные',
      quantity: frameScrews.toDouble(),
      unit: 'шт',
      withReserve: frameScrews.toDouble(),
      purchaseQty: frameScrews,
      category: 'Крепёж',
    ));
  }

  if (dubels > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Дюбели',
      quantity: dubels.toDouble(),
      unit: 'шт',
      withReserve: dubels.toDouble(),
      purchaseQty: dubels,
      category: 'Крепёж',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Биты для шуруповёрта',
    quantity: bits.toDouble(),
    unit: 'шт',
    withReserve: bits.toDouble(),
    purchaseQty: bits,
    category: 'Инструмент',
  ));

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'materialType': materialType.toDouble(),
      'sheetCount': sheetCount.toDouble(),
      'fastenerStep': fastenerStep.toDouble(),
      'withFrameScrews': withFrameScrews.toDouble(),
      'withDubels': withDubels.toDouble(),
      'stepCoeff': _roundValue(stepCoeff, 3),
      'screwsPerUnit': screwsPerUnit.toDouble(),
      'totalScrews': totalScrews.toDouble(),
      'klaimers': klaimers.toDouble(),
      'frameScrews': frameScrews.toDouble(),
      'dubels': dubels.toDouble(),
      'bits': bits.toDouble(),
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
