import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */




bool hasCanonicalGuttersInputs(Map<String, double> inputs) {
  return inputs.containsKey('roofPerimeter') ||
      inputs.containsKey('funnels') ||
      inputs.containsKey('gutterDia');
}

Map<String, double> normalizeLegacyGuttersInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['roofPerimeter'] = (inputs['roofPerimeter'] ?? 40).toDouble();
  normalized['roofHeight'] = (inputs['roofHeight'] ?? 5).toDouble();
  normalized['funnels'] = (inputs['funnels'] ?? 4).toDouble();
  normalized['gutterDia'] = (inputs['gutterDia'] ?? 90).toDouble();
  normalized['gutterLength'] = (inputs['gutterLength'] ?? 3).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalGutters(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(guttersSpecData);

  final normalized = hasCanonicalGuttersInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyGuttersInputs(inputs);

  final roofPerimeter = math.max(5.0, math.min(200.0, (normalized['roofPerimeter'] ?? defaultFor(spec, 'roofPerimeter', 40)).toDouble()));
  final roofHeight = math.max(2.0, math.min(15.0, (normalized['roofHeight'] ?? defaultFor(spec, 'roofHeight', 5)).toDouble()));
  final funnels = (normalized['funnels'] ?? defaultFor(spec, 'funnels', 4)).round().clamp(1, 20);
  final gutterDia = (normalized['gutterDia'] ?? defaultFor(spec, 'gutterDia', 90)).round().clamp(75, 125);
  final gutterLength = (normalized['gutterLength'] ?? defaultFor(spec, 'gutterLength', 3)).round().clamp(3, 4);

  // Gutters
  final gutterPcs = (roofPerimeter / gutterLength * spec.materialRule<num>('gutter_reserve').toDouble()).ceil();

  // Pipes
  final pipePerFunnel = (roofHeight / gutterLength).ceil() + 1;
  final pipePcs = pipePerFunnel * funnels;

  // Gutter joints
  final gutterJoints = (roofPerimeter / gutterLength).ceil() - 1;

  // Hooks
  final gutterHooks = (roofPerimeter / spec.materialRule<num>('hook_step_m').toDouble() * spec.materialRule<num>('hook_reserve').toDouble()).ceil();

  // Pipe clamps
  final pipeClamps = (roofHeight / spec.materialRule<num>('pipe_clamp_step_m').toDouble() * funnels * spec.materialRule<num>('pipe_clamp_reserve').toDouble()).ceil();

  // Corners
  final corners = spec.materialRule<num>('building_corners').toDouble();

  // Knee elbows
  final kneeElbows = funnels;

  // End caps
  final endCaps = funnels;

  // Connectors
  final connectors = (gutterJoints * spec.materialRule<num>('connector_reserve').toDouble()).ceil();

  // Sealant
  final sealantTubes = ((gutterJoints + funnels * 2) / spec.materialRule<num>('sealant_connections_per_tube').toDouble()).ceil();

  // Primary quantity for scenarios
  final primaryQuantity = gutterPcs;
  final primaryLabel = 'gutter-${gutterDia}mm-${gutterLength}m';
  const primaryUnit = 'шт';

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(primaryQuantity * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'gutterDia:$gutterDia',
        'gutterLength:$gutterLength',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: primaryLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: primaryUnit,
      ),
    );
  }

  // Warnings
  final warnings = <String>[];
  final recommendedFunnels = (roofPerimeter / spec.warningRule<num>('recommended_funnel_interval_m').toDouble()).ceil();
  if (funnels < recommendedFunnels) {
    warnings.add('Недостаточно воронок: рекомендуется минимум $recommendedFunnels шт. (1 на каждые ${spec.warningRule<num>('recommended_funnel_interval_m').toDouble().round()} м периметра) для достаточного водоотведения');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Желоб водосточный (ø$gutterDia мм, $gutterLength м)',
      quantity: gutterPcs.toDouble(),
      unit: 'шт',
      withReserve: gutterPcs.toDouble(),
      purchaseQty: gutterPcs.toDouble(),
      category: 'Желоба',
    ),
    CanonicalMaterialResult(
      name: 'Труба водосточная (ø$gutterDia мм, $gutterLength м)',
      quantity: pipePcs.toDouble(),
      unit: 'шт',
      withReserve: pipePcs.toDouble(),
      purchaseQty: pipePcs.toDouble(),
      category: 'Трубы',
    ),
    CanonicalMaterialResult(
      name: 'Воронки водосборные',
      quantity: funnels.toDouble(),
      unit: 'шт',
      withReserve: funnels.toDouble(),
      purchaseQty: funnels.toDouble(),
      category: 'Воронки',
    ),
    CanonicalMaterialResult(
      name: 'Соединители желобов',
      quantity: connectors.toDouble(),
      unit: 'шт',
      withReserve: connectors.toDouble(),
      purchaseQty: connectors.toDouble(),
      category: 'Соединители',
    ),
    CanonicalMaterialResult(
      name: 'Колена водосточные',
      quantity: kneeElbows.toDouble(),
      unit: 'шт',
      withReserve: kneeElbows.toDouble(),
      purchaseQty: kneeElbows.toDouble(),
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Заглушки желоба (пары)',
      quantity: endCaps.toDouble(),
      unit: 'шт',
      withReserve: endCaps.toDouble(),
      purchaseQty: endCaps.toDouble(),
      category: 'Заглушки',
    ),
    CanonicalMaterialResult(
      name: 'Кронштейны желоба',
      quantity: gutterHooks.toDouble(),
      unit: 'шт',
      withReserve: gutterHooks.toDouble(),
      purchaseQty: gutterHooks.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Хомуты трубы',
      quantity: pipeClamps.toDouble(),
      unit: 'шт',
      withReserve: pipeClamps.toDouble(),
      purchaseQty: pipeClamps.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Угловые элементы',
      quantity: corners.toDouble(),
      unit: 'шт',
      withReserve: corners.toDouble(),
      purchaseQty: corners.toDouble(),
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (${spec.materialRule<num>('sealant_tube_ml').toDouble()} мл)',
      quantity: sealantTubes.toDouble(),
      unit: 'тюбиков',
      withReserve: sealantTubes.toDouble(),
      purchaseQty: sealantTubes.toDouble(),
      category: 'Герметизация',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofPerimeter': roundValue(roofPerimeter, 3),
      'roofHeight': roundValue(roofHeight, 3),
      'funnels': funnels.toDouble(),
      'gutterDia': gutterDia.toDouble(),
      'gutterLength': gutterLength.toDouble(),
      'gutterPcs': gutterPcs.toDouble(),
      'pipePcs': pipePcs.toDouble(),
      'pipePerFunnel': pipePerFunnel.toDouble(),
      'gutterJoints': gutterJoints.toDouble(),
      'gutterHooks': gutterHooks.toDouble(),
      'pipeClamps': pipeClamps.toDouble(),
      'corners': corners.toDouble(),
      'kneeElbows': kneeElbows.toDouble(),
      'endCaps': endCaps.toDouble(),
      'connectors': connectors.toDouble(),
      'sealantTubes': sealantTubes.toDouble(),
      'recommendedFunnels': recommendedFunnels.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
