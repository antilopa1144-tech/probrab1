import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

const TileCanonicalSpec tileCanonicalSpecV1 = TileCanonicalSpec(
  calculatorId: 'tile',
  formulaVersion: 'tile-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 4, min: 0.5, max: 30),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 3, min: 0.5, max: 30),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 12, min: 1, max: 500),
    CanonicalInputField(key: 'tileWidthCm', unit: 'cm', defaultValue: 30, min: 5, max: 200),
    CanonicalInputField(key: 'tileHeightCm', unit: 'cm', defaultValue: 30, min: 5, max: 200),
    CanonicalInputField(key: 'jointWidth', unit: 'mm', defaultValue: 3, min: 1, max: 10),
    CanonicalInputField(key: 'groutDepth', unit: 'mm', defaultValue: 0, min: 0, max: 15),
    CanonicalInputField(key: 'layoutPattern', defaultValue: 1, min: 1, max: 4),
    CanonicalInputField(key: 'roomComplexity', defaultValue: 1, min: 1, max: 3),
  ],
  enabledFactors: ['geometry_complexity', 'installation_method', 'worker_skill'],
  layouts: [
    TileLayoutSpec(id: 1, key: 'straight', label: 'Прямая укладка', wastePercent: 10),
    TileLayoutSpec(id: 2, key: 'diagonal', label: 'Диагональная укладка', wastePercent: 15),
    TileLayoutSpec(id: 3, key: 'offset', label: 'Укладка со смещением', wastePercent: 10),
    TileLayoutSpec(id: 4, key: 'herringbone', label: 'Укладка ёлочкой', wastePercent: 20),
  ],
  roomComplexities: [
    TileRoomComplexitySpec(id: 1, key: 'simple', label: 'Прямоугольная комната', wasteBonusPercent: 0),
    TileRoomComplexitySpec(id: 2, key: 'l_shaped', label: 'Г-образная комната', wasteBonusPercent: 5),
    TileRoomComplexitySpec(id: 3, key: 'complex', label: 'Сложная геометрия', wasteBonusPercent: 10),
  ],
  packagingRules: TilePackagingRules(
    tileUnit: 'шт',
    tilePackageSize: 1,
    glueBagKg: 25,
    groutBagKg: 2,
    primerCanLiters: 5,
    svpPackSize: 100,
  ),
  materialRules: TileMaterialRules(
    glueKgPerM2Small: 3.5,
    glueKgPerM2Medium: 4,
    glueKgPerM2Large: 5.5,
    glueKgPerM2Xl: 6.5,
    primerLitersPerM2: 0.15,
    groutDensityKgPerM3: 1600,
    groutLossFactor: 1.1,
    crossesReserveFactor: 1.2,
    svpThresholdCm: 45,
    largeTileExtraWastePercent: 5,
    mosaicWasteDiscountPercent: -3,
    siliconeTubeAreaM2: 15,
  ),
  warningRules: TileWarningRules(
    lowTileCountThreshold: 5,
    largeTileWarningThresholdCm: 60,
    herringboneLargeAreaM2: 30,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

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

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(TileCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveArea(TileCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 1)).round();
  if (inputMode == 0) {
    final length = math.max(0.5, inputs['length'] ?? _defaultFor(spec, 'length', 4)).toDouble();
    final width = math.max(0.5, inputs['width'] ?? _defaultFor(spec, 'width', 3)).toDouble();
    return {'inputMode': 0.0, 'area': _roundValue(length * width, 3)};
  }
  return {
    'inputMode': 1.0,
    'area': _roundValue(math.max(1, inputs['area'] ?? _defaultFor(spec, 'area', 12)).toDouble(), 3),
  };
}

TileLayoutSpec _resolveLayout(TileCanonicalSpec spec, Map<String, double> inputs) {
  final layoutId = (inputs['layoutPattern'] ?? _defaultFor(spec, 'layoutPattern', 1)).round().clamp(1, 4);
  return spec.layouts.firstWhere((item) => item.id == layoutId, orElse: () => spec.layouts.first);
}

TileRoomComplexitySpec _resolveRoomComplexity(TileCanonicalSpec spec, Map<String, double> inputs) {
  final complexityId = (inputs['roomComplexity'] ?? _defaultFor(spec, 'roomComplexity', 1)).round().clamp(1, 3);
  return spec.roomComplexities.firstWhere((item) => item.id == complexityId, orElse: () => spec.roomComplexities.first);
}

double _resolveTileSizeAdjustment(TileCanonicalSpec spec, double averageTileSizeCm) {
  if (averageTileSizeCm > spec.warningRules.largeTileWarningThresholdCm) {
    return spec.materialRules.largeTileExtraWastePercent;
  }
  if (averageTileSizeCm < 10) {
    return spec.materialRules.mosaicWasteDiscountPercent;
  }
  return 0;
}

double _resolveGlueRate(TileCanonicalSpec spec, double averageTileSizeCm) {
  if (averageTileSizeCm < 20) return spec.materialRules.glueKgPerM2Small;
  if (averageTileSizeCm < 40) return spec.materialRules.glueKgPerM2Medium;
  if (averageTileSizeCm <= 60) return spec.materialRules.glueKgPerM2Large;
  return spec.materialRules.glueKgPerM2Xl;
}

double _resolveGroutDepth(double averageTileSizeCm, double requestedGroutDepth) {
  if (requestedGroutDepth > 0) return requestedGroutDepth;
  if (averageTileSizeCm < 15) return 4;
  if (averageTileSizeCm < 40) return 6;
  if (averageTileSizeCm <= 60) return 8;
  return 10;
}

Map<String, double> _keyFactors(TileCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(TileCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalTile(
  Map<String, double> inputs, {
  TileCanonicalSpec spec = tileCanonicalSpecV1,
}) {
  final normalized = hasCanonicalTileInputs(inputs) ? Map<String, double>.from(inputs) : normalizeLegacyTileInputs(inputs);
  final areaInfo = _resolveArea(spec, normalized);
  final area = areaInfo['area']!;
  final tileWidthCm = (normalized['tileWidthCm'] ?? _defaultFor(spec, 'tileWidthCm', 30)).clamp(5, 200).toDouble();
  final tileHeightCm = (normalized['tileHeightCm'] ?? _defaultFor(spec, 'tileHeightCm', 30)).clamp(5, 200).toDouble();
  final layout = _resolveLayout(spec, normalized);
  final roomComplexity = _resolveRoomComplexity(spec, normalized);
  final jointWidthMm = (normalized['jointWidth'] ?? _defaultFor(spec, 'jointWidth', 3)).clamp(1, 10).toDouble();
  final averageTileSizeCm = _roundValue((tileWidthCm + tileHeightCm) / 2, 3);
  final sizeAdjustment = _resolveTileSizeAdjustment(spec, averageTileSizeCm);
  final wastePercent = _roundValue(layout.wastePercent + roomComplexity.wasteBonusPercent + sizeAdjustment, 3);
  final tileAreaM2 = _roundValue((tileWidthCm / 100) * (tileHeightCm / 100), 6);
  final baseExactNeed = tileAreaM2 > 0 ? _roundValue((area / tileAreaM2) * (1 + wastePercent / 100), 6) : 0.0;
  final groutDepthMm = _resolveGroutDepth(averageTileSizeCm, (normalized['groutDepth'] ?? 0).toDouble());
  final tileWidthM = tileWidthCm / 100;
  final tileHeightM = tileHeightCm / 100;
  final jointsLength = (1 / tileWidthM) + (1 / tileHeightM);
  final groutKg = _roundValue(area * jointsLength * (jointWidthMm / 1000) * (groutDepthMm / 1000) * spec.materialRules.groutDensityKgPerM3 * spec.materialRules.groutLossFactor, 6);
  final glueRate = _resolveGlueRate(spec, averageTileSizeCm);
  final glueKg = _roundValue(area * glueRate, 6);
  final primerLiters = _roundValue(area * spec.materialRules.primerLitersPerM2, 6);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeed * multiplier, 6);
    final packageSize = spec.packagingRules.tilePackageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'tile-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'layout:${layout.key}',
        'room:${roomComplexity.key}',
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
        unit: spec.packagingRules.tileUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final glueBags = glueKg > 0 ? math.max(1, (glueKg / spec.packagingRules.glueBagKg).ceil()) : 0;
  final groutBags = groutKg > 0 ? math.max(1, (groutKg / spec.packagingRules.groutBagKg).ceil()) : 0;
  final primerCans = primerLiters > 0 ? math.max(1, (primerLiters / spec.packagingRules.primerCanLiters).ceil()) : 0;
  final crossesNeeded = (recScenario.purchaseQuantity * spec.materialRules.crossesReserveFactor).ceil();
  final svpPackages = averageTileSizeCm >= spec.materialRules.svpThresholdCm
      ? math.max(1, (crossesNeeded / spec.packagingRules.svpPackSize).ceil())
      : 0;
  final siliconeTubes = math.max(1, (area / spec.materialRules.siliconeTubeAreaM2).ceil());

  final warnings = <String>[];
  if (baseExactNeed < spec.warningRules.lowTileCountThreshold) {
    warnings.add('При укладке меньше 5 плиток процент отходов может быть выше расчётного');
  }
  if (layout.id == 2) {
    warnings.add('Диагональная укладка требует большего запаса и аккуратной подрезки');
  }
  if (averageTileSizeCm > spec.warningRules.largeTileWarningThresholdCm) {
    warnings.add('Крупный формат требует двойного нанесения клея и более ровного основания');
  }
  if (layout.id == 4 && area > spec.warningRules.herringboneLargeAreaM2) {
    warnings.add('Укладка ёлочкой на большой площади сильно увеличивает отходы и требования к раскладке');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Плитка ${ (tileWidthCm * 10).round() }×${ (tileHeightCm * 10).round() } мм',
      quantity: recScenario.exactNeed,
      unit: spec.packagingRules.tileUnit,
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: recScenario.buyPlan.packagesCount,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Плиточный клей (${spec.packagingRules.glueBagKg.toInt()} кг)',
      quantity: glueKg,
      unit: 'кг',
      withReserve: glueBags * spec.packagingRules.glueBagKg,
      purchaseQty: glueBags,
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Затирка цементная (${spec.packagingRules.groutBagKg.toInt()} кг)',
      quantity: groutKg,
      unit: 'кг',
      withReserve: groutBags * spec.packagingRules.groutBagKg,
      purchaseQty: groutBags,
      category: 'Затирка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка глубокого проникновения (${spec.packagingRules.primerCanLiters.toInt()} л)',
      quantity: primerLiters,
      unit: 'л',
      withReserve: primerCans * spec.packagingRules.primerCanLiters,
      purchaseQty: primerCans,
      category: 'Подготовка',
    ),
  ];

  if (averageTileSizeCm >= spec.materialRules.svpThresholdCm) {
    materials.add(CanonicalMaterialResult(
      name: 'СВП (${spec.packagingRules.svpPackSize} шт)',
      quantity: _roundValue(crossesNeeded / spec.packagingRules.svpPackSize, 6),
      unit: 'уп',
      withReserve: svpPackages.toDouble(),
      purchaseQty: svpPackages,
      category: 'Крепёж',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: 'Крестики для плитки',
      quantity: crossesNeeded.toDouble(),
      unit: 'шт',
      withReserve: crossesNeeded.toDouble(),
      purchaseQty: crossesNeeded,
      category: 'Крепёж',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Герметик силиконовый',
    quantity: siliconeTubes.toDouble(),
    unit: 'шт',
    withReserve: siliconeTubes.toDouble(),
    purchaseQty: siliconeTubes,
    category: 'Затирка',
  ));

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': areaInfo['inputMode']!,
      'tileWidthCm': _roundValue(tileWidthCm, 3),
      'tileHeightCm': _roundValue(tileHeightCm, 3),
      'averageTileSizeCm': averageTileSizeCm,
      'jointWidth': _roundValue(jointWidthMm, 3),
      'groutDepth': _roundValue(groutDepthMm, 3),
      'layoutPattern': layout.id.toDouble(),
      'roomComplexity': roomComplexity.id.toDouble(),
      'tileArea': tileAreaM2,
      'wastePercent': wastePercent,
      'sizeAdjustment': _roundValue(sizeAdjustment, 3),
      'baseExactNeedTiles': baseExactNeed,
      'tilesNeeded': recScenario.purchaseQuantity,
      'glueRateKgPerM2': _roundValue(glueRate, 3),
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

