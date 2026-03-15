import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const Map<int, String> _brickTypeLabels = {
  0: 'Кирпич одинарный (65 мм)',
  1: 'Кирпич полуторный (88 мм)',
  2: 'Кирпич двойной (138 мм)',
};

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final wallWidth = math.max(0.5, inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 5)).toDouble();
    final wallHeight = math.max(0.5, inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 3)).toDouble();
    return {
      'inputMode': 0.0,
      'area': roundValue(wallWidth * wallHeight, 3),
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
    };
  }
  final area = math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 15)).toDouble();
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 5)).toDouble();
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 3)).toDouble();
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'wallWidth': wallWidth,
    'wallHeight': wallHeight,
  };
}

CanonicalCalculatorContractResult calculateCanonicalBrick(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(brickSpecData);

  final areaInfo = _resolveArea(spec, inputs);
  final area = areaInfo['area']!;
  final wallWidth = areaInfo['wallWidth']!;
  final wallHeight = areaInfo['wallHeight']!;

  final brickType = (inputs['brickType'] ?? defaultFor(spec, 'brickType', 0)).round().clamp(0, 2);
  final wallThickness = (inputs['wallThickness'] ?? defaultFor(spec, 'wallThickness', 1)).round().clamp(0, 3);
  final workingConditions = (inputs['workingConditions'] ?? defaultFor(spec, 'workingConditions', 1)).round().clamp(1, 4);
  final wasteMode = (inputs['wasteMode'] ?? defaultFor(spec, 'wasteMode', 0)).round().clamp(0, 2);

  final bricksPerSqmMap = spec.normativeValue<Map>('bricks_per_sqm') ?? {};
  final bricksPerSqm = ((bricksPerSqmMap['$brickType'] as Map?)?['$wallThickness'] as num? ?? 102).toDouble();
  final mortarPerSqmMap = spec.normativeValue<Map>('mortar_per_sqm') ?? {};
  final mortarPerSqm = ((mortarPerSqmMap['$brickType'] as Map?)?['$wallThickness'] as num? ?? 0.023).toDouble();
  final brickHeightMmMap = spec.normativeValue<Map>('brick_height_mm') ?? {};
  final brickHeightMm = (brickHeightMmMap['$brickType'] as num? ?? 65).toDouble();
  final conditionsMultiplierMap = spec.normativeValue<Map>('conditions_multiplier') ?? {};
  final conditionsMultiplier = (conditionsMultiplierMap['$workingConditions'] as num? ?? 1.0).toDouble();
  final wasteCoeffsMap = spec.normativeValue<Map>('waste_coeffs') ?? {};
  final wasteCoeff = (wasteCoeffsMap['$wasteMode'] as num? ?? 1.05).toDouble();

  final baseBricksNeeded = area * bricksPerSqm * wasteCoeff;

  final mortarVolume = roundValue(area * mortarPerSqm * spec.materialRule<num>('mortar_loss_factor').toDouble() * conditionsMultiplier, 6);
  final cementKg = roundValue(mortarVolume * spec.materialRule<num>('cement_kg_per_m3').toDouble(), 3);
  final cementBags = cementKg > 0 ? (cementKg / spec.materialRule<num>('cement_bag_kg').toDouble()).ceil() : 0;
  final sandM3 = roundValue(mortarVolume * spec.materialRule<num>('sand_m3_per_m3_mortar').toDouble(), 3);

  final totalRows = (wallHeight * 1000 / (brickHeightMm + spec.materialRule<num>('mesh_joint_mm').toDouble())).ceil();
  final meshInterval = wallThickness == 0 ? 3 : 5;
  final meshLayers = (totalRows / meshInterval).ceil();
  final meshArea = roundValue((meshLayers * wallWidth * spec.materialRule<num>('mesh_overlap_factor').toDouble() * 10).ceil() / 10, 3);

  final plasticizerL = roundValue((mortarVolume * spec.materialRule<num>('plasticizer_l_per_m3').toDouble() * 10).ceil() / 10, 3);

  final flexibleTies = wallThickness >= spec.materialRule<num>('flexible_ties_wall_thickness_threshold').toDouble()
      ? (area * spec.materialRule<num>('flexible_ties_per_m2').toDouble()).ceil()
      : 0;

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseBricksNeeded * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'brick-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'brickType:$brickType',
        'wallThickness:$wallThickness',
        'wasteMode:$wasteMode',
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
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (wallThickness == spec.warningRule<num>('non_load_bearing_wall_thickness').toDouble()) {
    warnings.add('Толщина стены в 0.5 кирпича (120 мм) — только для ненесущих перегородок');
  }
  if (cementBags >= spec.warningRule<num>('manual_mix_grade_threshold').toDouble()) {
    warnings.add('Большой объём раствора — ручное замешивание будет затруднено, рекомендуется бетономешалка');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickTypeLabels[brickType] ?? 'Кирпич',
      quantity: roundValue(recScenario.exactNeed, 6),
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceil().toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Цемент М400 (${spec.materialRule<num>('cement_bag_kg').toInt()} кг)',
      quantity: cementBags.toDouble(),
      unit: 'мешков',
      withReserve: cementBags.toDouble(),
      purchaseQty: cementBags.toInt(),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Песок строительный',
      quantity: roundValue(sandM3, 3),
      unit: 'м³',
      withReserve: roundValue((sandM3 * 10).ceil() / 10, 3),
      purchaseQty: sandM3.ceil(),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Кладочная сетка',
      quantity: roundValue(meshArea, 3),
      unit: 'м²',
      withReserve: meshArea.ceil().toDouble(),
      purchaseQty: meshArea.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Пластификатор',
      quantity: roundValue(plasticizerL, 3),
      unit: 'л',
      withReserve: roundValue(plasticizerL, 1),
      purchaseQty: plasticizerL.ceil(),
      category: 'Раствор',
    ),
  ];

  if (wallThickness >= spec.materialRule<num>('flexible_ties_wall_thickness_threshold').toDouble()) {
    materials.add(CanonicalMaterialResult(
      name: 'Гибкие связи',
      quantity: flexibleTies.toDouble(),
      unit: 'шт',
      withReserve: flexibleTies.toDouble(),
      purchaseQty: flexibleTies.toInt(),
      category: 'Крепёж',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': areaInfo['inputMode']!,
      'wallWidth': roundValue(wallWidth, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'brickType': brickType.toDouble(),
      'wallThickness': wallThickness.toDouble(),
      'wallThicknessMm': ((spec.normativeValue<Map>('wall_thickness_mm') ?? {})['$wallThickness'] as num? ?? 250).toDouble(),
      'workingConditions': workingConditions.toDouble(),
      'wasteMode': wasteMode.toDouble(),
      'wasteCoeff': wasteCoeff,
      'bricksPerSqm': bricksPerSqm,
      'mortarPerSqm': mortarPerSqm,
      'conditionsMultiplier': conditionsMultiplier,
      'bricksNeeded': roundValue(recScenario.exactNeed, 3),
      'mortarVolume': mortarVolume,
      'cementKg': cementKg,
      'cementBags': cementBags.toDouble(),
      'sandM3': sandM3,
      'totalRows': totalRows.toDouble(),
      'meshInterval': meshInterval.toDouble(),
      'meshLayers': meshLayers.toDouble(),
      'meshArea': meshArea,
      'plasticizerL': plasticizerL,
      'flexibleTies': flexibleTies.toDouble(),
      'minExactNeedBricks': scenarios['MIN']!.exactNeed,
      'recExactNeedBricks': recScenario.exactNeed,
      'maxExactNeedBricks': scenarios['MAX']!.exactNeed,
      'minPurchaseBricks': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseBricks': recScenario.purchaseQuantity,
      'maxPurchaseBricks': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
