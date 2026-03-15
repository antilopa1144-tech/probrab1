import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class CeilingCassettePackagingRules {
  final String unit;
  final double packageSize;

  const CeilingCassettePackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class CeilingCassetteMaterialRules {
  final Map<int, double> cassetteAreas;
  final Map<int, double> cassetteSizes;
  final double cassetteReserve;
  final double mainProfileSpacing;
  final double crossProfileSpacing;
  final double hangerSpacing;
  final double wallProfileLength;
  final double wallProfileReserve;

  const CeilingCassetteMaterialRules({
    required this.cassetteAreas,
    required this.cassetteSizes,
    required this.cassetteReserve,
    required this.mainProfileSpacing,
    required this.crossProfileSpacing,
    required this.hangerSpacing,
    required this.wallProfileLength,
    required this.wallProfileReserve,
  });
}

class CeilingCassetteWarningRules {
  final double largeAreaThresholdM2;

  const CeilingCassetteWarningRules({
    required this.largeAreaThresholdM2,
  });
}

class CeilingCassetteCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final CeilingCassettePackagingRules packagingRules;
  final CeilingCassetteMaterialRules materialRules;
  final CeilingCassetteWarningRules warningRules;

  const CeilingCassetteCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const CeilingCassetteCanonicalSpec ceilingCassetteCanonicalSpecV1 = CeilingCassetteCanonicalSpec(
  calculatorId: 'ceiling-cassette',
  formulaVersion: 'ceiling-cassette-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 30, min: 1, max: 500),
    CanonicalInputField(key: 'cassetteSize', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'roomLength', unit: 'm', defaultValue: 6, min: 2, max: 50),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: CeilingCassettePackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: CeilingCassetteMaterialRules(
    cassetteAreas: {0: 0.354, 1: 0.36, 2: 0.09},
    cassetteSizes: {0: 0.595, 1: 0.6, 2: 0.3},
    cassetteReserve: 1.1,
    mainProfileSpacing: 1.2,
    crossProfileSpacing: 0.6,
    hangerSpacing: 1.2,
    wallProfileLength: 3,
    wallProfileReserve: 1.05,
  ),
  warningRules: CeilingCassetteWarningRules(
    largeAreaThresholdM2: 200,
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

double _defaultFor(CeilingCassetteCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(CeilingCassetteCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(CeilingCassetteCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalCeilingCassette(
  Map<String, double> inputs, {
  CeilingCassetteCanonicalSpec spec = ceilingCassetteCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? _defaultFor(spec, 'area', 30)));
  final cassetteSize = (inputs['cassetteSize'] ?? _defaultFor(spec, 'cassetteSize', 0)).round().clamp(0, 2);
  final roomLength = math.max(2.0, math.min(50.0, inputs['roomLength'] ?? _defaultFor(spec, 'roomLength', 6)));

  final roomWidth = area / roomLength;
  final cassetteDim = spec.materialRules.cassetteSizes[cassetteSize] ?? 0.595;

  // Cassettes
  final cassPerRow = (roomLength / cassetteDim).ceil();
  final rows = (roomWidth / cassetteDim).ceil();
  final totalCass = (rows * cassPerRow * spec.materialRules.cassetteReserve).ceil();

  // Main profiles
  final mainRows = (roomWidth / spec.materialRules.mainProfileSpacing).ceil() + 1;
  final mainProfiles = (mainRows * roomLength / spec.materialRules.mainProfileSpacing).ceil();

  // Cross profiles
  final crossPerRow = (roomLength / spec.materialRules.crossProfileSpacing).ceil();
  final crossProfiles = mainRows * crossPerRow;

  // Hangers
  final hangers = ((roomLength / spec.materialRules.hangerSpacing) + 1).ceil() * mainRows;

  // Wall angle profiles
  final wallProfilePcs = ((roomLength + roomWidth) * 2 * spec.materialRules.wallProfileReserve / spec.materialRules.wallProfileLength).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalCass * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'cassette-$cassetteSize';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'cassetteSize:$cassetteSize',
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

  final cassetteLabels = {0: '595\u00d7595 \u043c\u043c', 1: '600\u00d7600 \u043c\u043c', 2: '300\u00d7300 \u043c\u043c'};

  final warnings = <String>[];
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u041a\u0430\u0441\u0441\u0435\u0442\u0430 ${cassetteLabels[cassetteSize] ?? "595\u00d7595 \u043c\u043c"}',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u043b\u0430\u0432\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c \u0422-\u043e\u0431\u0440\u0430\u0437\u043d\u044b\u0439',
      quantity: mainProfiles.toDouble(),
      unit: '\u0448\u0442',
      withReserve: mainProfiles.toDouble(),
      purchaseQty: mainProfiles,
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u043e\u043f\u0435\u0440\u0435\u0447\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c',
      quantity: crossProfiles.toDouble(),
      unit: '\u0448\u0442',
      withReserve: crossProfiles.toDouble(),
      purchaseQty: crossProfiles,
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
      name: '\u0423\u0433\u043b\u043e\u0432\u043e\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c 3\u043c',
      quantity: wallProfilePcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: wallProfilePcs.toDouble(),
      purchaseQty: wallProfilePcs,
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'cassetteSize': cassetteSize.toDouble(),
      'roomLength': _roundValue(roomLength, 3),
      'roomWidth': _roundValue(roomWidth, 3),
      'cassPerRow': cassPerRow.toDouble(),
      'rows': rows.toDouble(),
      'totalCass': totalCass.toDouble(),
      'mainRows': mainRows.toDouble(),
      'mainProfiles': mainProfiles.toDouble(),
      'crossPerRow': crossPerRow.toDouble(),
      'crossProfiles': crossProfiles.toDouble(),
      'hangers': hangers.toDouble(),
      'wallProfilePcs': wallProfilePcs.toDouble(),
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
