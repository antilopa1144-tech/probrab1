import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

bool hasCanonicalGuttersInputs(Map<String, double> inputs) {
  return inputs.containsKey('roofPerimeter') ||
      inputs.containsKey('roofArea') ||
      inputs.containsKey('systemType') ||
      inputs.containsKey('gutterDia');
}

Map<String, double> normalizeLegacyGuttersInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized.putIfAbsent('roofPerimeter', () => 20);
  normalized.putIfAbsent('roofArea', () => 100);
  normalized.putIfAbsent('roofHeight', () => 5);
  normalized.putIfAbsent('funnels', () => 2);
  normalized.putIfAbsent('gutterLength', () => 3);
  normalized.putIfAbsent('gutterSections', () => 2);
  normalized.putIfAbsent('gutterCornerCount', () => 0);
  normalized.putIfAbsent('endCapCount', () => 4);
  normalized.putIfAbsent('hasEaveOffset', () => 1);
  normalized.putIfAbsent('bendCount45', () => 0);
  normalized.putIfAbsent('bendCount90', () => 0);

  normalized.putIfAbsent('systemType', () {
    final legacyDiameter = (inputs['gutterDia'] ?? 90).round();
    if (legacyDiameter <= 80) return 0;
    if (legacyDiameter >= 110 && legacyDiameter < 125) return 3;
    if (legacyDiameter >= 125) return 2;
    return 1;
  });

  return normalized;
}

CanonicalCalculatorContractResult calculateCanonicalGutters(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(guttersSpecData);
  final normalized = normalizeLegacyGuttersInputs(inputs);

  final roofPerimeter = math
      .max(
        5.0,
        math.min(
          200.0,
          normalized['roofPerimeter'] ?? defaultFor(spec, 'roofPerimeter', 20),
        ),
      )
      .toDouble();
  final roofArea = math
      .max(
        10.0,
        math.min(
          1000.0,
          normalized['roofArea'] ?? defaultFor(spec, 'roofArea', 100),
        ),
      )
      .toDouble();
  final roofHeight = math
      .max(
        2.0,
        math.min(
          15.0,
          normalized['roofHeight'] ?? defaultFor(spec, 'roofHeight', 5),
        ),
      )
      .toDouble();
  final funnels = (normalized['funnels'] ?? defaultFor(spec, 'funnels', 2))
      .round()
      .clamp(1, 20);
  final systemType =
      (normalized['systemType'] ?? defaultFor(spec, 'systemType', 1))
          .round()
          .clamp(0, 3);
  final gutterLength = math
      .max(
        1.5,
        math.min(
          3.0,
          normalized['gutterLength'] ?? defaultFor(spec, 'gutterLength', 3),
        ),
      )
      .toDouble();
  final gutterSections =
      (normalized['gutterSections'] ?? defaultFor(spec, 'gutterSections', 2))
          .round()
          .clamp(1, 20);
  final gutterCornerCount =
      (normalized['gutterCornerCount'] ??
              defaultFor(spec, 'gutterCornerCount', 0))
          .round()
          .clamp(0, 20);
  final endCapCount =
      (normalized['endCapCount'] ?? defaultFor(spec, 'endCapCount', 4))
          .round()
          .clamp(0, 40);
  final hasEaveOffset =
      (normalized['hasEaveOffset'] ?? defaultFor(spec, 'hasEaveOffset', 1))
          .round() ==
      1;
  final bendCount45 =
      (normalized['bendCount45'] ?? defaultFor(spec, 'bendCount45', 0))
          .round()
          .clamp(0, 20);
  final bendCount90 =
      (normalized['bendCount90'] ?? defaultFor(spec, 'bendCount90', 0))
          .round()
          .clamp(0, 20);

  final systems = spec.materialRule<Map<String, dynamic>>('systems');
  final system = Map<String, dynamic>.from(
    (systems['$systemType'] ?? systems['1']) as Map,
  );
  final gutterDiameter = (system['gutter_diameter_mm'] as num).round();
  final pipeDiameter = (system['pipe_diameter_mm'] as num).round();
  final capacityEdgeM2 = (system['capacity_edge_m2'] as num).toDouble();
  final hookStepM = (system['hook_step_m'] as num).toDouble();
  final specialElementOffsetM = spec
      .materialRule<num>('special_element_offset_m')
      .toDouble();
  final clampStepM = spec.materialRule<num>('pipe_clamp_step_m').toDouble();
  final maxRunPerFunnelM = spec
      .warningRule<num>('max_gutter_run_per_funnel_m')
      .toDouble();

  final gutterSectionLength = roofPerimeter / gutterSections;
  final gutterPcsPerSection = (gutterSectionLength / gutterLength).ceil();
  final gutterExactPcs = roofPerimeter / gutterLength;
  final gutterPcs = gutterPcsPerSection * gutterSections;

  final pipeExactPcs = roofHeight * funnels / gutterLength;
  final pipePerFunnel = (roofHeight / gutterLength).ceil();
  final pipePcs = pipePerFunnel * funnels;
  final pipeCouplings = math.max(0, (pipePerFunnel - 1) * funnels);

  final gutterJoints = math.max(0, (gutterPcsPerSection - 1) * gutterSections);
  final specialElementBrackets =
      gutterCornerCount + funnels * 2 + gutterJoints * 2;
  final regularBracketLength = math.max(
    0.0,
    roofPerimeter - specialElementBrackets * specialElementOffsetM,
  );
  final gutterHooks =
      (specialElementBrackets + regularBracketLength / hookStepM).ceil();
  final pipeClamps = ((roofHeight / clampStepM + 1) * funnels).ceil();

  final kneeElbows = hasEaveOffset ? funnels * 2 : 0;
  final drainOutlets = funnels;
  final connectors = gutterJoints;

  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  final primaryQuantity = (gutterExactPcs * accuracyMult).ceil();
  final primaryLabel = 'gutter-${gutterDiameter}mm-${gutterLength}m';
  const primaryUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(primaryQuantity * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'systemType:$systemType',
        'gutterLength:$gutterLength',
        'packaging:$primaryLabel',
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
        packageLabel: primaryLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: primaryUnit,
      ),
    );
  }

  final recommendedFunnelsByArea = (roofArea / capacityEdgeM2).ceil();
  final recommendedFunnelsByLength =
      gutterSections * (gutterSectionLength / maxRunPerFunnelM).ceil();
  final recommendedFunnels = math.max(
    gutterSections,
    math.max(recommendedFunnelsByArea, recommendedFunnelsByLength),
  );
  final warnings = <String>[];
  if (funnels < recommendedFunnels) {
    warnings.add(
      'Недостаточно воронок: рекомендуется минимум $recommendedFunnels шт. '
      'для ${roofArea.round()} м² и $gutterSections участков желоба',
    );
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Желоб водосточный (ø$gutterDiameter мм, $gutterLength м)',
      quantity: roundValue(gutterExactPcs, 3),
      unit: 'шт',
      withReserve: roundValue(gutterExactPcs, 3),
      purchaseQty: gutterPcs.toDouble(),
      category: 'Желоба',
    ),
    CanonicalMaterialResult(
      name: 'Труба водосточная (ø$pipeDiameter мм, $gutterLength м)',
      quantity: roundValue(pipeExactPcs, 3),
      unit: 'шт',
      withReserve: roundValue(pipeExactPcs, 3),
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
    if (connectors > 0)
      CanonicalMaterialResult(
        name: 'Соединители желобов',
        quantity: connectors.toDouble(),
        unit: 'шт',
        withReserve: connectors.toDouble(),
        purchaseQty: connectors.toDouble(),
        category: 'Соединители',
      ),
    if (pipeCouplings > 0)
      CanonicalMaterialResult(
        name: 'Муфты соединительные для труб',
        quantity: pipeCouplings.toDouble(),
        unit: 'шт',
        withReserve: pipeCouplings.toDouble(),
        purchaseQty: pipeCouplings.toDouble(),
        category: 'Соединители',
      ),
    if (kneeElbows > 0)
      CanonicalMaterialResult(
        name: 'Колена универсальные для обхода карниза',
        quantity: kneeElbows.toDouble(),
        unit: 'шт',
        withReserve: kneeElbows.toDouble(),
        purchaseQty: kneeElbows.toDouble(),
        category: 'Фасонные',
      ),
    CanonicalMaterialResult(
      name: 'Водосточные сливы (наконечники)',
      quantity: drainOutlets.toDouble(),
      unit: 'шт',
      withReserve: drainOutlets.toDouble(),
      purchaseQty: drainOutlets.toDouble(),
      category: 'Фасонные',
    ),
    if (endCapCount > 0)
      CanonicalMaterialResult(
        name: 'Заглушки желоба',
        quantity: endCapCount.toDouble(),
        unit: 'шт',
        withReserve: endCapCount.toDouble(),
        purchaseQty: endCapCount.toDouble(),
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
    if (gutterCornerCount > 0)
      CanonicalMaterialResult(
        name: 'Угловые элементы',
        quantity: gutterCornerCount.toDouble(),
        unit: 'шт',
        withReserve: gutterCornerCount.toDouble(),
        purchaseQty: gutterCornerCount.toDouble(),
        category: 'Фасонные',
      ),
    if (bendCount45 > 0)
      CanonicalMaterialResult(
        name: 'Колена/отводы 45°',
        quantity: bendCount45.toDouble(),
        unit: 'шт',
        withReserve: bendCount45.toDouble(),
        purchaseQty: bendCount45.toDouble(),
        category: 'Фасонные',
      ),
    if (bendCount90 > 0)
      CanonicalMaterialResult(
        name: 'Колена/отводы 90°',
        quantity: bendCount90.toDouble(),
        unit: 'шт',
        withReserve: bendCount90.toDouble(),
        purchaseQty: bendCount90.toDouble(),
        category: 'Фасонные',
      ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofPerimeter': roundValue(roofPerimeter, 3),
      'roofArea': roundValue(roofArea, 3),
      'roofHeight': roundValue(roofHeight, 3),
      'funnels': funnels.toDouble(),
      'systemType': systemType.toDouble(),
      'gutterDia': gutterDiameter.toDouble(),
      'pipeDia': pipeDiameter.toDouble(),
      'gutterLength': gutterLength,
      'gutterSections': gutterSections.toDouble(),
      'gutterSectionLength': roundValue(gutterSectionLength, 3),
      'gutterCornerCount': gutterCornerCount.toDouble(),
      'endCapCount': endCapCount.toDouble(),
      'hasEaveOffset': hasEaveOffset ? 1 : 0,
      'gutterExactPcs': roundValue(gutterExactPcs, 3),
      'gutterPcs': gutterPcs.toDouble(),
      'pipeExactPcs': roundValue(pipeExactPcs, 3),
      'pipePcs': pipePcs.toDouble(),
      'pipePerFunnel': pipePerFunnel.toDouble(),
      'pipeCouplings': pipeCouplings.toDouble(),
      'gutterJoints': gutterJoints.toDouble(),
      'gutterHooks': gutterHooks.toDouble(),
      'pipeClamps': pipeClamps.toDouble(),
      'corners': gutterCornerCount.toDouble(),
      'elbows45': bendCount45.toDouble(),
      'elbows90': bendCount90.toDouble(),
      'bendCount45': bendCount45.toDouble(),
      'bendCount90': bendCount90.toDouble(),
      'kneeElbows': kneeElbows.toDouble(),
      'drainOutlets': drainOutlets.toDouble(),
      'endCaps': endCapCount.toDouble(),
      'connectors': connectors.toDouble(),
      'recommendedFunnelsByArea': recommendedFunnelsByArea.toDouble(),
      'recommendedFunnelsByLength': recommendedFunnelsByLength.toDouble(),
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
