import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0))
      .round();
  if (inputMode == 0) {
    final wallWidth = math
        .max(1, inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 10))
        .toDouble();
    final wallHeight = math
        .max(1, inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7))
        .toDouble();
    return {
      'inputMode': 0.0,
      'wallArea': roundValue(wallWidth * wallHeight, 3),
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
    };
  }
  final area = math
      .max(1, inputs['area'] ?? defaultFor(spec, 'area', 27))
      .toDouble();
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 10))
      .toDouble();
  final wallHeight =
      (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble();
  return {
    'inputMode': 1.0,
    'wallArea': roundValue(area, 3),
    'wallWidth': wallWidth,
    'wallHeight': wallHeight,
  };
}

int _resolveClosest(double raw, List<int> options) {
  int closest = options[0];
  double minDiff = (closest - raw).abs();
  for (final opt in options) {
    final diff = (opt - raw).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = opt;
    }
  }
  return closest;
}

CanonicalCalculatorContractResult calculateCanonicalAeratedConcrete(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(aeratedConcreteSpecData);

  final areaInfo = _resolveArea(spec, inputs);
  final wallArea = areaInfo['wallArea']!;
  final wallWidth = areaInfo['wallWidth']!;
  final wallHeight = areaInfo['wallHeight']!;
  final inputMode = areaInfo['inputMode']!.round();

  final openingsArea = math
      .max(0, inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 5))
      .toDouble();
  final blockThickness = _resolveClosest(
    inputs['blockThickness'] ?? defaultFor(spec, 'blockThickness', 200),
    (spec.normativeValue<List>('block_thickness_options') ?? [200]).cast<int>(),
  );
  final blockHeight = _resolveClosest(
    inputs['blockHeight'] ?? defaultFor(spec, 'blockHeight', 200),
    (spec.normativeValue<List>('block_height_options') ?? [200]).cast<int>(),
  );
  final blockLength = _resolveClosest(
    inputs['blockLength'] ?? defaultFor(spec, 'blockLength', 600),
    (spec.normativeValue<List>('block_length_options') ?? [600]).cast<int>(),
  );

  final netArea = math.max(0, wallArea - openingsArea).toDouble();

  final blockFaceArea = (blockHeight / 1000) * (blockLength / 1000);
  final blocksPerSqm = 1.0 / blockFaceArea;
  final blocksNet = netArea * blocksPerSqm;
  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  final blocksWithReserve =
      (blocksNet *
              spec.materialRule<num>('block_reserve').toDouble() *
              accuracyMult)
          .ceil();

  final volume = roundValue(netArea * (blockThickness / 1000), 6);

  final glueKg = roundValue(
    volume * spec.materialRule<num>('glue_kg_per_m3').toDouble(),
    3,
  );
  final glueBags = (glueKg / spec.materialRule<num>('glue_bag_kg').toDouble())
      .ceil();

  final rows = (wallHeight / (blockHeight / 1000)).ceil();
  final rebarRows =
      (rows / spec.materialRule<num>('rebar_armoring_interval').toDouble())
          .ceil();

  final estimatedWallLength = inputMode == 0 ? wallWidth : netArea / wallHeight;
  final rebarLength =
      (estimatedWallLength *
              rebarRows *
              spec.materialRule<num>('rebar_reserve').toDouble())
          .ceil();

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(blocksWithReserve * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel =
        'block-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'blockThickness:$blockThickness',
        'blockHeight:$blockHeight',
        'blockLength:$blockLength',
        'packaging:$packageLabel',
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
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (blockThickness <=
      spec.warningRule<num>('non_load_bearing_thickness_mm').toDouble()) {
    warnings.add(
      'Блоки толщиной до 150 мм обычно применяют для ненесущих перегородок. Назначение стены подтверждают проектом',
    );
  }
  if (blockThickness >=
      spec.warningRule<num>('thermal_check_thickness_mm').toDouble()) {
    warnings.add(
      'Для наружной стены проверьте сопротивление теплопередаче всей конструкции по СП 50.13330 — одной толщины блока недостаточно',
    );
  }
  if (openingsArea > 0) {
    warnings.add(
      'Площадь проёмов вычтена из блоков, но перемычки и U-блоки не посчитаны: нужны количество и ширина каждого проёма, опирание и проектная схема',
    );
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name:
          'Автоклавный газобетонный блок $blockLength×$blockHeight×$blockThickness мм',
      quantity: roundValue(blocksNet, 3),
      unit: '\u0448\u0442',
      withReserve: blocksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name:
          'Клей для тонкошовной кладки газобетона, мешок ${spec.materialRule<num>('glue_bag_kg').toInt()} кг',
      quantity: glueBags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags.toDouble(),
      category: '\u041a\u043b\u0430\u0434\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: 'Арматура класса А500С Ø8 мм для штроб',
      quantity: rebarLength.toDouble(),
      unit: '\u043f.\u043c',
      withReserve: rebarLength.toDouble(),
      purchaseQty: rebarLength.toDouble(),
      category:
          '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': areaInfo['inputMode']!,
      'wallWidth': roundValue(wallWidth, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'wallArea': roundValue(wallArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'netArea': roundValue(netArea, 3),
      'blockThickness': blockThickness.toDouble(),
      'blockHeight': blockHeight.toDouble(),
      'blockLength': blockLength.toDouble(),
      'blockFaceArea': roundValue(blockFaceArea, 6),
      'blocksPerSqm': roundValue(blocksPerSqm, 3),
      'blocksNet': roundValue(blocksNet, 3),
      'blocksWithReserve': blocksWithReserve.toDouble(),
      'volume': volume,
      'glueKg': glueKg,
      'glueBags': glueBags.toDouble(),
      'rows': rows.toDouble(),
      'rebarRows': rebarRows.toDouble(),
      'perimeter': roundValue(estimatedWallLength, 3),
      'estimatedWallLength': roundValue(estimatedWallLength, 3),
      'rebarLength': rebarLength.toDouble(),
      'lintelsCalculated': 0.0,
      'minExactNeedBlocks': scenarios['MIN']!.exactNeed,
      'recExactNeedBlocks': recScenario.exactNeed,
      'maxExactNeedBlocks': scenarios['MAX']!.exactNeed,
      'minPurchaseBlocks': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseBlocks': recScenario.purchaseQuantity,
      'maxPurchaseBlocks': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
