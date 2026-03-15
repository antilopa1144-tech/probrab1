import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class BathroomTileSizeSpec {
  final double w;
  final double h;

  const BathroomTileSizeSpec({required this.w, required this.h});
}

class BathroomPackagingRules {
  final String unit;
  final int packageSize;

  const BathroomPackagingRules({required this.unit, required this.packageSize});
}

class BathroomMaterialRules {
  final Map<int, BathroomTileSizeSpec> floorTileSizes;
  final Map<int, BathroomTileSizeSpec> wallTileSizes;
  final double tileReserve;
  final double floorAdhesiveKgPerM2;
  final double wallAdhesiveKgPerM2;
  final double adhesiveBagKg;
  final double groutKgPerM2;
  final double groutBagKg;
  final double waterproofMasticKgPerM2;
  final double waterproofBucketKg;
  final double waterproofWallHeight;
  final double primerLPerM2;
  final double primerCanL;
  final int crossesPerTile;
  final int crossesPack;
  final double siliconeMPerTube;

  const BathroomMaterialRules({
    required this.floorTileSizes,
    required this.wallTileSizes,
    required this.tileReserve,
    required this.floorAdhesiveKgPerM2,
    required this.wallAdhesiveKgPerM2,
    required this.adhesiveBagKg,
    required this.groutKgPerM2,
    required this.groutBagKg,
    required this.waterproofMasticKgPerM2,
    required this.waterproofBucketKg,
    required this.waterproofWallHeight,
    required this.primerLPerM2,
    required this.primerCanL,
    required this.crossesPerTile,
    required this.crossesPack,
    required this.siliconeMPerTube,
  });
}

class BathroomWarningRules {
  final double smallFloorAreaThresholdM2;
  final String waterproofingMandatoryCode;

  const BathroomWarningRules({required this.smallFloorAreaThresholdM2, required this.waterproofingMandatoryCode});
}

class BathroomCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final BathroomPackagingRules packagingRules;
  final BathroomMaterialRules materialRules;
  final BathroomWarningRules warningRules;

  const BathroomCanonicalSpec({
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

const BathroomCanonicalSpec bathroomCanonicalSpecV1 = BathroomCanonicalSpec(
  calculatorId: 'bathroom',
  formulaVersion: 'bathroom-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 2.5, min: 1, max: 10),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 1.7, min: 1, max: 10),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.5, min: 2, max: 3.5),
    CanonicalInputField(key: 'floorTileSize', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'wallTileSize', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'hasWaterproofing', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'doorWidth', unit: 'm', defaultValue: 0.7, min: 0.6, max: 1.0),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: BathroomPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: BathroomMaterialRules(
    floorTileSizes: {
      0: BathroomTileSizeSpec(w: 0.3, h: 0.3),
      1: BathroomTileSizeSpec(w: 0.45, h: 0.45),
      2: BathroomTileSizeSpec(w: 0.6, h: 0.6),
    },
    wallTileSizes: {
      0: BathroomTileSizeSpec(w: 0.2, h: 0.3),
      1: BathroomTileSizeSpec(w: 0.25, h: 0.4),
      2: BathroomTileSizeSpec(w: 0.3, h: 0.6),
    },
    tileReserve: 1.10,
    floorAdhesiveKgPerM2: 5,
    wallAdhesiveKgPerM2: 3.5,
    adhesiveBagKg: 25,
    groutKgPerM2: 0.5,
    groutBagKg: 2,
    waterproofMasticKgPerM2: 1.5,
    waterproofBucketKg: 4,
    waterproofWallHeight: 0.2,
    primerLPerM2: 0.2,
    primerCanL: 5,
    crossesPerTile: 3,
    crossesPack: 100,
    siliconeMPerTube: 3,
  ),
  warningRules: BathroomWarningRules(
    smallFloorAreaThresholdM2: 2,
    waterproofingMandatoryCode: 'SP 29.13330',
  ),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _floorTileLabels = {
  0: '300×300 мм',
  1: '450×450 мм',
  2: '600×600 мм',
};

const Map<int, String> _wallTileLabels = {
  0: '200×300 мм',
  1: '250×400 мм',
  2: '300×600 мм',
};

/* ─── helpers ─── */

bool hasCanonicalBathroomInputs(Map<String, double> inputs) {
  return inputs.containsKey('floorTileSize') ||
      inputs.containsKey('wallTileSize') ||
      inputs.containsKey('hasWaterproofing');
}

Map<String, double> normalizeLegacyBathroomInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['length'] = (inputs['length'] ?? 2.5).toDouble();
  normalized['width'] = (inputs['width'] ?? 1.7).toDouble();
  normalized['height'] = (inputs['height'] ?? 2.5).toDouble();
  normalized['floorTileSize'] = (inputs['floorTileSize'] ?? 0).toDouble();
  normalized['wallTileSize'] = (inputs['wallTileSize'] ?? 0).toDouble();
  normalized['hasWaterproofing'] = (inputs['hasWaterproofing'] ?? 1).toDouble();
  normalized['doorWidth'] = (inputs['doorWidth'] ?? 0.7).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(BathroomCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(BathroomCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(BathroomCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalBathroom(
  Map<String, double> inputs, {
  BathroomCanonicalSpec spec = bathroomCanonicalSpecV1,
}) {
  final normalized = hasCanonicalBathroomInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBathroomInputs(inputs);

  final length = math.max(1.0, math.min(10.0, (normalized['length'] ?? _defaultFor(spec, 'length', 2.5)).toDouble()));
  final width = math.max(1.0, math.min(10.0, (normalized['width'] ?? _defaultFor(spec, 'width', 1.7)).toDouble()));
  final height = math.max(2.0, math.min(3.5, (normalized['height'] ?? _defaultFor(spec, 'height', 2.5)).toDouble()));
  final floorTileSize = (normalized['floorTileSize'] ?? _defaultFor(spec, 'floorTileSize', 0)).round().clamp(0, 2);
  final wallTileSize = (normalized['wallTileSize'] ?? _defaultFor(spec, 'wallTileSize', 0)).round().clamp(0, 2);
  final hasWaterproofing = (normalized['hasWaterproofing'] ?? _defaultFor(spec, 'hasWaterproofing', 1)).round().clamp(0, 1);
  final doorWidth = math.max(0.6, math.min(1.0, (normalized['doorWidth'] ?? _defaultFor(spec, 'doorWidth', 0.7)).toDouble()));

  // Geometry
  final floorArea = _roundValue(length * width, 3);
  final perimeter = _roundValue(2 * (length + width), 3);
  final wallArea = _roundValue(perimeter * height - doorWidth * 2.1, 3);

  // Tiles
  final floorTile = spec.materialRules.floorTileSizes[floorTileSize] ?? spec.materialRules.floorTileSizes[0]!;
  final wallTile = spec.materialRules.wallTileSizes[wallTileSize] ?? spec.materialRules.wallTileSizes[0]!;
  final floorTileArea = _roundValue(floorTile.w * floorTile.h, 6);
  final wallTileArea = _roundValue(wallTile.w * wallTile.h, 6);
  final tilesFloor = (floorArea / floorTileArea * spec.materialRules.tileReserve).ceil();
  final tilesWall = (wallArea / wallTileArea * spec.materialRules.tileReserve).ceil();

  // Adhesive
  final floorAdhesiveBags = (floorArea * spec.materialRules.floorAdhesiveKgPerM2 / spec.materialRules.adhesiveBagKg).ceil();
  final wallAdhesiveBags = (wallArea * spec.materialRules.wallAdhesiveKgPerM2 / spec.materialRules.adhesiveBagKg).ceil();

  // Grout
  final groutBags = ((floorArea + wallArea) * spec.materialRules.groutKgPerM2 / spec.materialRules.groutBagKg).ceil();

  // Waterproofing
  var masticBuckets = 0;
  var tapeRolls = 0;
  if (hasWaterproofing == 1) {
    masticBuckets = ((floorArea + perimeter * spec.materialRules.waterproofWallHeight) * spec.materialRules.waterproofMasticKgPerM2 / spec.materialRules.waterproofBucketKg).ceil();
    tapeRolls = ((perimeter + 1.2) / 10).ceil();
  }

  // Primer
  final primerCans = ((floorArea + wallArea) * spec.materialRules.primerLPerM2 / spec.materialRules.primerCanL).ceil();

  // Crosses
  final totalTiles = tilesFloor + tilesWall;
  final crossesPacks = (totalTiles * spec.materialRules.crossesPerTile / spec.materialRules.crossesPack).ceil();

  // Silicone
  final siliconeTubes = (perimeter / spec.materialRules.siliconeMPerTube).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalTiles * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'floorTileSize:$floorTileSize',
        'wallTileSize:$wallTileSize',
        'hasWaterproofing:$hasWaterproofing',
        'packaging:bathroom-tile-piece',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'bathroom-tile-piece',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (floorArea < spec.warningRules.smallFloorAreaThresholdM2) {
    warnings.add('При площади менее ${spec.warningRules.smallFloorAreaThresholdM2.round()} м² повышенный расход на подрезку плитки');
  }
  if (hasWaterproofing == 0) {
    warnings.add('Гидроизоляция обязательна согласно ${spec.warningRules.waterproofingMandatoryCode}');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Плитка напольная ${_floorTileLabels[floorTileSize] ?? "300×300 мм"}',
      quantity: tilesFloor.toDouble(),
      unit: 'шт',
      withReserve: tilesFloor.toDouble(),
      purchaseQty: tilesFloor,
      category: 'Плитка',
    ),
    CanonicalMaterialResult(
      name: 'Плитка настенная ${_wallTileLabels[wallTileSize] ?? "200×300 мм"}',
      quantity: tilesWall.toDouble(),
      unit: 'шт',
      withReserve: tilesWall.toDouble(),
      purchaseQty: tilesWall,
      category: 'Плитка',
    ),
    CanonicalMaterialResult(
      name: 'Клей для напольной плитки (${spec.materialRules.adhesiveBagKg.round()} кг)',
      quantity: _roundValue(floorArea * spec.materialRules.floorAdhesiveKgPerM2, 3),
      unit: 'кг',
      withReserve: (floorAdhesiveBags * spec.materialRules.adhesiveBagKg).toDouble(),
      purchaseQty: floorAdhesiveBags,
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Клей для настенной плитки (${spec.materialRules.adhesiveBagKg.round()} кг)',
      quantity: _roundValue(wallArea * spec.materialRules.wallAdhesiveKgPerM2, 3),
      unit: 'кг',
      withReserve: (wallAdhesiveBags * spec.materialRules.adhesiveBagKg).toDouble(),
      purchaseQty: wallAdhesiveBags,
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Затирка (${spec.materialRules.groutBagKg.round()} кг)',
      quantity: _roundValue((floorArea + wallArea) * spec.materialRules.groutKgPerM2, 3),
      unit: 'кг',
      withReserve: (groutBags * spec.materialRules.groutBagKg).toDouble(),
      purchaseQty: groutBags,
      category: 'Затирка',
    ),
  ];

  if (hasWaterproofing == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Мастика гидроизоляционная (${spec.materialRules.waterproofBucketKg.round()} кг)',
        quantity: _roundValue((floorArea + perimeter * spec.materialRules.waterproofWallHeight) * spec.materialRules.waterproofMasticKgPerM2, 3),
        unit: 'кг',
        withReserve: (masticBuckets * spec.materialRules.waterproofBucketKg).toDouble(),
        purchaseQty: masticBuckets,
        category: 'Гидроизоляция',
      ),
      CanonicalMaterialResult(
        name: 'Лента гидроизоляционная (10 м)',
        quantity: _roundValue(perimeter + 1.2, 3),
        unit: 'м',
        withReserve: (tapeRolls * 10).toDouble(),
        purchaseQty: tapeRolls,
        category: 'Гидроизоляция',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Грунтовка (${spec.materialRules.primerCanL.round()} л)',
      quantity: _roundValue((floorArea + wallArea) * spec.materialRules.primerLPerM2, 3),
      unit: 'л',
      withReserve: (primerCans * spec.materialRules.primerCanL).toDouble(),
      purchaseQty: primerCans,
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Крестики (упаковка ${spec.materialRules.crossesPack} шт)',
      quantity: (totalTiles * spec.materialRules.crossesPerTile).toDouble(),
      unit: 'шт',
      withReserve: (crossesPacks * spec.materialRules.crossesPack).toDouble(),
      purchaseQty: crossesPacks,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Силиконовый герметик',
      quantity: siliconeTubes.toDouble(),
      unit: 'туб',
      withReserve: siliconeTubes.toDouble(),
      purchaseQty: siliconeTubes,
      category: 'Герметик',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': _roundValue(length, 3),
      'width': _roundValue(width, 3),
      'height': _roundValue(height, 3),
      'floorTileSize': floorTileSize.toDouble(),
      'wallTileSize': wallTileSize.toDouble(),
      'hasWaterproofing': hasWaterproofing.toDouble(),
      'doorWidth': _roundValue(doorWidth, 3),
      'floorArea': floorArea,
      'perimeter': perimeter,
      'wallArea': wallArea,
      'floorTileArea': floorTileArea,
      'wallTileArea': wallTileArea,
      'tilesFloor': tilesFloor.toDouble(),
      'tilesWall': tilesWall.toDouble(),
      'totalTiles': totalTiles.toDouble(),
      'floorAdhesiveBags': floorAdhesiveBags.toDouble(),
      'wallAdhesiveBags': wallAdhesiveBags.toDouble(),
      'groutBags': groutBags.toDouble(),
      'masticBuckets': masticBuckets.toDouble(),
      'tapeRolls': tapeRolls.toDouble(),
      'primerCans': primerCans.toDouble(),
      'crossesPacks': crossesPacks.toDouble(),
      'siliconeTubes': siliconeTubes.toDouble(),
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
