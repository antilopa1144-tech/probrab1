import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class GypsumBoardPackagingRules {
  final String unit;
  final double packageSize;

  const GypsumBoardPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class GypsumBoardMaterialRules {
  final double sheetArea;
  final double sheetReserve;
  final double ppStepDefault;
  final double screwsGklPerSheet;
  final double dubelStep;
  final double dubelReserve;
  final double serpyankaReserve;
  final double puttyPerSerpyanka;
  final double puttyBag;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final double profileLength;

  const GypsumBoardMaterialRules({
    required this.sheetArea,
    required this.sheetReserve,
    required this.ppStepDefault,
    required this.screwsGklPerSheet,
    required this.dubelStep,
    required this.dubelReserve,
    required this.serpyankaReserve,
    required this.puttyPerSerpyanka,
    required this.puttyBag,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.profileLength,
  });
}

class GypsumBoardWarningRules {
  final double largeAreaThresholdM2;
  final bool doubleLayerNote;

  const GypsumBoardWarningRules({
    required this.largeAreaThresholdM2,
    required this.doubleLayerNote,
  });
}

class GypsumBoardCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final GypsumBoardPackagingRules packagingRules;
  final GypsumBoardMaterialRules materialRules;
  final GypsumBoardWarningRules warningRules;

  const GypsumBoardCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const GypsumBoardCanonicalSpec gypsumBoardCanonicalSpecV1 = GypsumBoardCanonicalSpec(
  calculatorId: 'gypsum-board',
  formulaVersion: 'gypsum-board-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm²', defaultValue: 40, min: 1, max: 1000),
    CanonicalInputField(key: 'constructionType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'layers', defaultValue: 1, min: 1, max: 2),
    CanonicalInputField(key: 'gklType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'profileStep', unit: 'mm', defaultValue: 600, min: 400, max: 600),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: GypsumBoardPackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: GypsumBoardMaterialRules(
    sheetArea: 3.0,
    sheetReserve: 1.1,
    ppStepDefault: 600,
    screwsGklPerSheet: 24,
    dubelStep: 0.5,
    dubelReserve: 1.1,
    serpyankaReserve: 1.1,
    puttyPerSerpyanka: 0.025,
    puttyBag: 25,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCan: 10,
    profileLength: 3,
  ),
  warningRules: GypsumBoardWarningRules(
    largeAreaThresholdM2: 200,
    doubleLayerNote: true,
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

double _defaultFor(GypsumBoardCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(GypsumBoardCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(GypsumBoardCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalGypsumBoard(
  Map<String, double> inputs, {
  GypsumBoardCanonicalSpec spec = gypsumBoardCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(1000.0, inputs['area'] ?? _defaultFor(spec, 'area', 40)));
  final constructionType = (inputs['constructionType'] ?? _defaultFor(spec, 'constructionType', 0)).round().clamp(0, 2);
  final layersRaw = (inputs['layers'] ?? _defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final gklType = (inputs['gklType'] ?? _defaultFor(spec, 'gklType', 0)).round().clamp(0, 2);
  final profileStepRaw = (inputs['profileStep'] ?? _defaultFor(spec, 'profileStep', 600)).round();
  final profileStep = profileStepRaw <= 400 ? 400 : 600;
  final stepM = profileStep / 1000.0;

  // Sheets
  final sheetsOneSide = (area * layers / spec.materialRules.sheetArea * spec.materialRules.sheetReserve).ceil();
  final totalSheets = constructionType == 1 ? sheetsOneSide * 2 : sheetsOneSide;
  final sides = constructionType == 1 ? 2 : 1;

  // Height estimate
  final height = constructionType == 2
      ? 1.0
      : math.sqrt(area / 1.5).clamp(2.5, 4.0);
  final wallLength = area / height;

  // PP profiles
  final ppCount = constructionType == 2
      ? (wallLength / stepM).ceil() * (height / stepM).ceil()
      : (wallLength / stepM).ceil() + 1;
  final ppMeters = ppCount * height;
  final ppPcs = (ppMeters * 1.05 / spec.materialRules.profileLength).ceil();

  // PN guide profiles
  final guideM = constructionType == 1
      ? (wallLength + height) * 2 * 2
      : (wallLength + height) * 2;
  final guidePcs = (guideM * 1.05 / spec.materialRules.profileLength).ceil();

  // Screws & dubels
  final screws = (totalSheets * spec.materialRules.screwsGklPerSheet).round();
  final dubels = (guideM / spec.materialRules.dubelStep * 2 * spec.materialRules.dubelReserve).ceil();

  // Serpyanka
  final jointsM = (totalSheets * height * layers * spec.materialRules.serpyankaReserve).ceil();
  final puttyBags = (jointsM / 10 / spec.materialRules.puttyBag).ceil();

  // Primer
  final primerCans = (area * sides * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCan).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalSheets * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'gkl-sheet-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'constructionType:$constructionType',
        'gklType:$gklType',
        'layers:$layers',
        'profileStep:$profileStep',
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
  if (layers == 2) {
    warnings.add('\u0412\u0442\u043e\u0440\u043e\u0439 \u0441\u043b\u043e\u0439 \u0413\u041a\u041b \u043c\u043e\u043d\u0442\u0438\u0440\u0443\u0435\u0442\u0441\u044f \u0441\u043e \u0441\u043c\u0435\u0449\u0435\u043d\u0438\u0435\u043c \u0448\u0432\u043e\u0432');
  }

  final gklTypeLabels = {0: '\u0413\u041a\u041b \u0441\u0442\u0430\u043d\u0434\u0430\u0440\u0442\u043d\u044b\u0439', 1: '\u0413\u041a\u041b\u0412 \u0432\u043b\u0430\u0433\u043e\u0441\u0442\u043e\u0439\u043a\u0438\u0439', 2: '\u0413\u041a\u041b\u041e \u043e\u0433\u043d\u0435\u0441\u0442\u043e\u0439\u043a\u0438\u0439'};

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: gklTypeLabels[gklType] ?? '\u0413\u041a\u041b',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u041f\u041f 60\u00d727 3\u043c',
      quantity: ppPcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: ppPcs.toDouble(),
      purchaseQty: ppPcs,
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u041f\u041d 27\u00d728 3\u043c',
      quantity: guidePcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: guidePcs.toDouble(),
      purchaseQty: guidePcs,
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u0421\u0430\u043c\u043e\u0440\u0435\u0437\u044b \u0434\u043b\u044f \u0413\u041a\u041b',
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
    CanonicalMaterialResult(
      name: '\u0421\u0435\u0440\u043f\u044f\u043d\u043a\u0430',
      quantity: jointsM.toDouble(),
      unit: '\u043c',
      withReserve: jointsM.toDouble(),
      purchaseQty: jointsM,
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u0428\u043f\u0430\u043a\u043b\u0451\u0432\u043a\u0430 25 \u043a\u0433',
      quantity: puttyBags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: puttyBags.toDouble(),
      purchaseQty: puttyBags,
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u0440\u0443\u043d\u0442\u043e\u0432\u043a\u0430 10 \u043b',
      quantity: primerCans.toDouble(),
      unit: '\u043a\u0430\u043d\u0438\u0441\u0442\u0440',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'constructionType': constructionType.toDouble(),
      'layers': layers.toDouble(),
      'gklType': gklType.toDouble(),
      'profileStep': profileStep.toDouble(),
      'sides': sides.toDouble(),
      'height': _roundValue(height, 3),
      'wallLength': _roundValue(wallLength, 3),
      'sheetsOneSide': sheetsOneSide.toDouble(),
      'totalSheets': totalSheets.toDouble(),
      'ppCount': ppCount.toDouble(),
      'ppPcs': ppPcs.toDouble(),
      'guidePcs': guidePcs.toDouble(),
      'guideM': _roundValue(guideM, 3),
      'screws': screws.toDouble(),
      'dubels': dubels.toDouble(),
      'jointsM': jointsM.toDouble(),
      'puttyBags': puttyBags.toDouble(),
      'primerCans': primerCans.toDouble(),
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
