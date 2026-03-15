import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

bool hasCanonicalTileInputs(Map<String, double> inputs) {
  return inputs.containsKey('tileWidthCm') || inputs.containsKey('tileHeightCm');
}

Map<String, double> normalizeLegacyTileInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final tileSize = (inputs['tileSize'] ?? 60).toDouble();
  if (!normalized.containsKey('tileWidthCm') || !normalized.containsKey('tileHeightCm')) {
    double tileWidthCm;
    double tileHeightCm;
    if (tileSize == 0) {
      tileWidthCm = (inputs['tileWidth'] ?? 60).toDouble();
      tileHeightCm = (inputs['tileHeight'] ?? 60).toDouble();
    } else if (tileSize == 120) {
      tileWidthCm = 120;
      tileHeightCm = 60;
    } else {
      tileWidthCm = tileSize;
      tileHeightCm = tileSize;
    }
    normalized['tileWidthCm'] = tileWidthCm;
    normalized['tileHeightCm'] = tileHeightCm;
  }

  if (!normalized.containsKey('layoutPattern')) {
    normalized['layoutPattern'] = (inputs['layoutPattern'] ?? 1).round().clamp(1, 4).toDouble();
  }
  if (!normalized.containsKey('roomComplexity')) {
    normalized['roomComplexity'] = (inputs['roomComplexity'] ?? 1).round().clamp(1, 3).toDouble();
  }
  if (!normalized.containsKey('groutDepth')) {
    normalized['groutDepth'] = (inputs['groutDepth'] ?? 0).toDouble();
  }
  return normalized;
}

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 1)).round();
  if (inputMode == 0) {
    final length = math.max(0.5, inputs['length'] ?? defaultFor(spec, 'length', 4)).toDouble();
    final width = math.max(0.5, inputs['width'] ?? defaultFor(spec, 'width', 3)).toDouble();
    return {'inputMode': 0.0, 'area': roundValue(length * width, 3)};
  }
  return {
    'inputMode': 1.0,
    'area': roundValue(math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 12)).toDouble(), 3),
  };
}

Map<String, dynamic> _resolveLayout(SpecReader spec, Map<String, double> inputs) {
  final layoutId = (inputs['layoutPattern'] ?? defaultFor(spec, 'layoutPattern', 1)).round().clamp(1, 4);
  return spec.normativeList('layouts').firstWhere((item) => (item['id'] as num).toInt() == layoutId, orElse: () => spec.normativeList('layouts').first);
}

Map<String, dynamic> _resolveRoomComplexity(SpecReader spec, Map<String, double> inputs) {
  final complexityId = (inputs['roomComplexity'] ?? defaultFor(spec, 'roomComplexity', 1)).round().clamp(1, 3);
  return spec.normativeList('room_complexities').firstWhere((item) => (item['id'] as num).toInt() == complexityId, orElse: () => spec.normativeList('room_complexities').first);
}

double _resolveTileSizeAdjustment(SpecReader spec, double averageTileSizeCm) {
  if (averageTileSizeCm > spec.warningRule<num>('large_tile_warning_threshold_cm').toDouble()) {
    return spec.materialRule<num>('large_tile_extra_waste_percent').toDouble();
  }
  if (averageTileSizeCm < 10) {
    return spec.materialRule<num>('mosaic_waste_discount_percent').toDouble();
  }
  return 0;
}

double _resolveGlueRate(SpecReader spec, double averageTileSizeCm) {
  if (averageTileSizeCm < 20) return spec.materialRule<num>('glue_kg_per_m2_small').toDouble();
  if (averageTileSizeCm < 40) return spec.materialRule<num>('glue_kg_per_m2_medium').toDouble();
  if (averageTileSizeCm <= 60) return spec.materialRule<num>('glue_kg_per_m2_large').toDouble();
  return spec.materialRule<num>('glue_kg_per_m2_xl').toDouble();
}

double _resolveGroutDepth(double averageTileSizeCm, double requestedGroutDepth) {
  if (requestedGroutDepth > 0) return requestedGroutDepth;
  if (averageTileSizeCm < 15) return 4;
  if (averageTileSizeCm < 40) return 6;
  if (averageTileSizeCm <= 60) return 8;
  return 10;
}

CanonicalCalculatorContractResult calculateCanonicalTile(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(tileSpecData);

  final normalized = hasCanonicalTileInputs(inputs) ? Map<String, double>.from(inputs) : normalizeLegacyTileInputs(inputs);
  final areaInfo = _resolveArea(spec, normalized);
  final area = areaInfo['area']!;
  final tileWidthCm = (normalized['tileWidthCm'] ?? defaultFor(spec, 'tileWidthCm', 30)).clamp(5, 200).toDouble();
  final tileHeightCm = (normalized['tileHeightCm'] ?? defaultFor(spec, 'tileHeightCm', 30)).clamp(5, 200).toDouble();
  final layout = _resolveLayout(spec, normalized);
  final roomComplexity = _resolveRoomComplexity(spec, normalized);
  final jointWidthMm = (normalized['jointWidth'] ?? defaultFor(spec, 'jointWidth', 3)).clamp(1, 10).toDouble();
  final averageTileSizeCm = roundValue((tileWidthCm + tileHeightCm) / 2, 3);
  final sizeAdjustment = _resolveTileSizeAdjustment(spec, averageTileSizeCm);
  final wastePercent = roundValue((layout['waste_percent'] as num).toDouble() + (roomComplexity['waste_bonus_percent'] as num).toDouble() + sizeAdjustment, 3);
  final tileAreaM2 = roundValue((tileWidthCm / 100) * (tileHeightCm / 100), 6);
  final baseExactNeed = tileAreaM2 > 0 ? roundValue((area / tileAreaM2) * (1 + wastePercent / 100), 6) : 0.0;
  final groutDepthMm = _resolveGroutDepth(averageTileSizeCm, (normalized['groutDepth'] ?? 0).toDouble());
  final tileWidthM = tileWidthCm / 100;
  final tileHeightM = tileHeightCm / 100;
  final jointsLength = (1 / tileWidthM) + (1 / tileHeightM);
  final groutKg = roundValue(area * jointsLength * (jointWidthMm / 1000) * (groutDepthMm / 1000) * spec.materialRule<num>('grout_density_kg_per_m3').toDouble() * spec.materialRule<num>('grout_loss_factor').toDouble(), 6);
  final glueRate = _resolveGlueRate(spec, averageTileSizeCm);
  final glueKg = roundValue(area * glueRate, 6);
  final primerLiters = roundValue(area * spec.materialRule<num>('primer_liters_per_m2').toDouble(), 6);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeed * multiplier, 6);
    final packageSize = spec.packagingRule<num>('tile_package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'tile-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'layout:${layout['key'] as String}',
        'room:${roomComplexity['key'] as String}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('tile_unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final glueBags = glueKg > 0 ? math.max(1, (glueKg / spec.packagingRule<num>('glue_bag_kg').toDouble()).ceil()) : 0;
  final groutBags = groutKg > 0 ? math.max(1, (groutKg / spec.packagingRule<num>('grout_bag_kg').toDouble()).ceil()) : 0;
  final primerCans = primerLiters > 0 ? math.max(1, (primerLiters / spec.packagingRule<num>('primer_can_liters').toDouble()).ceil()) : 0;
  final crossesNeeded = (recScenario.purchaseQuantity * spec.materialRule<num>('crosses_reserve_factor').toDouble()).ceil();
  final svpPackages = averageTileSizeCm >= spec.materialRule<num>('svp_threshold_cm').toDouble()
      ? math.max(1, (crossesNeeded / spec.packagingRule<num>('svp_pack_size').toDouble()).ceil())
      : 0;
  final siliconeTubes = math.max(1, (area / spec.materialRule<num>('silicone_tube_area_m2').toDouble()).ceil());

  final warnings = <String>[];
  if (baseExactNeed < spec.warningRule<num>('low_tile_count_threshold').toDouble()) {
    warnings.add('При укладке меньше 5 плиток процент отходов может быть выше расчётного');
  }
  if ((layout['id'] as num).toInt() == 2) {
    warnings.add('Диагональная укладка требует большего запаса и аккуратной подрезки');
  }
  if (averageTileSizeCm > spec.warningRule<num>('large_tile_warning_threshold_cm').toDouble()) {
    warnings.add('Крупный формат требует двойного нанесения клея и более ровного основания');
  }
  if ((layout['id'] as num).toInt() == 4 && area > spec.warningRule<num>('herringbone_large_area_m2').toDouble()) {
    warnings.add('Укладка ёлочкой на большой площади сильно увеличивает отходы и требования к раскладке');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Плитка ${ (tileWidthCm * 10).round() }×${ (tileHeightCm * 10).round() } мм',
      quantity: recScenario.exactNeed,
      unit: spec.packagingRule<String>('tile_unit'),
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: recScenario.buyPlan.packagesCount,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Плиточный клей (${spec.packagingRule<num>('glue_bag_kg').toInt()} кг)',
      quantity: glueKg,
      unit: 'кг',
      withReserve: glueBags * spec.packagingRule<num>('glue_bag_kg').toDouble(),
      purchaseQty: glueBags.toInt(),
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Затирка цементная (${spec.packagingRule<num>('grout_bag_kg').toInt()} кг)',
      quantity: groutKg,
      unit: 'кг',
      withReserve: groutBags * spec.packagingRule<num>('grout_bag_kg').toDouble(),
      purchaseQty: groutBags.toInt(),
      category: 'Затирка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка глубокого проникновения (${spec.packagingRule<num>('primer_can_liters').toInt()} л)',
      quantity: primerLiters,
      unit: 'л',
      withReserve: primerCans * spec.packagingRule<num>('primer_can_liters').toDouble(),
      purchaseQty: primerCans.toInt(),
      category: 'Подготовка',
    ),
  ];

  if (averageTileSizeCm >= spec.materialRule<num>('svp_threshold_cm').toDouble()) {
    materials.add(CanonicalMaterialResult(
      name: 'СВП (${spec.packagingRule<num>('svp_pack_size').toDouble()} шт)',
      quantity: roundValue(crossesNeeded / spec.packagingRule<num>('svp_pack_size').toDouble(), 6),
      unit: 'уп',
      withReserve: svpPackages.toDouble(),
      purchaseQty: svpPackages.toInt(),
      category: 'Крепёж',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: 'Крестики для плитки',
      quantity: crossesNeeded.toDouble(),
      unit: 'шт',
      withReserve: crossesNeeded.toDouble(),
      purchaseQty: crossesNeeded.toInt(),
      category: 'Крепёж',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Герметик силиконовый',
    quantity: siliconeTubes.toDouble(),
    unit: 'шт',
    withReserve: siliconeTubes.toDouble(),
    purchaseQty: siliconeTubes.toInt(),
    category: 'Затирка',
  ));

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': areaInfo['inputMode']!,
      'tileWidthCm': roundValue(tileWidthCm, 3),
      'tileHeightCm': roundValue(tileHeightCm, 3),
      'averageTileSizeCm': averageTileSizeCm,
      'jointWidth': roundValue(jointWidthMm, 3),
      'groutDepth': roundValue(groutDepthMm, 3),
      'layoutPattern': (layout['id'] as num).toInt().toDouble(),
      'roomComplexity': (roomComplexity['id'] as num).toInt().toDouble(),
      'tileArea': tileAreaM2,
      'wastePercent': wastePercent,
      'sizeAdjustment': roundValue(sizeAdjustment, 3),
      'baseExactNeedTiles': baseExactNeed,
      'tilesNeeded': recScenario.purchaseQuantity,
      'glueRateKgPerM2': roundValue(glueRate, 3),
      'glueNeededKg': glueKg,
      'groutNeededKg': groutKg,
      'primerNeededL': primerLiters,
      'crossesNeeded': crossesNeeded.toDouble(),
      'svpPackages': svpPackages.toDouble(),
      'siliconeTubes': siliconeTubes.toDouble(),
      'minExactNeedTiles': scenarios['MIN']!.exactNeed,
      'recExactNeedTiles': recScenario.exactNeed,
      'maxExactNeedTiles': scenarios['MAX']!.exactNeed,
      'minPurchaseTiles': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseTiles': recScenario.purchaseQuantity,
      'maxPurchaseTiles': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}

