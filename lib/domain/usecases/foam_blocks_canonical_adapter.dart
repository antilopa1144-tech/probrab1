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
    final wallLength = math.max(1, inputs['wallLength'] ?? defaultFor(spec, 'wallLength', 10)).toDouble();
    final wallHeight = math.max(1, inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble();
    return {
      'inputMode': 0.0,
      'wallArea': roundValue(wallLength * wallHeight, 3),
      'wallLength': wallLength,
      'wallHeight': wallHeight,
    };
  }
  final area = math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 27)).toDouble();
  final wallLength = (inputs['wallLength'] ?? defaultFor(spec, 'wallLength', 10)).toDouble();
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble();
  return {
    'inputMode': 1.0,
    'wallArea': roundValue(area, 3),
    'wallLength': wallLength,
    'wallHeight': wallHeight,
  };
}

CanonicalCalculatorContractResult calculateCanonicalFoamBlocks(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(foamBlocksSpecData);

  final areaInfo = _resolveArea(spec, inputs);
  final wallArea = areaInfo['wallArea']!;
  final wallLength = areaInfo['wallLength']!;
  final wallHeight = areaInfo['wallHeight']!;

  final openingsArea = math.max(0, inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 5)).toDouble();
  final blockSize = (inputs['blockSize'] ?? defaultFor(spec, 'blockSize', 0)).round().clamp(0, 3);
  final mortarType = (inputs['mortarType'] ?? defaultFor(spec, 'mortarType', 0)).round().clamp(0, 1);

  final blockSizes = spec.normativeValue<Map>('block_sizes') ?? {};
  final blockDef = (blockSizes['$blockSize'] ?? blockSizes['0']) as Map<String, dynamic>;
  final l = (blockDef['l'] as num).toDouble();
  final h = (blockDef['h'] as num).toDouble();
  final t = (blockDef['t'] as num).toDouble();
  final blockLabel = blockDef['label'] as String;

  final isKeramzit = blockSize >= 2;

  final netArea = math.max(0, wallArea - openingsArea).toDouble();

  final blockFaceArea = (l / 1000) * (h / 1000);
  final blocksNet = netArea / blockFaceArea;
  final blocksWithReserve = (blocksNet * spec.materialRule<num>('block_reserve').toDouble()).ceil();

  final volume = roundValue(netArea * (t / 1000), 6);

  int mortarBags;
  String mortarLabel;
  String mortarUnit;
  if (mortarType == 0) {
    final glueKg = roundValue(volume * spec.materialRule<num>('glue_kg_per_m3').toDouble(), 3);
    mortarBags = (glueKg / spec.materialRule<num>('glue_bag_kg').toDouble()).ceil();
    mortarLabel = '\u041a\u043b\u0435\u0439 \u0434\u043b\u044f \u043a\u043b\u0430\u0434\u043a\u0438 (${spec.materialRule<num>('glue_bag_kg').toInt()} \u043a\u0433)';
    mortarUnit = '\u043c\u0435\u0448\u043a\u043e\u0432';
  } else {
    final cpsM3 = roundValue(volume * spec.materialRule<num>('cps_volume_per_m3').toDouble(), 6);
    final cpsKg = roundValue(cpsM3 * spec.materialRule<num>('cps_kg_per_m3').toDouble(), 3);
    mortarBags = (cpsKg / spec.materialRule<num>('cps_bag_kg').toDouble()).ceil();
    mortarLabel = '\u0426\u041f\u0421 (${spec.materialRule<num>('cps_bag_kg').toInt()} \u043a\u0433)';
    mortarUnit = '\u043c\u0435\u0448\u043a\u043e\u0432';
  }

  final rows = (wallHeight / (h / 1000)).ceil();

  double meshArea = 0;
  int rebarLength = 0;
  CanonicalMaterialResult reinforcementMaterial;

  if (isKeramzit) {
    final meshRows = (rows / spec.materialRule<num>('mesh_interval').toDouble()).ceil();
    meshArea = roundValue(wallLength * (t / 1000) * meshRows, 3);
    reinforcementMaterial = CanonicalMaterialResult(
      name: '\u041a\u043b\u0430\u0434\u043e\u0447\u043d\u0430\u044f \u0441\u0435\u0442\u043a\u0430',
      quantity: roundValue(meshArea, 3),
      unit: '\u043c\u00b2',
      withReserve: meshArea.ceil().toDouble(),
      purchaseQty: meshArea.ceil(),
      category: '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    );
  } else {
    final rebarRows = (rows / spec.materialRule<num>('rebar_interval').toDouble()).ceil();
    rebarLength = (wallLength * rebarRows * 2 * spec.materialRule<num>('rebar_reserve').toDouble()).ceil();
    reinforcementMaterial = CanonicalMaterialResult(
      name: '\u0410\u0440\u043c\u0430\u0442\u0443\u0440\u0430 \u00d88',
      quantity: rebarLength.toDouble(),
      unit: '\u043f.\u043c',
      withReserve: rebarLength.toDouble(),
      purchaseQty: rebarLength.toInt(),
      category: '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    );
  }

  final openingsCount = (openingsArea / 2).ceil();
  final uBlocks = (openingsCount * 2 * spec.materialRule<num>('rebar_reserve').toDouble()).ceil();

  final primerCans = (netArea * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can_l').toDouble()).ceil();

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
        'blockSize:$blockSize',
        'mortarType:$mortarType',
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
  if (t <= spec.warningRule<num>('non_load_bearing_thickness_mm').toDouble()) {
    warnings.add('\u0422\u043e\u043b\u0449\u0438\u043d\u0430 \u0431\u043b\u043e\u043a\u0430 \u2264100 \u043c\u043c \u2014 \u0442\u043e\u043b\u044c\u043a\u043e \u0434\u043b\u044f \u043d\u0435\u043d\u0435\u0441\u0443\u0449\u0438\u0445 \u043f\u0435\u0440\u0435\u0433\u043e\u0440\u043e\u0434\u043e\u043a');
  }
  if (isKeramzit) {
    warnings.add('\u041a\u0435\u0440\u0430\u043c\u0437\u0438\u0442\u043e\u0431\u043b\u043e\u043a \u043f\u0440\u0438 \u043d\u0430\u0440\u0443\u0436\u043d\u043e\u0439 \u043a\u043b\u0430\u0434\u043a\u0435 \u2014 \u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u0443\u0442\u0435\u043f\u043b\u0435\u043d\u0438\u0435 \u043e\u0442 100 \u043c\u043c');
  }
  if (mortarType == 1 && !isKeramzit) {
    warnings.add('\u0414\u043b\u044f \u043f\u0435\u043d\u043e\u0431\u043b\u043e\u043a\u043e\u0432 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043a\u043b\u0435\u0435\u0432\u043e\u0439 \u0440\u0430\u0441\u0442\u0432\u043e\u0440 \u0432\u043c\u0435\u0441\u0442\u043e \u0426\u041f\u0421 \u2014 \u0431\u043e\u043b\u0435\u0435 \u0442\u043e\u043d\u043a\u0438\u0439 \u0448\u043e\u0432, \u043b\u0443\u0447\u0448\u0430\u044f \u0442\u0435\u043f\u043b\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u044f');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: blockLabel,
      quantity: roundValue(blocksNet, 3),
      unit: '\u0448\u0442',
      withReserve: blocksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: mortarLabel,
      quantity: mortarBags.toDouble(),
      unit: mortarUnit,
      withReserve: mortarBags.toDouble(),
      purchaseQty: mortarBags.toInt(),
      category: '\u041a\u043b\u0430\u0434\u043a\u0430',
    ),
    reinforcementMaterial,
    CanonicalMaterialResult(
      name: 'U-\u0431\u043b\u043e\u043a\u0438 (\u043f\u0435\u0440\u0435\u043c\u044b\u0447\u043a\u0438)',
      quantity: uBlocks.toDouble(),
      unit: '\u0448\u0442',
      withReserve: uBlocks.toDouble(),
      purchaseQty: uBlocks.toInt(),
      category: '\u041f\u0440\u043e\u0451\u043c\u044b',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u0440\u0443\u043d\u0442\u043e\u0432\u043a\u0430 (${spec.materialRule<num>('primer_can_l').toInt()} \u043b)',
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
      'inputMode': areaInfo['inputMode']!,
      'wallLength': roundValue(wallLength, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'wallArea': roundValue(wallArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'netArea': roundValue(netArea, 3),
      'blockSize': blockSize.toDouble(),
      'blockL': l.toDouble(),
      'blockH': h.toDouble(),
      'blockT': t.toDouble(),
      'mortarType': mortarType.toDouble(),
      'blockFaceArea': roundValue(blockFaceArea, 6),
      'blocksNet': roundValue(blocksNet, 3),
      'blocksWithReserve': blocksWithReserve.toDouble(),
      'volume': volume,
      'mortarBags': mortarBags.toDouble(),
      'rows': rows.toDouble(),
      'meshArea': roundValue(meshArea, 3),
      'rebarLength': rebarLength.toDouble(),
      'openingsCount': openingsCount.toDouble(),
      'uBlocks': uBlocks.toDouble(),
      'primerCans': primerCans.toDouble(),
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
