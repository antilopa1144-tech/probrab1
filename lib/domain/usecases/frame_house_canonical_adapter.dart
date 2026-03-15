import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class FrameHousePackagingRules {
  final String unit;
  final int packageSize;

  const FrameHousePackagingRules({required this.unit, required this.packageSize});
}

class FrameHouseMaterialRules {
  final Map<int, double> outerSheetArea;
  final Map<int, double> innerSheetArea;
  final Map<int, double> insulationThickness;
  final double plateArea;
  final int packSize;
  final double vaporRoll;
  final double windRoll;
  final double membraneReserve;
  final double outerReserve;
  final double innerReserve;
  final int screwsPerSheet;
  final int nailsPerStud;
  final int screwPerKg;
  final int nailPerKg;
  final double studReserve;
  final double strappingReserve;
  final double plateReserve;

  const FrameHouseMaterialRules({
    required this.outerSheetArea,
    required this.innerSheetArea,
    required this.insulationThickness,
    required this.plateArea,
    required this.packSize,
    required this.vaporRoll,
    required this.windRoll,
    required this.membraneReserve,
    required this.outerReserve,
    required this.innerReserve,
    required this.screwsPerSheet,
    required this.nailsPerStud,
    required this.screwPerKg,
    required this.nailPerKg,
    required this.studReserve,
    required this.strappingReserve,
    required this.plateReserve,
  });
}

class FrameHouseWarningRules {
  final double largeWallAreaThresholdM2;

  const FrameHouseWarningRules({required this.largeWallAreaThresholdM2});
}

class FrameHouseCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FrameHousePackagingRules packagingRules;
  final FrameHouseMaterialRules materialRules;
  final FrameHouseWarningRules warningRules;

  const FrameHouseCanonicalSpec({
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

const FrameHouseCanonicalSpec frameHouseCanonicalSpecV1 = FrameHouseCanonicalSpec(
  calculatorId: 'frame-house',
  formulaVersion: 'frame-house-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'wallLength', unit: 'm', defaultValue: 30, min: 1, max: 100),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 2, max: 4),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 10, min: 0, max: 50),
    CanonicalInputField(key: 'studStep', unit: 'mm', defaultValue: 600, min: 400, max: 600),
    CanonicalInputField(key: 'insulationType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'outerSheathing', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'innerSheathing', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: FrameHousePackagingRules(unit: 'уп', packageSize: 8),
  materialRules: FrameHouseMaterialRules(
    outerSheetArea: {0: 3.125, 1: 3.125, 2: 3.84},
    innerSheetArea: {0: 3.125, 1: 3.0, 2: 1.0},
    insulationThickness: {0: 0.15, 1: 0.2, 2: 0.15},
    plateArea: 0.72,
    packSize: 8,
    vaporRoll: 75,
    windRoll: 75,
    membraneReserve: 1.15,
    outerReserve: 1.08,
    innerReserve: 1.10,
    screwsPerSheet: 28,
    nailsPerStud: 20,
    screwPerKg: 600,
    nailPerKg: 200,
    studReserve: 1.05,
    strappingReserve: 1.05,
    plateReserve: 1.05,
  ),
  warningRules: FrameHouseWarningRules(largeWallAreaThresholdM2: 200),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _insulationTypeLabels = {
  0: 'Минеральная вата 150 мм',
  1: 'Минеральная вата 200 мм',
  2: 'Пенополистирол 150 мм',
};

const Map<int, String> _outerSheathingLabels = {
  0: 'OSB-9 мм',
  1: 'OSB-12 мм',
  2: 'ЦСП-12 мм',
};

const Map<int, String> _innerSheathingLabels = {
  0: 'OSB-9 мм',
  1: 'ГКЛ',
  2: 'Вагонка',
};

/* ─── helpers ─── */

bool hasCanonicalFrameHouseInputs(Map<String, double> inputs) {
  return inputs.containsKey('studStep') ||
      inputs.containsKey('insulationType') ||
      inputs.containsKey('wallLength');
}

Map<String, double> normalizeLegacyFrameHouseInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['wallLength'] = (inputs['wallLength'] ?? 30).toDouble();
  normalized['wallHeight'] = (inputs['wallHeight'] ?? 2.7).toDouble();
  normalized['openingsArea'] = (inputs['openingsArea'] ?? 10).toDouble();
  normalized['studStep'] = (inputs['studStep'] ?? 600).toDouble();
  normalized['insulationType'] = (inputs['insulationType'] ?? 0).toDouble();
  normalized['outerSheathing'] = (inputs['outerSheathing'] ?? 0).toDouble();
  normalized['innerSheathing'] = (inputs['innerSheathing'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FrameHouseCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FrameHouseCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FrameHouseCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalFrameHouse(
  Map<String, double> inputs, {
  FrameHouseCanonicalSpec spec = frameHouseCanonicalSpecV1,
}) {
  final normalized = hasCanonicalFrameHouseInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFrameHouseInputs(inputs);

  final wallLength = math.max(1.0, math.min(100.0, (normalized['wallLength'] ?? _defaultFor(spec, 'wallLength', 30)).toDouble()));
  final wallHeight = math.max(2.0, math.min(4.0, (normalized['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble()));
  final openingsArea = math.max(0.0, math.min(50.0, (normalized['openingsArea'] ?? _defaultFor(spec, 'openingsArea', 10)).toDouble()));
  final studStep = (normalized['studStep'] ?? _defaultFor(spec, 'studStep', 600)).round().clamp(400, 600);
  final insulationType = (normalized['insulationType'] ?? _defaultFor(spec, 'insulationType', 0)).round().clamp(0, 2);
  final outerSheathing = (normalized['outerSheathing'] ?? _defaultFor(spec, 'outerSheathing', 0)).round().clamp(0, 2);
  final innerSheathing = (normalized['innerSheathing'] ?? _defaultFor(spec, 'innerSheathing', 0)).round().clamp(0, 2);

  // Geometry
  final wallArea = math.max(0.0, wallLength * wallHeight - openingsArea);
  final studs = (wallLength / (studStep / 1000)).ceil() + 1;
  final studMeters = studs * wallHeight * spec.materialRules.studReserve;
  final studBoards = (studMeters / 6).ceil();
  final strappingM = wallLength * 2 * spec.materialRules.strappingReserve;
  final strappingBoards = (strappingM / 6).ceil();

  // Sheathing
  final outerSheetArea = spec.materialRules.outerSheetArea[outerSheathing] ?? 3.125;
  final innerSheetArea = spec.materialRules.innerSheetArea[innerSheathing] ?? 3.125;
  final outerSheets = (wallArea / outerSheetArea * spec.materialRules.outerReserve).ceil();
  final innerSheets = (wallArea * spec.materialRules.innerReserve / innerSheetArea).ceil();

  // Insulation
  final thickness = spec.materialRules.insulationThickness[insulationType] ?? 0.15;
  final insulVol = _roundValue(wallArea * thickness, 3);
  final layerCount = (thickness / 0.05).ceil();
  final platesPerLayer = (wallArea / spec.materialRules.plateArea * spec.materialRules.plateReserve).ceil();
  final totalPlates = platesPerLayer * layerCount;
  final packs = (totalPlates / spec.materialRules.packSize).ceil();

  // Membranes
  final vaporRolls = (wallArea * spec.materialRules.membraneReserve / spec.materialRules.vaporRoll).ceil();
  final windRolls = (wallArea * spec.materialRules.membraneReserve / spec.materialRules.windRoll).ceil();
  final tapeRolls = (vaporRolls + windRolls) * 2;

  // Fasteners
  final screwsKg = ((outerSheets + innerSheets) * spec.materialRules.screwsPerSheet * spec.materialRules.studReserve / spec.materialRules.screwPerKg * 10).ceil() / 10;
  final nailsKg = (studs * spec.materialRules.nailsPerStud * spec.materialRules.studReserve / spec.materialRules.nailPerKg * 10).ceil() / 10;

  // Scenarios
  final basePrimary = totalPlates;
  final packageLabel = 'insulation-pack-8';
  final packageUnit = 'уп';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / spec.materialRules.packSize).ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: (packageCount * spec.materialRules.packSize).toDouble(),
      leftover: _roundValue(packageCount * spec.materialRules.packSize - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'studStep:$studStep',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: spec.materialRules.packSize.toDouble(),
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (wallArea > spec.warningRules.largeWallAreaThresholdM2) {
    warnings.add('Большая площадь стен — рассмотрите усиление каркаса');
  }
  if (insulationType == 2 && wallHeight > 3) {
    warnings.add('Для высоких стен рекомендуется минеральная вата вместо ПСБ');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Стойки каркаса (шаг $studStep мм)',
      quantity: studs.toDouble(),
      unit: 'шт',
      withReserve: studBoards.toDouble(),
      purchaseQty: studBoards,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Обвязка (доски 6 м)',
      quantity: _roundValue(strappingM, 2),
      unit: 'м',
      withReserve: strappingBoards.toDouble(),
      purchaseQty: strappingBoards,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Наружная обшивка — ${_outerSheathingLabels[outerSheathing]}',
      quantity: outerSheets.toDouble(),
      unit: 'листов',
      withReserve: outerSheets.toDouble(),
      purchaseQty: outerSheets,
      category: 'Обшивка',
    ),
    CanonicalMaterialResult(
      name: 'Внутренняя обшивка — ${_innerSheathingLabels[innerSheathing]}',
      quantity: innerSheets.toDouble(),
      unit: innerSheathing == 2 ? 'шт' : 'листов',
      withReserve: innerSheets.toDouble(),
      purchaseQty: innerSheets,
      category: 'Обшивка',
    ),
    CanonicalMaterialResult(
      name: 'Утеплитель — ${_insulationTypeLabels[insulationType]}',
      quantity: recScenario.exactNeed,
      unit: 'плит',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: packs,
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Утеплитель (упаковки по ${spec.materialRules.packSize} шт)',
      quantity: packs.toDouble(),
      unit: 'уп',
      withReserve: packs.toDouble(),
      purchaseQty: packs,
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Пароизоляция (рулон ${spec.materialRules.vaporRoll.round()} м²)',
      quantity: vaporRolls.toDouble(),
      unit: 'рулонов',
      withReserve: vaporRolls.toDouble(),
      purchaseQty: vaporRolls,
      category: 'Мембраны',
    ),
    CanonicalMaterialResult(
      name: 'Ветрозащита (рулон ${spec.materialRules.windRoll.round()} м²)',
      quantity: windRolls.toDouble(),
      unit: 'рулонов',
      withReserve: windRolls.toDouble(),
      purchaseQty: windRolls,
      category: 'Мембраны',
    ),
    CanonicalMaterialResult(
      name: 'Скотч для мембран',
      quantity: tapeRolls.toDouble(),
      unit: 'рулонов',
      withReserve: tapeRolls.toDouble(),
      purchaseQty: tapeRolls,
      category: 'Мембраны',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы',
      quantity: screwsKg,
      unit: 'кг',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Гвозди',
      quantity: nailsKg,
      unit: 'кг',
      withReserve: nailsKg,
      purchaseQty: nailsKg.ceil(),
      category: 'Крепёж',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'wallLength': _roundValue(wallLength, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'studStep': studStep.toDouble(),
      'insulationType': insulationType.toDouble(),
      'outerSheathing': outerSheathing.toDouble(),
      'innerSheathing': innerSheathing.toDouble(),
      'wallArea': _roundValue(wallArea, 3),
      'studs': studs.toDouble(),
      'studMeters': _roundValue(studMeters, 3),
      'studBoards': studBoards.toDouble(),
      'strappingM': _roundValue(strappingM, 3),
      'strappingBoards': strappingBoards.toDouble(),
      'outerSheets': outerSheets.toDouble(),
      'innerSheets': innerSheets.toDouble(),
      'insulVol': insulVol,
      'layerCount': layerCount.toDouble(),
      'platesPerLayer': platesPerLayer.toDouble(),
      'totalPlates': totalPlates.toDouble(),
      'packs': packs.toDouble(),
      'vaporRolls': vaporRolls.toDouble(),
      'windRolls': windRolls.toDouble(),
      'tapeRolls': tapeRolls.toDouble(),
      'screwsKg': screwsKg,
      'nailsKg': nailsKg,
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
