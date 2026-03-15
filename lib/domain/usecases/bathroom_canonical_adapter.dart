import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

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


CanonicalCalculatorContractResult calculateCanonicalBathroom(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(bathroomSpecData);

  final normalized = hasCanonicalBathroomInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBathroomInputs(inputs);

  final length = math.max(1.0, math.min(10.0, (normalized['length'] ?? defaultFor(spec, 'length', 2.5)).toDouble()));
  final width = math.max(1.0, math.min(10.0, (normalized['width'] ?? defaultFor(spec, 'width', 1.7)).toDouble()));
  final height = math.max(2.0, math.min(3.5, (normalized['height'] ?? defaultFor(spec, 'height', 2.5)).toDouble()));
  final floorTileSize = (normalized['floorTileSize'] ?? defaultFor(spec, 'floorTileSize', 0)).round().clamp(0, 2);
  final wallTileSize = (normalized['wallTileSize'] ?? defaultFor(spec, 'wallTileSize', 0)).round().clamp(0, 2);
  final hasWaterproofing = (normalized['hasWaterproofing'] ?? defaultFor(spec, 'hasWaterproofing', 1)).round().clamp(0, 1);
  final doorWidth = math.max(0.6, math.min(1.0, (normalized['doorWidth'] ?? defaultFor(spec, 'doorWidth', 0.7)).toDouble()));

  // Geometry
  final floorArea = roundValue(length * width, 3);
  final perimeter = roundValue(2 * (length + width), 3);
  final wallArea = roundValue(perimeter * height - doorWidth * 2.1, 3);

  // Tiles
  final floorTileSizes = spec.materialRule<Map>('floor_tile_sizes');
  final floorTile = (floorTileSizes['$floorTileSize'] ?? floorTileSizes['0']) as Map;
  final wallTileSizes = spec.materialRule<Map>('wall_tile_sizes');
  final wallTile = (wallTileSizes['$wallTileSize'] ?? wallTileSizes['0']) as Map;
  final floorTileArea = roundValue((floorTile['w'] as num).toDouble() * (floorTile['h'] as num).toDouble(), 6);
  final wallTileArea = roundValue((wallTile['w'] as num).toDouble() * (wallTile['h'] as num).toDouble(), 6);
  final tilesFloor = (floorArea / floorTileArea * spec.materialRule<num>('tile_reserve').toDouble()).ceil();
  final tilesWall = (wallArea / wallTileArea * spec.materialRule<num>('tile_reserve').toDouble()).ceil();

  // Adhesive
  final floorAdhesiveBags = (floorArea * spec.materialRule<num>('floor_adhesive_kg_per_m2').toDouble() / spec.materialRule<num>('adhesive_bag_kg').toDouble()).ceil();
  final wallAdhesiveBags = (wallArea * spec.materialRule<num>('wall_adhesive_kg_per_m2').toDouble() / spec.materialRule<num>('adhesive_bag_kg').toDouble()).ceil();

  // Grout
  final groutBags = ((floorArea + wallArea) * spec.materialRule<num>('grout_kg_per_m2').toDouble() / spec.materialRule<num>('grout_bag_kg').toDouble()).ceil();

  // Waterproofing
  var masticBuckets = 0;
  var tapeRolls = 0;
  if (hasWaterproofing == 1) {
    masticBuckets = ((floorArea + perimeter * spec.materialRule<num>('waterproof_wall_height').toDouble()) * spec.materialRule<num>('waterproof_mastic_kg_per_m2').toDouble() / spec.materialRule<num>('waterproof_bucket_kg').toDouble()).ceil();
    tapeRolls = ((perimeter + 1.2) / 10).ceil();
  }

  // Primer
  final primerCans = ((floorArea + wallArea) * spec.materialRule<num>('primer_l_per_m2').toDouble() / spec.materialRule<num>('primer_can_l').toDouble()).ceil();

  // Crosses
  final totalTiles = tilesFloor + tilesWall;
  final crossesPacks = (totalTiles * spec.materialRule<num>('crosses_per_tile').toDouble() / spec.materialRule<num>('crosses_pack').toDouble()).ceil();

  // Silicone
  final siliconeTubes = (perimeter / spec.materialRule<num>('silicone_m_per_tube').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(totalTiles * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'floorTileSize:$floorTileSize',
        'wallTileSize:$wallTileSize',
        'hasWaterproofing:$hasWaterproofing',
        'packaging:bathroom-tile-piece',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'bathroom-tile-piece',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (floorArea < spec.warningRule<num>('small_floor_area_threshold_m2').toDouble()) {
    warnings.add('При площади менее ${spec.warningRule<num>('small_floor_area_threshold_m2').toDouble().round()} м² повышенный расход на подрезку плитки');
  }
  if (hasWaterproofing == 0) {
    warnings.add('Гидроизоляция обязательна согласно ${spec.warningRule<num>('waterproofing_mandatory_code').toDouble()}');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Плитка напольная ${_floorTileLabels[floorTileSize] ?? "300×300 мм"}',
      quantity: tilesFloor.toDouble(),
      unit: 'шт',
      withReserve: tilesFloor.toDouble(),
      purchaseQty: tilesFloor.toInt(),
      category: 'Плитка',
    ),
    CanonicalMaterialResult(
      name: 'Плитка настенная ${_wallTileLabels[wallTileSize] ?? "200×300 мм"}',
      quantity: tilesWall.toDouble(),
      unit: 'шт',
      withReserve: tilesWall.toDouble(),
      purchaseQty: tilesWall.toInt(),
      category: 'Плитка',
    ),
    CanonicalMaterialResult(
      name: 'Клей для напольной плитки (${spec.materialRule<num>('adhesive_bag_kg').toDouble().round()} кг)',
      quantity: roundValue(floorArea * spec.materialRule<num>('floor_adhesive_kg_per_m2').toDouble(), 3),
      unit: 'кг',
      withReserve: (floorAdhesiveBags * spec.materialRule<num>('adhesive_bag_kg').toDouble()),
      purchaseQty: floorAdhesiveBags.toInt(),
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Клей для настенной плитки (${spec.materialRule<num>('adhesive_bag_kg').toDouble().round()} кг)',
      quantity: roundValue(wallArea * spec.materialRule<num>('wall_adhesive_kg_per_m2').toDouble(), 3),
      unit: 'кг',
      withReserve: (wallAdhesiveBags * spec.materialRule<num>('adhesive_bag_kg').toDouble()),
      purchaseQty: wallAdhesiveBags.toInt(),
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Затирка (${spec.materialRule<num>('grout_bag_kg').toDouble().round()} кг)',
      quantity: roundValue((floorArea + wallArea) * spec.materialRule<num>('grout_kg_per_m2').toDouble(), 3),
      unit: 'кг',
      withReserve: (groutBags * spec.materialRule<num>('grout_bag_kg').toDouble()),
      purchaseQty: groutBags.toInt(),
      category: 'Затирка',
    ),
  ];

  if (hasWaterproofing == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Мастика гидроизоляционная (${spec.materialRule<num>('waterproof_bucket_kg').toDouble().round()} кг)',
        quantity: roundValue((floorArea + perimeter * spec.materialRule<num>('waterproof_wall_height').toDouble()) * spec.materialRule<num>('waterproof_mastic_kg_per_m2').toDouble(), 3),
        unit: 'кг',
        withReserve: (masticBuckets * spec.materialRule<num>('waterproof_bucket_kg').toDouble()),
        purchaseQty: masticBuckets.toInt(),
        category: 'Гидроизоляция',
      ),
      CanonicalMaterialResult(
        name: 'Лента гидроизоляционная (10 м)',
        quantity: roundValue(perimeter + 1.2, 3),
        unit: 'м',
        withReserve: (tapeRolls * 10).toDouble(),
        purchaseQty: tapeRolls.toInt(),
        category: 'Гидроизоляция',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Грунтовка (${spec.materialRule<num>('primer_can_l').toDouble().round()} л)',
      quantity: roundValue((floorArea + wallArea) * spec.materialRule<num>('primer_l_per_m2').toDouble(), 3),
      unit: 'л',
      withReserve: (primerCans * spec.materialRule<num>('primer_can_l').toDouble()),
      purchaseQty: primerCans.toInt(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Крестики (упаковка ${spec.materialRule<num>('crosses_pack').toDouble()} шт)',
      quantity: (totalTiles * spec.materialRule<num>('crosses_per_tile').toDouble()),
      unit: 'шт',
      withReserve: (crossesPacks * spec.materialRule<num>('crosses_pack').toDouble()),
      purchaseQty: crossesPacks.toInt(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Силиконовый герметик',
      quantity: siliconeTubes.toDouble(),
      unit: 'туб',
      withReserve: siliconeTubes.toDouble(),
      purchaseQty: siliconeTubes.toInt(),
      category: 'Герметик',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'height': roundValue(height, 3),
      'floorTileSize': floorTileSize.toDouble(),
      'wallTileSize': wallTileSize.toDouble(),
      'hasWaterproofing': hasWaterproofing.toDouble(),
      'doorWidth': roundValue(doorWidth, 3),
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
