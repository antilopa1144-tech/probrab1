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

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final wallWidth = math.max(1, inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 10)).toDouble();
    final wallHeight = math.max(1, inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble();
    return {
      'inputMode': 0.0,
      'wallArea': roundValue(wallWidth * wallHeight, 3),
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
    };
  }
  final area = math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 27)).toDouble();
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 10)).toDouble();
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble();
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

  final openingsArea = math.max(0, inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 5)).toDouble();
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
  final blocksWithReserve = (blocksNet * spec.materialRule<num>('block_reserve').toDouble()).ceil();

  final volume = roundValue(netArea * (blockThickness / 1000), 6);

  final glueKg = roundValue(volume * spec.materialRule<num>('glue_kg_per_m3').toDouble(), 3);
  final glueBags = (glueKg / spec.materialRule<num>('glue_bag_kg').toDouble()).ceil();

  final rows = (wallHeight / (blockHeight / 1000)).ceil();
  final rebarRows = (rows / spec.materialRule<num>('rebar_armoring_interval').toDouble()).ceil();

  final perimeter = inputMode == 0
      ? wallWidth
      : math.sqrt(netArea) * 2;
  final rebarLength = (perimeter * rebarRows * spec.materialRule<num>('rebar_reserve').toDouble()).ceil();

  final primerCans = (netArea * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can_l').toDouble()).ceil();

  final openingsCount = (openingsArea / 2).ceil();
  final uBlocks = (openingsCount * 2 * spec.materialRule<num>('rebar_reserve').toDouble()).ceil();

  final cornerProfiles = (wallHeight / spec.materialRule<num>('corner_profile_length_m').toDouble()).ceil() * spec.materialRule<num>('corner_profile_count').toDouble();

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(blocksWithReserve * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'block-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
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
  if (blockThickness <= spec.warningRule<num>('non_load_bearing_thickness_mm').toDouble()) {
    warnings.add('\u0422\u043e\u043b\u0449\u0438\u043d\u0430 \u0431\u043b\u043e\u043a\u0430 \u2264150 \u043c\u043c \u2014 \u0442\u043e\u043b\u044c\u043a\u043e \u0434\u043b\u044f \u043d\u0435\u043d\u0435\u0441\u0443\u0449\u0438\u0445 \u043f\u0435\u0440\u0435\u0433\u043e\u0440\u043e\u0434\u043e\u043a');
  }
  if (blockThickness >= spec.warningRule<num>('thermal_check_thickness_mm').toDouble()) {
    warnings.add('\u0422\u043e\u043b\u0449\u0438\u043d\u0430 \u0431\u043b\u043e\u043a\u0430 \u2265300 \u043c\u043c \u2014 \u043f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0442\u0435\u043f\u043b\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u044e \u043f\u043e \u0421\u041f 50.13330');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u0413\u0430\u0437\u043e\u0431\u043b\u043e\u043a $blockLength\u00d7$blockHeight\u00d7$blockThickness \u043c\u043c',
      quantity: roundValue(blocksNet, 3),
      unit: '\u0448\u0442',
      withReserve: blocksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u041a\u043b\u0435\u0439 \u0434\u043b\u044f \u0433\u0430\u0437\u043e\u0431\u0435\u0442\u043e\u043d\u0430 (${spec.materialRule<num>('glue_bag_kg').toInt()} \u043a\u0433)',
      quantity: glueBags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags.toInt(),
      category: '\u041a\u043b\u0430\u0434\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u0410\u0440\u043c\u0430\u0442\u0443\u0440\u0430 \u00d88',
      quantity: rebarLength.toDouble(),
      unit: '\u043f.\u043c',
      withReserve: rebarLength.toDouble(),
      purchaseQty: rebarLength.toInt(),
      category: '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u0440\u0443\u043d\u0442\u043e\u0432\u043a\u0430 (${spec.materialRule<num>('primer_can_l').toInt()} \u043b)',
      quantity: primerCans.toDouble(),
      unit: '\u043a\u0430\u043d\u0438\u0441\u0442\u0440',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toInt(),
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: 'U-\u0431\u043b\u043e\u043a\u0438 (\u043f\u0435\u0440\u0435\u043c\u044b\u0447\u043a\u0438)',
      quantity: uBlocks.toDouble(),
      unit: '\u0448\u0442',
      withReserve: uBlocks.toDouble(),
      purchaseQty: uBlocks.toInt(),
      category: '\u041f\u0440\u043e\u0451\u043c\u044b',
    ),
    CanonicalMaterialResult(
      name: '\u0423\u0433\u043b\u043e\u0432\u044b\u0435 \u043f\u0440\u043e\u0444\u0438\u043b\u0438',
      quantity: cornerProfiles.toDouble(),
      unit: '\u0448\u0442',
      withReserve: cornerProfiles.toDouble(),
      purchaseQty: cornerProfiles.toInt(),
      category: '\u041f\u0440\u043e\u0451\u043c\u044b',
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
      'perimeter': roundValue(perimeter, 3),
      'rebarLength': rebarLength.toDouble(),
      'primerCans': primerCans.toDouble(),
      'openingsCount': openingsCount.toDouble(),
      'uBlocks': uBlocks.toDouble(),
      'cornerProfiles': cornerProfiles.toDouble(),
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
