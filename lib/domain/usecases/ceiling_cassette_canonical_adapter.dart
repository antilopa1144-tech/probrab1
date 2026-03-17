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

CanonicalCalculatorContractResult calculateCanonicalCeilingCassette(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(ceilingCassetteSpecData);

  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 30)));
  final cassetteSize = (inputs['cassetteSize'] ?? defaultFor(spec, 'cassetteSize', 0)).round().clamp(0, 2);
  final roomLength = math.max(2.0, math.min(50.0, inputs['roomLength'] ?? defaultFor(spec, 'roomLength', 6)));

  final roomWidth = area / roomLength;
  final cassetteDim = (spec.materialRule<Map>('cassette_sizes')['$cassetteSize'] as num?)?.toDouble() ?? 0.595;

  // Cassettes
  final cassPerRow = (roomLength / cassetteDim).ceil();
  final rows = (roomWidth / cassetteDim).ceil();
  final totalCass = (rows * cassPerRow * spec.materialRule<num>('cassette_reserve').toDouble()).ceil();

  // Main profiles
  final mainRows = (roomWidth / spec.materialRule<num>('main_profile_spacing').toDouble()).ceil() + 1;
  final mainProfiles = (mainRows * roomLength / spec.materialRule<num>('main_profile_spacing').toDouble()).ceil();

  // Cross profiles
  final crossPerRow = (roomLength / spec.materialRule<num>('cross_profile_spacing').toDouble()).ceil();
  final crossProfiles = mainRows * crossPerRow;

  // Hangers
  final hangers = ((roomLength / spec.materialRule<num>('hanger_spacing').toDouble()) + 1).ceil() * mainRows;

  // Wall angle profiles
  final wallProfilePcs = ((roomLength + roomWidth) * 2 * spec.materialRule<num>('wall_profile_reserve').toDouble() / spec.materialRule<num>('wall_profile_length').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(totalCass * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'cassette-$cassetteSize';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'cassetteSize:$cassetteSize',
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

  final cassetteLabels = {0: '595\u00d7595 \u043c\u043c', 1: '600\u00d7600 \u043c\u043c', 2: '300\u00d7300 \u043c\u043c'};

  final warnings = <String>[];
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u041a\u0430\u0441\u0441\u0435\u0442\u0430 ${cassetteLabels[cassetteSize] ?? "595\u00d7595 \u043c\u043c"}',
      quantity: recScenario.exactNeed,
      unit: '\u0448\u0442',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u043b\u0430\u0432\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c \u0422-\u043e\u0431\u0440\u0430\u0437\u043d\u044b\u0439',
      quantity: mainProfiles.toDouble(),
      unit: '\u0448\u0442',
      withReserve: mainProfiles.toDouble(),
      purchaseQty: mainProfiles.toDouble(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
    CanonicalMaterialResult(
      name: '\u041f\u043e\u043f\u0435\u0440\u0435\u0447\u043d\u044b\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c',
      quantity: crossProfiles.toDouble(),
      unit: '\u0448\u0442',
      withReserve: crossProfiles.toDouble(),
      purchaseQty: crossProfiles.toDouble(),
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
      name: '\u0423\u0433\u043b\u043e\u0432\u043e\u0439 \u043f\u0440\u043e\u0444\u0438\u043b\u044c 3\u043c',
      quantity: wallProfilePcs.toDouble(),
      unit: '\u0448\u0442',
      withReserve: wallProfilePcs.toDouble(),
      purchaseQty: wallProfilePcs.toDouble(),
      category: '\u041a\u0430\u0440\u043a\u0430\u0441',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'cassetteSize': cassetteSize.toDouble(),
      'roomLength': roundValue(roomLength, 3),
      'roomWidth': roundValue(roomWidth, 3),
      'cassPerRow': cassPerRow.toDouble(),
      'rows': rows.toDouble(),
      'totalCass': totalCass.toDouble(),
      'mainRows': mainRows.toDouble(),
      'mainProfiles': mainProfiles.toDouble(),
      'crossPerRow': crossPerRow.toDouble(),
      'crossProfiles': crossProfiles.toDouble(),
      'hangers': hangers.toDouble(),
      'wallProfilePcs': wallProfilePcs.toDouble(),
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
