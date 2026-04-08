import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';




CanonicalCalculatorContractResult calculateCanonicalDrywallCeiling(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(drywallCeilingSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(1.0, 20.0);
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(1.0, 20.0);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 20)).clamp(1.0, 200.0);
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final profileStepRaw = inputs['profileStep'] ?? defaultFor(spec, 'profileStep', 600);
  final profileStep = profileStepRaw <= 400 ? 400.0 : 600.0;

  // Area
  final area = inputMode == 0 ? roundValue(length * width, 3) : areaInput;

  // Sheets
  final sheets = (area * layers / spec.materialRule<num>('sheet_area').toDouble() * spec.materialRule<num>('sheet_reserve').toDouble()).ceil();

  // Profiles
  final mainProfileRows = (width / (profileStep / 1000)).ceil();
  final mainM = mainProfileRows * length;
  final crossRows = (length / spec.materialRule<num>('cross_step').toDouble()).ceil();
  final crossM = crossRows * width;
  final totalProfileM = (mainM + crossM) * spec.materialRule<num>('profile_reserve').toDouble();
  final ppPcs = (totalProfileM / spec.materialRule<num>('profile_length').toDouble()).ceil();

  final effectiveLength = inputMode == 0 ? length : math.sqrt(area);
  final effectiveWidth = inputMode == 0 ? width : math.sqrt(area);
  final pnM = 2 * (effectiveLength + effectiveWidth) * spec.materialRule<num>('profile_reserve').toDouble();
  final pnPcs = (pnM / spec.materialRule<num>('profile_length').toDouble()).ceil();

  // Suspensions & crabs
  final suspCount = mainProfileRows * (length / spec.materialRule<num>('suspension_step').toDouble()).ceil();
  final crabCount = mainProfileRows * crossRows;

  // Screws
  final screwsGKL = sheets * spec.materialRule<num>('screws_per_sheet').toDouble();
  final screwsKg = (screwsGKL * spec.materialRule<num>('screw_reserve').toDouble() / spec.materialRule<num>('screws_per_kg').toDouble() * 10).ceil() / 10;

  // Clop screws
  final clopCount = suspCount * spec.materialRule<num>('clop_per_susp').toDouble() + crabCount * spec.materialRule<num>('clop_per_crab').toDouble();

  // Dowels
  final dowelCount = suspCount * 2 + (pnM / spec.materialRule<num>('dowel_step').toDouble()).ceil();

  // Serpyanka
  final serpM = (area * spec.materialRule<num>('serpyanka_coeff').toDouble() * spec.materialRule<num>('serpyanka_reserve').toDouble()).ceil();
  final serpRolls = (serpM / spec.materialRule<num>('serpyanka_roll').toDouble()).ceil();

  // Putty
  final puttyKg = (serpM * spec.materialRule<num>('putty_kg_per_m').toDouble()).ceil();
  final puttyBags = (puttyKg / spec.materialRule<num>('putty_bag').toDouble()).ceil();

  // Primer
  final primerL = area * spec.materialRule<num>('primer_l_per_m2').toDouble();
  final primerCans = (primerL * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('drywall', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(sheets * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'layers:$layers',
        'profileStep:$profileStep',
        'packaging:gkl-ceiling-${spec.packagingRule<num>('package_size').toDouble()}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'gkl-ceiling-${spec.packagingRule<num>('package_size').toDouble()}',
        packageSize: spec.packagingRule<num>('package_size').toDouble(),
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (layers == 2) {
    warnings.add('Второй слой ГКЛ монтируется со смещением 400 мм');
  }
  if (area > spec.warningRule<num>('deformation_joint_area_threshold_m2').toDouble()) {
    warnings.add('Площадь более 50 м\u00b2 — предусмотрите деформационные швы');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ГКЛ листы',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПП 60\u00d727 3м',
      quantity: ppPcs.toDouble(),
      unit: 'шт',
      withReserve: ppPcs.toDouble(),
      purchaseQty: ppPcs.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПН 27\u00d728 3м',
      quantity: pnPcs.toDouble(),
      unit: 'шт',
      withReserve: pnPcs.toDouble(),
      purchaseQty: pnPcs.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Подвесы прямые',
      quantity: suspCount.toDouble(),
      unit: 'шт',
      withReserve: suspCount.toDouble(),
      purchaseQty: suspCount.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Крабы (соединители)',
      quantity: crabCount.toDouble(),
      unit: 'шт',
      withReserve: crabCount.toDouble(),
      purchaseQty: crabCount.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы 3.5\u00d725 (кг)',
      quantity: screwsKg,
      unit: 'кг',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы-клопы',
      quantity: clopCount.toDouble(),
      unit: 'шт',
      withReserve: clopCount.toDouble(),
      purchaseQty: clopCount.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбели',
      quantity: dowelCount.toDouble(),
      unit: 'шт',
      withReserve: dowelCount.toDouble(),
      purchaseQty: dowelCount.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Серпянка 45м',
      quantity: serpRolls.toDouble(),
      unit: 'рулонов',
      withReserve: serpRolls.toDouble(),
      purchaseQty: serpRolls.toDouble(),
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка Knauf Fugen 25кг',
      quantity: puttyBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyBags.toDouble(),
      purchaseQty: puttyBags.toDouble(),
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка 10л',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toDouble(),
      category: 'Отделка',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'length': inputMode == 0 ? roundValue(length, 3) : 0.0,
      'width': inputMode == 0 ? roundValue(width, 3) : 0.0,
      'layers': layers.toDouble(),
      'profileStep': profileStep,
      'sheets': sheets.toDouble(),
      'mainProfileRows': mainProfileRows.toDouble(),
      'mainM': roundValue(mainM, 3),
      'crossRows': crossRows.toDouble(),
      'crossM': roundValue(crossM, 3),
      'totalProfileM': roundValue(totalProfileM, 3),
      'ppPcs': ppPcs.toDouble(),
      'pnM': roundValue(pnM, 3),
      'pnPcs': pnPcs.toDouble(),
      'suspCount': suspCount.toDouble(),
      'crabCount': crabCount.toDouble(),
      'screwsGKL': screwsGKL.toDouble(),
      'screwsKg': screwsKg,
      'clopCount': clopCount.toDouble(),
      'dowelCount': dowelCount.toDouble(),
      'serpM': serpM.toDouble(),
      'serpRolls': serpRolls.toDouble(),
      'puttyKg': puttyKg.toDouble(),
      'puttyBags': puttyBags.toDouble(),
      'primerL': roundValue(primerL, 3),
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
