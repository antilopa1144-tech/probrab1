import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


CanonicalCalculatorContractResult calculateCanonicalCeilingStretch(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(ceilingStretchSpecData);

  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 20)));
  final corners = (inputs['corners'] ?? defaultFor(spec, 'corners', 4)).round().clamp(3, 20);
  final fixtures = (inputs['fixtures'] ?? defaultFor(spec, 'fixtures', 4)).round().clamp(0, 50);
  final type = (inputs['type'] ?? defaultFor(spec, 'type', 0)).round().clamp(0, 2);

  // Perimeter from area (square approximation)
  final perim = math.sqrt(area) * 4;

  // Baguette profiles
  final baguetLen = perim * spec.materialRule<num>('baguet_reserve').toDouble();
  final profilePcs = (baguetLen / spec.materialRule<num>('baguet_length').toDouble()).ceil();

  // Decorative insert
  final insertLen = perim * spec.materialRule<num>('insert_reserve').toDouble();

  // Masking tape
  final maskingTape = (perim * spec.materialRule<num>('baguet_reserve').toDouble() / spec.materialRule<num>('masking_tape_roll').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(profilePcs * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    const packageLabel = 'baguet-profile';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'type:$type',
        'corners:$corners',
        'fixtures:$fixtures',
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
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0432\u043e\u0437\u043c\u043e\u0436\u043d\u043e \u043f\u043e\u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u0440\u0430\u0437\u0434\u0435\u043b\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c');
  }
  if (fixtures > spec.warningRule<num>('many_fixtures_threshold').toDouble()) {
    warnings.add('\u041c\u043d\u043e\u0433\u043e \u0441\u0432\u0435\u0442\u0438\u043b\u044c\u043d\u0438\u043a\u043e\u0432 \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u0443\u0441\u0438\u043b\u0435\u043d\u043d\u043e\u0435 \u043a\u0440\u0435\u043f\u043b\u0435\u043d\u0438\u0435');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u0411\u0430\u0433\u0435\u0442\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c 2.5\u043c',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u0414\u0435\u043a\u043e\u0440\u0430\u0442\u0438\u0432\u043d\u0430\u044f \u0432\u0441\u0442\u0430\u0432\u043a\u0430',
      quantity: roundValue(insertLen, 3),
      unit: '\u043c',
      withReserve: insertLen.ceilToDouble(),
      purchaseQty: insertLen.ceil().toDouble(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u041c\u0430\u0441\u043a\u0438\u0440\u043e\u0432\u043e\u0447\u043d\u0430\u044f \u043b\u0435\u043d\u0442\u0430 50\u043c',
      quantity: maskingTape.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: maskingTape.toDouble(),
      purchaseQty: maskingTape.toDouble(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u041e\u0431\u0440\u0430\u0431\u043e\u0442\u043a\u0430 \u0443\u0433\u043b\u043e\u0432',
      quantity: corners.toDouble(),
      unit: '\u0448\u0442',
      withReserve: corners.toDouble(),
      purchaseQty: corners.toDouble(),
      category: '\u041c\u043e\u043d\u0442\u0430\u0436',
    ),
    CanonicalMaterialResult(
      name: '\u0423\u0441\u0438\u043b\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0435 \u043a\u043e\u043b\u044c\u0446\u0430 \u0434\u043b\u044f \u0441\u0432\u0435\u0442\u0438\u043b\u044c\u043d\u0438\u043a\u043e\u0432',
      quantity: fixtures.toDouble(),
      unit: '\u0448\u0442',
      withReserve: fixtures.toDouble(),
      purchaseQty: fixtures.toDouble(),
      category: '\u041c\u043e\u043d\u0442\u0430\u0436',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'type': type.toDouble(),
      'corners': corners.toDouble(),
      'fixtures': fixtures.toDouble(),
      'perim': roundValue(perim, 3),
      'baguetLen': roundValue(baguetLen, 3),
      'profilePcs': profilePcs.toDouble(),
      'insertLen': roundValue(insertLen, 3),
      'maskingTape': maskingTape.toDouble(),
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
