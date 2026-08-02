import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
};

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

CanonicalCalculatorContractResult calculateCanonicalStripFoundation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(stripFoundationSpecData);
  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMultiplier = accuracyPrimaryMultiplier(
    'concrete',
    accuracyMode,
  );

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
  final reinforcement =
      (inputs['reinforcement'] ?? defaultFor(spec, 'reinforcement', 1))
          .round()
          .clamp(0, 3);
  final deliveryMethod =
      (inputs['deliveryMethod'] ?? defaultFor(spec, 'deliveryMethod', 0))
          .round()
          .clamp(0, 2);
  final formworkHeightMm = inputs.containsKey('formworkHeight')
      ? inputs['formworkHeight']!.clamp(0, 2000).toDouble()
      : aboveGround;

  final rebarDiameter =
      (spec.materialRule<Map>('rebar_diameters')['$reinforcement'] as num?)
          ?.toDouble() ??
      12;
  final threads =
      (spec.materialRule<Map>('rebar_threads')['$reinforcement'] as num?)
          ?.toDouble() ??
      4;
  final weightPerM =
      (spec.materialRule<Map>('weight_per_m')['$rebarDiameter'] as num?)
          ?.toDouble() ??
      0.888;

  final totalHeightM = (depth + aboveGround) / 1000;
  final volume = roundValue(perimeter * (width / 1000) * totalHeightM, 6);
  final deliveryLossM3 =
      (spec.materialRule<Map>('delivery_loss_m3')['$deliveryMethod'] as num?)
          ?.toDouble() ??
      0;
  final baseOrderNeed = roundValue(volume + deliveryLossM3, 6);
  final accuracyAdjustedVolume = roundValue(volume * accuracyMultiplier, 6);

  final longitudinalLength = roundValue(
    perimeter *
        threads *
        spec.materialRule<num>('longitudinal_reserve_factor').toDouble(),
    6,
  );
  final longitudinalWeight = roundValue(longitudinalLength * weightPerM, 6);

  final clampStep = spec.materialRule<num>('clamp_step_m').toDouble();
  final clampCount = (perimeter / clampStep).ceil();
  final cover = spec.materialRule<num>('concrete_cover_m').toDouble();
  final clampWidth = math.max(0, width / 1000 - 2 * cover);
  final clampHeight = math.max(0, totalHeightM - 2 * cover);
  final clampPerimeter =
      2 * (clampWidth + clampHeight) +
      spec.materialRule<num>('clamp_hooks_m').toDouble();
  final clampLength = roundValue(
    clampCount *
        clampPerimeter *
        spec.materialRule<num>('clamp_length_reserve').toDouble(),
    6,
  );
  final clampWeight = roundValue(
    clampLength * spec.materialRule<num>('clamp_weight_kg_per_m').toDouble(),
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

  final formworkArea = roundValue(2 * perimeter * (formworkHeightMm / 1000), 6);
  final boardArea =
      spec.materialRule<num>('formwork_board_width_m').toDouble() *
      spec.materialRule<num>('formwork_board_length_m').toDouble();
  final boards = formworkArea > 0
      ? (formworkArea *
                spec.materialRule<num>('formwork_board_reserve').toDouble() /
                boardArea)
            .ceil()
      : 0;

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final fieldMultiplier = scenarioMultiplier(
      spec.enabledFactors,
      _factorTable,
      scenarioName,
    );
    final scenarioNeed =
        accuracyAdjustedVolume * fieldMultiplier + deliveryLossM3;
    final exactNeed = roundValue(math.max(baseOrderNeed, scenarioNeed), 6);
    final package = _pickPackage(
      exactNeed,
      spec.packagingRule<num>('volume_step_m3').toDouble(),
      spec.packagingRule<String>('unit'),
    );
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'reinforcement:$reinforcement',
        'deliveryMethod:$deliveryMethod',
        'delivery_loss_m3:$deliveryLossM3',
        'longitudinal_reserve_factor:${spec.materialRule<num>('longitudinal_reserve_factor')}',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(fieldMultiplier, 6),
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
      quantity: roundValue(longitudinalWeight, 3),
      unit: 'кг',
      withReserve: longitudinalWeight.ceilToDouble(),
      purchaseQty: longitudinalWeight.ceilToDouble(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Хомуты ∅${spec.materialRule<num>('clamp_diameter_mm').toInt()} мм',
      quantity: roundValue(clampWeight, 3),
      unit: 'кг',
      withReserve: clampWeight.ceilToDouble(),
      purchaseQty: clampWeight.ceilToDouble(),
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
        withReserve: roundValue(formworkArea, 3),
        purchaseQty: formworkArea.ceilToDouble(),
        category: 'Опалубка',
      ),
    if (formworkArea > 0)
      CanonicalMaterialResult(
        name: 'Доска обрезная не менее 25×150×6000 мм',
        quantity: boards.toDouble(),
        unit: 'шт',
        withReserve: boards.toDouble(),
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
      'reinforcement': reinforcement.toDouble(),
      'deliveryMethod': deliveryMethod.toDouble(),
      'deliveryLossM3': roundValue(deliveryLossM3, 3),
      'totalH': roundValue(totalHeightM, 3),
      'vol': roundValue(volume, 3),
      'volReserve': roundValue(recScenario.exactNeed, 3),
      'rebarDiam': rebarDiameter,
      'threads': threads,
      'longLen': roundValue(longitudinalLength, 3),
      'longWeightKg': roundValue(longitudinalWeight, 3),
      'clampCount': clampCount.toDouble(),
      'clampLen': roundValue(clampLength, 3),
      'clampWeightKg': roundValue(clampWeight, 3),
      'tieCount': tieCount.toDouble(),
      'wireLengthM': roundValue(wireLength, 3),
      'wireKg': roundValue(wireWeight, 3),
      'formworkHeightMm': roundValue(formworkHeightMm, 3),
      'formwork': roundValue(formworkArea, 3),
      'boards': boards.toDouble(),
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
