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

CanonicalCalculatorContractResult calculateCanonicalGypsumBoard(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(gypsumBoardSpecData);

  final area = math.max(1.0, math.min(1000.0, inputs['area'] ?? defaultFor(spec, 'area', 40)));
  final constructionType = (inputs['constructionType'] ?? defaultFor(spec, 'constructionType', 0)).round().clamp(0, 2);
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;
  final gklType = (inputs['gklType'] ?? defaultFor(spec, 'gklType', 0)).round().clamp(0, 2);
  final profileStepRaw = (inputs['profileStep'] ?? defaultFor(spec, 'profileStep', 600)).round();
  final profileStep = profileStepRaw <= 400 ? 400 : 600;
  final stepM = profileStep / 1000.0;

  // Sheets
  final sheetsOneSide = (area * layers / spec.materialRule<num>('sheet_area').toDouble() * spec.materialRule<num>('sheet_reserve').toDouble()).ceil();
  final totalSheets = constructionType == 1 ? sheetsOneSide * 2 : sheetsOneSide;
  final sides = constructionType == 1 ? 2 : 1;

  // Height estimate
  final height = constructionType == 2
      ? 1.0
      : math.sqrt(area / 1.5).clamp(2.5, 4.0);
  final wallLength = area / height;

  // PP profiles
  final ppCount = constructionType == 2
      ? (wallLength / stepM).ceil() * (height / stepM).ceil()
      : (wallLength / stepM).ceil() + 1;
  final ppMeters = ppCount * height;
  final ppPcs = (ppMeters * 1.05 / spec.materialRule<num>('profile_length').toDouble()).ceil();

  // PN guide profiles
  final guideM = constructionType == 1
      ? (wallLength + height) * 2 * 2
      : (wallLength + height) * 2;
  final guidePcs = (guideM * 1.05 / spec.materialRule<num>('profile_length').toDouble()).ceil();

  // Screws & dubels
  final screws = (totalSheets * spec.materialRule<num>('screws_gkl_per_sheet').toDouble()).round();
  final dubels = (guideM / spec.materialRule<num>('dubel_step').toDouble() * 2 * spec.materialRule<num>('dubel_reserve').toDouble()).ceil();

  // Serpyanka
  final jointsM = (totalSheets * height * layers * spec.materialRule<num>('serpyanka_reserve').toDouble()).ceil();
  final puttyBags = (jointsM / 10 / spec.materialRule<num>('putty_bag').toDouble()).ceil();

  // Primer
  final primerCans = (area * sides * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(totalSheets * multiplier, 6);
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
        'constructionType:$constructionType',
        'gklType:$gklType',
        'layers:$layers',
        'profileStep:$profileStep',
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
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }
  if (layers == 2) {
    warnings.add('\u0412\u0442\u043e\u0440\u043e\u0439 \u0441\u043b\u043e\u0439 \u0413\u041a\u041b \u043c\u043e\u043d\u0442\u0438\u0440\u0443\u0435\u0442\u0441\u044f \u0441\u043e \u0441\u043c\u0435\u0449\u0435\u043d\u0438\u0435\u043c \u0448\u0432\u043e\u0432');
  }

  final gklTypeLabels = {0: '\u0413\u041a\u041b \u0441\u0442\u0430\u043d\u0434\u0430\u0440\u0442\u043d\u044b\u0439', 1: '\u0413\u041a\u041b\u0412 \u0432\u043b\u0430\u0433\u043e\u0441\u0442\u043e\u0439\u043a\u0438\u0439', 2: '\u0413\u041a\u041b\u041e \u043e\u0433\u043d\u0435\u0441\u0442\u043e\u0439\u043a\u0438\u0439'};

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: gklTypeLabels[gklType] ?? '\u0413\u041a\u041b',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u041f\u041f 60\u00d727 3\u043c',
      quantity: ppPcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: ppPcs.toDouble(),
      purchaseQty: ppPcs.toInt(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u041f\u041d 27\u00d728 3\u043c',
      quantity: guidePcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: guidePcs.toDouble(),
      purchaseQty: guidePcs.toInt(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u0421\u0430\u043c\u043e\u0440\u0435\u0437\u044b \u0434\u043b\u044f \u0413\u041a\u041b',
      quantity: screws.toDouble(),
      unit: '\u0448\u0442',
      withReserve: screws.toDouble(),
      purchaseQty: screws.toInt(),
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0414\u044e\u0431\u0435\u043b\u0438',
      quantity: dubels.toDouble(),
      unit: '\u0448\u0442',
      withReserve: dubels.toDouble(),
      purchaseQty: dubels.toInt(),
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0421\u0435\u0440\u043f\u044f\u043d\u043a\u0430',
      quantity: jointsM.toDouble(),
      unit: '\u043c',
      withReserve: jointsM.toDouble(),
      purchaseQty: jointsM.toInt(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u0428\u043f\u0430\u043a\u043b\u0451\u0432\u043a\u0430 25 \u043a\u0433',
      quantity: puttyBags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: puttyBags.toDouble(),
      purchaseQty: puttyBags.toInt(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u0440\u0443\u043d\u0442\u043e\u0432\u043a\u0430 10 \u043b',
      quantity: primerCans.toDouble(),
      unit: '\u043a\u0430\u043d\u0438\u0441\u0442\u0440',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toInt(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'constructionType': constructionType.toDouble(),
      'layers': layers.toDouble(),
      'gklType': gklType.toDouble(),
      'profileStep': profileStep.toDouble(),
      'sides': sides.toDouble(),
      'height': roundValue(height, 3),
      'wallLength': roundValue(wallLength, 3),
      'sheetsOneSide': sheetsOneSide.toDouble(),
      'totalSheets': totalSheets.toDouble(),
      'ppCount': ppCount.toDouble(),
      'ppPcs': ppPcs.toDouble(),
      'guidePcs': guidePcs.toDouble(),
      'guideM': roundValue(guideM, 3),
      'screws': screws.toDouble(),
      'dubels': dubels.toDouble(),
      'jointsM': jointsM.toDouble(),
      'puttyBags': puttyBags.toDouble(),
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
