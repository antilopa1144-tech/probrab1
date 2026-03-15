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

const Map<int, String> _brickFormatLabels = {
  0: 'Кирпич одинарный (65 мм)',
  1: 'Кирпич полуторный (88 мм)',
  2: 'Кирпич двойной (138 мм)',
};


bool hasCanonicalBrickworkInputs(Map<String, double> inputs) {
  return inputs.containsKey('brickFormat') ||
      inputs.containsKey('mortarJoint') ||
      inputs.containsKey('openingsArea');
}

Map<String, double> normalizeLegacyBrickworkInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final hasDimensions = (inputs['wallLength'] ?? 0) > 0 && (inputs['wallHeight'] ?? 0) > 0;
  if (!normalized.containsKey('inputMode')) {
    normalized['inputMode'] = hasDimensions ? 0.0 : 1.0;
  }
  normalized['brickFormat'] = (inputs['brickFormat'] ?? inputs['brickType'] ?? 0).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 1).toDouble();
  normalized['mortarJoint'] = (inputs['mortarJoint'] ?? 10).toDouble();
  normalized['openingsArea'] = (inputs['openingsArea'] ?? 5).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalBrickwork(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(brickworkSpecData);

  final normalized = hasCanonicalBrickworkInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBrickworkInputs(inputs);

  final inputMode = (normalized['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  double wallLength;
  double wallHeight;
  double wallArea;

  if (inputMode == 0) {
    wallLength = math.max(1, math.min(100, (normalized['wallLength'] ?? defaultFor(spec, 'wallLength', 10)).toDouble()));
    wallHeight = math.max(1, math.min(5, (normalized['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble()));
    wallArea = roundValue(wallLength * wallHeight, 3);
  } else {
    wallArea = math.max(1, math.min(500, (normalized['area'] ?? defaultFor(spec, 'area', 27)).toDouble()));
    wallLength = (normalized['wallLength'] ?? defaultFor(spec, 'wallLength', 10)).toDouble();
    wallHeight = (normalized['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble();
  }

  final openingsArea = math.max(0.0, math.min(50.0, (normalized['openingsArea'] ?? defaultFor(spec, 'openingsArea', 5)).toDouble()));
  final brickFormat = (normalized['brickFormat'] ?? defaultFor(spec, 'brickFormat', 0)).round().clamp(0, 2);
  final wallThicknessIdx = (normalized['wallThickness'] ?? defaultFor(spec, 'wallThickness', 1)).round().clamp(0, 3);
  final mortarJoint = math.max(8.0, math.min(15.0, (normalized['mortarJoint'] ?? defaultFor(spec, 'mortarJoint', 10)).toDouble()));

  // Area
  final netArea = math.max(0.0, wallArea - openingsArea);

  // Bricks
  final bricksMap = spec.materialRule<Map>('bricks_per_sqm');
  final baseBricks = ((bricksMap['$brickFormat'] as Map?)?['$wallThicknessIdx'] as num?)?.toDouble() ?? 102.0;
  final jointCoeff = mortarJoint == 10 ? 1.0 : (10 / mortarJoint) * 0.97 + 0.03;
  final bricksPerSqm = baseBricks * jointCoeff;
  final totalBricks = netArea * bricksPerSqm;
  final bricksWithReserve = (totalBricks * spec.materialRule<num>('block_reserve').toDouble()).ceil();

  // Mortar
  final wallThicknessMm = (spec.materialRule<Map>('wall_thickness_mm')['$wallThicknessIdx'] as num?)?.toDouble() ?? 250.0;
  final wallVolume = roundValue(netArea * (wallThicknessMm / 1000), 6);
  final mortarCoeff = (spec.materialRule<Map>('mortar_per_m3')['$brickFormat'] as num?)?.toDouble() ?? 0.221;
  final mortarM3 = roundValue(wallVolume * mortarCoeff, 6);
  final mortarKg = roundValue(mortarM3 * spec.materialRule<num>('mortar_density').toDouble(), 3);
  final mortarBags = (mortarKg / spec.materialRule<num>('mortar_bag_kg').toDouble()).ceil();

  // Mesh
  final brickH = (spec.materialRule<Map>('brick_heights')['$brickFormat'] as num?)?.toDouble() ?? 65.0;
  final rowHeight = (brickH + mortarJoint) / 1000;
  final totalRows = (wallHeight / rowHeight).ceil();
  final meshRows = (totalRows / 5).floor();
  final meshArea = roundValue(wallLength * (wallThicknessMm / 1000) * meshRows, 3);

  // Lintels
  final openingsCount = (openingsArea / 2).ceil();
  final lintelsPerOpening = wallThicknessIdx >= 1 ? 2 : 1;
  final totalLintels = openingsCount * lintelsPerOpening;

  // Pallets
  final bricksPerPallet = (spec.materialRule<Map>('bricks_per_pallet')['$brickFormat'] as num?)?.toDouble() ?? 480;
  final pallets = (bricksWithReserve / bricksPerPallet).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(bricksWithReserve * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'brickFormat:$brickFormat',
        'wallThickness:$wallThicknessIdx',
        'mortarJoint:${mortarJoint.round()}',
        'packaging:brickwork-piece',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'brickwork-piece',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (wallThicknessIdx == spec.warningRule<num>('non_load_bearing_wall_thickness').toDouble()) {
    warnings.add('Толщина стены в 0.5 кирпича (120 мм) — только для ненесущих перегородок');
  }
  if (wallThicknessIdx >= spec.warningRule<num>('armor_belt_wall_thickness_threshold').toDouble() &&
      wallHeight > spec.warningRule<num>('armor_belt_height_threshold').toDouble()) {
    warnings.add('При толщине стены 1.5+ кирпича и высоте более 3 м необходим армопояс');
  }
  if (brickFormat == 2 && wallThicknessIdx == 0) {
    warnings.add('Двойной кирпич в полкирпича (120 мм) — нестандартное решение, проверьте проект');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickFormatLabels[brickFormat] ?? 'Кирпич',
      quantity: roundValue(totalBricks, 3),
      unit: 'шт',
      withReserve: bricksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Поддоны кирпича',
      quantity: pallets.toDouble(),
      unit: 'шт',
      withReserve: pallets.toDouble(),
      purchaseQty: pallets.toInt(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Раствор кладочный (${spec.materialRule<num>('mortar_bag_kg').toDouble().round()} кг)',
      quantity: mortarBags.toDouble(),
      unit: 'мешков',
      withReserve: mortarBags.toDouble(),
      purchaseQty: mortarBags.toInt(),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Кладочная сетка',
      quantity: meshArea,
      unit: 'м²',
      withReserve: meshArea.ceilToDouble(),
      purchaseQty: meshArea.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Перемычки (ЖБ)',
      quantity: totalLintels.toDouble(),
      unit: 'шт',
      withReserve: totalLintels.toDouble(),
      purchaseQty: totalLintels.toInt(),
      category: 'Проёмы',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': inputMode.toDouble(),
      'wallLength': roundValue(wallLength, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'wallArea': roundValue(wallArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'netArea': roundValue(netArea, 3),
      'brickFormat': brickFormat.toDouble(),
      'wallThicknessIdx': wallThicknessIdx.toDouble(),
      'wallThicknessMm': wallThicknessMm,
      'mortarJoint': mortarJoint,
      'baseBricks': baseBricks,
      'jointCoeff': roundValue(jointCoeff, 6),
      'bricksPerSqm': roundValue(bricksPerSqm, 3),
      'totalBricks': roundValue(totalBricks, 3),
      'bricksWithReserve': bricksWithReserve.toDouble(),
      'wallVolume': wallVolume,
      'mortarCoeff': mortarCoeff,
      'mortarM3': mortarM3,
      'mortarKg': mortarKg,
      'mortarBags': mortarBags.toDouble(),
      'brickH': brickH,
      'rowHeight': roundValue(rowHeight, 4),
      'totalRows': totalRows.toDouble(),
      'meshRows': meshRows.toDouble(),
      'meshArea': meshArea,
      'openingsCount': openingsCount.toDouble(),
      'lintelsPerOpening': lintelsPerOpening.toDouble(),
      'totalLintels': totalLintels.toDouble(),
      'pallets': pallets.toDouble(),
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
