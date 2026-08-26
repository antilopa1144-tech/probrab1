import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<int, String> _brickTypeLabels = {
  0: 'Кирпич одинарный 250×120×65 мм',
  1: 'Кирпич полуторный 250×120×88 мм',
  2: 'Кирпич двойной 250×120×138 мм',
};

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0))
      .round();
  if (inputMode == 0) {
    final wallWidth = math
        .max(0.5, inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 5))
        .toDouble();
    final wallHeight = math
        .max(0.5, inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 3))
        .toDouble();
    return {
      'inputMode': 0.0,
      'area': roundValue(wallWidth * wallHeight, 3),
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
    };
  }
  final area = math
      .max(1, inputs['area'] ?? defaultFor(spec, 'area', 15))
      .toDouble();
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 3))
      .toDouble();
  final wallWidth =
      (inputs['wallWidth'] ??
              (wallHeight > 0
                  ? area / wallHeight
                  : defaultFor(spec, 'wallWidth', 5)))
          .toDouble();
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

  final brickType = (inputs['brickType'] ?? defaultFor(spec, 'brickType', 0))
      .round()
      .clamp(0, 2);
  final wallThickness =
      (inputs['wallThickness'] ?? defaultFor(spec, 'wallThickness', 1))
          .round()
          .clamp(0, 3);
  final workingConditions =
      (inputs['workingConditions'] ?? defaultFor(spec, 'workingConditions', 1))
          .round()
          .clamp(1, 4);
  final wasteMode = (inputs['wasteMode'] ?? defaultFor(spec, 'wasteMode', 0))
      .round()
      .clamp(0, 2);
  final mortarAdditive =
      (inputs['mortarAdditive'] ?? defaultFor(spec, 'mortarAdditive', 0))
          .round()
          .clamp(0, 1);

  final bricksPerSqmMap = spec.normativeValue<Map>('bricks_per_sqm') ?? {};
  final bricksPerSqm =
      ((bricksPerSqmMap['$brickType'] as Map?)?['$wallThickness'] as num? ??
              102)
          .toDouble();
  final mortarPerSqmMap = spec.normativeValue<Map>('mortar_per_sqm') ?? {};
  final mortarPerSqm =
      ((mortarPerSqmMap['$brickType'] as Map?)?['$wallThickness'] as num? ??
              0.023)
          .toDouble();
  final brickHeightMmMap = spec.normativeValue<Map>('brick_height_mm') ?? {};
  final brickHeightMm = (brickHeightMmMap['$brickType'] as num? ?? 65)
      .toDouble();
  final conditionsMultiplierMap =
      spec.normativeValue<Map>('conditions_multiplier') ?? {};
  final conditionsMultiplier =
      (conditionsMultiplierMap['$workingConditions'] as num? ?? 1.0).toDouble();
  final wasteCoeffsMap = spec.normativeValue<Map>('waste_coeffs') ?? {};
  final wasteCoeff = (wasteCoeffsMap['$wasteMode'] as num? ?? 1.05).toDouble();
  final maxWasteCoeff = wasteCoeffsMap.values.whereType<num>().fold<double>(
    wasteCoeff,
    (current, value) => math.max(current, value.toDouble()),
  );

  final bricksNet = area * bricksPerSqm;

  final mortarVolume = roundValue(
    area *
        mortarPerSqm *
        spec.materialRule<num>('mortar_loss_factor').toDouble() *
        conditionsMultiplier,
    6,
  );
  final cementKg = roundValue(
    mortarVolume * spec.materialRule<num>('cement_kg_per_m3').toDouble(),
    3,
  );
  final cementBags = cementKg > 0
      ? (cementKg / spec.materialRule<num>('cement_bag_kg').toDouble()).ceil()
      : 0;
  final sandM3 = roundValue(
    mortarVolume * spec.materialRule<num>('sand_m3_per_m3_mortar').toDouble(),
    3,
  );

  final totalRows =
      (wallHeight *
              1000 /
              (brickHeightMm +
                  spec.materialRule<num>('mesh_joint_mm').toDouble()))
          .ceil();
  final meshInterval = wallThickness == 0 ? 3 : 5;
  final meshLayers = (totalRows / meshInterval).ceil();
  final meshLengthM = roundValue(
    (meshLayers *
                wallWidth *
                spec.materialRule<num>('mesh_overlap_factor').toDouble() *
                10)
            .ceil() /
        10,
    3,
  );

  final plasticizerL = roundValue(
    (mortarVolume *
                spec.materialRule<num>('plasticizer_l_per_m3').toDouble() *
                10)
            .ceil() /
        10,
    3,
  );
  final wallThicknessMm =
      ((spec.normativeValue<Map>('wall_thickness_mm') ?? {})['$wallThickness']
                  as num? ??
              250)
          .toDouble();
  final wallThicknessM = wallThicknessMm / 1000;
  final footprintArea = roundValue(wallWidth * wallThicknessM, 6);
  final perimeter = roundValue(wallWidth * 2 + wallThicknessM * 2, 6);

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final scenarioWasteCoeff = scenarioName == 'MIN'
        ? 1.0
        : scenarioName == 'MAX'
        ? math.max(wasteCoeff, maxWasteCoeff)
        : wasteCoeff;
    final exactNeed = roundValue(bricksNet * scenarioWasteCoeff, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel =
        'brick-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'brickType:$brickType',
        'wallThickness:$wallThickness',
        'wasteMode:$wasteMode',
        'wasteMultiplier:$scenarioWasteCoeff',
        'scenario_policy:explicit_brick_waste',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        'waste_multiplier': roundValue(scenarioWasteCoeff, 6),
        'field_multiplier': roundValue(scenarioWasteCoeff, 6),
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
  if (wallThickness ==
      spec.warningRule<num>('non_load_bearing_wall_thickness').toDouble()) {
    warnings.add(
      'Толщина стены в 0.5 кирпича (120 мм) — только для ненесущих перегородок',
    );
  }
  if (cementBags >=
      spec.warningRule<num>('manual_mix_grade_threshold').toDouble()) {
    warnings.add(
      'Большой объём раствора — ручное замешивание будет затруднено, рекомендуется бетономешалка',
    );
  }
  if (wallThickness >=
      spec
          .materialRule<num>('flexible_ties_wall_thickness_threshold')
          .toDouble()) {
    warnings.add(
      'Гибкие связи не включены в покупку: они нужны для многослойной стены или кирпичной облицовки, а не определяются только толщиной кладки',
    );
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickTypeLabels[brickType] ?? 'Кирпич',
      quantity: roundValue(bricksNet, 6),
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.purchaseQuantity,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name:
          'Цемент ЦЕМ I/II 32,5 (М400), мешок ${spec.materialRule<num>('cement_bag_kg').toInt()} кг',
      quantity: cementBags.toDouble(),
      unit: 'мешков',
      withReserve: cementBags.toDouble(),
      purchaseQty: cementBags.toDouble(),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Песок для кладочного раствора, фракция 0–2 мм',
      quantity: roundValue(sandM3, 3),
      unit: 'м³',
      withReserve: roundValue((sandM3 * 10).ceil() / 10, 3),
      purchaseQty: roundValue((sandM3 * 10).ceil() / 10, 3),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Кладочная сетка Ø3–4 мм, ячейка 50×50 мм',
      quantity: roundValue(meshLengthM, 3),
      unit: 'п.м.',
      withReserve: roundValue((meshLengthM * 10).ceil() / 10, 3),
      purchaseQty: roundValue((meshLengthM * 10).ceil() / 10, 3),
      category: 'Армирование',
    ),
  ];

  if (mortarAdditive == 0) {
    final limeKg = mortarVolume * 150 * 1.1;
    final limeBags = (limeKg / 25).ceil();
    materials.add(
      CanonicalMaterialResult(
        name: 'Известь гашёная (тесто)',
        quantity: roundValue(limeKg, 3),
        unit: 'кг',
        withReserve: (limeBags * 25).toDouble(),
        purchaseQty: (limeBags * 25).toDouble(),
        category: 'Раствор',
        packageInfo: {'count': limeBags, 'size': 25.0, 'packageUnit': 'мешков'},
      ),
    );
  } else {
    final plasticizerWithReserve = mortarVolume * 0.5 * 1.1;
    materials.add(
      CanonicalMaterialResult(
        name: 'Пластификатор для кладочного раствора',
        quantity: roundValue(plasticizerWithReserve, 3),
        unit: 'л',
        withReserve: roundValue(plasticizerWithReserve, 3),
        purchaseQty: roundValue(plasticizerWithReserve, 3),
        category: 'Раствор',
      ),
    );
  }

  materials.addAll([
    const CanonicalMaterialResult(
      name: 'Кельма каменщика',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Инструмент',
    ),
    const CanonicalMaterialResult(
      name: 'Молоток-кирочка для подколки',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Инструмент',
    ),
    const CanonicalMaterialResult(
      name: 'Уровень строительный 600 мм',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Инструмент',
    ),
    CanonicalMaterialResult(
      name: 'Шнур-причалка строительный',
      quantity: roundValue(perimeter * 1.5, 3),
      unit: 'м',
      withReserve: roundValue(perimeter * 1.5, 3),
      purchaseQty: roundValue(perimeter * 1.5, 3),
      category: 'Инструмент',
    ),
    const CanonicalMaterialResult(
      name: 'Расшивка для швов',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Инструмент',
    ),
    const CanonicalMaterialResult(
      name: 'Ёмкость для замеса раствора (60 л)',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Инструмент',
    ),
    CanonicalMaterialResult(
      name: 'Рубероид (гидроизоляция между фундаментом и стеной)',
      quantity: roundValue(footprintArea * 1.1, 3),
      unit: 'м²',
      withReserve: 15,
      purchaseQty: 15,
      category: 'Гидроизоляция',
      packageInfo: const {'count': 1, 'size': 15.0, 'packageUnit': 'рулонов'},
    ),
  ]);

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
      'wallThicknessMm': wallThicknessMm,
      'workingConditions': workingConditions.toDouble(),
      'wasteMode': wasteMode.toDouble(),
      'wasteCoeff': wasteCoeff,
      'bricksPerSqm': bricksPerSqm,
      'mortarPerSqm': mortarPerSqm,
      'conditionsMultiplier': conditionsMultiplier,
      'bricksNet': roundValue(bricksNet, 3),
      'bricksWithWaste': roundValue(recScenario.exactNeed, 3),
      'bricksNeeded': roundValue(recScenario.exactNeed, 3),
      'mortarVolume': mortarVolume,
      'cementKg': cementKg,
      'cementBags': cementBags.toDouble(),
      'sandM3': sandM3,
      'totalRows': totalRows.toDouble(),
      'meshInterval': meshInterval.toDouble(),
      'meshLayers': meshLayers.toDouble(),
      'meshLengthM': meshLengthM,
      'meshArea': meshLengthM,
      'plasticizerL': plasticizerL,
      'mortarAdditive': mortarAdditive.toDouble(),
      'flexibleTies': 0.0,
      'footprintArea': footprintArea,
      'perimeter': perimeter,
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
