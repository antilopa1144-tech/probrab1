import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class FoamBlockSizeSpec {
  final int l;
  final int h;
  final int t;
  final String label;

  const FoamBlockSizeSpec({
    required this.l,
    required this.h,
    required this.t,
    required this.label,
  });
}

class FoamBlocksPackagingRules {
  final String unit;
  final double packageSize;

  const FoamBlocksPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class FoamBlocksMaterialRules {
  final double blockReserve;
  final double glueKgPerM3;
  final double glueBagKg;
  final double cpsKgPerM3;
  final double cpsVolumePerM3;
  final double cpsBagKg;
  final int meshInterval;
  final int rebarInterval;
  final double rebarReserve;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCanL;

  const FoamBlocksMaterialRules({
    required this.blockReserve,
    required this.glueKgPerM3,
    required this.glueBagKg,
    required this.cpsKgPerM3,
    required this.cpsVolumePerM3,
    required this.cpsBagKg,
    required this.meshInterval,
    required this.rebarInterval,
    required this.rebarReserve,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCanL,
  });
}

class FoamBlocksWarningRules {
  final int nonLoadBearingThicknessMm;

  const FoamBlocksWarningRules({
    required this.nonLoadBearingThicknessMm,
  });
}

class FoamBlocksCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final Map<int, FoamBlockSizeSpec> blockSizes;
  final FoamBlocksPackagingRules packagingRules;
  final FoamBlocksMaterialRules materialRules;
  final FoamBlocksWarningRules warningRules;

  const FoamBlocksCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.blockSizes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const FoamBlocksCanonicalSpec foamBlocksCanonicalSpecV1 = FoamBlocksCanonicalSpec(
  calculatorId: 'foam-blocks',
  formulaVersion: 'foam-blocks-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'wallLength', unit: 'm', defaultValue: 10, min: 1, max: 100),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 1, max: 5),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 27, min: 1, max: 500),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 5, min: 0, max: 50),
    CanonicalInputField(key: 'blockSize', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'mortarType', defaultValue: 0, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  blockSizes: {
    0: FoamBlockSizeSpec(l: 600, h: 300, t: 200, label: '\u041f\u0435\u043d\u043e\u0431\u043b\u043e\u043a 600\u00d7300\u00d7200'),
    1: FoamBlockSizeSpec(l: 600, h: 300, t: 100, label: '\u041f\u0435\u043d\u043e\u0431\u043b\u043e\u043a 600\u00d7300\u00d7100'),
    2: FoamBlockSizeSpec(l: 390, h: 190, t: 188, label: '\u041a\u0435\u0440\u0430\u043c\u0437\u0438\u0442\u043e\u0431\u043b\u043e\u043a 390\u00d7190\u00d7188'),
    3: FoamBlockSizeSpec(l: 390, h: 190, t: 90, label: '\u041a\u0435\u0440\u0430\u043c\u0437\u0438\u0442\u043e\u0431\u043b\u043e\u043a 390\u00d7190\u00d790'),
  },
  packagingRules: FoamBlocksPackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: FoamBlocksMaterialRules(
    blockReserve: 1.05,
    glueKgPerM3: 25,
    glueBagKg: 25,
    cpsKgPerM3: 1700,
    cpsVolumePerM3: 0.25,
    cpsBagKg: 50,
    meshInterval: 3,
    rebarInterval: 4,
    rebarReserve: 1.1,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCanL: 10,
  ),
  warningRules: FoamBlocksWarningRules(
    nonLoadBearingThicknessMm: 100,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FoamBlocksCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveArea(FoamBlocksCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final wallLength = math.max(1, inputs['wallLength'] ?? _defaultFor(spec, 'wallLength', 10)).toDouble();
    final wallHeight = math.max(1, inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble();
    return {
      'inputMode': 0.0,
      'wallArea': _roundValue(wallLength * wallHeight, 3),
      'wallLength': wallLength,
      'wallHeight': wallHeight,
    };
  }
  final area = math.max(1, inputs['area'] ?? _defaultFor(spec, 'area', 27)).toDouble();
  final wallLength = (inputs['wallLength'] ?? _defaultFor(spec, 'wallLength', 10)).toDouble();
  final wallHeight = (inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble();
  return {
    'inputMode': 1.0,
    'wallArea': _roundValue(area, 3),
    'wallLength': wallLength,
    'wallHeight': wallHeight,
  };
}

Map<String, double> _keyFactors(FoamBlocksCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FoamBlocksCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalFoamBlocks(
  Map<String, double> inputs, {
  FoamBlocksCanonicalSpec spec = foamBlocksCanonicalSpecV1,
}) {
  final areaInfo = _resolveArea(spec, inputs);
  final wallArea = areaInfo['wallArea']!;
  final wallLength = areaInfo['wallLength']!;
  final wallHeight = areaInfo['wallHeight']!;

  final openingsArea = math.max(0, inputs['openingsArea'] ?? _defaultFor(spec, 'openingsArea', 5)).toDouble();
  final blockSize = (inputs['blockSize'] ?? _defaultFor(spec, 'blockSize', 0)).round().clamp(0, 3);
  final mortarType = (inputs['mortarType'] ?? _defaultFor(spec, 'mortarType', 0)).round().clamp(0, 1);

  final blockDef = spec.blockSizes[blockSize]!;
  final l = blockDef.l;
  final h = blockDef.h;
  final t = blockDef.t;
  final blockLabel = blockDef.label;

  final isKeramzit = blockSize >= 2;

  final netArea = math.max(0, wallArea - openingsArea).toDouble();

  final blockFaceArea = (l / 1000) * (h / 1000);
  final blocksNet = netArea / blockFaceArea;
  final blocksWithReserve = (blocksNet * spec.materialRules.blockReserve).ceil();

  final volume = _roundValue(netArea * (t / 1000), 6);

  int mortarBags;
  String mortarLabel;
  String mortarUnit;
  if (mortarType == 0) {
    final glueKg = _roundValue(volume * spec.materialRules.glueKgPerM3, 3);
    mortarBags = (glueKg / spec.materialRules.glueBagKg).ceil();
    mortarLabel = '\u041a\u043b\u0435\u0439 \u0434\u043b\u044f \u043a\u043b\u0430\u0434\u043a\u0438 (${spec.materialRules.glueBagKg.toInt()} \u043a\u0433)';
    mortarUnit = '\u043c\u0435\u0448\u043a\u043e\u0432';
  } else {
    final cpsM3 = _roundValue(volume * spec.materialRules.cpsVolumePerM3, 6);
    final cpsKg = _roundValue(cpsM3 * spec.materialRules.cpsKgPerM3, 3);
    mortarBags = (cpsKg / spec.materialRules.cpsBagKg).ceil();
    mortarLabel = '\u0426\u041f\u0421 (${spec.materialRules.cpsBagKg.toInt()} \u043a\u0433)';
    mortarUnit = '\u043c\u0435\u0448\u043a\u043e\u0432';
  }

  final rows = (wallHeight / (h / 1000)).ceil();

  double meshArea = 0;
  int rebarLength = 0;
  CanonicalMaterialResult reinforcementMaterial;

  if (isKeramzit) {
    final meshRows = (rows / spec.materialRules.meshInterval).ceil();
    meshArea = _roundValue(wallLength * (t / 1000) * meshRows, 3);
    reinforcementMaterial = CanonicalMaterialResult(
      name: '\u041a\u043b\u0430\u0434\u043e\u0447\u043d\u0430\u044f \u0441\u0435\u0442\u043a\u0430',
      quantity: _roundValue(meshArea, 3),
      unit: '\u043c\u00b2',
      withReserve: meshArea.ceil().toDouble(),
      purchaseQty: meshArea.ceil(),
      category: '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    );
  } else {
    final rebarRows = (rows / spec.materialRules.rebarInterval).ceil();
    rebarLength = (wallLength * rebarRows * 2 * spec.materialRules.rebarReserve).ceil();
    reinforcementMaterial = CanonicalMaterialResult(
      name: '\u0410\u0440\u043c\u0430\u0442\u0443\u0440\u0430 \u00d88',
      quantity: rebarLength.toDouble(),
      unit: '\u043f.\u043c',
      withReserve: rebarLength.toDouble(),
      purchaseQty: rebarLength,
      category: '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    );
  }

  final openingsCount = (openingsArea / 2).ceil();
  final uBlocks = (openingsCount * 2 * spec.materialRules.rebarReserve).ceil();

  final primerCans = (netArea * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCanL).ceil();

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(blocksWithReserve * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'block-piece-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'blockSize:$blockSize',
        'mortarType:$mortarType',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (t <= spec.warningRules.nonLoadBearingThicknessMm) {
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
      quantity: _roundValue(blocksNet, 3),
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
      purchaseQty: mortarBags,
      category: '\u041a\u043b\u0430\u0434\u043a\u0430',
    ),
    reinforcementMaterial,
    CanonicalMaterialResult(
      name: 'U-\u0431\u043b\u043e\u043a\u0438 (\u043f\u0435\u0440\u0435\u043c\u044b\u0447\u043a\u0438)',
      quantity: uBlocks.toDouble(),
      unit: '\u0448\u0442',
      withReserve: uBlocks.toDouble(),
      purchaseQty: uBlocks,
      category: '\u041f\u0440\u043e\u0451\u043c\u044b',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u0440\u0443\u043d\u0442\u043e\u0432\u043a\u0430 (${spec.materialRules.primerCanL.toInt()} \u043b)',
      quantity: primerCans.toDouble(),
      unit: '\u043a\u0430\u043d\u0438\u0441\u0442\u0440',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': areaInfo['inputMode']!,
      'wallLength': _roundValue(wallLength, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'wallArea': _roundValue(wallArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'netArea': _roundValue(netArea, 3),
      'blockSize': blockSize.toDouble(),
      'blockL': l.toDouble(),
      'blockH': h.toDouble(),
      'blockT': t.toDouble(),
      'mortarType': mortarType.toDouble(),
      'blockFaceArea': _roundValue(blockFaceArea, 6),
      'blocksNet': _roundValue(blocksNet, 3),
      'blocksWithReserve': blocksWithReserve.toDouble(),
      'volume': volume,
      'mortarBags': mortarBags.toDouble(),
      'rows': rows.toDouble(),
      'meshArea': _roundValue(meshArea, 3),
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
