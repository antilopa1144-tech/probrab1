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

const Map<int, String> _slopeTypeLabels = {
  0: 'Сэндвич-панели ПВХ',
  1: 'Штукатурка',
  2: 'ГКЛ',
};


bool hasCanonicalWindowsInputs(Map<String, double> inputs) {
  return inputs.containsKey('windowCount') ||
      inputs.containsKey('windowWidth') ||
      inputs.containsKey('slopeType');
}

Map<String, double> normalizeLegacyWindowsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['windowCount'] = (inputs['windowCount'] ?? 5).toDouble();
  normalized['windowWidth'] = (inputs['windowWidth'] ?? 1200).toDouble();
  normalized['windowHeight'] = (inputs['windowHeight'] ?? 1400).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 500).toDouble();
  normalized['slopeType'] = (inputs['slopeType'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalWindows(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(windowsSpecData);

  final normalized = hasCanonicalWindowsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyWindowsInputs(inputs);

  final windowCount = (normalized['windowCount'] ?? defaultFor(spec, 'windowCount', 5)).round().clamp(1, 20);
  final windowWidth = (normalized['windowWidth'] ?? defaultFor(spec, 'windowWidth', 1200)).round().clamp(600, 2100);
  final windowHeight = (normalized['windowHeight'] ?? defaultFor(spec, 'windowHeight', 1400)).round().clamp(900, 2000);
  final wallThickness = (normalized['wallThickness'] ?? defaultFor(spec, 'wallThickness', 500)).round().clamp(200, 600);
  final slopeType = (normalized['slopeType'] ?? defaultFor(spec, 'slopeType', 0)).round().clamp(0, 2);

  // Geometry
  final perimM = 2 * (windowWidth + windowHeight) / 1000;

  // PSUL / IFLUL
  final psulRolls = (perimM * windowCount * spec.materialRule<num>('psul_reserve').toDouble() / spec.materialRule<num>('psul_roll_m').toDouble()).ceil();
  final iflulRolls = (perimM * windowCount * spec.materialRule<num>('psul_reserve').toDouble() / spec.materialRule<num>('iflul_roll_m').toDouble()).ceil();

  // Foam
  final foamCans = (perimM / 3 * windowCount * spec.materialRule<num>('foam_reserve').toDouble()).ceil();

  // Anchors & screws
  final anchorsPerWindow = (perimM / spec.materialRule<num>('anchor_step').toDouble()).ceil();
  final totalAnchors = (anchorsPerWindow * windowCount * spec.materialRule<num>('anchor_reserve').toDouble()).ceil();
  final screwsPcs = (totalAnchors * 2 * spec.materialRule<num>('screw_reserve').toDouble()).ceil();
  final screwsKg = (screwsPcs / 1000 * 10).ceil() / 10; // 3.5×25 мм: 1000 шт/кг

  // Windowsill
  final sillWidth = wallThickness / 1000 + spec.materialRule<num>('windowsill_overhang').toDouble();
  final sillPcs = windowCount;

  // Slopes
  final slopeSideArea = 2 * (windowHeight / 1000) * (wallThickness / 1000);
  final slopeTopArea = (windowWidth / 1000) * (wallThickness / 1000);
  final totalSlopeArea = (slopeSideArea + slopeTopArea) * windowCount;

  // Slope materials by type
  var sandwichPcs = 0;
  var fProfilePcs = 0;
  var plasterBags = 0;
  var cornerPcs = 0;
  var gklSheets = 0;
  var screwsGKL = 0;
  var puttyBags = 0;

  if (slopeType == 0) {
    sandwichPcs = (totalSlopeArea * spec.materialRule<num>('slope_sandwich_reserve').toDouble() / spec.materialRule<num>('sandwich_panel_m2').toDouble()).ceil();
    final fProfileLen = perimM * 0.75 * windowCount * spec.materialRule<num>('psul_reserve').toDouble();
    fProfilePcs = (fProfileLen / spec.materialRule<num>('f_profile_length').toDouble()).ceil();
  } else if (slopeType == 1) {
    plasterBags = (totalSlopeArea * spec.materialRule<num>('plaster_kg_per_m2').toDouble() / spec.materialRule<num>('plaster_bag').toDouble()).ceil();
    cornerPcs = (perimM * 0.75 * windowCount * spec.materialRule<num>('psul_reserve').toDouble() / 3).ceil();
  } else {
    gklSheets = (totalSlopeArea * spec.materialRule<num>('slope_gkl_reserve').toDouble() / spec.materialRule<num>('gkl_sheet_m2').toDouble()).ceil();
    final screwsGKLpcs = (gklSheets * 20 * spec.materialRule<num>('screw_reserve').toDouble()).ceil();
    screwsGKL = (screwsGKLpcs / 1000 * 10).ceil(); // *10 for rounding
    puttyBags = (totalSlopeArea * 1.2 / spec.materialRule<num>('plaster_bag').toDouble()).ceil();
  }

  // Scenarios
  final basePrimary = foamCans;
  const packageLabel = 'foam-can';
  const packageUnit = 'баллонов';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'slopeType:$slopeType',
        'windowWidth:$windowWidth',
        'windowHeight:$windowHeight',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (windowWidth >= spec.warningRule<num>('wide_window_threshold_mm').toDouble()) {
    warnings.add('Для широких окон рекомендуется усиленный монтаж');
  }
  if (wallThickness >= spec.warningRule<num>('thick_wall_threshold_mm').toDouble()) {
    warnings.add('Толстые стены — проверьте глубину подоконника');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ПСУЛ (рулон ${spec.materialRule<num>('psul_roll_m').toDouble()} м)',
      quantity: psulRolls.toDouble(),
      unit: 'рулонов',
      withReserve: psulRolls.toDouble(),
      purchaseQty: psulRolls.toDouble(),
      category: 'Лента',
    ),
    CanonicalMaterialResult(
      name: 'Внутренняя лента (рулон ${spec.materialRule<num>('iflul_roll_m').toDouble()} м)',
      quantity: iflulRolls.toDouble(),
      unit: 'рулонов',
      withReserve: iflulRolls.toDouble(),
      purchaseQty: iflulRolls.toDouble(),
      category: 'Лента',
    ),
    CanonicalMaterialResult(
      name: 'Монтажная пена',
      quantity: recScenario.exactNeed,
      unit: 'баллонов',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Анкерные пластины',
      quantity: totalAnchors.toDouble(),
      unit: 'шт',
      withReserve: totalAnchors.toDouble(),
      purchaseQty: totalAnchors.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы для анкеров',
      quantity: screwsKg,
      unit: 'кг',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Подоконник (ширина ${(sillWidth * 1000).round()} мм)',
      quantity: sillPcs.toDouble(),
      unit: 'шт',
      withReserve: sillPcs.toDouble(),
      purchaseQty: sillPcs.toDouble(),
      category: 'Подоконники',
    ),
  ];

  if (slopeType == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_slopeTypeLabels[0]}',
        quantity: sandwichPcs.toDouble(),
        unit: 'шт',
        withReserve: sandwichPcs.toDouble(),
        purchaseQty: sandwichPcs.toDouble(),
        category: 'Откосы',
      ),
      CanonicalMaterialResult(
        name: 'F-профиль (${spec.materialRule<num>('f_profile_length').toDouble().round()} м)',
        quantity: fProfilePcs.toDouble(),
        unit: 'шт',
        withReserve: fProfilePcs.toDouble(),
        purchaseQty: fProfilePcs.toDouble(),
        category: 'Откосы',
      ),
    ]);
  } else if (slopeType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Штукатурка (мешки ${spec.materialRule<num>('plaster_bag').toDouble().round()} кг)',
        quantity: plasterBags.toDouble(),
        unit: 'мешков',
        withReserve: plasterBags.toDouble(),
        purchaseQty: plasterBags.toDouble(),
        category: 'Откосы',
      ),
      CanonicalMaterialResult(
        name: 'Уголок перфорированный',
        quantity: cornerPcs.toDouble(),
        unit: 'шт',
        withReserve: cornerPcs.toDouble(),
        purchaseQty: cornerPcs.toDouble(),
        category: 'Откосы',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ГКЛ для откосов',
        quantity: gklSheets.toDouble(),
        unit: 'листов',
        withReserve: gklSheets.toDouble(),
        purchaseQty: gklSheets.toDouble(),
        category: 'Откосы',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы для ГКЛ',
        quantity: screwsGKL / 10,
        unit: 'кг',
        withReserve: screwsGKL / 10,
        purchaseQty: (screwsGKL / 10).ceil().toDouble(),
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (мешки ${spec.materialRule<num>('plaster_bag').toDouble().round()} кг)',
        quantity: puttyBags.toDouble(),
        unit: 'мешков',
        withReserve: puttyBags.toDouble(),
        purchaseQty: puttyBags.toDouble(),
        category: 'Откосы',
      ),
    ]);
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'windowCount': windowCount.toDouble(),
      'windowWidth': windowWidth.toDouble(),
      'windowHeight': windowHeight.toDouble(),
      'wallThickness': wallThickness.toDouble(),
      'slopeType': slopeType.toDouble(),
      'perimM': roundValue(perimM, 3),
      'psulRolls': psulRolls.toDouble(),
      'iflulRolls': iflulRolls.toDouble(),
      'foamCans': foamCans.toDouble(),
      'anchorsPerWindow': anchorsPerWindow.toDouble(),
      'totalAnchors': totalAnchors.toDouble(),
      'screws': screwsKg,
      'sillWidth': roundValue(sillWidth, 3),
      'sillPcs': sillPcs.toDouble(),
      'slopeSideArea': roundValue(slopeSideArea, 4),
      'slopeTopArea': roundValue(slopeTopArea, 4),
      'totalSlopeArea': roundValue(totalSlopeArea, 4),
      'sandwichPcs': sandwichPcs.toDouble(),
      'fProfilePcs': fProfilePcs.toDouble(),
      'plasterBags': plasterBags.toDouble(),
      'cornerPcs': cornerPcs.toDouble(),
      'gklSheets': gklSheets.toDouble(),
      'screwsGKL': screwsGKL / 10,
      'puttyBags': puttyBags.toDouble(),
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
