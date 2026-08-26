import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

String _compactNumber(double value, [int decimals = 3]) {
  final fixed = value.toStringAsFixed(decimals);
  if (!fixed.contains('.')) return fixed;
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

CanonicalCalculatorContractResult calculateCanonicalDrywallCeiling(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(drywallCeilingSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0))
      .round()
      .clamp(0, 1);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(
    1.0,
    20.0,
  );
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(
    1.0,
    20.0,
  );
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 20)).clamp(
    1.0,
    200.0,
  );
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final area = inputMode == 0 ? roundValue(length * width, 3) : areaInput;
  final effectiveLength = inputMode == 0 ? length : math.sqrt(area);
  final effectiveWidth = inputMode == 0 ? width : math.sqrt(area);
  final perimeter = 2 * (effectiveLength + effectiveWidth);
  final sheetWidthM =
      math.max(
        600,
        inputs['sheetWidthMm'] ?? defaultFor(spec, 'sheetWidthMm', 1200),
      ) /
      1000;
  final sheetLengthM =
      math.max(
        1200,
        inputs['sheetLengthMm'] ?? defaultFor(spec, 'sheetLengthMm', 2500),
      ) /
      1000;
  final sheetArea = sheetWidthM * sheetLengthM;
  final sheetReservePercent = math
      .max(
        0,
        inputs['sheetReservePercent'] ??
            defaultFor(spec, 'sheetReservePercent', 10),
      )
      .toDouble();
  final profileLengthM = math
      .max(2, inputs['profileLengthM'] ?? defaultFor(spec, 'profileLengthM', 3))
      .toDouble();
  final profileReservePercent = math
      .max(
        0,
        inputs['profileReservePercent'] ??
            defaultFor(spec, 'profileReservePercent', 5),
      )
      .toDouble();
  final fastenerReservePercent = math
      .max(
        0,
        inputs['fastenerReservePercent'] ??
            defaultFor(spec, 'fastenerReservePercent', 5),
      )
      .toDouble();
  final finishReservePercent = math
      .max(
        0,
        inputs['finishReservePercent'] ??
            defaultFor(spec, 'finishReservePercent', 10),
      )
      .toDouble();
  final screwPackCount = math.max(
    100,
    (inputs['screwPackCount'] ?? defaultFor(spec, 'screwPackCount', 1000))
        .round(),
  );
  final tapeRollM = math
      .max(10, inputs['tapeRollM'] ?? defaultFor(spec, 'tapeRollM', 45))
      .toDouble();
  final puttyBagKg = math
      .max(1, inputs['puttyBagKg'] ?? defaultFor(spec, 'puttyBagKg', 25))
      .toDouble();
  final primerRateLPerM2 = math
      .max(
        0.05,
        inputs['primerRateLPerM2'] ??
            defaultFor(spec, 'primerRateLPerM2', 0.15),
      )
      .toDouble();
  final primerCanL = math
      .max(0.5, inputs['primerCanL'] ?? defaultFor(spec, 'primerCanL', 5))
      .toDouble();

  double reserveMultiplier(double percent) => 1 + percent / 100;
  final baseSheets = area * layers / sheetArea;
  final recSheets = baseSheets * reserveMultiplier(sheetReservePercent);
  final maxExtraSheetPercent = spec
      .materialRule<num>('max_extra_sheet_percent')
      .toDouble();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final reservePercent = scenarioName == 'MIN'
        ? 0.0
        : scenarioName == 'MAX'
        ? sheetReservePercent + maxExtraSheetPercent
        : sheetReservePercent;
    final multiplier = reserveMultiplier(reservePercent);
    final exactNeed = roundValue(baseSheets * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'input_mode:$inputMode',
        'layers:$layers',
        'sheet:${roundValue(sheetWidthM * 1000, 0)}x${roundValue(sheetLengthM * 1000, 0)}',
        'scenario_policy:explicit_sheet_reserve',
      ],
      keyFactors: {
        'field_multiplier': roundValue(multiplier, 6),
        'reserve_percent': roundValue(reservePercent, 3),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'gkl-sheet',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final profileBaseM = area * spec.materialRule<num>('pp_m_per_m2').toDouble();
  final totalProfileM = profileBaseM * reserveMultiplier(profileReservePercent);
  final ppPcs = (totalProfileM / profileLengthM).ceil();
  final pnBaseM = perimeter;
  final pnM = pnBaseM * reserveMultiplier(profileReservePercent);
  final pnPcs = (pnM / profileLengthM).ceil();
  final suspensionsBase =
      area * spec.materialRule<num>('suspension_per_m2').toDouble();
  final suspCount =
      (suspensionsBase * reserveMultiplier(fastenerReservePercent)).ceil();
  final connectorsBase =
      area * spec.materialRule<num>('connector_per_m2').toDouble();
  final crabCount = (connectorsBase * reserveMultiplier(fastenerReservePercent))
      .ceil();
  final screwsGKL =
      area *
      layers *
      spec.materialRule<num>('screws_per_m2_per_layer').toDouble();
  final screwsWithReserve =
      screwsGKL * reserveMultiplier(fastenerReservePercent);
  final screwPacks = (screwsWithReserve / screwPackCount).ceil();
  final perimeterDowelsBase =
      perimeter / spec.materialRule<num>('perimeter_dowel_step_m').toDouble();
  final perimeterDowels =
      (perimeterDowelsBase * reserveMultiplier(fastenerReservePercent)).ceil();
  final ceilingAnchors = suspCount;
  final dowelCount = ceilingAnchors + perimeterDowels;
  final tapeBaseM = area * spec.materialRule<num>('tape_m_per_m2').toDouble();
  final tapeM = tapeBaseM * reserveMultiplier(finishReservePercent);
  final tapeRolls = (tapeM / tapeRollM).ceil();
  final puttyBaseKg =
      area * spec.materialRule<num>('putty_kg_per_m2').toDouble();
  final puttyKg = puttyBaseKg * reserveMultiplier(finishReservePercent);
  final puttyBags = (puttyKg / puttyBagKg).ceil();
  final primerBaseL = area * primerRateLPerM2;
  final primerL = primerBaseL * reserveMultiplier(finishReservePercent);
  final primerCans = (primerL / primerCanL).ceil();

  // Warnings
  final warnings = <String>[];
  if (layers == 2) {
    warnings.add(
      'Для двух слоёв нужна разбежка стыков; допустимость каркаса и нагрузки проверьте по выбранной системе',
    );
  }
  if (area >
      spec.warningRule<num>('deformation_joint_area_threshold_m2').toDouble()) {
    warnings.add(
      'Площадь более 50 м\u00b2 — расположение деформационных швов должен определить проект',
    );
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name:
          'Гипсокартонные листы (ГКЛ) ${_compactNumber(sheetWidthM * 1000, 0)}×${_compactNumber(sheetLengthM * 1000, 0)} мм для потолка',
      quantity: roundValue(baseSheets, 6),
      unit: 'шт',
      withReserve: roundValue(recSheets, 6),
      purchaseQty: recScenario.purchaseQuantity,
      category: 'Основное',
      packageInfo: {
        'count': recScenario.buyPlan.packagesCount,
        'size': 1.0,
        'packageUnit': 'листов',
      },
    ),
    CanonicalMaterialResult(
      name:
          'Потолочный профиль ПП 60×27×${_compactNumber(profileLengthM * 1000, 0)} мм',
      quantity: roundValue(profileBaseM / profileLengthM, 6),
      unit: 'шт',
      withReserve: roundValue(totalProfileM / profileLengthM, 6),
      purchaseQty: ppPcs.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name:
          'Направляющий профиль ПН 27×28×${_compactNumber(profileLengthM * 1000, 0)} мм',
      quantity: roundValue(pnBaseM / profileLengthM, 6),
      unit: 'шт',
      withReserve: roundValue(pnM / profileLengthM, 6),
      purchaseQty: pnPcs.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Подвес для профиля 60×27 мм',
      quantity: roundValue(suspensionsBase, 6),
      unit: 'шт',
      withReserve: suspCount.toDouble(),
      purchaseQty: suspCount.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Одноуровневый соединитель («краб») для ПП 60×27 мм',
      quantity: roundValue(connectorsBase, 6),
      unit: 'шт',
      withReserve: crabCount.toDouble(),
      purchaseQty: crabCount.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: layers == 2
          ? 'Саморезы для ГКЛ по металлу: первый и второй слой'
          : 'Саморезы для ГКЛ по металлу 3,5×25 мм',
      quantity: roundValue(screwsGKL, 6),
      unit: 'шт',
      withReserve: roundValue(screwsWithReserve, 6),
      purchaseQty: (screwPacks * screwPackCount).toDouble(),
      category: 'Крепёж',
      packageInfo: {
        'count': screwPacks,
        'size': screwPackCount.toDouble(),
        'packageUnit': 'упаковок',
      },
    ),
    CanonicalMaterialResult(
      name:
          'Крепёж к основанию: металлические анкеры подвесов и дюбели направляющего профиля',
      quantity: roundValue(suspensionsBase + perimeterDowelsBase, 6),
      unit: 'шт',
      withReserve: dowelCount.toDouble(),
      purchaseQty: dowelCount.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Армирующая лента для швов (${_compactNumber(tapeRollM, 1)} м)',
      quantity: roundValue(tapeBaseM, 6),
      unit: 'м',
      withReserve: roundValue(tapeM, 6),
      purchaseQty: tapeRolls * tapeRollM,
      category: 'Отделка',
      packageInfo: {
        'count': tapeRolls,
        'size': tapeRollM,
        'packageUnit': 'рулонов',
      },
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка для стыков ГКЛ (${_compactNumber(puttyBagKg, 1)} кг)',
      quantity: roundValue(puttyBaseKg, 6),
      unit: 'кг',
      withReserve: roundValue(puttyKg, 6),
      purchaseQty: puttyBags * puttyBagKg,
      category: 'Отделка',
      packageInfo: {
        'count': puttyBags,
        'size': puttyBagKg,
        'packageUnit': 'мешков',
      },
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (${_compactNumber(primerCanL, 1)} л)',
      quantity: roundValue(primerBaseL, 6),
      unit: 'л',
      withReserve: roundValue(primerL, 6),
      purchaseQty: primerCans * primerCanL,
      category: 'Отделка',
      packageInfo: {
        'count': primerCans,
        'size': primerCanL,
        'packageUnit': 'канистр',
      },
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'perimeter': roundValue(perimeter, 3),
      'inputMode': inputMode.toDouble(),
      'length': inputMode == 0 ? roundValue(length, 3) : 0.0,
      'width': inputMode == 0 ? roundValue(width, 3) : 0.0,
      'layers': layers.toDouble(),
      'sheetWidthMm': roundValue(sheetWidthM * 1000, 0),
      'sheetLengthMm': roundValue(sheetLengthM * 1000, 0),
      'sheetArea': roundValue(sheetArea, 6),
      'sheetReservePercent': roundValue(sheetReservePercent, 3),
      'baseSheets': roundValue(baseSheets, 6),
      'sheets': recScenario.purchaseQuantity,
      'profileLengthM': roundValue(profileLengthM, 3),
      'profileReservePercent': roundValue(profileReservePercent, 3),
      'profileBaseM': roundValue(profileBaseM, 6),
      'totalProfileM': roundValue(totalProfileM, 6),
      'ppPcs': ppPcs.toDouble(),
      'pnM': roundValue(pnM, 6),
      'pnPcs': pnPcs.toDouble(),
      'suspCount': suspCount.toDouble(),
      'crabCount': crabCount.toDouble(),
      'screwsGKL': roundValue(screwsGKL, 6),
      'screwsWithReserve': roundValue(screwsWithReserve, 6),
      'screwPacks': screwPacks.toDouble(),
      'screwPackCount': screwPackCount.toDouble(),
      'dowelCount': dowelCount.toDouble(),
      'ceilingAnchors': ceilingAnchors.toDouble(),
      'perimeterDowels': perimeterDowels.toDouble(),
      'tapeM': roundValue(tapeM, 6),
      'tapeRolls': tapeRolls.toDouble(),
      'puttyKg': roundValue(puttyKg, 6),
      'puttyBags': puttyBags.toDouble(),
      'primerL': roundValue(primerL, 6),
      'primerCans': primerCans.toDouble(),
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
