import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


CanonicalCalculatorContractResult calculateCanonicalCeilingRail(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(ceilingRailSpecData);

  final area = math.max(1.0, math.min(200.0, inputs['area'] ?? defaultFor(spec, 'area', 20)));
  final railWidthRaw = (inputs['railWidth'] ?? defaultFor(spec, 'railWidth', 100)).round();
  final allowedWidths = [100, 150, 200];
  final railWidth = allowedWidths.contains(railWidthRaw) ? railWidthRaw : 100;
  final railLengthRaw = inputs['railLength'] ?? defaultFor(spec, 'railLength', 3.0);
  final allowedLengths = [3.0, 3.6, 4.0];
  var railLength = allowedLengths[0];
  var minDiff = (allowedLengths[0] - railLengthRaw).abs();
  for (final l in allowedLengths) {
    final diff = (l - railLengthRaw).abs();
    if (diff < minDiff) {
      minDiff = diff;
      railLength = l;
    }
  }
  final roomLength = math.max(1.0, math.min(30.0, inputs['roomLength'] ?? defaultFor(spec, 'roomLength', 5)));

  final roomWidth = area / roomLength;

  // Rails
  final railRows = (roomWidth / (railWidth / 1000.0)).ceil();
  final totalRailLen = railRows * roomLength * spec.materialRule<num>('rail_reserve').toDouble();
  final railPcs = (totalRailLen / railLength).ceil();

  // T-profile guides
  final guideCount = (roomLength / spec.materialRule<num>('t_profile_spacing').toDouble()).ceil() + 1;
  final guideTotal = guideCount * roomWidth * spec.materialRule<num>('t_reserve').toDouble();
  final guidePcs = (guideTotal / spec.materialRule<num>('t_profile_length').toDouble()).ceil();

  // Hangers
  final hangers = ((roomWidth / spec.materialRule<num>('hanger_spacing').toDouble()) + 1).ceil() * guideCount;

  // Screws & dubels (in kg)
  final screwsPcs = (hangers * spec.materialRule<num>('screws_per_hanger').toDouble() + railPcs * spec.materialRule<num>('screws_per_rail').toDouble()).round();
  final screwsKg = (screwsPcs / 1000 * 10).ceil() / 10; // 3.5×25 мм: 1000 шт/кг
  final dubels = hangers;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(railPcs * accuracyMult * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'rail-${railWidth}mm';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'railWidth:$railWidth',
        'railLength:$railLength',
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
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u0420\u0435\u0439\u043a\u0430 $railWidth \u043c\u043c \u00d7 $railLength \u043c',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u0422-\u043f\u0440\u043e\u0444\u0438\u043b\u044c (\u0441\u0442\u0440\u0438\u043d\u0433\u0435\u0440) 3\u043c',
      quantity: guidePcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: guidePcs.toDouble(),
      purchaseQty: guidePcs.toDouble(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u043e\u0434\u0432\u0435\u0441',
      quantity: hangers.toDouble(),
      unit: '\u0448\u0442',
      withReserve: hangers.toDouble(),
      purchaseQty: hangers.toDouble(),
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0421\u0430\u043c\u043e\u0440\u0435\u0437\u044b',
      quantity: screwsKg,
      unit: '\u043a\u0433',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil().toDouble(),
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0414\u044e\u0431\u0435\u043b\u0438',
      quantity: dubels.toDouble(),
      unit: '\u0448\u0442',
      withReserve: dubels.toDouble(),
      purchaseQty: dubels.toDouble(),
      category: '\u041a\u0440\u0435\u043f\u0451\u0436',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'railWidth': railWidth.toDouble(),
      'railLength': railLength,
      'roomLength': roundValue(roomLength, 3),
      'roomWidth': roundValue(roomWidth, 3),
      'railRows': railRows.toDouble(),
      'totalRailLen': roundValue(totalRailLen, 3),
      'railPcs': railPcs.toDouble(),
      'guideCount': guideCount.toDouble(),
      'guidePcs': guidePcs.toDouble(),
      'hangers': hangers.toDouble(),
      'screws': screwsKg,
      'dubels': dubels.toDouble(),
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
