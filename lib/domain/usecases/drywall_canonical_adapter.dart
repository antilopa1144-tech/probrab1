import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class DrywallSheetSizeSpec {
  final int id;
  final double w;
  final double h;
  final double area;

  const DrywallSheetSizeSpec({
    required this.id,
    required this.w,
    required this.h,
    required this.area,
  });
}

class DrywallPackagingRules {
  final String unit;
  final double packageSize;

  const DrywallPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class DrywallMaterialRules {
  final double sheetReserve;
  final double profileReserve;
  final double screwsTfPerM2;
  final double screwsLbPerProfile;
  final double dowelsStepM;
  final double puttyStartKgPerM2;
  final double puttyFinishKgPerM2;
  final double puttyReserve;
  final double puttyBagKg;
  final double serpyankaMPerSheet;
  final double serpyankaReserve;
  final double serpyankaRollM;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCanL;
  final double sandpaperM2PerSheet;
  final double sandpaperPack;
  final double profileLengthM;
  final double sealingTapeRollM;

  const DrywallMaterialRules({
    required this.sheetReserve,
    required this.profileReserve,
    required this.screwsTfPerM2,
    required this.screwsLbPerProfile,
    required this.dowelsStepM,
    required this.puttyStartKgPerM2,
    required this.puttyFinishKgPerM2,
    required this.puttyReserve,
    required this.puttyBagKg,
    required this.serpyankaMPerSheet,
    required this.serpyankaReserve,
    required this.serpyankaRollM,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCanL,
    required this.sandpaperM2PerSheet,
    required this.sandpaperPack,
    required this.profileLengthM,
    required this.sealingTapeRollM,
  });
}

class DrywallWarningRules {
  final double wideProfileHeightThreshold;

  const DrywallWarningRules({
    required this.wideProfileHeightThreshold,
  });
}

class DrywallCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final Map<int, DrywallSheetSizeSpec> sheetSizes;
  final DrywallPackagingRules packagingRules;
  final DrywallMaterialRules materialRules;
  final DrywallWarningRules warningRules;

  const DrywallCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.sheetSizes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const DrywallCanonicalSpec drywallCanonicalSpecV1 = DrywallCanonicalSpec(
  calculatorId: 'drywall',
  formulaVersion: 'drywall-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'workType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 0.5, max: 30),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 1.5, max: 5),
    CanonicalInputField(key: 'layers', defaultValue: 1, min: 1, max: 2),
    CanonicalInputField(key: 'sheetSize', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'profileStep', unit: 'm', defaultValue: 0.6, min: 0.4, max: 0.6),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  sheetSizes: {
    0: DrywallSheetSizeSpec(id: 0, w: 1.2, h: 2.5, area: 3.0),
    1: DrywallSheetSizeSpec(id: 1, w: 1.2, h: 3.0, area: 3.6),
    2: DrywallSheetSizeSpec(id: 2, w: 0.6, h: 2.5, area: 1.5),
  },
  packagingRules: DrywallPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: DrywallMaterialRules(
    sheetReserve: 1.10,
    profileReserve: 1.05,
    screwsTfPerM2: 30,
    screwsLbPerProfile: 4,
    dowelsStepM: 0.6,
    puttyStartKgPerM2: 0.8,
    puttyFinishKgPerM2: 1.0,
    puttyReserve: 1.15,
    puttyBagKg: 25,
    serpyankaMPerSheet: 2.5,
    serpyankaReserve: 1.1,
    serpyankaRollM: 90,
    primerLPerM2: 0.3,
    primerReserve: 1.15,
    primerCanL: 10,
    sandpaperM2PerSheet: 5,
    sandpaperPack: 10,
    profileLengthM: 3,
    sealingTapeRollM: 30,
  ),
  warningRules: DrywallWarningRules(
    wideProfileHeightThreshold: 3.5,
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

double _defaultFor(DrywallCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(DrywallCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(DrywallCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalDrywall(
  Map<String, double> inputs, {
  DrywallCanonicalSpec spec = drywallCanonicalSpecV1,
}) {
  final workType = (inputs['workType'] ?? _defaultFor(spec, 'workType', 0)).round().clamp(0, 2);
  final length = math.max(0.5, math.min(30.0, inputs['length'] ?? _defaultFor(spec, 'length', 5)));
  final height = math.max(1.5, math.min(5.0, inputs['height'] ?? _defaultFor(spec, 'height', 2.7)));
  final layersRaw = (inputs['layers'] ?? _defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final sheetSize = (inputs['sheetSize'] ?? _defaultFor(spec, 'sheetSize', 0)).round().clamp(0, 2);
  final profileStepRaw = inputs['profileStep'] ?? _defaultFor(spec, 'profileStep', 0.6);
  final profileStep = profileStepRaw <= 0.4 ? 0.4 : 0.6;

  final area = _roundValue(length * height, 3);
  final sides = workType == 0 ? 2 : 1;
  final totalSheetArea = area * sides * layers;

  final gklArea = spec.sheetSizes[sheetSize]?.area ?? spec.sheetSizes[0]!.area;
  final baseSheetsNeeded = (totalSheetArea / gklArea * spec.materialRules.sheetReserve).ceil();

  // Profile PN (perimeter)
  final pnPerimeter = 2 * (length + height);
  final pnLength = (pnPerimeter * spec.materialRules.profileReserve / spec.materialRules.profileLengthM).ceil() * spec.materialRules.profileLengthM;
  final pnPieces = (pnLength / spec.materialRules.profileLengthM).round();

  // Profile PP (studs)
  final ppCount = (length / profileStep).ceil() + 1;
  final ppLength = ppCount * height * spec.materialRules.profileReserve;
  final ppPieces = (ppLength / spec.materialRules.profileLengthM).ceil();

  // Screws
  final screwsTF = (totalSheetArea * spec.materialRules.screwsTfPerM2 * spec.materialRules.profileReserve).ceil();
  final screwsLB = (ppCount * spec.materialRules.screwsLbPerProfile * spec.materialRules.profileReserve).ceil();

  // Dowels
  final dowels = (pnPerimeter / spec.materialRules.dowelsStepM).ceil();

  // Sealing tape
  final sealingTapeRolls = (pnPerimeter / spec.materialRules.sealingTapeRollM).ceil();

  // Putty
  final puttyStartBags = (totalSheetArea * spec.materialRules.puttyStartKgPerM2 * spec.materialRules.puttyReserve / spec.materialRules.puttyBagKg).ceil();
  final puttyFinishBags = (totalSheetArea * spec.materialRules.puttyFinishKgPerM2 * spec.materialRules.puttyReserve / spec.materialRules.puttyBagKg).ceil();

  // Serpyanka
  final serpyankaRolls = (baseSheetsNeeded * spec.materialRules.serpyankaMPerSheet * spec.materialRules.serpyankaReserve / spec.materialRules.serpyankaRollM).ceil();

  // Primer
  final primerCans = (totalSheetArea * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCanL).ceil();

  // Sandpaper
  final sandpaperPacks = ((totalSheetArea / spec.materialRules.sandpaperM2PerSheet).ceil() / spec.materialRules.sandpaperPack).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseSheetsNeeded * multiplier, 6);
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
        'workType:$workType',
        'sheetSize:$sheetSize',
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
  if (height > spec.warningRules.wideProfileHeightThreshold) {
    warnings.add('Высота более 3.5 м — требуются профили шириной 100 мм');
  }
  if (layers == 2) {
    warnings.add('Второй слой ГКЛ монтируется со смещением 600 мм');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ГКЛ листы',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПН 27\u00d728 3м',
      quantity: pnPieces.toDouble(),
      unit: 'шт',
      withReserve: pnPieces.toDouble(),
      purchaseQty: pnPieces,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПП 60\u00d727 3м',
      quantity: ppPieces.toDouble(),
      unit: 'шт',
      withReserve: ppPieces.toDouble(),
      purchaseQty: ppPieces,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы 3.5\u00d725 мм',
      quantity: screwsTF.toDouble(),
      unit: 'шт',
      withReserve: screwsTF.toDouble(),
      purchaseQty: screwsTF,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы-клопы 3.5\u00d79.5 мм',
      quantity: screwsLB.toDouble(),
      unit: 'шт',
      withReserve: screwsLB.toDouble(),
      purchaseQty: screwsLB,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбели 6\u00d740',
      quantity: dowels.toDouble(),
      unit: 'шт',
      withReserve: dowels.toDouble(),
      purchaseQty: dowels,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Лента уплотнительная (рулон 30м)',
      quantity: sealingTapeRolls.toDouble(),
      unit: 'рулон',
      withReserve: sealingTapeRolls.toDouble(),
      purchaseQty: sealingTapeRolls,
      category: 'Изоляция',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка стартовая 25кг',
      quantity: puttyStartBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyStartBags.toDouble(),
      purchaseQty: puttyStartBags,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка финишная 25кг',
      quantity: puttyFinishBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyFinishBags.toDouble(),
      purchaseQty: puttyFinishBags,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Серпянка 90м',
      quantity: serpyankaRolls.toDouble(),
      unit: 'рулонов',
      withReserve: serpyankaRolls.toDouble(),
      purchaseQty: serpyankaRolls,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка 10л',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Наждачная бумага P180',
      quantity: sandpaperPacks.toDouble(),
      unit: 'упаковок',
      withReserve: sandpaperPacks.toDouble(),
      purchaseQty: sandpaperPacks,
      category: 'Отделка',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'workType': workType.toDouble(),
      'length': _roundValue(length, 3),
      'height': _roundValue(height, 3),
      'layers': layers.toDouble(),
      'sheetSize': sheetSize.toDouble(),
      'profileStep': profileStep,
      'sides': sides.toDouble(),
      'totalSheetArea': _roundValue(totalSheetArea, 3),
      'gklArea': gklArea,
      'sheetsNeeded': _roundValue(recScenario.exactNeed, 3),
      'pnPerimeter': _roundValue(pnPerimeter, 3),
      'pnPieces': pnPieces.toDouble(),
      'ppCount': ppCount.toDouble(),
      'ppPieces': ppPieces.toDouble(),
      'screwsTF': screwsTF.toDouble(),
      'screwsLB': screwsLB.toDouble(),
      'dowels': dowels.toDouble(),
      'sealingTapeRolls': sealingTapeRolls.toDouble(),
      'puttyStartBags': puttyStartBags.toDouble(),
      'puttyFinishBags': puttyFinishBags.toDouble(),
      'serpyankaRolls': serpyankaRolls.toDouble(),
      'primerCans': primerCans.toDouble(),
      'sandpaperPacks': sandpaperPacks.toDouble(),
      'minExactNeedSheets': scenarios['MIN']!.exactNeed,
      'recExactNeedSheets': recScenario.exactNeed,
      'maxExactNeedSheets': scenarios['MAX']!.exactNeed,
      'minPurchaseSheets': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseSheets': recScenario.purchaseQuantity,
      'maxPurchaseSheets': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
