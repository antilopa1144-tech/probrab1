import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* --- Spec model classes --- */

class RoofingTypeSpec {
  final int id;
  final String key;
  final String label;

  const RoofingTypeSpec({
    required this.id,
    required this.key,
    required this.label,
  });
}

class RoofingComplexitySpec {
  final int id;
  final String key;
  final String label;
  final double coefficient;

  const RoofingComplexitySpec({
    required this.id,
    required this.key,
    required this.label,
    required this.coefficient,
  });
}

class RoofingGenericSheetSpec {
  final int id;
  final String key;
  final String label;
  final double effectiveWidth;
  final double effectiveHeight;
  final double area;
  final double fastenersPerM2;

  const RoofingGenericSheetSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.effectiveWidth,
    required this.effectiveHeight,
    required this.area,
    required this.fastenersPerM2,
  });
}

class RoofingPackagingRules {
  final String sheetUnit;
  final String tileUnit;
  final String packUnit;

  const RoofingPackagingRules({
    required this.sheetUnit,
    required this.tileUnit,
    required this.packUnit,
  });
}

class RoofingMaterialRules {
  final double metalTileOverlapHorizontalM;
  final double metalTileOverlapVerticalM;
  final double metalTileScrewsPerM2;
  final double metalTileRidgeElementM;
  final double metalTileRidgeReserve;
  final double metalTileSnowGuardSpacingM;
  final double metalTileWaterproofingReserve;
  final double metalTileWaterproofingRollM2;
  final double metalTileBattenStepM;
  final double metalTileBattenReserve;
  final double metalTileCounterBattenStepM;
  final double metalTileCounterBattenReserve;
  final double softPackAreaM2;
  final double softUnderlaymentRollM2;
  final double softUnderlaymentReserve;
  final double softMasticBucketKg;
  final double softNailsPerM2;
  final double softNailsPerKg;
  final double softNailsReserve;
  final double softRidgeElementM;
  final double softRidgeReserve;
  final double softOsbSheetM2;
  final double softOsbReserve;
  final double softVentAreaM2;
  final double softLowSlopeThreshold;
  final double genericRidgeElementM;
  final double genericRidgeReserve;
  final double genericWaterproofingReserve;
  final double genericWaterproofingRollM2;

  const RoofingMaterialRules({
    required this.metalTileOverlapHorizontalM,
    required this.metalTileOverlapVerticalM,
    required this.metalTileScrewsPerM2,
    required this.metalTileRidgeElementM,
    required this.metalTileRidgeReserve,
    required this.metalTileSnowGuardSpacingM,
    required this.metalTileWaterproofingReserve,
    required this.metalTileWaterproofingRollM2,
    required this.metalTileBattenStepM,
    required this.metalTileBattenReserve,
    required this.metalTileCounterBattenStepM,
    required this.metalTileCounterBattenReserve,
    required this.softPackAreaM2,
    required this.softUnderlaymentRollM2,
    required this.softUnderlaymentReserve,
    required this.softMasticBucketKg,
    required this.softNailsPerM2,
    required this.softNailsPerKg,
    required this.softNailsReserve,
    required this.softRidgeElementM,
    required this.softRidgeReserve,
    required this.softOsbSheetM2,
    required this.softOsbReserve,
    required this.softVentAreaM2,
    required this.softLowSlopeThreshold,
    required this.genericRidgeElementM,
    required this.genericRidgeReserve,
    required this.genericWaterproofingReserve,
    required this.genericWaterproofingRollM2,
  });
}

class RoofingWarningRules {
  final double metalTileMinSlope;
  final double softRoofingMinSlope;
  final double largeRoofAreaThreshold;

  const RoofingWarningRules({
    required this.metalTileMinSlope,
    required this.softRoofingMinSlope,
    required this.largeRoofAreaThreshold,
  });
}

class RoofingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<RoofingTypeSpec> roofingTypes;
  final List<RoofingComplexitySpec> complexityProfiles;
  final List<RoofingGenericSheetSpec> genericSheetSpecs;
  final RoofingPackagingRules packagingRules;
  final RoofingMaterialRules materialRules;
  final RoofingWarningRules warningRules;

  const RoofingCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.roofingTypes,
    required this.complexityProfiles,
    required this.genericSheetSpecs,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* --- Default spec (mirrors roofing-canonical.v1.json) --- */

const RoofingCanonicalSpec roofingCanonicalSpecV1 = RoofingCanonicalSpec(
  calculatorId: 'roofing',
  formulaVersion: 'roofing-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'roofingType', defaultValue: 0, min: 0, max: 5),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 80, min: 10, max: 500),
    CanonicalInputField(key: 'slope', unit: 'deg', defaultValue: 30, min: 5, max: 60),
    CanonicalInputField(key: 'ridgeLength', unit: 'm', defaultValue: 8, min: 1, max: 30),
    CanonicalInputField(key: 'sheetWidth', unit: 'm', defaultValue: 1.18, min: 0.8, max: 1.5),
    CanonicalInputField(key: 'sheetLength', unit: 'm', defaultValue: 2.5, min: 1, max: 8),
    CanonicalInputField(key: 'complexity', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  roofingTypes: [
    RoofingTypeSpec(id: 0, key: 'metal_tile', label: 'Металлочерепица'),
    RoofingTypeSpec(id: 1, key: 'soft', label: 'Мягкая кровля'),
    RoofingTypeSpec(id: 2, key: 'profnastil', label: 'Профнастил'),
    RoofingTypeSpec(id: 3, key: 'ondulin', label: 'Ондулин'),
    RoofingTypeSpec(id: 4, key: 'shale', label: 'Шифер'),
    RoofingTypeSpec(id: 5, key: 'ceramic', label: 'Керамическая черепица'),
  ],
  complexityProfiles: [
    RoofingComplexitySpec(id: 0, key: 'simple', label: 'Простая', coefficient: 1.05),
    RoofingComplexitySpec(id: 1, key: 'medium', label: 'Средняя', coefficient: 1.15),
    RoofingComplexitySpec(id: 2, key: 'complex', label: 'Сложная', coefficient: 1.25),
  ],
  genericSheetSpecs: [
    RoofingGenericSheetSpec(id: 2, key: 'profnastil', label: 'Профнастил', effectiveWidth: 0, effectiveHeight: 0, area: 0, fastenersPerM2: 10),
    RoofingGenericSheetSpec(id: 3, key: 'ondulin', label: 'Ондулин', effectiveWidth: 0.83, effectiveHeight: 1.85, area: 1.5355, fastenersPerM2: 20),
    RoofingGenericSheetSpec(id: 4, key: 'shale', label: 'Шифер', effectiveWidth: 0.98, effectiveHeight: 1.55, area: 1.519, fastenersPerM2: 4),
    RoofingGenericSheetSpec(id: 5, key: 'ceramic', label: 'Керамическая черепица', effectiveWidth: 0, effectiveHeight: 0, area: 0.07692, fastenersPerM2: 4),
  ],
  packagingRules: RoofingPackagingRules(
    sheetUnit: 'листов',
    tileUnit: 'шт',
    packUnit: 'упаковок',
  ),
  materialRules: RoofingMaterialRules(
    metalTileOverlapHorizontalM: 0.08,
    metalTileOverlapVerticalM: 0.15,
    metalTileScrewsPerM2: 9,
    metalTileRidgeElementM: 2,
    metalTileRidgeReserve: 1.05,
    metalTileSnowGuardSpacingM: 3,
    metalTileWaterproofingReserve: 1.15,
    metalTileWaterproofingRollM2: 75,
    metalTileBattenStepM: 0.35,
    metalTileBattenReserve: 1.1,
    metalTileCounterBattenStepM: 1.0,
    metalTileCounterBattenReserve: 1.1,
    softPackAreaM2: 3.0,
    softUnderlaymentRollM2: 15,
    softUnderlaymentReserve: 1.15,
    softMasticBucketKg: 3,
    softNailsPerM2: 80,
    softNailsPerKg: 400,
    softNailsReserve: 1.05,
    softRidgeElementM: 0.5,
    softRidgeReserve: 1.05,
    softOsbSheetM2: 3.125,
    softOsbReserve: 1.05,
    softVentAreaM2: 25,
    softLowSlopeThreshold: 18,
    genericRidgeElementM: 0.33,
    genericRidgeReserve: 1.05,
    genericWaterproofingReserve: 1.15,
    genericWaterproofingRollM2: 75,
  ),
  warningRules: RoofingWarningRules(
    metalTileMinSlope: 14,
    softRoofingMinSlope: 12,
    largeRoofAreaThreshold: 200,
  ),
);

/* --- Constants (must match TS engine exactly) --- */

const List<double> _complexityCoeffs = [1.05, 1.15, 1.25];

const Map<int, String> _roofingTypeLabels = {
  0: 'Металлочерепица',
  1: 'Мягкая кровля',
  2: 'Профнастил',
  3: 'Ондулин',
  4: 'Шифер',
  5: 'Керамическая черепица',
};

/* --- Factor table --- */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* --- Helpers --- */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(RoofingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(RoofingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(RoofingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* --- Main calculator --- */

CanonicalCalculatorContractResult calculateCanonicalRoofing(
  Map<String, double> inputs, {
  RoofingCanonicalSpec spec = roofingCanonicalSpecV1,
}) {
  final roofingType = (inputs['roofingType'] ?? _defaultFor(spec, 'roofingType', 0)).round().clamp(0, 5);
  final area = (inputs['area'] ?? _defaultFor(spec, 'area', 80)).clamp(10, 500).toDouble();
  final slope = (inputs['slope'] ?? _defaultFor(spec, 'slope', 30)).clamp(5, 60).toDouble();
  final ridgeLength = (inputs['ridgeLength'] ?? _defaultFor(spec, 'ridgeLength', 8)).clamp(1, 30).toDouble();
  final sheetWidth = (inputs['sheetWidth'] ?? _defaultFor(spec, 'sheetWidth', 1.18)).clamp(0.8, 1.5).toDouble();
  final sheetLength = (inputs['sheetLength'] ?? _defaultFor(spec, 'sheetLength', 2.5)).clamp(1, 8).toDouble();
  final complexity = (inputs['complexity'] ?? _defaultFor(spec, 'complexity', 0)).round().clamp(0, 2);

  final complexityCoeff = _complexityCoeffs[complexity];
  final slopeFactor = 1 / math.cos(slope * math.pi / 180);
  final realArea = area * slopeFactor;
  final perimeterEst = 4 * math.sqrt(area);

  final materials = <CanonicalMaterialResult>[];
  final warnings = <String>[];

  /* primary material quantity -- used for scenario packaging */
  var primaryQuantity = 0;
  var primaryUnit = 'шт';
  var primaryLabel = '';

  if (roofingType == 0) {
    /* -- METAL TILE -- */
    final effectiveWidth = sheetWidth - 0.08;
    final sheetArea = effectiveWidth * (sheetLength - 0.15);
    final sheetsNeeded = (realArea / sheetArea * complexityCoeff).ceil();
    final ridgePieces = (ridgeLength / 2 * 1.05).ceil();
    final snowGuards = (perimeterEst / 3).ceil();
    final screws = (realArea * 9).ceil();
    final waterproofingM2 = (realArea * 1.15).ceil();
    final waterproofingRolls = (waterproofingM2 / 75).ceil();
    final battens = (realArea / 0.35 * 1.1).ceil();
    final counterBattens = (realArea / 1.0 * 1.1).ceil();

    primaryQuantity = sheetsNeeded;
    primaryUnit = 'листов';
    primaryLabel = 'metal-tile-sheet';

    materials.add(CanonicalMaterialResult(
      name: '${_roofingTypeLabels[0]} (${sheetWidth}x$sheetLength м)',
      quantity: sheetsNeeded.toDouble(),
      unit: 'листов',
      withReserve: sheetsNeeded.toDouble(),
      purchaseQty: sheetsNeeded,
      category: 'Основное',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Коньковые элементы (2 м)',
      quantity: ridgePieces.toDouble(),
      unit: 'шт',
      withReserve: ridgePieces.toDouble(),
      purchaseQty: ridgePieces,
      category: 'Доборные',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Снегозадержатели',
      quantity: snowGuards.toDouble(),
      unit: 'шт',
      withReserve: snowGuards.toDouble(),
      purchaseQty: snowGuards,
      category: 'Безопасность',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Кровельные саморезы',
      quantity: screws.toDouble(),
      unit: 'шт',
      withReserve: screws.toDouble(),
      purchaseQty: screws,
      category: 'Крепёж',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Гидроизоляция (рулон 75 м²)',
      quantity: waterproofingM2.toDouble(),
      unit: 'м²',
      withReserve: (waterproofingRolls * 75).toDouble(),
      purchaseQty: waterproofingRolls,
      category: 'Изоляция',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Обрешётка (доска 25x100, шаг ~350 мм)',
      quantity: battens.toDouble(),
      unit: 'шт',
      withReserve: battens.toDouble(),
      purchaseQty: battens,
      category: 'Каркас',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Контробрешётка (брусок 50x50)',
      quantity: counterBattens.toDouble(),
      unit: 'шт',
      withReserve: counterBattens.toDouble(),
      purchaseQty: counterBattens,
      category: 'Каркас',
    ));
  } else if (roofingType == 1) {
    /* -- SOFT ROOFING -- */
    final packs = (realArea / 3.0 * complexityCoeff).ceil();

    int underlaymentRolls;
    if (slope < 18) {
      underlaymentRolls = (realArea * 1.15 / 15).ceil();
    } else {
      final criticalLinear = perimeterEst + ridgeLength;
      final criticalArea = criticalLinear * 1.0 * 1.15;
      underlaymentRolls = (criticalArea / 15).ceil();
    }

    final masticKg = (perimeterEst + ridgeLength) * 0.1 + realArea * 0.1;
    final masticBuckets = (masticKg / 3).ceil();
    final nailsKg = (realArea * 80 / 400 * 1.05).ceil();
    final ridgeShingles = (ridgeLength / 0.5 * 1.05).ceil();
    final osbSheets = (realArea / 3.125 * 1.05).ceil();
    final ventOutputs = (realArea / 25).ceil();

    primaryQuantity = packs;
    primaryUnit = 'упаковок';
    primaryLabel = 'soft-roofing-pack-3m2';

    materials.add(CanonicalMaterialResult(
      name: '${_roofingTypeLabels[1]} (упаковка 3 м²)',
      quantity: packs.toDouble(),
      unit: 'упаковок',
      withReserve: packs.toDouble(),
      purchaseQty: packs,
      category: 'Основное',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Подкладочный ковёр (рулон 15 м²)',
      quantity: underlaymentRolls.toDouble(),
      unit: 'рулонов',
      withReserve: underlaymentRolls.toDouble(),
      purchaseQty: underlaymentRolls,
      category: 'Изоляция',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Мастика битумная (ведро 3 кг)',
      quantity: _roundValue(masticKg, 3),
      unit: 'кг',
      withReserve: (masticBuckets * 3).toDouble(),
      purchaseQty: masticBuckets,
      category: 'Клей',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Кровельные гвозди',
      quantity: nailsKg.toDouble(),
      unit: 'кг',
      withReserve: nailsKg.toDouble(),
      purchaseQty: nailsKg,
      category: 'Крепёж',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Коньково-карнизная черепица',
      quantity: ridgeShingles.toDouble(),
      unit: 'шт',
      withReserve: ridgeShingles.toDouble(),
      purchaseQty: ridgeShingles,
      category: 'Доборные',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Плиты OSB (1250x2500=3.125 м²)',
      quantity: osbSheets.toDouble(),
      unit: 'листов',
      withReserve: osbSheets.toDouble(),
      purchaseQty: osbSheets,
      category: 'Каркас',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Вентиляционные выходы',
      quantity: ventOutputs.toDouble(),
      unit: 'шт',
      withReserve: ventOutputs.toDouble(),
      purchaseQty: ventOutputs,
      category: 'Вентиляция',
    ));
  } else {
    /* -- GENERIC: profnastil (2), ondulin (3), shale (4), ceramic (5) -- */
    final typeIdx = roofingType - 2; // 0..3
    double unitSheetArea;
    String unitLabel;
    String unitName;

    if (roofingType == 2) {
      // profnastil
      final effectiveW = sheetWidth - 0.05;
      unitSheetArea = effectiveW * (sheetLength - 0.1);
      unitLabel = 'profnastil-${sheetWidth}x$sheetLength';
      unitName = '${_roofingTypeLabels[2]} (${sheetWidth}x$sheetLength м)';
    } else if (roofingType == 3) {
      // ondulin: sheet 0.95x2.0, effective 0.83x1.85
      unitSheetArea = 0.83 * 1.85; // 1.5355
      unitLabel = 'ondulin-0.95x2.0';
      unitName = '${_roofingTypeLabels[3]} (лист 0.95x2.0 м)';
    } else if (roofingType == 4) {
      // shale: sheet 1.13x1.75, effective 0.98x1.55
      unitSheetArea = 0.98 * 1.55; // 1.519
      unitLabel = 'shale-1.13x1.75';
      unitName = '${_roofingTypeLabels[4]} (лист 1.13x1.75 м)';
    } else {
      // ceramic: 1 tile = 0.03 m², ~13 tiles/m²
      unitSheetArea = 1 / 13; // ~0.07692
      unitLabel = 'ceramic-tile';
      unitName = '${_roofingTypeLabels[5]} (~13 шт/м²)';
    }

    final sheetsOrTiles = (realArea / unitSheetArea * complexityCoeff).ceil();
    final ridgePieces = (ridgeLength / 0.33 * 1.05).ceil();

    const fastenerRates = [10, 20, 4, 4];
    final fastenersNeeded = (realArea * fastenerRates[typeIdx]).ceil();
    final waterproofingRolls = (realArea * 1.15 / 75).ceil();

    final tileUnit = roofingType == 5 ? 'шт' : 'листов';

    primaryQuantity = sheetsOrTiles;
    primaryUnit = tileUnit;
    primaryLabel = unitLabel;

    materials.add(CanonicalMaterialResult(
      name: unitName,
      quantity: sheetsOrTiles.toDouble(),
      unit: tileUnit,
      withReserve: sheetsOrTiles.toDouble(),
      purchaseQty: sheetsOrTiles,
      category: 'Основное',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Коньковые элементы (0.33 м)',
      quantity: ridgePieces.toDouble(),
      unit: 'шт',
      withReserve: ridgePieces.toDouble(),
      purchaseQty: ridgePieces,
      category: 'Доборные',
    ));
    materials.add(CanonicalMaterialResult(
      name: roofingType == 3 ? 'Гвозди кровельные' : 'Крепёж кровельный',
      quantity: fastenersNeeded.toDouble(),
      unit: 'шт',
      withReserve: fastenersNeeded.toDouble(),
      purchaseQty: fastenersNeeded,
      category: 'Крепёж',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Гидроизоляция (рулон 75 м²)',
      quantity: (realArea * 1.15).ceilToDouble(),
      unit: 'м²',
      withReserve: (waterproofingRolls * 75).toDouble(),
      purchaseQty: waterproofingRolls,
      category: 'Изоляция',
    ));
  }

  /* -- scenarios -- */
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(primaryQuantity * multiplier, 6);
    final packages = exactNeed > 0 ? (exactNeed / 1.0).ceil() : 0;
    final purchaseQuantity = _roundValue(packages * 1.0, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'roofingType:$roofingType',
        'complexity:$complexity',
        'slope:${slope.toInt()}',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: primaryLabel,
        packageSize: 1.0,
        packagesCount: packages,
        unit: primaryUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* -- warnings -- */
  if (slope < spec.warningRules.metalTileMinSlope && roofingType == 0) {
    warnings.add('Уклон менее 14\u00b0 \u2014 слишком пологий для металлочерепицы');
  }
  if (slope < spec.warningRules.softRoofingMinSlope && roofingType == 1) {
    warnings.add('Уклон менее 12\u00b0 \u2014 слишком пологий для мягкой кровли');
  }
  if (complexity == 2) {
    warnings.add('Сложная геометрия крыши \u2014 рекомендуется профессиональный монтаж');
  }
  if (realArea > spec.warningRules.largeRoofAreaThreshold) {
    warnings.add('Большая площадь крыши \u2014 рекомендуется доставка краном');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofingType': roofingType.toDouble(),
      'area': _roundValue(area, 3),
      'slope': _roundValue(slope, 3),
      'ridgeLength': _roundValue(ridgeLength, 3),
      'sheetWidth': _roundValue(sheetWidth, 3),
      'sheetLength': _roundValue(sheetLength, 3),
      'complexity': complexity.toDouble(),
      'slopeFactor': _roundValue(slopeFactor, 6),
      'realArea': _roundValue(realArea, 3),
      'perimeterEst': _roundValue(perimeterEst, 3),
      'complexityCoeff': complexityCoeff,
      'primaryQuantity': primaryQuantity.toDouble(),
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
