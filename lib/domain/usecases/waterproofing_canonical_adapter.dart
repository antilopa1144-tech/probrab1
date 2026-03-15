import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class WaterproofingPackagingRules {
  final String unit;
  final int packageSize;

  const WaterproofingPackagingRules({required this.unit, required this.packageSize});
}

class WaterproofingMaterialRules {
  final Map<int, double> consumptionPerLayer;
  final Map<int, double> bucketKg;
  final double tapeReserve;
  final double siliconeMPerTube;
  final double primerKgPerM2;
  final double primerCanKg;
  final double bitumenLPerM2;
  final double bitumenCanL;
  final double jointSealantMPerTube;

  const WaterproofingMaterialRules({
    required this.consumptionPerLayer,
    required this.bucketKg,
    required this.tapeReserve,
    required this.siliconeMPerTube,
    required this.primerKgPerM2,
    required this.primerCanKg,
    required this.bitumenLPerM2,
    required this.bitumenCanL,
    required this.jointSealantMPerTube,
  });
}

class WaterproofingWarningRules {
  final int minLayersResidential;
  final int minWallHeightMm;

  const WaterproofingWarningRules({required this.minLayersResidential, required this.minWallHeightMm});
}

class WaterproofingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final WaterproofingPackagingRules packagingRules;
  final WaterproofingMaterialRules materialRules;
  final WaterproofingWarningRules warningRules;

  const WaterproofingCanonicalSpec({
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

const WaterproofingCanonicalSpec waterproofingCanonicalSpecV1 = WaterproofingCanonicalSpec(
  calculatorId: 'waterproofing',
  formulaVersion: 'waterproofing-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'floorArea', unit: 'm2', defaultValue: 6, min: 1, max: 50),
    CanonicalInputField(key: 'wallHeight', unit: 'mm', defaultValue: 200, min: 0, max: 2000),
    CanonicalInputField(key: 'roomPerimeter', unit: 'm', defaultValue: 10, min: 4, max: 40),
    CanonicalInputField(key: 'masticType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'layers', defaultValue: 2, min: 1, max: 3),
  ],
  enabledFactors: ['surface_quality', 'worker_skill', 'waste_factor'],
  packagingRules: WaterproofingPackagingRules(unit: 'вёдер', packageSize: 1),
  materialRules: WaterproofingMaterialRules(
    consumptionPerLayer: {0: 1.0, 1: 1.2, 2: 0.8},
    bucketKg: {0: 15, 1: 20, 2: 15},
    tapeReserve: 1.10,
    siliconeMPerTube: 6,
    primerKgPerM2: 0.15,
    primerCanKg: 2,
    bitumenLPerM2: 0.3,
    bitumenCanL: 20,
    jointSealantMPerTube: 10,
  ),
  warningRules: WaterproofingWarningRules(minLayersResidential: 2, minWallHeightMm: 200),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'surface_quality': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.10},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _masticTypeLabels = {
  0: 'Ceresit CL 51',
  1: 'Жидкая резина',
  2: 'Полимерная мастика',
};

/* ─── helpers ─── */

bool hasCanonicalWaterproofingInputs(Map<String, double> inputs) {
  return inputs.containsKey('masticType') ||
      inputs.containsKey('layers') ||
      inputs.containsKey('wallHeight');
}

Map<String, double> normalizeLegacyWaterproofingInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['floorArea'] = (inputs['floorArea'] ?? 6).toDouble();
  normalized['wallHeight'] = (inputs['wallHeight'] ?? 200).toDouble();
  normalized['roomPerimeter'] = (inputs['roomPerimeter'] ?? 10).toDouble();
  normalized['masticType'] = (inputs['masticType'] ?? 0).toDouble();
  normalized['layers'] = (inputs['layers'] ?? 2).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WaterproofingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(WaterproofingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WaterproofingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalWaterproofing(
  Map<String, double> inputs, {
  WaterproofingCanonicalSpec spec = waterproofingCanonicalSpecV1,
}) {
  final normalized = hasCanonicalWaterproofingInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyWaterproofingInputs(inputs);

  final floorArea = math.max(1.0, math.min(50.0, (normalized['floorArea'] ?? _defaultFor(spec, 'floorArea', 6)).toDouble()));
  final wallHeightMm = math.max(0.0, math.min(2000.0, (normalized['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 200)).toDouble()));
  final roomPerimeter = math.max(4.0, math.min(40.0, (normalized['roomPerimeter'] ?? _defaultFor(spec, 'roomPerimeter', 10)).toDouble()));
  final masticType = (normalized['masticType'] ?? _defaultFor(spec, 'masticType', 0)).round().clamp(0, 2);
  final layers = (normalized['layers'] ?? _defaultFor(spec, 'layers', 2)).round().clamp(1, 3);

  // Areas
  final wallArea = _roundValue(roomPerimeter * (wallHeightMm / 1000), 3);
  final totalArea = _roundValue(floorArea + wallArea, 3);

  // Mastic
  final consumption = spec.materialRules.consumptionPerLayer[masticType] ?? 1.0;
  final bucketKg = spec.materialRules.bucketKg[masticType] ?? 15.0;
  final masticKg = _roundValue(totalArea * consumption * layers, 3);
  final masticBuckets = (masticKg / bucketKg).ceil();

  // Tape
  final tapeM = _roundValue((roomPerimeter + (wallHeightMm > 0 ? roomPerimeter * 1.2 : 0)) * spec.materialRules.tapeReserve, 3);
  final tapeRolls = (tapeM / 10).ceil();

  // Silicone
  final siliconeTubes = (roomPerimeter / spec.materialRules.siliconeMPerTube).ceil() + 1;

  // Primer / bitumen
  var primerKg = 0.0;
  var primerCans = 0;
  var bitumenL = 0.0;
  var bitumenCans = 0;

  if (masticType == 0) {
    primerKg = _roundValue(totalArea * spec.materialRules.primerKgPerM2 * 1.1, 3);
    primerCans = (primerKg / spec.materialRules.primerCanKg).ceil();
  } else {
    bitumenL = _roundValue(totalArea * spec.materialRules.bitumenLPerM2 * 1.1, 3);
    bitumenCans = (bitumenL / spec.materialRules.bitumenCanL).ceil();
  }

  // Joint sealant
  final jointTubes = (roomPerimeter * 0.5 / spec.materialRules.jointSealantMPerTube).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(masticBuckets * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'masticType:$masticType',
        'layers:$layers',
        'packaging:mastic-bucket-${bucketKg.round()}kg',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'mastic-bucket-${bucketKg.round()}kg',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (layers < spec.warningRules.minLayersResidential) {
    warnings.add('Один слой допускается только для нежилых помещений');
  }
  if (wallHeightMm == 0) {
    warnings.add('Обработка стен обязательна минимум на ${spec.warningRules.minWallHeightMm} мм от пола');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_masticTypeLabels[masticType] ?? "Мастика"} (${bucketKg.round()} кг)',
      quantity: masticKg,
      unit: 'кг',
      withReserve: (masticBuckets * bucketKg).toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Лента гидроизоляционная (10 м)',
      quantity: tapeM,
      unit: 'м',
      withReserve: (tapeRolls * 10).toDouble(),
      purchaseQty: tapeRolls,
      category: 'Лента',
    ),
    CanonicalMaterialResult(
      name: 'Силиконовый герметик',
      quantity: siliconeTubes.toDouble(),
      unit: 'туб',
      withReserve: siliconeTubes.toDouble(),
      purchaseQty: siliconeTubes,
      category: 'Герметик',
    ),
  ];

  if (masticType == 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Грунтовка Ceresit (${spec.materialRules.primerCanKg.round()} кг)',
      quantity: primerKg,
      unit: 'кг',
      withReserve: (primerCans * spec.materialRules.primerCanKg).toDouble(),
      purchaseQty: primerCans,
      category: 'Подготовка',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: 'Битумный праймер (${spec.materialRules.bitumenCanL.round()} л)',
      quantity: bitumenL,
      unit: 'л',
      withReserve: (bitumenCans * spec.materialRules.bitumenCanL).toDouble(),
      purchaseQty: bitumenCans,
      category: 'Подготовка',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Герметик для стыков',
    quantity: jointTubes.toDouble(),
    unit: 'туб',
    withReserve: jointTubes.toDouble(),
    purchaseQty: jointTubes,
    category: 'Герметик',
  ));

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'floorArea': _roundValue(floorArea, 3),
      'wallHeightMm': wallHeightMm,
      'roomPerimeter': _roundValue(roomPerimeter, 3),
      'masticType': masticType.toDouble(),
      'layers': layers.toDouble(),
      'wallArea': wallArea,
      'totalArea': totalArea,
      'masticKg': masticKg,
      'masticBuckets': masticBuckets.toDouble(),
      'tapeM': tapeM,
      'tapeRolls': tapeRolls.toDouble(),
      'siliconeTubes': siliconeTubes.toDouble(),
      'primerKg': primerKg,
      'primerCans': primerCans.toDouble(),
      'bitumenL': bitumenL,
      'bitumenCans': bitumenCans.toDouble(),
      'jointTubes': jointTubes.toDouble(),
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
