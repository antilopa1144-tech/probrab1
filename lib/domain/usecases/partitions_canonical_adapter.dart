import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class PartitionsBlockDimsSpec {
  final int id;
  final double lengthMm;
  final double heightMm;

  const PartitionsBlockDimsSpec({
    required this.id,
    required this.lengthMm,
    required this.heightMm,
  });
}

class PartitionsPackagingRules {
  final String unit;
  final double packageSize;

  const PartitionsPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class PartitionsMaterialRules {
  final Map<int, PartitionsBlockDimsSpec> blockDims;
  final Map<int, double> glueRate;
  final double gypsumMilkRate;
  final double gypsumBag;
  final double glueBag;
  final double blockReserve;
  final double meshInterval;
  final double meshReserve;
  final double meshRoll;
  final double foamPerPerim;
  final double foamCan;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final double sealTapeReserve;

  const PartitionsMaterialRules({
    required this.blockDims,
    required this.glueRate,
    required this.gypsumMilkRate,
    required this.gypsumBag,
    required this.glueBag,
    required this.blockReserve,
    required this.meshInterval,
    required this.meshReserve,
    required this.meshRoll,
    required this.foamPerPerim,
    required this.foamCan,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.sealTapeReserve,
  });
}

class PartitionsWarningRules {
  final double highWallThresholdM;

  const PartitionsWarningRules({
    required this.highWallThresholdM,
  });
}

class PartitionsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final PartitionsPackagingRules packagingRules;
  final PartitionsMaterialRules materialRules;
  final PartitionsWarningRules warningRules;

  const PartitionsCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const PartitionsCanonicalSpec partitionsCanonicalSpecV1 = PartitionsCanonicalSpec(
  calculatorId: 'partitions',
  formulaVersion: 'partitions-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 50),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 4),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 100, min: 75, max: 200),
    CanonicalInputField(key: 'blockType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: PartitionsPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: PartitionsMaterialRules(
    blockDims: {
      0: PartitionsBlockDimsSpec(id: 0, lengthMm: 625, heightMm: 250),
      1: PartitionsBlockDimsSpec(id: 1, lengthMm: 625, heightMm: 250),
      2: PartitionsBlockDimsSpec(id: 2, lengthMm: 667, heightMm: 500),
    },
    glueRate: {0: 1.5, 1: 1.5, 2: 0},
    gypsumMilkRate: 0.8,
    gypsumBag: 20,
    glueBag: 25,
    blockReserve: 1.05,
    meshInterval: 0.75,
    meshReserve: 1.05,
    meshRoll: 50,
    foamPerPerim: 5,
    foamCan: 750,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCan: 10,
    sealTapeReserve: 1.1,
  ),
  warningRules: PartitionsWarningRules(
    highWallThresholdM: 3.5,
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

double _defaultFor(PartitionsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(PartitionsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(PartitionsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalPartitions(
  Map<String, double> inputs, {
  PartitionsCanonicalSpec spec = partitionsCanonicalSpecV1,
}) {
  final length = math.max(1.0, math.min(50.0, inputs['length'] ?? _defaultFor(spec, 'length', 5)));
  final height = math.max(2.0, math.min(4.0, inputs['height'] ?? _defaultFor(spec, 'height', 2.7)));
  final thickness = math.max(75.0, math.min(200.0, (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 100)).roundToDouble()));
  final blockType = (inputs['blockType'] ?? _defaultFor(spec, 'blockType', 0)).round().clamp(0, 2);

  // Wall area
  final wallArea = length * height;

  // Block dimensions
  final dims = spec.materialRules.blockDims[blockType] ?? spec.materialRules.blockDims[0]!;
  final blockArea = (dims.lengthMm / 1000) * (dims.heightMm / 1000);
  final blocks = (wallArea / blockArea * spec.materialRules.blockReserve).ceil();

  // Glue / gypsum
  final glueRate = spec.materialRules.glueRate[blockType] ?? 0;
  final glueBags = blockType != 2
      ? (wallArea * glueRate / spec.materialRules.glueBag).ceil()
      : 0;
  final gypsumBags = blockType == 2
      ? (wallArea * spec.materialRules.gypsumMilkRate / spec.materialRules.gypsumBag).ceil()
      : 0;

  // Reinforcing mesh
  final armRows = (height / spec.materialRules.meshInterval).ceil();
  final meshLen = length * armRows * spec.materialRules.meshReserve;
  final meshRolls = (meshLen / spec.materialRules.meshRoll).ceil();

  // Foam
  final foamBottles = ((length + height * 2) / spec.materialRules.foamPerPerim).ceil();

  // Primer (both sides)
  final primer = (wallArea * 2 * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCan).ceil();

  // Sealing tape
  final sealTape = ((length * 2 + height * 2) * spec.materialRules.sealTapeReserve).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(blocks * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    const packageLabel = 'partition-block';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'blockType:$blockType',
        'thickness:${thickness.toInt()}',
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
  if (height > spec.warningRules.highWallThresholdM) {
    warnings.add('Высота перегородки более 3.5 м — рекомендуется усиленное армирование');
  }
  if (blockType == 2 && thickness > 100) {
    warnings.add('Гипсовые ПГП толще 100 мм — проверьте наличие нужного размера');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Блоки перегородочные',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
  ];

  if (glueBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для блоков 25кг',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags,
      category: 'Кладка',
    ));
  }

  if (gypsumBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Гипсовое молочко 20кг',
      quantity: gypsumBags.toDouble(),
      unit: 'мешков',
      withReserve: gypsumBags.toDouble(),
      purchaseQty: gypsumBags,
      category: 'Кладка',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Армирующая сетка (рулон ${spec.materialRules.meshRoll.toInt()} м)',
      quantity: meshRolls.toDouble(),
      unit: 'рулонов',
      withReserve: meshRolls.toDouble(),
      purchaseQty: meshRolls,
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Монтажная пена 750мл',
      quantity: foamBottles.toDouble(),
      unit: 'шт',
      withReserve: foamBottles.toDouble(),
      purchaseQty: foamBottles,
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRules.primerCan.toInt()} л)',
      quantity: primer.toDouble(),
      unit: 'канистр',
      withReserve: primer.toDouble(),
      purchaseQty: primer,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Уплотнительная лента',
      quantity: sealTape.toDouble(),
      unit: 'м',
      withReserve: sealTape.toDouble(),
      purchaseQty: sealTape,
      category: 'Монтаж',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': _roundValue(length, 3),
      'height': _roundValue(height, 3),
      'thickness': thickness,
      'blockType': blockType.toDouble(),
      'wallArea': _roundValue(wallArea, 3),
      'blockArea': _roundValue(blockArea, 6),
      'blocks': blocks.toDouble(),
      'glueBags': glueBags.toDouble(),
      'gypsumBags': gypsumBags.toDouble(),
      'armRows': armRows.toDouble(),
      'meshLen': _roundValue(meshLen, 3),
      'meshRolls': meshRolls.toDouble(),
      'foamBottles': foamBottles.toDouble(),
      'primer': primer.toDouble(),
      'sealTape': sealTape.toDouble(),
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
