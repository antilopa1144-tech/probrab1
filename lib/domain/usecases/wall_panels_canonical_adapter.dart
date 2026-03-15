import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class WallPanelsPackagingRules {
  final String unit;
  final int packageSize;

  const WallPanelsPackagingRules({required this.unit, required this.packageSize});
}

class WallPanelsMaterialRules {
  final Map<int, double> panelAreas;
  final double panelReserve;
  final double glueCoverage;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final Map<int, double> battenSpacing;
  final double battenLength;
  final double battenReserve;
  final double dubelStep;
  final int klaymerPerM2;
  final double moldingLength;
  final double moldingReserve;
  final double sealantPerPerim;

  const WallPanelsMaterialRules({
    required this.panelAreas,
    required this.panelReserve,
    required this.glueCoverage,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.battenSpacing,
    required this.battenLength,
    required this.battenReserve,
    required this.dubelStep,
    required this.klaymerPerM2,
    required this.moldingLength,
    required this.moldingReserve,
    required this.sealantPerPerim,
  });
}

class WallPanelsWarningRules {
  final double largeAreaThresholdM2;
  final List<int> flatSurfaceWarningPanelTypes;

  const WallPanelsWarningRules({required this.largeAreaThresholdM2, required this.flatSurfaceWarningPanelTypes});
}

class WallPanelsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final WallPanelsPackagingRules packagingRules;
  final WallPanelsMaterialRules materialRules;
  final WallPanelsWarningRules warningRules;

  const WallPanelsCanonicalSpec({
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

const WallPanelsCanonicalSpec wallPanelsCanonicalSpecV1 = WallPanelsCanonicalSpec(
  calculatorId: 'wall-panels',
  formulaVersion: 'wall-panels-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 200),
    CanonicalInputField(key: 'panelType', defaultValue: 0, min: 0, max: 4),
    CanonicalInputField(key: 'mountMethod', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 4),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: WallPanelsPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: WallPanelsMaterialRules(
    panelAreas: {0: 0.75, 1: 0.494, 2: 0.25, 3: 0.3, 4: 0.5},
    panelReserve: 1.1,
    glueCoverage: 4,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCan: 10,
    battenSpacing: {0: 0.5, 1: 0.5, 2: 0.4, 3: 0.4, 4: 0.4},
    battenLength: 3,
    battenReserve: 1.05,
    dubelStep: 0.5,
    klaymerPerM2: 5,
    moldingLength: 3,
    moldingReserve: 1.05,
    sealantPerPerim: 10,
  ),
  warningRules: WallPanelsWarningRules(largeAreaThresholdM2: 100, flatSurfaceWarningPanelTypes: [2]),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _panelTypeLabels = {
  0: 'ПВХ-панели (0.75 м\u00b2)',
  1: 'МДФ-панели (0.494 м\u00b2)',
  2: '3D-панели (0.25 м\u00b2)',
  3: 'Деревянные панели (0.3 м\u00b2)',
  4: 'Каменный шпон (0.5 м\u00b2)',
};

/* ─── helpers ─── */

bool hasCanonicalWallPanelsInputs(Map<String, double> inputs) {
  return inputs.containsKey('panelType') ||
      inputs.containsKey('area') ||
      inputs.containsKey('mountMethod');
}

Map<String, double> normalizeLegacyWallPanelsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 20).toDouble();
  normalized['panelType'] = (inputs['panelType'] ?? 0).toDouble();
  normalized['mountMethod'] = (inputs['mountMethod'] ?? 0).toDouble();
  normalized['height'] = (inputs['height'] ?? 2.7).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WallPanelsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(WallPanelsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WallPanelsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalWallPanels(
  Map<String, double> inputs, {
  WallPanelsCanonicalSpec spec = wallPanelsCanonicalSpecV1,
}) {
  final normalized = hasCanonicalWallPanelsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyWallPanelsInputs(inputs);

  final area = (normalized['area'] ?? _defaultFor(spec, 'area', 20)).round().clamp(1, 200);
  final panelType = (normalized['panelType'] ?? _defaultFor(spec, 'panelType', 0)).round().clamp(0, 4);
  final mountMethod = (normalized['mountMethod'] ?? _defaultFor(spec, 'mountMethod', 0)).round().clamp(0, 1);
  final height = (normalized['height'] ?? _defaultFor(spec, 'height', 2.7)).clamp(2.0, 4.0);

  // Panel area
  final panelArea = spec.materialRules.panelAreas[panelType] ?? 0.75;
  final battenSpacing = spec.materialRules.battenSpacing[panelType] ?? 0.5;

  // Common formulas
  final panels = (area * spec.materialRules.panelReserve / panelArea).ceil();
  final perim = math.sqrt(area) * 4;

  // Mount-specific
  var glueBottles = 0;
  var primer = 0;
  var battenRows = 0;
  double wallLength = 0;
  double battenM = 0;
  var battenPcs = 0;
  var dubels = 0;
  var klaimers = 0;

  if (mountMethod == 0) {
    // Glue
    glueBottles = (area / spec.materialRules.glueCoverage).ceil();
    primer = (area * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCan).ceil();
  } else {
    // Batten frame
    battenRows = (height / battenSpacing).ceil() + 1;
    wallLength = area / height;
    battenM = battenRows * wallLength * spec.materialRules.battenReserve;
    battenPcs = (battenM / spec.materialRules.battenLength).ceil();
    dubels = (battenM / spec.materialRules.dubelStep).ceil();
    klaimers = (area * spec.materialRules.klaymerPerM2).ceil();
  }

  // All methods
  final molding = (perim * spec.materialRules.moldingReserve / spec.materialRules.moldingLength).ceil();
  final sealant = (perim / spec.materialRules.sealantPerPerim).ceil();

  // Scenarios
  const packageLabel = 'wall-panel';
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
        'panelType:$panelType',
        'mountMethod:$mountMethod',
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
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку панелей');
  }
  if (spec.warningRules.flatSurfaceWarningPanelTypes.contains(panelType) && mountMethod == 0) {
    warnings.add('3D-панели на клей — убедитесь в ровности основания');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_panelTypeLabels[panelType]}',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
  ];

  if (mountMethod == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Монтажный клей (флаконы)',
        quantity: glueBottles.toDouble(),
        unit: 'шт',
        withReserve: glueBottles.toDouble(),
        purchaseQty: glueBottles,
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка (канистра ${spec.materialRules.primerCan.round()} л)',
        quantity: primer.toDouble(),
        unit: 'канистр',
        withReserve: primer.toDouble(),
        purchaseQty: primer,
        category: 'Грунтовка',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Обрешётка (бруски ${spec.materialRules.battenLength.round()} м)',
        quantity: battenPcs.toDouble(),
        unit: 'шт',
        withReserve: battenPcs.toDouble(),
        purchaseQty: battenPcs,
        category: 'Подсистема',
      ),
      CanonicalMaterialResult(
        name: 'Дюбели для обрешётки',
        quantity: dubels.toDouble(),
        unit: 'шт',
        withReserve: dubels.toDouble(),
        purchaseQty: dubels,
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Кляймеры',
        quantity: klaimers.toDouble(),
        unit: 'шт',
        withReserve: klaimers.toDouble(),
        purchaseQty: klaimers,
        category: 'Крепёж',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Молдинги (${spec.materialRules.moldingLength.round()} м)',
      quantity: molding.toDouble(),
      unit: 'шт',
      withReserve: molding.toDouble(),
      purchaseQty: molding,
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealant.toDouble(),
      unit: 'шт',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant,
      category: 'Монтаж',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area.toDouble(),
      'panelType': panelType.toDouble(),
      'mountMethod': mountMethod.toDouble(),
      'height': height,
      'panelArea': panelArea,
      'battenSpacing': battenSpacing,
      'panels': panels.toDouble(),
      'perim': _roundValue(perim, 4),
      'glueBottles': glueBottles.toDouble(),
      'primer': primer.toDouble(),
      'battenRows': battenRows.toDouble(),
      'wallLength': _roundValue(wallLength, 4),
      'battenM': _roundValue(battenM, 4),
      'battenPcs': battenPcs.toDouble(),
      'dubels': dubels.toDouble(),
      'klaimers': klaimers.toDouble(),
      'molding': molding.toDouble(),
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
