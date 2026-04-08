import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


CanonicalCalculatorContractResult calculateCanonicalDrywall(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(drywallSpecData);

  final workType = (inputs['workType'] ?? defaultFor(spec, 'workType', 0)).round().clamp(0, 2);
  final length = math.max(0.5, math.min(30.0, inputs['length'] ?? defaultFor(spec, 'length', 5)));
  final height = math.max(1.5, math.min(5.0, inputs['height'] ?? defaultFor(spec, 'height', 2.7)));
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final sheetSize = (inputs['sheetSize'] ?? defaultFor(spec, 'sheetSize', 0)).round().clamp(0, 2);
  final profileStepRaw = inputs['profileStep'] ?? defaultFor(spec, 'profileStep', 0.6);
  final profileStep = profileStepRaw <= 0.4 ? 0.4 : 0.6;

  final area = roundValue(length * height, 3);
  final sides = workType == 0 ? 2 : 1;
  final totalSheetArea = area * sides * layers;

  final sheetSizes = spec.normativeValue<Map>('sheet_sizes') ?? {};
  final sheetDef = (sheetSizes['$sheetSize'] ?? sheetSizes['0']) as Map<String, dynamic>;
  final gklArea = (sheetDef['area'] as num).toDouble();
  final baseSheetsNeeded = (totalSheetArea / gklArea * spec.materialRule<num>('sheet_reserve').toDouble()).ceil();

  // Profile PN (perimeter)
  final pnPerimeter = 2 * (length + height);
  final pnLength = (pnPerimeter * spec.materialRule<num>('profile_reserve').toDouble() / spec.materialRule<num>('profile_length_m').toDouble()).ceil() * spec.materialRule<num>('profile_length_m').toDouble();
  final pnPieces = (pnLength / spec.materialRule<num>('profile_length_m').toDouble()).round();

  // Profile PP (studs)
  final ppCount = (length / profileStep).ceil() + 1;
  final ppLength = ppCount * height * spec.materialRule<num>('profile_reserve').toDouble();
  final ppPieces = (ppLength / spec.materialRule<num>('profile_length_m').toDouble()).ceil();

  // Screws (in kg)
  final screwsTFpcs = (totalSheetArea * spec.materialRule<num>('screws_tf_per_m2').toDouble() * spec.materialRule<num>('profile_reserve').toDouble()).ceil();
  final screwsTFkg = (screwsTFpcs / 1000 * 10).ceil() / 10; // 3.5×25 мм: 1000 шт/кг
  final screwsLBpcs = (ppCount * spec.materialRule<num>('screws_lb_per_profile').toDouble() * spec.materialRule<num>('profile_reserve').toDouble()).ceil();
  final screwsLBkg = (screwsLBpcs / 4000 * 10).ceil() / 10; // 3.5×9.5 мм клопы: 4000 шт/кг

  // Dowels
  final dowels = (pnPerimeter / spec.materialRule<num>('dowels_step_m').toDouble()).ceil();

  // Sealing tape
  final sealingTapeRolls = (pnPerimeter / spec.materialRule<num>('sealing_tape_roll_m').toDouble()).ceil();

  // Putty
  final puttyStartBags = (totalSheetArea * spec.materialRule<num>('putty_start_kg_per_m2').toDouble() * spec.materialRule<num>('putty_reserve').toDouble() / spec.materialRule<num>('putty_bag_kg').toDouble()).ceil();
  final puttyFinishBags = (totalSheetArea * spec.materialRule<num>('putty_finish_kg_per_m2').toDouble() * spec.materialRule<num>('putty_reserve').toDouble() / spec.materialRule<num>('putty_bag_kg').toDouble()).ceil();

  // Serpyanka
  final serpyankaRolls = (baseSheetsNeeded * spec.materialRule<num>('serpyanka_m_per_sheet').toDouble() * spec.materialRule<num>('serpyanka_reserve').toDouble() / spec.materialRule<num>('serpyanka_roll_m').toDouble()).ceil();

  // Primer
  final primerCans = (totalSheetArea * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can_l').toDouble()).ceil();

  // Sandpaper
  final sandpaperPacks = ((totalSheetArea / spec.materialRule<num>('sandpaper_m2_per_sheet').toDouble()).ceil() / spec.materialRule<num>('sandpaper_pack').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('drywall', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(baseSheetsNeeded * accuracyMult * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'gkl-sheet-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'workType:$workType',
        'sheetSize:$sheetSize',
        'layers:$layers',
        'profileStep:$profileStep',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
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
  if (height > spec.warningRule<num>('wide_profile_height_threshold').toDouble()) {
    warnings.add('Высота более 3.5 м — требуются профили шириной 100 мм');
  }
  if (layers == 2) {
    warnings.add('Второй слой ГКЛ монтируется со смещением 600 мм');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ГКЛ листы',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПН 27\u00d728 3м',
      quantity: pnPieces.toDouble(),
      unit: 'шт',
      withReserve: pnPieces.toDouble(),
      purchaseQty: pnPieces.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Профиль ПП 60\u00d727 3м',
      quantity: ppPieces.toDouble(),
      unit: 'шт',
      withReserve: ppPieces.toDouble(),
      purchaseQty: ppPieces.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы 3.5\u00d725 мм',
      quantity: screwsTFkg,
      unit: 'кг',
      withReserve: screwsTFkg,
      purchaseQty: screwsTFkg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы-клопы 3.5\u00d79.5 мм',
      quantity: screwsLBkg,
      unit: 'кг',
      withReserve: screwsLBkg,
      purchaseQty: screwsLBkg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбели 6\u00d740',
      quantity: dowels.toDouble(),
      unit: 'шт',
      withReserve: dowels.toDouble(),
      purchaseQty: dowels.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Лента уплотнительная (рулон 30м)',
      quantity: sealingTapeRolls.toDouble(),
      unit: 'рулон',
      withReserve: sealingTapeRolls.toDouble(),
      purchaseQty: sealingTapeRolls.toDouble(),
      category: 'Изоляция',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка стартовая 25кг',
      quantity: puttyStartBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyStartBags.toDouble(),
      purchaseQty: puttyStartBags.toDouble(),
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка финишная 25кг',
      quantity: puttyFinishBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyFinishBags.toDouble(),
      purchaseQty: puttyFinishBags.toDouble(),
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Серпянка 90м',
      quantity: serpyankaRolls.toDouble(),
      unit: 'рулонов',
      withReserve: serpyankaRolls.toDouble(),
      purchaseQty: serpyankaRolls.toDouble(),
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
    CanonicalMaterialResult(
      name: 'Наждачная бумага P180',
      quantity: sandpaperPacks.toDouble(),
      unit: 'упаковок',
      withReserve: sandpaperPacks.toDouble(),
      purchaseQty: sandpaperPacks.toDouble(),
      category: 'Отделка',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'workType': workType.toDouble(),
      'length': roundValue(length, 3),
      'height': roundValue(height, 3),
      'layers': layers.toDouble(),
      'sheetSize': sheetSize.toDouble(),
      'profileStep': profileStep,
      'sides': sides.toDouble(),
      'totalSheetArea': roundValue(totalSheetArea, 3),
      'gklArea': gklArea,
      'sheetsNeeded': roundValue(recScenario.exactNeed, 3),
      'pnPerimeter': roundValue(pnPerimeter, 3),
      'pnPieces': pnPieces.toDouble(),
      'ppCount': ppCount.toDouble(),
      'ppPieces': ppPieces.toDouble(),
      'screwsTF': screwsTFkg,
      'screwsLB': screwsLBkg,
      'dowels': dowels.toDouble(),
      'sealingTapeRolls': sealingTapeRolls.toDouble(),
      'puttyStartBags': puttyStartBags.toDouble(),
      'puttyFinishBags': puttyFinishBags.toDouble(),
      'serpyankaRolls': serpyankaRolls.toDouble(),
      'primerCans': primerCans.toDouble(),
      'sandpaperPacks': sandpaperPacks.toDouble(),
      'minExactNeedSheets': scenarios['MIN']!.exactNeed,
      'recExactNeedSheets': recScenario.exactNeed,
      'maxExactNeedSheets': scenarios['MAX']!.exactNeed,
      'minPurchaseSheets': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseSheets': recScenario.purchaseQuantity,
      'maxPurchaseSheets': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
