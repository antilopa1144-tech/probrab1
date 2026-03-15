import '../models/canonical_calculator_contract.dart';

/* ─── spec instance ─── */

const MdfPanelsCanonicalSpec mdfPanelsCanonicalSpecV1 = MdfPanelsCanonicalSpec(
  calculatorId: 'mdf-panels',
  formulaVersion: 'mdf-panels-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 500),
    CanonicalInputField(key: 'wallWidth', unit: 'm', defaultValue: 4, min: 0.5, max: 30),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 0.5, max: 10),
    CanonicalInputField(key: 'panelWidth', unit: 'm', defaultValue: 0.25, min: 0.1, max: 0.4),
    CanonicalInputField(key: 'panelType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'needProfile', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'needPlinth', defaultValue: 1, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: MdfPanelsPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: MdfPanelsMaterialRules(
    panelReserve: 1.10,
    profileReserve: 1.10,
    profileStep: 0.5,
    standardPanelLength: 2.7,
    clipsPerPanel: 5,
    plinthLength: 2.7,
    plinthExtra: 2.0,
  ),
  warningRules: MdfPanelsWarningRules(largeAreaThresholdM2: 100),
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

double _defaultFor(MdfPanelsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(MdfPanelsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(MdfPanelsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalMdfPanels(
  Map<String, double> inputs, {
  MdfPanelsCanonicalSpec spec = mdfPanelsCanonicalSpecV1,
}) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? _defaultFor(spec, 'area', 20)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 4)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).clamp(0.5, 10.0);
  final panelWidth = (inputs['panelWidth'] ?? _defaultFor(spec, 'panelWidth', 0.25)).clamp(0.1, 0.4);
  final panelType = (inputs['panelType'] ?? _defaultFor(spec, 'panelType', 0)).round().clamp(0, 2);
  final needProfile = (inputs['needProfile'] ?? _defaultFor(spec, 'needProfile', 1)).round() == 1 ? 1 : 0;
  final needPlinth = (inputs['needPlinth'] ?? _defaultFor(spec, 'needPlinth', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? _roundValue(wallWidth * wallHeight, 3) : areaInput;

  // Panels
  final panelArea = panelWidth * spec.materialRules.standardPanelLength;
  final panels = (area * spec.materialRules.panelReserve / panelArea).ceil();

  // Clips
  final clips = panels * spec.materialRules.clipsPerPanel;

  // Profile (conditional)
  final profileRows = needProfile == 1 ? (wallHeight / spec.materialRules.profileStep).ceil() + 1 : 0;
  final profileLen = profileRows * wallWidth * spec.materialRules.profileReserve;

  // Plinth (conditional)
  final plinthLen = needPlinth == 1 ? wallWidth * 2 + spec.materialRules.plinthExtra : 0.0;
  final plinthPcs = (plinthLen / spec.materialRules.plinthLength).ceil();

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
        'needPlinth:$needPlinth',
        'packaging:mdf-panel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'mdf-panel',
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
  if (panelType == 0) {
    warnings.add('Стандартные МДФ-панели не рекомендуются для влажных помещений');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'МДФ-панели',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры (клипсы)',
      quantity: clips.toDouble(),
      unit: 'шт',
      withReserve: clips.toDouble(),
      purchaseQty: clips,
      category: 'Крепёж',
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

  if (needPlinth == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Плинтус',
      quantity: plinthPcs.toDouble(),
      unit: 'шт',
      withReserve: plinthPcs.toDouble(),
      purchaseQty: plinthPcs,
      category: 'Профиль',
    ));
  }

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
      'needPlinth': needPlinth.toDouble(),
      'panelArea': _roundValue(panelArea, 4),
      'panels': panels.toDouble(),
      'clips': clips.toDouble(),
      'profileRows': profileRows.toDouble(),
      'profileLen': _roundValue(profileLen, 3),
      'plinthLen': _roundValue(plinthLen, 3),
      'plinthPcs': plinthPcs.toDouble(),
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
