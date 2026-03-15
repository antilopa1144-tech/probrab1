import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class DoorsPackagingRules {
  final String unit;
  final int packageSize;

  const DoorsPackagingRules({required this.unit, required this.packageSize});
}

class DoorsMaterialRules {
  final Map<int, List<int>> doorDims;
  final int boxDepth;
  final int foamMlPerM;
  final int foamCanMl;
  final int screwsPerDoor;
  final int dubelsPerDoor;
  final double glueCartridgePerDoor;
  final int doborStandardH;
  final int nalichnikStandardH;
  final double foamReserve;
  final int screwPack;
  final int dubelPack;

  const DoorsMaterialRules({
    required this.doorDims,
    required this.boxDepth,
    required this.foamMlPerM,
    required this.foamCanMl,
    required this.screwsPerDoor,
    required this.dubelsPerDoor,
    required this.glueCartridgePerDoor,
    required this.doborStandardH,
    required this.nalichnikStandardH,
    required this.foamReserve,
    required this.screwPack,
    required this.dubelPack,
  });
}

class DoorsWarningRules {
  final int thickWallThresholdMm;
  final int bulkDoorThreshold;

  const DoorsWarningRules({required this.thickWallThresholdMm, required this.bulkDoorThreshold});
}

class DoorsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final DoorsPackagingRules packagingRules;
  final DoorsMaterialRules materialRules;
  final DoorsWarningRules warningRules;

  const DoorsCanonicalSpec({
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

const DoorsCanonicalSpec doorsCanonicalSpecV1 = DoorsCanonicalSpec(
  calculatorId: 'doors',
  formulaVersion: 'doors-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'doorCount', defaultValue: 3, min: 1, max: 20),
    CanonicalInputField(key: 'doorType', defaultValue: 0, min: 0, max: 4),
    CanonicalInputField(key: 'wallThickness', unit: 'mm', defaultValue: 120, min: 80, max: 380),
    CanonicalInputField(key: 'withNalichnik', defaultValue: 1, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: DoorsPackagingRules(unit: 'баллонов', packageSize: 1),
  materialRules: DoorsMaterialRules(
    doorDims: {0: [700, 2000], 1: [800, 2000], 2: [900, 2000], 3: [860, 2050], 4: [700, 2100]},
    boxDepth: 70,
    foamMlPerM: 100,
    foamCanMl: 750,
    screwsPerDoor: 12,
    dubelsPerDoor: 6,
    glueCartridgePerDoor: 0.5,
    doborStandardH: 2200,
    nalichnikStandardH: 2200,
    foamReserve: 1.1,
    screwPack: 50,
    dubelPack: 20,
  ),
  warningRules: DoorsWarningRules(thickWallThresholdMm: 200, bulkDoorThreshold: 10),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

bool hasCanonicalDoorsInputs(Map<String, double> inputs) {
  return inputs.containsKey('doorType') ||
      inputs.containsKey('doorCount') ||
      inputs.containsKey('wallThickness');
}

Map<String, double> normalizeLegacyDoorsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['doorCount'] = (inputs['doorCount'] ?? 3).toDouble();
  normalized['doorType'] = (inputs['doorType'] ?? 0).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 120).toDouble();
  normalized['withNalichnik'] = (inputs['withNalichnik'] ?? 1).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(DoorsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(DoorsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(DoorsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalDoors(
  Map<String, double> inputs, {
  DoorsCanonicalSpec spec = doorsCanonicalSpecV1,
}) {
  final normalized = hasCanonicalDoorsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyDoorsInputs(inputs);

  final doorCount = (normalized['doorCount'] ?? _defaultFor(spec, 'doorCount', 3)).round().clamp(1, 20);
  final doorType = (normalized['doorType'] ?? _defaultFor(spec, 'doorType', 0)).round().clamp(0, 4);
  final wallThickness = (normalized['wallThickness'] ?? _defaultFor(spec, 'wallThickness', 120)).round().clamp(80, 380);
  final withNalichnik = (normalized['withNalichnik'] ?? _defaultFor(spec, 'withNalichnik', 1)).round().clamp(0, 1);

  // Door dimensions
  final dims = spec.materialRules.doorDims[doorType] ?? [700, 2000];
  final doorW = dims[0];
  final doorH = dims[1];
  final perimM = 2 * (doorW + doorH) / 1000;

  // Foam
  final foamPerDoor = perimM * spec.materialRules.foamMlPerM / 1000;
  final foamCans = (doorCount * foamPerDoor * spec.materialRules.foamReserve / (spec.materialRules.foamCanMl / 1000)).ceil();

  // Dobor
  final needDobor = wallThickness > spec.materialRules.boxDepth;
  final doborWidth = needDobor ? wallThickness - spec.materialRules.boxDepth : 0;
  var doborPcs = 0;
  if (needDobor) {
    final doborLenPerDoor = (2 * doorH + doorW) / 1000 * 1.05;
    doborPcs = (doborLenPerDoor / (spec.materialRules.doborStandardH / 1000)).ceil() * doorCount;
  }

  // Nalichnik
  var nalichnikPcs = 0;
  if (withNalichnik == 1) {
    final nalichnikLenPerDoor = (2 * doorH + doorW) / 1000 * 1.05;
    nalichnikPcs = (nalichnikLenPerDoor / (spec.materialRules.nalichnikStandardH / 1000)).ceil() * doorCount * 2;
  }

  // Glue
  final glueCarts = (doorCount * spec.materialRules.glueCartridgePerDoor).ceil();

  // Fasteners
  final screwPacks = (doorCount * spec.materialRules.screwsPerDoor / spec.materialRules.screwPack).ceil();
  final dubelPacks = (doorCount * spec.materialRules.dubelsPerDoor / spec.materialRules.dubelPack).ceil();

  // Scenarios
  final basePrimary = foamCans;
  const packageLabel = 'foam-can-750ml';
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
        'doorType:$doorType',
        'wallThickness:$wallThickness',
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
  if (wallThickness >= spec.warningRules.thickWallThresholdMm) {
    warnings.add('При толстых стенах проверьте ширину доборов в магазине');
  }
  if (doorCount > spec.warningRules.bulkDoorThreshold) {
    warnings.add('Большое количество дверей — рассмотрите оптовую закупку');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Монтажная пена (750 мл)',
      quantity: recScenario.exactNeed,
      unit: 'баллонов',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы (упаковка ${spec.materialRules.screwPack} шт)',
      quantity: (doorCount * spec.materialRules.screwsPerDoor).toDouble(),
      unit: 'шт',
      withReserve: (screwPacks * spec.materialRules.screwPack).toDouble(),
      purchaseQty: screwPacks,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбели (упаковка ${spec.materialRules.dubelPack} шт)',
      quantity: (doorCount * spec.materialRules.dubelsPerDoor).toDouble(),
      unit: 'шт',
      withReserve: (dubelPacks * spec.materialRules.dubelPack).toDouble(),
      purchaseQty: dubelPacks,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Клей-герметик (картриджи)',
      quantity: glueCarts.toDouble(),
      unit: 'шт',
      withReserve: glueCarts.toDouble(),
      purchaseQty: glueCarts,
      category: 'Монтаж',
    ),
  ];

  if (needDobor) {
    materials.add(CanonicalMaterialResult(
      name: 'Доборы (ширина $doborWidth мм)',
      quantity: doborPcs.toDouble(),
      unit: 'шт',
      withReserve: doborPcs.toDouble(),
      purchaseQty: doborPcs,
      category: 'Комплектация',
    ));
  }

  if (withNalichnik == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Наличники',
      quantity: nalichnikPcs.toDouble(),
      unit: 'шт',
      withReserve: nalichnikPcs.toDouble(),
      purchaseQty: nalichnikPcs,
      category: 'Комплектация',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'doorCount': doorCount.toDouble(),
      'doorType': doorType.toDouble(),
      'wallThickness': wallThickness.toDouble(),
      'withNalichnik': withNalichnik.toDouble(),
      'doorW': doorW.toDouble(),
      'doorH': doorH.toDouble(),
      'perimM': _roundValue(perimM, 3),
      'foamPerDoor': _roundValue(foamPerDoor, 4),
      'foamCans': foamCans.toDouble(),
      'needDobor': needDobor ? 1.0 : 0.0,
      'doborWidth': doborWidth.toDouble(),
      'doborPcs': doborPcs.toDouble(),
      'nalichnikPcs': nalichnikPcs.toDouble(),
      'glueCarts': glueCarts.toDouble(),
      'screwPacks': screwPacks.toDouble(),
      'dubelPacks': dubelPacks.toDouble(),
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
