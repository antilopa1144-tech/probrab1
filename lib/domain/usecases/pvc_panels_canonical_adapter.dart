import '../models/canonical_calculator_contract.dart';

/* ─── spec instance ─── */

const PvcPanelsCanonicalSpec pvcPanelsCanonicalSpecV1 = PvcPanelsCanonicalSpec(
  calculatorId: 'pvc-panels',
  formulaVersion: 'pvc-panels-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 15, min: 1, max: 500),
    CanonicalInputField(key: 'wallWidth', unit: 'm', defaultValue: 3, min: 0.5, max: 30),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.5, min: 0.5, max: 10),
    CanonicalInputField(key: 'panelWidth', unit: 'm', defaultValue: 0.25, min: 0.1, max: 0.5),
    CanonicalInputField(key: 'panelType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'needProfile', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'needCorners', defaultValue: 1, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: PvcPanelsPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: PvcPanelsMaterialRules(
    panelReserve: 1.10,
    profileReserve: 1.10,
    profileStep: 0.4,
    panelLengths: [2.7, 3.0, 2.7],
    cornerProfileLength: 3.0,
    standardCorners: 4,
  ),
  warningRules: PvcPanelsWarningRules(largeAreaThresholdM2: 100),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(PvcPanelsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(PvcPanelsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(PvcPanelsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalPvcPanels(
  Map<String, double> inputs, {
  PvcPanelsCanonicalSpec spec = pvcPanelsCanonicalSpecV1,
}) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? _defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 3)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.5)).clamp(0.5, 10.0);
  final panelWidth = (inputs['panelWidth'] ?? _defaultFor(spec, 'panelWidth', 0.25)).clamp(0.1, 0.5);
  final panelType = (inputs['panelType'] ?? _defaultFor(spec, 'panelType', 0)).round().clamp(0, 2);
  final needProfile = (inputs['needProfile'] ?? _defaultFor(spec, 'needProfile', 1)).round() == 1 ? 1 : 0;
  final needCorners = (inputs['needCorners'] ?? _defaultFor(spec, 'needCorners', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? _roundValue(wallWidth * wallHeight, 3) : areaInput;

  // Panels
  final panelLength = panelType < spec.materialRules.panelLengths.length
      ? spec.materialRules.panelLengths[panelType]
      : spec.materialRules.panelLengths[0];
  final panelArea = panelWidth * panelLength;
  final panels = (area * spec.materialRules.panelReserve / panelArea).ceil();

  // Profile (conditional)
  final profileRows = needProfile == 1 ? (wallHeight / spec.materialRules.profileStep).ceil() + 1 : 0;
  final profileLen = profileRows * wallWidth * spec.materialRules.profileReserve;

  // Corner profile (conditional)
  final cornerPcs = needCorners == 1
      ? (wallHeight * spec.materialRules.standardCorners / spec.materialRules.cornerProfileLength).ceil()
      : 0;

  // Start profile
  final startProfile = wallWidth * 1.05;

  // Plinth
  final plinthLen = wallWidth * 2;

  // Scenarios
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
        'inputMode:$inputMode',
        'panelType:$panelType',
        'needProfile:$needProfile',
        'needCorners:$needCorners',
        'packaging:pvc-panel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'pvc-panel',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку панелей');
  }
  if (panelType == 2) {
    warnings.add('Для ванной комнаты используйте влагостойкие ПВХ-панели');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ПВХ-панели',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
  ];

  if (needProfile == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Профиль обрешётки (п.м.)',
      quantity: _roundValue(profileLen, 2),
      unit: 'п.м.',
      withReserve: profileLen.ceilToDouble(),
      purchaseQty: profileLen.ceil(),
      category: 'Подсистема',
    ));
  }

  if (needCorners == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Угловой профиль',
      quantity: cornerPcs.toDouble(),
      unit: 'шт',
      withReserve: cornerPcs.toDouble(),
      purchaseQty: cornerPcs,
      category: 'Профиль',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Стартовый профиль (п.м.)',
      quantity: _roundValue(startProfile, 2),
      unit: 'п.м.',
      withReserve: startProfile.ceilToDouble(),
      purchaseQty: startProfile.ceil(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус (п.м.)',
      quantity: _roundValue(plinthLen, 2),
      unit: 'п.м.',
      withReserve: plinthLen.ceilToDouble(),
      purchaseQty: plinthLen.ceil(),
      category: 'Профиль',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'wallWidth': _roundValue(wallWidth, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'panelWidth': _roundValue(panelWidth, 3),
      'panelType': panelType.toDouble(),
      'needProfile': needProfile.toDouble(),
      'needCorners': needCorners.toDouble(),
      'panelLength': panelLength,
      'panelArea': _roundValue(panelArea, 4),
      'panels': panels.toDouble(),
      'profileRows': profileRows.toDouble(),
      'profileLen': _roundValue(profileLen, 3),
      'cornerPcs': cornerPcs.toDouble(),
      'startProfile': _roundValue(startProfile, 3),
      'plinthLen': _roundValue(plinthLen, 3),
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
