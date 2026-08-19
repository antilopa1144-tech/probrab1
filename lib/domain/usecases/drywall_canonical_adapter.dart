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

  final workType = (inputs['workType'] ?? defaultFor(spec, 'workType', 0))
      .round()
      .clamp(0, 2);
  final inputMode =
      (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round() == 1
      ? 1
      : 0;
  final wallScope =
      workType == 1 &&
          (inputs['wallScope'] ?? defaultFor(spec, 'wallScope', 0)).round() == 1
      ? 1
      : 0;
  final sourceLength = math.max(
    0.5,
    math.min(30.0, inputs['length'] ?? defaultFor(spec, 'length', 5)),
  );
  final height = math.max(
    1.5,
    math.min(5.0, inputs['height'] ?? defaultFor(spec, 'height', 2.7)),
  );
  final roomLength = math.max(
    0.5,
    math.min(30.0, inputs['roomLength'] ?? defaultFor(spec, 'roomLength', 5)),
  );
  final roomWidth = math.max(
    0.5,
    math.min(30.0, inputs['roomWidth'] ?? defaultFor(spec, 'roomWidth', 4)),
  );
  final requestedArea = math.max(
    0.1,
    math.min(1000.0, inputs['area'] ?? defaultFor(spec, 'area', 20)),
  );
  final segments = inputMode == 1
      ? <double>[requestedArea / height]
      : wallScope == 1
      ? <double>[roomLength, roomWidth, roomLength, roomWidth]
      : <double>[sourceLength];
  final wallRun = segments.fold<double>(0, (sum, segment) => sum + segment);
  final grossArea = inputMode == 1 ? requestedArea : wallRun * height;
  final requestedOpenings = math.max(
    0.0,
    inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 0),
  );
  final openingsArea = inputMode == 1
      ? 0.0
      : math.min(requestedOpenings, math.max(0.0, grossArea - 0.1));
  final area = roundValue(math.max(0.1, grossArea - openingsArea), 3);
  final length = inputMode == 1 ? requestedArea / height : sourceLength;
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final sheetSize = (inputs['sheetSize'] ?? defaultFor(spec, 'sheetSize', 0))
      .round()
      .clamp(0, 2);
  final profileStepRaw =
      inputs['profileStep'] ?? defaultFor(spec, 'profileStep', 0.6);
  final profileStep = profileStepRaw <= 0.4 ? 0.4 : 0.6;

  final sides = workType == 0 ? 2 : 1;
  final totalSheetArea = area * sides * layers;

  final sheetSizes = spec.normativeValue<Map>('sheet_sizes') ?? {};
  final sheetDef =
      (sheetSizes['$sheetSize'] ?? sheetSizes['0']) as Map<String, dynamic>;
  final gklArea = (sheetDef['area'] as num).toDouble();
  final baseSheetsNeeded =
      (totalSheetArea /
              gklArea *
              spec.materialRule<num>('sheet_reserve').toDouble())
          .ceil();

  // Для перегородки направляющий профиль идёт по полу и потолку.
  // У облицовки каждая выбранная стена считается отдельной рамой.
  final pnPerimeter = workType == 0
      ? 2 * wallRun
      : segments.fold<double>(
          0,
          (sum, segment) => sum + 2 * (segment + height),
        );
  final pnLength =
      (pnPerimeter *
              spec.materialRule<num>('profile_reserve').toDouble() /
              spec.materialRule<num>('profile_length_m').toDouble())
          .ceil() *
      spec.materialRule<num>('profile_length_m').toDouble();
  final pnPieces =
      (pnLength / spec.materialRule<num>('profile_length_m').toDouble())
          .round();

  final ppCount = segments.fold<int>(
    0,
    (sum, segment) => sum + (segment / profileStep).ceil() + 1,
  );
  final ppLength =
      ppCount * height * spec.materialRule<num>('profile_reserve').toDouble();
  final ppPieces =
      (ppLength / spec.materialRule<num>('profile_length_m').toDouble()).ceil();

  // Саморезы считаются поштучно; второй слой крепится более длинными.
  final layerSheetArea = area * sides;
  final screws25Pcs =
      (layerSheetArea *
              spec.materialRule<num>('screws_tf_per_m2').toDouble() *
              spec.materialRule<num>('profile_reserve').toDouble())
          .ceil();
  final screws35Pcs = layers == 2
      ? (layerSheetArea *
                spec.materialRule<num>('screws_tf_per_m2').toDouble() *
                spec.materialRule<num>('profile_reserve').toDouble())
            .ceil()
      : 0;
  final screwsTFpcs = screws25Pcs + screws35Pcs;
  final screwsLBpcs =
      (ppCount *
              spec.materialRule<num>('screws_lb_per_profile').toDouble() *
              spec.materialRule<num>('profile_reserve').toDouble())
          .ceil();

  // Dowels
  final dowels =
      (pnPerimeter / spec.materialRule<num>('dowels_step_m').toDouble()).ceil();

  // Sealing tape
  final sealingTapeRolls =
      (pnPerimeter / spec.materialRule<num>('sealing_tape_roll_m').toDouble())
          .ceil();

  // Putty
  final puttyStartBags =
      (totalSheetArea *
              spec.materialRule<num>('putty_start_kg_per_m2').toDouble() *
              spec.materialRule<num>('putty_reserve').toDouble() /
              spec.materialRule<num>('putty_bag_kg').toDouble())
          .ceil();
  final puttyFinishBags =
      (totalSheetArea *
              spec.materialRule<num>('putty_finish_kg_per_m2').toDouble() *
              spec.materialRule<num>('putty_reserve').toDouble() /
              spec.materialRule<num>('putty_bag_kg').toDouble())
          .ceil();

  // Serpyanka
  final serpyankaRolls =
      (baseSheetsNeeded *
              spec.materialRule<num>('serpyanka_m_per_sheet').toDouble() *
              spec.materialRule<num>('serpyanka_reserve').toDouble() /
              spec.materialRule<num>('serpyanka_roll_m').toDouble())
          .ceil();

  // Primer
  final primerCans =
      (totalSheetArea *
              spec.materialRule<num>('primer_l_per_m2').toDouble() *
              spec.materialRule<num>('primer_reserve').toDouble() /
              spec.materialRule<num>('primer_can_l').toDouble())
          .ceil();

  // Sandpaper
  final sandpaperPacks =
      ((totalSheetArea /
                      spec
                          .materialRule<num>('sandpaper_m2_per_sheet')
                          .toDouble())
                  .ceil() /
              spec.materialRule<num>('sandpaper_pack').toDouble())
          .ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('drywall', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(
      baseSheetsNeeded * accuracyMult * multiplier,
      6,
    );
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel =
        'gkl-sheet-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'workType:$workType',
        'inputMode:$inputMode',
        'wallScope:$wallScope',
        'sheetSize:$sheetSize',
        'layers:$layers',
        'profileStep:$profileStep',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(
          spec.enabledFactors,
          defaultFactorTable,
          scenarioName,
        ),
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
  final sheetWidth = ((sheetDef['w'] as num).toDouble() * 1000).round();
  final sheetHeight = ((sheetDef['h'] as num).toDouble() * 1000).round();
  final isPartition = workType == 0;
  final guideProfileName = isPartition
      ? 'Направляющий профиль ПН 50×40 мм, длина 3 м'
      : 'Направляющий профиль ПН 27×28 мм, длина 3 м';
  final mainProfileName = isPartition
      ? 'Стоечный профиль ПС 50×50 мм, длина 3 м'
      : 'Потолочный профиль ПП 60×27 мм, длина 3 м';
  final screwsTfPackage = spec
      .materialRule<num>('screws_tf_package_pcs')
      .toInt();
  final screwsLbPackage = spec
      .materialRule<num>('screws_lb_package_pcs')
      .toInt();

  final warnings = <String>[];
  if (height >
      spec.warningRule<num>('wide_profile_height_threshold').toDouble()) {
    warnings.add('Высота более 3.5 м — требуются профили шириной 100 мм');
  }
  if (layers == 2) {
    warnings.add('Второй слой ГКЛ монтируется со смещением 600 мм');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Гипсокартонный лист (ГКЛ) 12,5×$sheetWidth×$sheetHeight мм',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: guideProfileName,
      quantity: pnPieces.toDouble(),
      unit: 'шт',
      withReserve: pnPieces.toDouble(),
      purchaseQty: pnPieces.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: mainProfileName,
      quantity: ppPieces.toDouble(),
      unit: 'шт',
      withReserve: ppPieces.toDouble(),
      purchaseQty: ppPieces.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы по металлу для гипсокартона 3,5×25 мм',
      quantity: screws25Pcs.toDouble(),
      unit: 'шт',
      withReserve: screws25Pcs.toDouble(),
      purchaseQty:
          (screws25Pcs / screwsTfPackage).ceil() * screwsTfPackage.toDouble(),
      category: 'Крепёж',
    ),
    if (screws35Pcs > 0)
      CanonicalMaterialResult(
        name: 'Саморезы по металлу для гипсокартона 3,5×35 мм',
        quantity: screws35Pcs.toDouble(),
        unit: 'шт',
        withReserve: screws35Pcs.toDouble(),
        purchaseQty:
            (screws35Pcs / screwsTfPackage).ceil() * screwsTfPackage.toDouble(),
        category: 'Крепёж',
      ),
    CanonicalMaterialResult(
      name: 'Саморезы с прессшайбой 3,5×9,5 мм для сборки каркаса',
      quantity: screwsLBpcs.toDouble(),
      unit: 'шт',
      withReserve: screwsLBpcs.toDouble(),
      purchaseQty:
          (screwsLBpcs / screwsLbPackage).ceil() * screwsLbPackage.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбель-гвозди 6×40 мм',
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
      name: 'Грунтовка глубокого проникновения (10 л)',
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
      'grossArea': roundValue(grossArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'inputMode': inputMode.toDouble(),
      'wallScope': wallScope.toDouble(),
      'workType': workType.toDouble(),
      'length': roundValue(length, 3),
      'roomLength': roundValue(roomLength, 3),
      'roomWidth': roundValue(roomWidth, 3),
      'wallRun': roundValue(wallRun, 3),
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
      'screwsTF': screwsTFpcs.toDouble(),
      'screwsLB': screwsLBpcs.toDouble(),
      'screws25Pcs': screws25Pcs.toDouble(),
      'screws35Pcs': screws35Pcs.toDouble(),
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
