import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class CeilingStretchPackagingRules {
  final String unit;
  final double packageSize;

  const CeilingStretchPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class CeilingStretchMaterialRules {
  final double baguetReserve;
  final double baguetLength;
  final double insertReserve;
  final double maskingTapeRoll;

  const CeilingStretchMaterialRules({
    required this.baguetReserve,
    required this.baguetLength,
    required this.insertReserve,
    required this.maskingTapeRoll,
  });
}

class CeilingStretchWarningRules {
  final double largeAreaThresholdM2;
  final double manyFixturesThreshold;

  const CeilingStretchWarningRules({
    required this.largeAreaThresholdM2,
    required this.manyFixturesThreshold,
  });
}

class CeilingStretchCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final CeilingStretchPackagingRules packagingRules;
  final CeilingStretchMaterialRules materialRules;
  final CeilingStretchWarningRules warningRules;

  const CeilingStretchCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const CeilingStretchCanonicalSpec ceilingStretchCanonicalSpecV1 = CeilingStretchCanonicalSpec(
  calculatorId: 'ceiling-stretch',
  formulaVersion: 'ceiling-stretch-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 20, min: 1, max: 500),
    CanonicalInputField(key: 'corners', defaultValue: 4, min: 3, max: 20),
    CanonicalInputField(key: 'fixtures', defaultValue: 4, min: 0, max: 50),
    CanonicalInputField(key: 'type', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: CeilingStretchPackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: CeilingStretchMaterialRules(
    baguetReserve: 1.1,
    baguetLength: 2.5,
    insertReserve: 1.1,
    maskingTapeRoll: 50,
  ),
  warningRules: CeilingStretchWarningRules(
    largeAreaThresholdM2: 50,
    manyFixturesThreshold: 20,
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

double _defaultFor(CeilingStretchCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(CeilingStretchCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(CeilingStretchCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalCeilingStretch(
  Map<String, double> inputs, {
  CeilingStretchCanonicalSpec spec = ceilingStretchCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? _defaultFor(spec, 'area', 20)));
  final corners = (inputs['corners'] ?? _defaultFor(spec, 'corners', 4)).round().clamp(3, 20);
  final fixtures = (inputs['fixtures'] ?? _defaultFor(spec, 'fixtures', 4)).round().clamp(0, 50);
  final type = (inputs['type'] ?? _defaultFor(spec, 'type', 0)).round().clamp(0, 2);

  // Perimeter from area (square approximation)
  final perim = math.sqrt(area) * 4;

  // Baguette profiles
  final baguetLen = perim * spec.materialRules.baguetReserve;
  final profilePcs = (baguetLen / spec.materialRules.baguetLength).ceil();

  // Decorative insert
  final insertLen = perim * spec.materialRules.insertReserve;

  // Masking tape
  final maskingTape = (perim * spec.materialRules.baguetReserve / spec.materialRules.maskingTapeRoll).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(profilePcs * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    const packageLabel = 'baguet-profile';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'type:$type',
        'corners:$corners',
        'fixtures:$fixtures',
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
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0432\u043e\u0437\u043c\u043e\u0436\u043d\u043e \u043f\u043e\u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u0440\u0430\u0437\u0434\u0435\u043b\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c');
  }
  if (fixtures > spec.warningRules.manyFixturesThreshold) {
    warnings.add('\u041c\u043d\u043e\u0433\u043e \u0441\u0432\u0435\u0442\u0438\u043b\u044c\u043d\u0438\u043a\u043e\u0432 \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u0443\u0441\u0438\u043b\u0435\u043d\u043d\u043e\u0435 \u043a\u0440\u0435\u043f\u043b\u0435\u043d\u0438\u0435');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u0411\u0430\u0433\u0435\u0442\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c 2.5\u043c',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u0414\u0435\u043a\u043e\u0440\u0430\u0442\u0438\u0432\u043d\u0430\u044f \u0432\u0441\u0442\u0430\u0432\u043a\u0430',
      quantity: _roundValue(insertLen, 3),
      unit: '\u043c',
      withReserve: insertLen.ceilToDouble(),
      purchaseQty: insertLen.ceil(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u041c\u0430\u0441\u043a\u0438\u0440\u043e\u0432\u043e\u0447\u043d\u0430\u044f \u043b\u0435\u043d\u0442\u0430 50\u043c',
      quantity: maskingTape.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: maskingTape.toDouble(),
      purchaseQty: maskingTape,
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u041e\u0431\u0440\u0430\u0431\u043e\u0442\u043a\u0430 \u0443\u0433\u043b\u043e\u0432',
      quantity: corners.toDouble(),
      unit: '\u0448\u0442',
      withReserve: corners.toDouble(),
      purchaseQty: corners,
      category: '\u041c\u043e\u043d\u0442\u0430\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0423\u0441\u0438\u043b\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0435 \u043a\u043e\u043b\u044c\u0446\u0430 \u0434\u043b\u044f \u0441\u0432\u0435\u0442\u0438\u043b\u044c\u043d\u0438\u043a\u043e\u0432',
      quantity: fixtures.toDouble(),
      unit: '\u0448\u0442',
      withReserve: fixtures.toDouble(),
      purchaseQty: fixtures,
      category: '\u041c\u043e\u043d\u0442\u0430\u0436',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'type': type.toDouble(),
      'corners': corners.toDouble(),
      'fixtures': fixtures.toDouble(),
      'perim': _roundValue(perim, 3),
      'baguetLen': _roundValue(baguetLen, 3),
      'profilePcs': profilePcs.toDouble(),
      'insertLen': _roundValue(insertLen, 3),
      'maskingTape': maskingTape.toDouble(),
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
