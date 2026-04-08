import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

/* ─── spec types ─── */



const Map<int, String> _finishTypeLabels = {
  0: 'Сэндвич-панели ПВХ',
  1: 'ПВХ-панели',
  2: 'Штукатурка',
  3: 'ГКЛ',
};


bool hasCanonicalSlopesInputs(Map<String, double> inputs) {
  return inputs.containsKey('openingType') ||
      inputs.containsKey('openingCount') ||
      inputs.containsKey('finishType');
}

Map<String, double> normalizeLegacySlopesInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['openingCount'] = (inputs['openingCount'] ?? 5).toDouble();
  normalized['openingType'] = (inputs['openingType'] ?? 0).toDouble();
  normalized['slopeWidth'] = (inputs['slopeWidth'] ?? 350).toDouble();
  normalized['finishType'] = (inputs['finishType'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalSlopes(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(slopesSpecData);

  final normalized = hasCanonicalSlopesInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacySlopesInputs(inputs);

  final openingCount = (normalized['openingCount'] ?? defaultFor(spec, 'openingCount', 5)).round().clamp(1, 30);
  final openingType = (normalized['openingType'] ?? defaultFor(spec, 'openingType', 0)).round().clamp(0, 3);
  final slopeWidth = (normalized['slopeWidth'] ?? defaultFor(spec, 'slopeWidth', 350)).round().clamp(150, 500);
  final finishType = (normalized['finishType'] ?? defaultFor(spec, 'finishType', 0)).round().clamp(0, 3);

  // Opening geometry
  final openingDims = spec.normativeValue<Map>('opening_dims') ?? {};
  final dims = (openingDims['$openingType'] ?? [1200, 1400, 3]) as List;
  final openW = (dims[0] as num).toInt();
  final openH = (dims[1] as num).toInt();
  final sides = (dims[2] as num).toInt();

  // slopePerim: for 3-sided = top + 2*sides; for 2-sided = 2*sides only
  double slopePerim;
  if (sides == 3) {
    slopePerim = (2 * openH + openW) / 1000;
  } else {
    slopePerim = (2 * openH) / 1000;
  }
  final slopeArea = slopePerim * (slopeWidth / 1000);
  final totalArea = roundValue(slopeArea * openingCount, 4);
  final totalPerim = roundValue(slopePerim * openingCount, 4);

  // Finish-type-specific materials
  var panelCount = 0;
  var fProfilePcs = 0;
  var foamCans = 0;
  var plasterBags = 0;
  var puttyBagsPlaster = 0;
  var cornerPcs = 0;
  var gklSheets = 0;
  var screwsGKL = 0;
  var puttyBagsGKL = 0;

  if (finishType == 0 || finishType == 1) {
    // Sandwich PVC / PVC panel
    panelCount = (totalArea * spec.materialRule<num>('panel_reserve').toDouble() / spec.materialRule<num>('panel_m2').toDouble()).ceil();
    fProfilePcs = (totalPerim * 1.1 / spec.materialRule<num>('f_profile_m').toDouble()).ceil();
    foamCans = (totalPerim / 5).ceil();
  } else if (finishType == 2) {
    // Plaster
    plasterBags = (totalArea * spec.materialRule<num>('plaster_kg_per_m2').toDouble() * spec.materialRule<num>('plaster_reserve').toDouble() / 25).ceil();
    puttyBagsPlaster = (totalArea * spec.materialRule<num>('putty_kg_per_m2').toDouble() * spec.materialRule<num>('putty_reserve').toDouble() / 25).ceil();
    cornerPcs = (totalPerim / spec.materialRule<num>('corner_profile_m').toDouble()).ceil();
  } else {
    // GKL
    gklSheets = (totalArea * spec.materialRule<num>('gkl_reserve').toDouble() / spec.materialRule<num>('gkl_m2').toDouble()).ceil();
    final screwsGKLpcs = (gklSheets * 20 * 1.05).ceil();
    screwsGKL = (screwsGKLpcs / 1000 * 10).ceil(); // *10 for rounding to 0.1 кг
    puttyBagsGKL = (totalArea * spec.materialRule<num>('putty_kg_per_m2').toDouble() * spec.materialRule<num>('putty_reserve').toDouble() / 25).ceil();
  }

  // Common materials
  final sealantTubes = (totalPerim / 5).ceil();
  final primerCans = (totalArea * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / 10).ceil();

  // Scenarios
  int basePrimary;
  String packageLabel;
  String packageUnit;

  if (finishType == 0 || finishType == 1) {
    basePrimary = panelCount;
    packageLabel = 'sandwich-panel';
    packageUnit = 'шт';
  } else if (finishType == 2) {
    basePrimary = plasterBags;
    packageLabel = 'plaster-bag-25kg';
    packageUnit = 'мешков';
  } else {
    basePrimary = gklSheets;
    packageLabel = 'gkl-sheet';
    packageUnit = 'листов';
  }

  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'openingType:$openingType',
        'finishType:$finishType',
        'slopeWidth:$slopeWidth',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
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
  if (slopeWidth >= spec.warningRule<num>('wide_slope_threshold_mm').toDouble()) {
    warnings.add('Широкие откосы — рекомендуется дополнительное утепление');
  }
  if (openingCount > spec.warningRule<num>('bulk_opening_threshold').toDouble()) {
    warnings.add('Большое количество проёмов — рассмотрите оптовую закупку');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[];

  if (finishType == 0 || finishType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_finishTypeLabels[finishType]}',
        quantity: recScenario.exactNeed,
        unit: 'шт',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil().toDouble(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'F-профиль (${spec.materialRule<num>('f_profile_m').toDouble().round()} м)',
        quantity: fProfilePcs.toDouble(),
        unit: 'шт',
        withReserve: fProfilePcs.toDouble(),
        purchaseQty: fProfilePcs.toDouble(),
        category: 'Профиль',
      ),
      CanonicalMaterialResult(
        name: 'Монтажная пена',
        quantity: foamCans.toDouble(),
        unit: 'баллонов',
        withReserve: foamCans.toDouble(),
        purchaseQty: foamCans.toDouble(),
        category: 'Монтаж',
      ),
    ]);
  } else if (finishType == 2) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Штукатурка (мешки 25 кг)',
        quantity: recScenario.exactNeed,
        unit: 'мешков',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil().toDouble(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (мешки 25 кг)',
        quantity: puttyBagsPlaster.toDouble(),
        unit: 'мешков',
        withReserve: puttyBagsPlaster.toDouble(),
        purchaseQty: puttyBagsPlaster.toDouble(),
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Уголок перфорированный',
        quantity: cornerPcs.toDouble(),
        unit: 'шт',
        withReserve: cornerPcs.toDouble(),
        purchaseQty: cornerPcs.toDouble(),
        category: 'Профиль',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ГКЛ для откосов',
        quantity: recScenario.exactNeed,
        unit: 'листов',
        withReserve: recScenario.exactNeed.ceilToDouble(),
        purchaseQty: recScenario.exactNeed.ceil().toDouble(),
        category: 'Отделка',
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
        name: 'Шпаклёвка (мешки 25 кг)',
        quantity: puttyBagsGKL.toDouble(),
        unit: 'мешков',
        withReserve: puttyBagsGKL.toDouble(),
        purchaseQty: puttyBagsGKL.toDouble(),
        category: 'Отделка',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealantTubes.toDouble(),
      unit: 'шт',
      withReserve: sealantTubes.toDouble(),
      purchaseQty: sealantTubes.toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра 10 л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toDouble(),
      category: 'Грунтовка',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'openingCount': openingCount.toDouble(),
      'openingType': openingType.toDouble(),
      'slopeWidth': slopeWidth.toDouble(),
      'finishType': finishType.toDouble(),
      'openW': openW.toDouble(),
      'openH': openH.toDouble(),
      'sides': sides.toDouble(),
      'slopePerim': roundValue(slopePerim, 4),
      'slopeArea': roundValue(slopeArea, 4),
      'totalArea': totalArea,
      'totalPerim': totalPerim,
      'panelCount': panelCount.toDouble(),
      'fProfilePcs': fProfilePcs.toDouble(),
      'foamCans': foamCans.toDouble(),
      'plasterBags': plasterBags.toDouble(),
      'puttyBagsPlaster': puttyBagsPlaster.toDouble(),
      'cornerPcs': cornerPcs.toDouble(),
      'gklSheets': gklSheets.toDouble(),
      'screwsGKL': screwsGKL / 10,
      'puttyBagsGKL': puttyBagsGKL.toDouble(),
      'sealantTubes': sealantTubes.toDouble(),
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
