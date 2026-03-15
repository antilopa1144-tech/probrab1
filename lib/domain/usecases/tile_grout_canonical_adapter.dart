import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class TileGroutPackagingRules {
  final String unit;
  final double defaultBagSize;
  final List<double> allowedBagSizes;

  const TileGroutPackagingRules({
    required this.unit,
    required this.defaultBagSize,
    required this.allowedBagSizes,
  });
}

class TileGroutMaterialRules {
  final Map<int, double> groutDensity;
  final double groutReserve;

  const TileGroutMaterialRules({
    required this.groutDensity,
    required this.groutReserve,
  });
}

class TileGroutWarningRules {
  final int wideJointThresholdMm;
  final bool epoxyWarning;

  const TileGroutWarningRules({
    required this.wideJointThresholdMm,
    required this.epoxyWarning,
  });
}

class TileGroutCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final TileGroutPackagingRules packagingRules;
  final TileGroutMaterialRules materialRules;
  final TileGroutWarningRules warningRules;

  const TileGroutCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const TileGroutCanonicalSpec tileGroutCanonicalSpecV1 = TileGroutCanonicalSpec(
  calculatorId: 'tile-grout',
  formulaVersion: 'tile-grout-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 20, min: 1, max: 500),
    CanonicalInputField(key: 'tileWidth', unit: 'mm', defaultValue: 300, min: 50, max: 1200),
    CanonicalInputField(key: 'tileHeight', unit: 'mm', defaultValue: 300, min: 50, max: 1200),
    CanonicalInputField(key: 'tileThickness', unit: 'mm', defaultValue: 8, min: 6, max: 25),
    CanonicalInputField(key: 'jointWidth', unit: 'mm', defaultValue: 3, min: 1, max: 20),
    CanonicalInputField(key: 'groutType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'bagSize', unit: 'kg', defaultValue: 2, min: 1, max: 5),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: TileGroutPackagingRules(
    unit: 'мешков',
    defaultBagSize: 2,
    allowedBagSizes: [1, 2, 5],
  ),
  materialRules: TileGroutMaterialRules(
    groutDensity: {0: 1600, 1: 1400, 2: 1200},
    groutReserve: 1.1,
  ),
  warningRules: TileGroutWarningRules(
    wideJointThresholdMm: 10,
    epoxyWarning: true,
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

double _defaultFor(TileGroutCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(TileGroutCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(TileGroutCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalTileGrout(
  Map<String, double> inputs, {
  TileGroutCanonicalSpec spec = tileGroutCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? _defaultFor(spec, 'area', 20)));
  final tileWidth = math.max(50, math.min(1200, (inputs['tileWidth'] ?? _defaultFor(spec, 'tileWidth', 300)).round()));
  final tileHeight = math.max(50, math.min(1200, (inputs['tileHeight'] ?? _defaultFor(spec, 'tileHeight', 300)).round()));
  final tileThickness = math.max(6, math.min(25, (inputs['tileThickness'] ?? _defaultFor(spec, 'tileThickness', 8)).round()));
  final jointWidth = math.max(1, math.min(20, (inputs['jointWidth'] ?? _defaultFor(spec, 'jointWidth', 3)).round()));
  final groutType = (inputs['groutType'] ?? _defaultFor(spec, 'groutType', 0)).round().clamp(0, 2);
  final bagSizeRaw = inputs['bagSize'] ?? _defaultFor(spec, 'bagSize', 2);
  final bagSize = [1.0, 2.0, 5.0].contains(bagSizeRaw) ? bagSizeRaw : 2.0;

  // Joint length per m2
  final jointLenPerM2 = (1000 / tileWidth) + (1000 / tileHeight);

  // Joint volume per m2 in liters
  final jointVolPerM2 = jointLenPerM2 * (jointWidth / 1000) * (tileThickness / 1000) * 1000;

  // Density in kg/L
  final density = (spec.materialRules.groutDensity[groutType] ?? spec.materialRules.groutDensity[0]!) / 1000;

  final kgPerM2 = jointVolPerM2 * density;
  final totalKg = area * kgPerM2 * spec.materialRules.groutReserve;
  final bags = (totalKg / bagSize).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalKg * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / bagSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * bagSize, 6);
    final packageLabel = 'grout-bag-${bagSize.toInt()}kg';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'groutType:$groutType',
        'bagSize:${bagSize.toInt()}',
        'tileWidth:$tileWidth',
        'tileHeight:$tileHeight',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: bagSize,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final groutTypeLabels = <int, String>{
    0: 'Затирка цементная',
    1: 'Затирка эпоксидная',
    2: 'Затирка полиуретановая',
  };

  final warnings = <String>[];
  if (groutType == 1) {
    warnings.add('Эпоксидная затирка требует быстрого нанесения — готовьте небольшими порциями');
  }
  if (jointWidth >= spec.warningRules.wideJointThresholdMm) {
    warnings.add('Широкие швы — рекомендуется крупнозернистая затирка');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${groutTypeLabels[groutType]} ${bagSize.toInt()}кг',
      quantity: recScenario.exactNeed,
      unit: 'кг',
      withReserve: recScenario.exactNeed,
      purchaseQty: (recScenario.purchaseQuantity / bagSize).ceil(),
      category: 'Основное',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'tileWidth': tileWidth.toDouble(),
      'tileHeight': tileHeight.toDouble(),
      'tileThickness': tileThickness.toDouble(),
      'jointWidth': jointWidth.toDouble(),
      'groutType': groutType.toDouble(),
      'bagSize': bagSize,
      'jointLenPerM2': _roundValue(jointLenPerM2, 6),
      'jointVolPerM2': _roundValue(jointVolPerM2, 6),
      'density': _roundValue(density, 3),
      'kgPerM2': _roundValue(kgPerM2, 6),
      'totalKg': _roundValue(totalKg, 3),
      'bags': bags.toDouble(),
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
