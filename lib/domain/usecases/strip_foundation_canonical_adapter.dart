import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

Map<String, dynamic> _pickPackage(
  double exactNeed,
  double stepSize,
  String unit,
) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = roundValue(count * stepSize, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': roundValue(purchase - exactNeed, 6),
    'label': 'strip-foundation-$stepSize$unit',
  };
}

double _allowedValue(SpecReader spec, String rule, double requested) {
  final allowed = spec
      .packagingRule<List>(rule)
      .whereType<num>()
      .map((value) => value.toDouble())
      .toList(growable: false);
  return allowed.contains(requested) ? requested : allowed.first;
}

CanonicalCalculatorContractResult calculateCanonicalStripFoundation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(stripFoundationSpecData);

  final perimeter = (inputs['perimeter'] ?? defaultFor(spec, 'perimeter', 40))
      .clamp(10, 200)
      .toDouble();
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 400))
      .clamp(200, 600)
      .toDouble();
  final depth = (inputs['depth'] ?? defaultFor(spec, 'depth', 700))
      .clamp(300, 2000)
      .toDouble();
  final aboveGround =
      (inputs['aboveGround'] ?? defaultFor(spec, 'aboveGround', 300))
          .clamp(0, 600)
          .toDouble();
  final formworkHeight =
      (inputs['formworkHeight'] ?? defaultFor(spec, 'formworkHeight', 300))
          .clamp(0, 2000)
          .toDouble();
  final reserve = (inputs['reserve'] ?? defaultFor(spec, 'reserve', 5))
      .clamp(0, 20)
      .toDouble();
  final readyMixOrderStep = _allowedValue(
    spec,
    'allowed_ready_mix_order_steps_m3',
    inputs['readyMixOrderStepM3'] ??
        defaultFor(spec, 'readyMixOrderStepM3', 0.1),
  );
  final deliveryAllowance =
      (inputs['deliveryAllowanceM3'] ??
              defaultFor(spec, 'deliveryAllowanceM3', 0))
          .clamp(0, 5)
          .toDouble();
  final reinforcement =
      (inputs['reinforcement'] ?? defaultFor(spec, 'reinforcement', 1))
          .round()
          .clamp(0, 3);
  final clampStepM =
      (inputs['clampStepMm'] ?? defaultFor(spec, 'clampStepMm', 400))
          .clamp(100, 1000)
          .toDouble() /
      1000;
  final concreteCoverM =
      (inputs['concreteCoverMm'] ?? defaultFor(spec, 'concreteCoverMm', 50))
          .clamp(20, 100)
          .toDouble() /
      1000;
  final clampHookAllowanceM =
      (inputs['clampHookAllowanceMm'] ??
              defaultFor(spec, 'clampHookAllowanceMm', 300))
          .clamp(0, 1000)
          .toDouble() /
      1000;
  final rebarReserve =
      (inputs['rebarReserve'] ?? defaultFor(spec, 'rebarReserve', 12))
          .clamp(0, 30)
          .toDouble();
  final rodLength = _allowedValue(
    spec,
    'allowed_rod_lengths_m',
    inputs['rodLengthM'] ?? defaultFor(spec, 'rodLengthM', 11.7),
  );
  final formworkReserve =
      (inputs['formworkReserve'] ?? defaultFor(spec, 'formworkReserve', 10))
          .clamp(0, 30)
          .toDouble();

  final rebarDiameter =
      (spec.materialRule<Map>('rebar_diameters')['$reinforcement'] as num?)
          ?.toDouble() ??
      12;
  final threads =
      (spec.materialRule<Map>('rebar_threads')['$reinforcement'] as num?)
          ?.toDouble() ??
      4;
  final weightPerM =
      (spec.materialRule<Map>('weight_per_m')[rebarDiameter.toInt().toString()]
              as num?)
          ?.toDouble() ??
      0.888;

  final totalHeightM = (depth + aboveGround) / 1000;
  final volume = roundValue(perimeter * (width / 1000) * totalHeightM, 6);

  final longitudinalExactLength = roundValue(perimeter * threads, 6);
  final longitudinalPlanningLength = roundValue(
    longitudinalExactLength * (1 + rebarReserve / 100),
    6,
  );
  final longitudinalBars = (longitudinalPlanningLength / rodLength).ceil();
  final longitudinalPurchaseLength = roundValue(
    longitudinalBars * rodLength,
    6,
  );
  final longitudinalWeight = roundValue(
    longitudinalExactLength * weightPerM,
    6,
  );
  final longitudinalPurchaseWeight = roundValue(
    longitudinalPurchaseLength * weightPerM,
    6,
  );

  final clampCount = (perimeter / clampStepM).ceil();
  final clampWidth = math.max(0, width / 1000 - 2 * concreteCoverM);
  final clampHeight = math.max(0, totalHeightM - 2 * concreteCoverM);
  final clampPerimeter = 2 * (clampWidth + clampHeight) + clampHookAllowanceM;
  final clampExactLength = roundValue(clampCount * clampPerimeter, 6);
  final clampPlanningLength = roundValue(
    clampExactLength * (1 + rebarReserve / 100),
    6,
  );
  final clampBars = (clampPlanningLength / rodLength).ceil();
  final clampPurchaseLength = roundValue(clampBars * rodLength, 6);
  final clampWeight = roundValue(
    clampExactLength *
        spec.materialRule<num>('clamp_weight_kg_per_m').toDouble(),
    6,
  );
  final clampPurchaseWeight = roundValue(
    clampPurchaseLength *
        spec.materialRule<num>('clamp_weight_kg_per_m').toDouble(),
    6,
  );

  final tieCount = clampCount * threads.round();
  final wireLength = roundValue(
    tieCount * spec.materialRule<num>('wire_length_per_tie_m').toDouble(),
    6,
  );
  final wireWeight = roundValue(
    wireLength * spec.materialRule<num>('wire_weight_kg_per_m').toDouble(),
    6,
  );

  final formworkArea = roundValue(2 * perimeter * (formworkHeight / 1000), 6);
  final formworkWithReserve = roundValue(
    formworkArea * (1 + formworkReserve / 100),
    6,
  );
  final boardArea =
      spec.materialRule<num>('formwork_board_width_m').toDouble() *
      spec.materialRule<num>('formwork_board_length_m').toDouble();
  final boardsExact = formworkArea > 0
      ? roundValue(formworkArea / boardArea, 6)
      : 0.0;
  final boards = formworkArea > 0
      ? (formworkWithReserve / boardArea).ceil()
      : 0;

  final scenarioPolicy =
      spec.raw['scenario_policy'] as Map<String, dynamic>? ?? const {};
  final recommendedMaxReserve =
      (scenarioPolicy['recommended_max_reserve_percent'] as num?)?.toDouble() ??
      10;
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final scenarioReserve = scenarioName == 'MIN'
        ? 0.0
        : scenarioName == 'MAX'
        ? math.max(reserve, recommendedMaxReserve)
        : reserve;
    final reserveMultiplier = 1 + scenarioReserve / 100;
    final exactNeed = roundValue(
      volume * reserveMultiplier + deliveryAllowance,
      6,
    );
    final package = _pickPackage(
      exactNeed,
      readyMixOrderStep,
      spec.packagingRule<String>('unit'),
    );
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'reinforcement:$reinforcement',
        'reserve_percent:$scenarioReserve',
        'delivery_allowance_m3:$deliveryAllowance',
        'rebar_reserve_percent:$rebarReserve',
        'rod_length_m:$rodLength',
        'scenario_policy:explicit_foundation_inputs',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        'reserve_percent': roundValue(scenarioReserve, 3),
        'field_multiplier': roundValue(reserveMultiplier, 6),
        'ready_mix_order_step_m3': readyMixOrderStep,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Товарный бетон — класс по проекту',
      quantity: roundValue(volume, 3),
      unit: 'м³',
      withReserve: roundValue(recScenario.exactNeed, 3),
      purchaseQty: recScenario.purchaseQuantity,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Рифлёная продольная арматура ∅${rebarDiameter.toInt()} мм',
      quantity: roundValue(longitudinalExactLength, 3),
      unit: 'пог. м',
      withReserve: roundValue(longitudinalPlanningLength, 3),
      purchaseQty: roundValue(longitudinalPurchaseLength, 3),
      packageInfo: {
        'count': longitudinalBars,
        'size': rodLength,
        'packageUnit': 'прутков',
      },
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Хомуты ∅${spec.materialRule<num>('clamp_diameter_mm').toInt()} мм',
      quantity: roundValue(clampExactLength, 3),
      unit: 'пог. м',
      withReserve: roundValue(clampPlanningLength, 3),
      purchaseQty: roundValue(clampPurchaseLength, 3),
      packageInfo: {
        'count': clampBars,
        'size': rodLength,
        'packageUnit': 'прутков',
      },
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Проволока вязальная отожжённая ∅1,2 мм',
      quantity: roundValue(wireWeight, 3),
      unit: 'кг',
      withReserve: roundValue(wireWeight, 3),
      purchaseQty: wireWeight.ceilToDouble(),
      category: 'Армирование',
    ),
    if (formworkArea > 0)
      CanonicalMaterialResult(
        name: 'Опалубка — щиты из обрезной доски',
        quantity: roundValue(formworkArea, 3),
        unit: 'м²',
        withReserve: roundValue(formworkWithReserve, 3),
        purchaseQty: roundValue(formworkWithReserve, 3),
        category: 'Опалубка',
      ),
    if (formworkArea > 0)
      CanonicalMaterialResult(
        name: 'Доска обрезная не менее 25×150×6000 мм',
        quantity: roundValue(boardsExact, 3),
        unit: 'шт',
        withReserve: roundValue(
          boardsExact *
              (formworkArea > 0 ? formworkWithReserve / formworkArea : 1),
          3,
        ),
        purchaseQty: boards.toDouble(),
        category: 'Опалубка',
      ),
  ];

  final warnings = <String>[
    'Калькулятор считает материалы по заданным размерам. Ширину, глубину, класс бетона и схему армирования определяют по нагрузкам и инженерно-геологическим данным участка.',
  ];
  if (depth <= spec.warningRule<num>('shallow_depth_threshold_mm').toDouble()) {
    warnings.add(
      'Введено мелкое заглубление. Его допустимость нельзя определить только по региону: нужны грунты, уровень подземных вод, нагрузки, тепловой режим и расчёт деформаций.',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'perimeter': roundValue(perimeter, 3),
      'width': roundValue(width, 3),
      'depth': roundValue(depth, 3),
      'aboveGround': roundValue(aboveGround, 3),
      'reserve': roundValue(reserve, 3),
      'readyMixOrderStepM3': readyMixOrderStep,
      'reinforcement': reinforcement.toDouble(),
      'deliveryAllowanceM3': roundValue(deliveryAllowance, 3),
      'totalH': roundValue(totalHeightM, 3),
      'vol': roundValue(volume, 3),
      'volReserve': roundValue(recScenario.exactNeed, 3),
      'rebarDiam': rebarDiameter,
      'threads': threads,
      'longExactLen': roundValue(longitudinalExactLength, 3),
      'longLen': roundValue(longitudinalPlanningLength, 3),
      'longPurchaseLen': roundValue(longitudinalPurchaseLength, 3),
      'longBars': longitudinalBars.toDouble(),
      'longWeightKg': roundValue(longitudinalWeight, 3),
      'longPurchaseWeightKg': roundValue(longitudinalPurchaseWeight, 3),
      'clampCount': clampCount.toDouble(),
      'clampStepMm': roundValue(clampStepM * 1000, 3),
      'concreteCoverMm': roundValue(concreteCoverM * 1000, 3),
      'clampHookAllowanceMm': roundValue(clampHookAllowanceM * 1000, 3),
      'clampExactLen': roundValue(clampExactLength, 3),
      'clampLen': roundValue(clampPlanningLength, 3),
      'clampPurchaseLen': roundValue(clampPurchaseLength, 3),
      'clampBars': clampBars.toDouble(),
      'clampWeightKg': roundValue(clampWeight, 3),
      'clampPurchaseWeightKg': roundValue(clampPurchaseWeight, 3),
      'tieCount': tieCount.toDouble(),
      'wireLengthM': roundValue(wireLength, 3),
      'wireKg': roundValue(wireWeight, 3),
      'formworkHeightMm': roundValue(formworkHeight, 3),
      'formwork': roundValue(formworkArea, 3),
      'formworkWithReserve': roundValue(formworkWithReserve, 3),
      'formworkReserve': roundValue(formworkReserve, 3),
      'boards': boards.toDouble(),
      'rodLengthM': rodLength,
      'rebarReserve': roundValue(rebarReserve, 3),
      'minExactNeedM3': scenarios['MIN']!.exactNeed,
      'recExactNeedM3': recScenario.exactNeed,
      'maxExactNeedM3': scenarios['MAX']!.exactNeed,
      'minPurchaseM3': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseM3': recScenario.purchaseQuantity,
      'maxPurchaseM3': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
