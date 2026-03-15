import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class WindowsPackagingRules {
  final String unit;
  final int packageSize;

  const WindowsPackagingRules({required this.unit, required this.packageSize});
}

class WindowsMaterialRules {
  final double psulRollM;
  final double iflulRollM;
  final double psulReserve;
  final double anchorStep;
  final double foamPerPerim;
  final double foamReserve;
  final double windowsillOverhang;
  final double windowsillRoll;
  final double sandwichPanelM2;
  final double gklSheetM2;
  final double plasterKgPerM2;
  final double plasterBag;
  final double slopeSandwichReserve;
  final double slopeGklReserve;
  final double anchorReserve;
  final double screwReserve;
  final double fProfileLength;

  const WindowsMaterialRules({
    required this.psulRollM,
    required this.iflulRollM,
    required this.psulReserve,
    required this.anchorStep,
    required this.foamPerPerim,
    required this.foamReserve,
    required this.windowsillOverhang,
    required this.windowsillRoll,
    required this.sandwichPanelM2,
    required this.gklSheetM2,
    required this.plasterKgPerM2,
    required this.plasterBag,
    required this.slopeSandwichReserve,
    required this.slopeGklReserve,
    required this.anchorReserve,
    required this.screwReserve,
    required this.fProfileLength,
  });
}

class WindowsWarningRules {
  final int wideWindowThresholdMm;
  final int thickWallThresholdMm;

  const WindowsWarningRules({required this.wideWindowThresholdMm, required this.thickWallThresholdMm});
}

class WindowsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final WindowsPackagingRules packagingRules;
  final WindowsMaterialRules materialRules;
  final WindowsWarningRules warningRules;

  const WindowsCanonicalSpec({
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

const WindowsCanonicalSpec windowsCanonicalSpecV1 = WindowsCanonicalSpec(
  calculatorId: 'windows',
  formulaVersion: 'windows-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'windowCount', defaultValue: 5, min: 1, max: 20),
    CanonicalInputField(key: 'windowWidth', unit: 'mm', defaultValue: 1200, min: 600, max: 2100),
    CanonicalInputField(key: 'windowHeight', unit: 'mm', defaultValue: 1400, min: 900, max: 2000),
    CanonicalInputField(key: 'wallThickness', unit: 'mm', defaultValue: 500, min: 200, max: 600),
    CanonicalInputField(key: 'slopeType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: WindowsPackagingRules(unit: 'баллонов', packageSize: 1),
  materialRules: WindowsMaterialRules(
    psulRollM: 5.6,
    iflulRollM: 8.5,
    psulReserve: 1.1,
    anchorStep: 0.7,
    foamPerPerim: 0.333,
    foamReserve: 1.1,
    windowsillOverhang: 0.15,
    windowsillRoll: 6,
    sandwichPanelM2: 3.6,
    gklSheetM2: 3.0,
    plasterKgPerM2: 10,
    plasterBag: 25,
    slopeSandwichReserve: 1.1,
    slopeGklReserve: 1.12,
    anchorReserve: 1.05,
    screwReserve: 1.05,
    fProfileLength: 3,
  ),
  warningRules: WindowsWarningRules(wideWindowThresholdMm: 1800, thickWallThresholdMm: 500),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _slopeTypeLabels = {
  0: 'Сэндвич-панели ПВХ',
  1: 'Штукатурка',
  2: 'ГКЛ',
};

/* ─── helpers ─── */

bool hasCanonicalWindowsInputs(Map<String, double> inputs) {
  return inputs.containsKey('windowCount') ||
      inputs.containsKey('windowWidth') ||
      inputs.containsKey('slopeType');
}

Map<String, double> normalizeLegacyWindowsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['windowCount'] = (inputs['windowCount'] ?? 5).toDouble();
  normalized['windowWidth'] = (inputs['windowWidth'] ?? 1200).toDouble();
  normalized['windowHeight'] = (inputs['windowHeight'] ?? 1400).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 500).toDouble();
  normalized['slopeType'] = (inputs['slopeType'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WindowsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(WindowsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WindowsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalWindows(
  Map<String, double> inputs, {
  WindowsCanonicalSpec spec = windowsCanonicalSpecV1,
}) {
  final normalized = hasCanonicalWindowsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyWindowsInputs(inputs);

  final windowCount = (normalized['windowCount'] ?? _defaultFor(spec, 'windowCount', 5)).round().clamp(1, 20);
  final windowWidth = (normalized['windowWidth'] ?? _defaultFor(spec, 'windowWidth', 1200)).round().clamp(600, 2100);
  final windowHeight = (normalized['windowHeight'] ?? _defaultFor(spec, 'windowHeight', 1400)).round().clamp(900, 2000);
  final wallThickness = (normalized['wallThickness'] ?? _defaultFor(spec, 'wallThickness', 500)).round().clamp(200, 600);
  final slopeType = (normalized['slopeType'] ?? _defaultFor(spec, 'slopeType', 0)).round().clamp(0, 2);

  // Geometry
  final perimM = 2 * (windowWidth + windowHeight) / 1000;

  // PSUL / IFLUL
  final psulRolls = (perimM * windowCount * spec.materialRules.psulReserve / spec.materialRules.psulRollM).ceil();
  final iflulRolls = (perimM * windowCount * spec.materialRules.psulReserve / spec.materialRules.iflulRollM).ceil();

  // Foam
  final foamCans = (perimM / 3 * windowCount * spec.materialRules.foamReserve).ceil();

  // Anchors & screws
  final anchorsPerWindow = (perimM / spec.materialRules.anchorStep).ceil();
  final totalAnchors = (anchorsPerWindow * windowCount * spec.materialRules.anchorReserve).ceil();
  final screws = (totalAnchors * 2 * spec.materialRules.screwReserve).ceil();

  // Windowsill
  final sillWidth = wallThickness / 1000 + spec.materialRules.windowsillOverhang;
  final sillPcs = windowCount;

  // Slopes
  final slopeSideArea = 2 * (windowHeight / 1000) * (wallThickness / 1000);
  final slopeTopArea = (windowWidth / 1000) * (wallThickness / 1000);
  final totalSlopeArea = (slopeSideArea + slopeTopArea) * windowCount;

  // Slope materials by type
  var sandwichPcs = 0;
  var fProfilePcs = 0;
  var plasterBags = 0;
  var cornerPcs = 0;
  var gklSheets = 0;
  var screwsGKL = 0;
  var puttyBags = 0;

  if (slopeType == 0) {
    sandwichPcs = (totalSlopeArea * spec.materialRules.slopeSandwichReserve / spec.materialRules.sandwichPanelM2).ceil();
    final fProfileLen = perimM * 0.75 * windowCount * spec.materialRules.psulReserve;
    fProfilePcs = (fProfileLen / spec.materialRules.fProfileLength).ceil();
  } else if (slopeType == 1) {
    plasterBags = (totalSlopeArea * spec.materialRules.plasterKgPerM2 / spec.materialRules.plasterBag).ceil();
    cornerPcs = (perimM * 0.75 * windowCount * spec.materialRules.psulReserve / 3).ceil();
  } else {
    gklSheets = (totalSlopeArea * spec.materialRules.slopeGklReserve / spec.materialRules.gklSheetM2).ceil();
    screwsGKL = (gklSheets * 20 * spec.materialRules.screwReserve).ceil();
    puttyBags = (totalSlopeArea * 1.2 / spec.materialRules.plasterBag).ceil();
  }

  // Scenarios
  final basePrimary = foamCans;
  const packageLabel = 'foam-can';
  const packageUnit = 'баллонов';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'slopeType:$slopeType',
        'windowWidth:$windowWidth',
        'windowHeight:$windowHeight',
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
  if (windowWidth >= spec.warningRules.wideWindowThresholdMm) {
    warnings.add('Для широких окон рекомендуется усиленный монтаж');
  }
  if (wallThickness >= spec.warningRules.thickWallThresholdMm) {
    warnings.add('Толстые стены — проверьте глубину подоконника');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ПСУЛ (рулон ${spec.materialRules.psulRollM} м)',
      quantity: psulRolls.toDouble(),
      unit: 'рулонов',
      withReserve: psulRolls.toDouble(),
      purchaseQty: psulRolls,
      category: 'Лента',
    ),
    CanonicalMaterialResult(
      name: 'Внутренняя лента (рулон ${spec.materialRules.iflulRollM} м)',
      quantity: iflulRolls.toDouble(),
      unit: 'рулонов',
      withReserve: iflulRolls.toDouble(),
      purchaseQty: iflulRolls,
      category: 'Лента',
    ),
    CanonicalMaterialResult(
      name: 'Монтажная пена',
      quantity: recScenario.exactNeed,
      unit: 'баллонов',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Анкерные пластины',
      quantity: totalAnchors.toDouble(),
      unit: 'шт',
      withReserve: totalAnchors.toDouble(),
      purchaseQty: totalAnchors,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы для анкеров',
      quantity: screws.toDouble(),
      unit: 'шт',
      withReserve: screws.toDouble(),
      purchaseQty: screws,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Подоконник (ширина ${(sillWidth * 1000).round()} мм)',
      quantity: sillPcs.toDouble(),
      unit: 'шт',
      withReserve: sillPcs.toDouble(),
      purchaseQty: sillPcs,
      category: 'Подоконники',
    ),
  ];

  if (slopeType == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_slopeTypeLabels[0]}',
        quantity: sandwichPcs.toDouble(),
        unit: 'шт',
        withReserve: sandwichPcs.toDouble(),
        purchaseQty: sandwichPcs,
        category: 'Откосы',
      ),
      CanonicalMaterialResult(
        name: 'F-профиль (${spec.materialRules.fProfileLength.round()} м)',
        quantity: fProfilePcs.toDouble(),
        unit: 'шт',
        withReserve: fProfilePcs.toDouble(),
        purchaseQty: fProfilePcs,
        category: 'Откосы',
      ),
    ]);
  } else if (slopeType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Штукатурка (мешки ${spec.materialRules.plasterBag.round()} кг)',
        quantity: plasterBags.toDouble(),
        unit: 'мешков',
        withReserve: plasterBags.toDouble(),
        purchaseQty: plasterBags,
        category: 'Откосы',
      ),
      CanonicalMaterialResult(
        name: 'Уголок перфорированный',
        quantity: cornerPcs.toDouble(),
        unit: 'шт',
        withReserve: cornerPcs.toDouble(),
        purchaseQty: cornerPcs,
        category: 'Откосы',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ГКЛ для откосов',
        quantity: gklSheets.toDouble(),
        unit: 'листов',
        withReserve: gklSheets.toDouble(),
        purchaseQty: gklSheets,
        category: 'Откосы',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы для ГКЛ',
        quantity: screwsGKL.toDouble(),
        unit: 'шт',
        withReserve: screwsGKL.toDouble(),
        purchaseQty: screwsGKL,
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (мешки ${spec.materialRules.plasterBag.round()} кг)',
        quantity: puttyBags.toDouble(),
        unit: 'мешков',
        withReserve: puttyBags.toDouble(),
        purchaseQty: puttyBags,
        category: 'Откосы',
      ),
    ]);
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'windowCount': windowCount.toDouble(),
      'windowWidth': windowWidth.toDouble(),
      'windowHeight': windowHeight.toDouble(),
      'wallThickness': wallThickness.toDouble(),
      'slopeType': slopeType.toDouble(),
      'perimM': _roundValue(perimM, 3),
      'psulRolls': psulRolls.toDouble(),
      'iflulRolls': iflulRolls.toDouble(),
      'foamCans': foamCans.toDouble(),
      'anchorsPerWindow': anchorsPerWindow.toDouble(),
      'totalAnchors': totalAnchors.toDouble(),
      'screws': screws.toDouble(),
      'sillWidth': _roundValue(sillWidth, 3),
      'sillPcs': sillPcs.toDouble(),
      'slopeSideArea': _roundValue(slopeSideArea, 4),
      'slopeTopArea': _roundValue(slopeTopArea, 4),
      'totalSlopeArea': _roundValue(totalSlopeArea, 4),
      'sandwichPcs': sandwichPcs.toDouble(),
      'fProfilePcs': fProfilePcs.toDouble(),
      'plasterBags': plasterBags.toDouble(),
      'cornerPcs': cornerPcs.toDouble(),
      'gklSheets': gklSheets.toDouble(),
      'screwsGKL': screwsGKL.toDouble(),
      'puttyBags': puttyBags.toDouble(),
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
