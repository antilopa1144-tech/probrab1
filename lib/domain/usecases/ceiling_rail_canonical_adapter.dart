import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class CeilingRailPackagingRules {
  final String unit;
  final double packageSize;

  const CeilingRailPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class CeilingRailMaterialRules {
  final double railReserve;
  final double tProfileSpacing;
  final double tProfileLength;
  final double tReserve;
  final double hangerSpacing;
  final double screwsPerHanger;
  final double screwsPerRail;

  const CeilingRailMaterialRules({
    required this.railReserve,
    required this.tProfileSpacing,
    required this.tProfileLength,
    required this.tReserve,
    required this.hangerSpacing,
    required this.screwsPerHanger,
    required this.screwsPerRail,
  });
}

class CeilingRailWarningRules {
  final double largeAreaThresholdM2;

  const CeilingRailWarningRules({
    required this.largeAreaThresholdM2,
  });
}

class CeilingRailCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final CeilingRailPackagingRules packagingRules;
  final CeilingRailMaterialRules materialRules;
  final CeilingRailWarningRules warningRules;

  const CeilingRailCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const CeilingRailCanonicalSpec ceilingRailCanonicalSpecV1 = CeilingRailCanonicalSpec(
  calculatorId: 'ceiling-rail',
  formulaVersion: 'ceiling-rail-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 20, min: 1, max: 200),
    CanonicalInputField(key: 'railWidth', unit: 'mm', defaultValue: 100, min: 100, max: 200),
    CanonicalInputField(key: 'railLength', unit: 'm', defaultValue: 3.0, min: 3.0, max: 4.0),
    CanonicalInputField(key: 'roomLength', unit: 'm', defaultValue: 5, min: 1, max: 30),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: CeilingRailPackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: CeilingRailMaterialRules(
    railReserve: 1.1,
    tProfileSpacing: 1.0,
    tProfileLength: 3,
    tReserve: 1.05,
    hangerSpacing: 1.2,
    screwsPerHanger: 4,
    screwsPerRail: 2,
  ),
  warningRules: CeilingRailWarningRules(
    largeAreaThresholdM2: 100,
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

double _defaultFor(CeilingRailCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(CeilingRailCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(CeilingRailCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalCeilingRail(
  Map<String, double> inputs, {
  CeilingRailCanonicalSpec spec = ceilingRailCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(200.0, inputs['area'] ?? _defaultFor(spec, 'area', 20)));
  final railWidthRaw = (inputs['railWidth'] ?? _defaultFor(spec, 'railWidth', 100)).round();
  final allowedWidths = [100, 150, 200];
  final railWidth = allowedWidths.contains(railWidthRaw) ? railWidthRaw : 100;
  final railLengthRaw = inputs['railLength'] ?? _defaultFor(spec, 'railLength', 3.0);
  final allowedLengths = [3.0, 3.6, 4.0];
  var railLength = allowedLengths[0];
  var minDiff = (allowedLengths[0] - railLengthRaw).abs();
  for (final l in allowedLengths) {
    final diff = (l - railLengthRaw).abs();
    if (diff < minDiff) {
      minDiff = diff;
      railLength = l;
    }
  }
  final roomLength = math.max(1.0, math.min(30.0, inputs['roomLength'] ?? _defaultFor(spec, 'roomLength', 5)));

  final roomWidth = area / roomLength;

  // Rails
  final railRows = (roomWidth / (railWidth / 1000.0)).ceil();
  final totalRailLen = railRows * roomLength * spec.materialRules.railReserve;
  final railPcs = (totalRailLen / railLength).ceil();

  // T-profile guides
  final guideCount = (roomLength / spec.materialRules.tProfileSpacing).ceil() + 1;
  final guideTotal = guideCount * roomWidth * spec.materialRules.tReserve;
  final guidePcs = (guideTotal / spec.materialRules.tProfileLength).ceil();

  // Hangers
  final hangers = ((roomWidth / spec.materialRules.hangerSpacing) + 1).ceil() * guideCount;

  // Screws & dubels
  final screws = (hangers * spec.materialRules.screwsPerHanger + railPcs * spec.materialRules.screwsPerRail).round();
  final dubels = hangers;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(railPcs * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'rail-${railWidth}mm';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'railWidth:$railWidth',
        'railLength:$railLength',
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
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u0420\u0435\u0439\u043a\u0430 $railWidth \u043c\u043c \u00d7 $railLength \u043c',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u0422-\u043f\u0440\u043e\u0444\u0438\u043b\u044c (\u0441\u0442\u0440\u0438\u043d\u0433\u0435\u0440) 3\u043c',
      quantity: guidePcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: guidePcs.toDouble(),
      purchaseQty: guidePcs,
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u043e\u0434\u0432\u0435\u0441',
      quantity: hangers.toDouble(),
      unit: '\u0448\u0442',
      withReserve: hangers.toDouble(),
      purchaseQty: hangers,
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0421\u0430\u043c\u043e\u0440\u0435\u0437\u044b',
      quantity: screws.toDouble(),
      unit: '\u0448\u0442',
      withReserve: screws.toDouble(),
      purchaseQty: screws,
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0414\u044e\u0431\u0435\u043b\u0438',
      quantity: dubels.toDouble(),
      unit: '\u0448\u0442',
      withReserve: dubels.toDouble(),
      purchaseQty: dubels,
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'railWidth': railWidth.toDouble(),
      'railLength': railLength,
      'roomLength': _roundValue(roomLength, 3),
      'roomWidth': _roundValue(roomWidth, 3),
      'railRows': railRows.toDouble(),
      'totalRailLen': _roundValue(totalRailLen, 3),
      'railPcs': railPcs.toDouble(),
      'guideCount': guideCount.toDouble(),
      'guidePcs': guidePcs.toDouble(),
      'hangers': hangers.toDouble(),
      'screws': screws.toDouble(),
      'dubels': dubels.toDouble(),
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
