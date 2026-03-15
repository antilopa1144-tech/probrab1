import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class GuttersPackagingRules {
  final String unit;
  final int packageSize;

  const GuttersPackagingRules({required this.unit, required this.packageSize});
}

class GuttersMaterialRules {
  final double gutterReserve;
  final double hookStepM;
  final double hookReserve;
  final double pipeClampStepM;
  final double pipeClampReserve;
  final int buildingCorners;
  final double connectorReserve;
  final int sealantConnectionsPerTube;
  final int sealantTubeMl;
  final double recommendedFunnelIntervalM;

  const GuttersMaterialRules({
    required this.gutterReserve,
    required this.hookStepM,
    required this.hookReserve,
    required this.pipeClampStepM,
    required this.pipeClampReserve,
    required this.buildingCorners,
    required this.connectorReserve,
    required this.sealantConnectionsPerTube,
    required this.sealantTubeMl,
    required this.recommendedFunnelIntervalM,
  });
}

class GuttersWarningRules {
  final double recommendedFunnelIntervalM;

  const GuttersWarningRules({required this.recommendedFunnelIntervalM});
}

class GuttersCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final GuttersPackagingRules packagingRules;
  final GuttersMaterialRules materialRules;
  final GuttersWarningRules warningRules;

  const GuttersCanonicalSpec({
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

const GuttersCanonicalSpec guttersCanonicalSpecV1 = GuttersCanonicalSpec(
  calculatorId: 'gutters',
  formulaVersion: 'gutters-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'roofPerimeter', unit: 'm', defaultValue: 40, min: 5, max: 200),
    CanonicalInputField(key: 'roofHeight', unit: 'm', defaultValue: 5, min: 2, max: 15),
    CanonicalInputField(key: 'funnels', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'gutterDia', unit: 'mm', defaultValue: 90, min: 75, max: 125),
    CanonicalInputField(key: 'gutterLength', unit: 'm', defaultValue: 3, min: 3, max: 4),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: GuttersPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: GuttersMaterialRules(
    gutterReserve: 1.05,
    hookStepM: 0.6,
    hookReserve: 1.05,
    pipeClampStepM: 1.5,
    pipeClampReserve: 1.05,
    buildingCorners: 8,
    connectorReserve: 1.05,
    sealantConnectionsPerTube: 20,
    sealantTubeMl: 310,
    recommendedFunnelIntervalM: 11,
  ),
  warningRules: GuttersWarningRules(recommendedFunnelIntervalM: 11),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

bool hasCanonicalGuttersInputs(Map<String, double> inputs) {
  return inputs.containsKey('roofPerimeter') ||
      inputs.containsKey('funnels') ||
      inputs.containsKey('gutterDia');
}

Map<String, double> normalizeLegacyGuttersInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['roofPerimeter'] = (inputs['roofPerimeter'] ?? 40).toDouble();
  normalized['roofHeight'] = (inputs['roofHeight'] ?? 5).toDouble();
  normalized['funnels'] = (inputs['funnels'] ?? 4).toDouble();
  normalized['gutterDia'] = (inputs['gutterDia'] ?? 90).toDouble();
  normalized['gutterLength'] = (inputs['gutterLength'] ?? 3).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(GuttersCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(GuttersCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(GuttersCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalGutters(
  Map<String, double> inputs, {
  GuttersCanonicalSpec spec = guttersCanonicalSpecV1,
}) {
  final normalized = hasCanonicalGuttersInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyGuttersInputs(inputs);

  final roofPerimeter = math.max(5.0, math.min(200.0, (normalized['roofPerimeter'] ?? _defaultFor(spec, 'roofPerimeter', 40)).toDouble()));
  final roofHeight = math.max(2.0, math.min(15.0, (normalized['roofHeight'] ?? _defaultFor(spec, 'roofHeight', 5)).toDouble()));
  final funnels = (normalized['funnels'] ?? _defaultFor(spec, 'funnels', 4)).round().clamp(1, 20);
  final gutterDia = (normalized['gutterDia'] ?? _defaultFor(spec, 'gutterDia', 90)).round().clamp(75, 125);
  final gutterLength = (normalized['gutterLength'] ?? _defaultFor(spec, 'gutterLength', 3)).round().clamp(3, 4);

  // Gutters
  final gutterPcs = (roofPerimeter / gutterLength * spec.materialRules.gutterReserve).ceil();

  // Pipes
  final pipePerFunnel = (roofHeight / gutterLength).ceil() + 1;
  final pipePcs = pipePerFunnel * funnels;

  // Gutter joints
  final gutterJoints = (roofPerimeter / gutterLength).ceil() - 1;

  // Hooks
  final gutterHooks = (roofPerimeter / spec.materialRules.hookStepM * spec.materialRules.hookReserve).ceil();

  // Pipe clamps
  final pipeClamps = (roofHeight / spec.materialRules.pipeClampStepM * funnels * spec.materialRules.pipeClampReserve).ceil();

  // Corners
  final corners = spec.materialRules.buildingCorners;

  // Knee elbows
  final kneeElbows = funnels;

  // End caps
  final endCaps = funnels;

  // Connectors
  final connectors = (gutterJoints * spec.materialRules.connectorReserve).ceil();

  // Sealant
  final sealantTubes = ((gutterJoints + funnels * 2) / spec.materialRules.sealantConnectionsPerTube).ceil();

  // Primary quantity for scenarios
  final primaryQuantity = gutterPcs;
  final primaryLabel = 'gutter-${gutterDia}mm-${gutterLength}m';
  const primaryUnit = 'шт';

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(primaryQuantity * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'gutterDia:$gutterDia',
        'gutterLength:$gutterLength',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: primaryLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: primaryUnit,
      ),
    );
  }

  // Warnings
  final warnings = <String>[];
  final recommendedFunnels = (roofPerimeter / spec.warningRules.recommendedFunnelIntervalM).ceil();
  if (funnels < recommendedFunnels) {
    warnings.add('Недостаточно воронок: рекомендуется минимум $recommendedFunnels шт. (1 на каждые ${spec.warningRules.recommendedFunnelIntervalM.round()} м периметра) для достаточного водоотведения');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Желоб водосточный (ø$gutterDia мм, $gutterLength м)',
      quantity: gutterPcs.toDouble(),
      unit: 'шт',
      withReserve: gutterPcs.toDouble(),
      purchaseQty: gutterPcs,
      category: 'Желоба',
    ),
    CanonicalMaterialResult(
      name: 'Труба водосточная (ø$gutterDia мм, $gutterLength м)',
      quantity: pipePcs.toDouble(),
      unit: 'шт',
      withReserve: pipePcs.toDouble(),
      purchaseQty: pipePcs,
      category: 'Трубы',
    ),
    CanonicalMaterialResult(
      name: 'Воронки водосборные',
      quantity: funnels.toDouble(),
      unit: 'шт',
      withReserve: funnels.toDouble(),
      purchaseQty: funnels,
      category: 'Воронки',
    ),
    CanonicalMaterialResult(
      name: 'Соединители желобов',
      quantity: connectors.toDouble(),
      unit: 'шт',
      withReserve: connectors.toDouble(),
      purchaseQty: connectors,
      category: 'Соединители',
    ),
    CanonicalMaterialResult(
      name: 'Колена водосточные',
      quantity: kneeElbows.toDouble(),
      unit: 'шт',
      withReserve: kneeElbows.toDouble(),
      purchaseQty: kneeElbows,
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Заглушки желоба (пары)',
      quantity: endCaps.toDouble(),
      unit: 'шт',
      withReserve: endCaps.toDouble(),
      purchaseQty: endCaps,
      category: 'Заглушки',
    ),
    CanonicalMaterialResult(
      name: 'Кронштейны желоба',
      quantity: gutterHooks.toDouble(),
      unit: 'шт',
      withReserve: gutterHooks.toDouble(),
      purchaseQty: gutterHooks,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Хомуты трубы',
      quantity: pipeClamps.toDouble(),
      unit: 'шт',
      withReserve: pipeClamps.toDouble(),
      purchaseQty: pipeClamps,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Угловые элементы',
      quantity: corners.toDouble(),
      unit: 'шт',
      withReserve: corners.toDouble(),
      purchaseQty: corners,
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (${spec.materialRules.sealantTubeMl} мл)',
      quantity: sealantTubes.toDouble(),
      unit: 'тюбиков',
      withReserve: sealantTubes.toDouble(),
      purchaseQty: sealantTubes,
      category: 'Герметизация',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofPerimeter': _roundValue(roofPerimeter, 3),
      'roofHeight': _roundValue(roofHeight, 3),
      'funnels': funnels.toDouble(),
      'gutterDia': gutterDia.toDouble(),
      'gutterLength': gutterLength.toDouble(),
      'gutterPcs': gutterPcs.toDouble(),
      'pipePcs': pipePcs.toDouble(),
      'pipePerFunnel': pipePerFunnel.toDouble(),
      'gutterJoints': gutterJoints.toDouble(),
      'gutterHooks': gutterHooks.toDouble(),
      'pipeClamps': pipeClamps.toDouble(),
      'corners': corners.toDouble(),
      'kneeElbows': kneeElbows.toDouble(),
      'endCaps': endCaps.toDouble(),
      'connectors': connectors.toDouble(),
      'sealantTubes': sealantTubes.toDouble(),
      'recommendedFunnels': recommendedFunnels.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
