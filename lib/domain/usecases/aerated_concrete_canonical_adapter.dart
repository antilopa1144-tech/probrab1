import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class AeratedConcretePackagingRules {
  final String unit;
  final double packageSize;

  const AeratedConcretePackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class AeratedConcreteMaterialRules {
  final double glueKgPerM3;
  final double glueBagKg;
  final double blockReserve;
  final int rebarArmoringInterval;
  final double rebarReserve;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCanL;
  final double cornerProfileLengthM;
  final int cornerProfileCount;

  const AeratedConcreteMaterialRules({
    required this.glueKgPerM3,
    required this.glueBagKg,
    required this.blockReserve,
    required this.rebarArmoringInterval,
    required this.rebarReserve,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCanL,
    required this.cornerProfileLengthM,
    required this.cornerProfileCount,
  });
}

class AeratedConcreteWarningRules {
  final int nonLoadBearingThicknessMm;
  final int thermalCheckThicknessMm;

  const AeratedConcreteWarningRules({
    required this.nonLoadBearingThicknessMm,
    required this.thermalCheckThicknessMm,
  });
}

class AeratedConcreteCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<int> blockThicknessOptions;
  final List<int> blockHeightOptions;
  final List<int> blockLengthOptions;
  final AeratedConcretePackagingRules packagingRules;
  final AeratedConcreteMaterialRules materialRules;
  final AeratedConcreteWarningRules warningRules;

  const AeratedConcreteCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.blockThicknessOptions,
    required this.blockHeightOptions,
    required this.blockLengthOptions,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const AeratedConcreteCanonicalSpec aeratedConcreteCanonicalSpecV1 = AeratedConcreteCanonicalSpec(
  calculatorId: 'aerated-concrete',
  formulaVersion: 'aerated-concrete-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'wallWidth', unit: 'm', defaultValue: 10, min: 1, max: 100),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 1, max: 5),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 27, min: 1, max: 500),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 5, min: 0, max: 50),
    CanonicalInputField(key: 'blockThickness', unit: 'mm', defaultValue: 200, min: 100, max: 400),
    CanonicalInputField(key: 'blockHeight', unit: 'mm', defaultValue: 200, min: 200, max: 250),
    CanonicalInputField(key: 'blockLength', unit: 'mm', defaultValue: 600, min: 600, max: 625),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  blockThicknessOptions: [100, 150, 200, 250, 300, 375, 400],
  blockHeightOptions: [200, 250],
  blockLengthOptions: [600, 625],
  packagingRules: AeratedConcretePackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: AeratedConcreteMaterialRules(
    glueKgPerM3: 28,
    glueBagKg: 25,
    blockReserve: 1.05,
    rebarArmoringInterval: 4,
    rebarReserve: 1.1,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCanL: 10,
    cornerProfileLengthM: 2.5,
    cornerProfileCount: 4,
  ),
  warningRules: AeratedConcreteWarningRules(
    nonLoadBearingThicknessMm: 150,
    thermalCheckThicknessMm: 300,
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

double _defaultFor(AeratedConcreteCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveArea(AeratedConcreteCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final wallWidth = math.max(1, inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 10)).toDouble();
    final wallHeight = math.max(1, inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble();
    return {
      'inputMode': 0.0,
      'wallArea': _roundValue(wallWidth * wallHeight, 3),
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
    };
  }
  final area = math.max(1, inputs['area'] ?? _defaultFor(spec, 'area', 27)).toDouble();
  final wallWidth = (inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 10)).toDouble();
  final wallHeight = (inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).toDouble();
  return {
    'inputMode': 1.0,
    'wallArea': _roundValue(area, 3),
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

Map<String, double> _keyFactors(AeratedConcreteCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(AeratedConcreteCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalAeratedConcrete(
  Map<String, double> inputs, {
  AeratedConcreteCanonicalSpec spec = aeratedConcreteCanonicalSpecV1,
}) {
  final areaInfo = _resolveArea(spec, inputs);
  final wallArea = areaInfo['wallArea']!;
  final wallWidth = areaInfo['wallWidth']!;
  final wallHeight = areaInfo['wallHeight']!;
  final inputMode = areaInfo['inputMode']!.round();

  final openingsArea = math.max(0, inputs['openingsArea'] ?? _defaultFor(spec, 'openingsArea', 5)).toDouble();
  final blockThickness = _resolveClosest(
    inputs['blockThickness'] ?? _defaultFor(spec, 'blockThickness', 200),
    spec.blockThicknessOptions,
  );
  final blockHeight = _resolveClosest(
    inputs['blockHeight'] ?? _defaultFor(spec, 'blockHeight', 200),
    spec.blockHeightOptions,
  );
  final blockLength = _resolveClosest(
    inputs['blockLength'] ?? _defaultFor(spec, 'blockLength', 600),
    spec.blockLengthOptions,
  );

  final netArea = math.max(0, wallArea - openingsArea).toDouble();

  final blockFaceArea = (blockHeight / 1000) * (blockLength / 1000);
  final blocksPerSqm = 1.0 / blockFaceArea;
  final blocksNet = netArea * blocksPerSqm;
  final blocksWithReserve = (blocksNet * spec.materialRules.blockReserve).ceil();

  final volume = _roundValue(netArea * (blockThickness / 1000), 6);

  final glueKg = _roundValue(volume * spec.materialRules.glueKgPerM3, 3);
  final glueBags = (glueKg / spec.materialRules.glueBagKg).ceil();

  final rows = (wallHeight / (blockHeight / 1000)).ceil();
  final rebarRows = (rows / spec.materialRules.rebarArmoringInterval).ceil();

  final perimeter = inputMode == 0
      ? wallWidth
      : math.sqrt(netArea) * 2;
  final rebarLength = (perimeter * rebarRows * spec.materialRules.rebarReserve).ceil();

  final primerCans = (netArea * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCanL).ceil();

  final openingsCount = (openingsArea / 2).ceil();
  final uBlocks = (openingsCount * 2 * spec.materialRules.rebarReserve).ceil();

  final cornerProfiles = (wallHeight / spec.materialRules.cornerProfileLengthM).ceil() * spec.materialRules.cornerProfileCount;

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
        'blockThickness:$blockThickness',
        'blockHeight:$blockHeight',
        'blockLength:$blockLength',
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
  if (blockThickness <= spec.warningRules.nonLoadBearingThicknessMm) {
    warnings.add('\u0422\u043e\u043b\u0449\u0438\u043d\u0430 \u0431\u043b\u043e\u043a\u0430 \u2264150 \u043c\u043c \u2014 \u0442\u043e\u043b\u044c\u043a\u043e \u0434\u043b\u044f \u043d\u0435\u043d\u0435\u0441\u0443\u0449\u0438\u0445 \u043f\u0435\u0440\u0435\u0433\u043e\u0440\u043e\u0434\u043e\u043a');
  }
  if (blockThickness >= spec.warningRules.thermalCheckThicknessMm) {
    warnings.add('\u0422\u043e\u043b\u0449\u0438\u043d\u0430 \u0431\u043b\u043e\u043a\u0430 \u2265300 \u043c\u043c \u2014 \u043f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0442\u0435\u043f\u043b\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u044e \u043f\u043e \u0421\u041f 50.13330');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '\u0413\u0430\u0437\u043e\u0431\u043b\u043e\u043a $blockLength\u00d7$blockHeight\u00d7$blockThickness \u043c\u043c',
      quantity: _roundValue(blocksNet, 3),
      unit: '\u0448\u0442',
      withReserve: blocksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u041a\u043b\u0435\u0439 \u0434\u043b\u044f \u0433\u0430\u0437\u043e\u0431\u0435\u0442\u043e\u043d\u0430 (${spec.materialRules.glueBagKg.toInt()} \u043a\u0433)',
      quantity: glueBags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags,
      category: '\u041a\u043b\u0430\u0434\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: '\u0410\u0440\u043c\u0430\u0442\u0443\u0440\u0430 \u00d88',
      quantity: rebarLength.toDouble(),
      unit: '\u043f.\u043c',
      withReserve: rebarLength.toDouble(),
      purchaseQty: rebarLength,
      category: '\u0410\u0440\u043c\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435',
    ),
    CanonicalMaterialResult(
      name: '\u0413\u0440\u0443\u043d\u0442\u043e\u0432\u043a\u0430 (${spec.materialRules.primerCanL.toInt()} \u043b)',
      quantity: primerCans.toDouble(),
      unit: '\u043a\u0430\u043d\u0438\u0441\u0442\u0440',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: '\u041e\u0442\u0434\u0435\u043b\u043a\u0430',
    ),
    CanonicalMaterialResult(
      name: 'U-\u0431\u043b\u043e\u043a\u0438 (\u043f\u0435\u0440\u0435\u043c\u044b\u0447\u043a\u0438)',
      quantity: uBlocks.toDouble(),
      unit: '\u0448\u0442',
      withReserve: uBlocks.toDouble(),
      purchaseQty: uBlocks,
      category: '\u041f\u0440\u043e\u0451\u043c\u044b',
    ),
    CanonicalMaterialResult(
      name: '\u0423\u0433\u043b\u043e\u0432\u044b\u0435 \u043f\u0440\u043e\u0444\u0438\u043b\u0438',
      quantity: cornerProfiles.toDouble(),
      unit: '\u0448\u0442',
      withReserve: cornerProfiles.toDouble(),
      purchaseQty: cornerProfiles,
      category: '\u041f\u0440\u043e\u0451\u043c\u044b',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': areaInfo['inputMode']!,
      'wallWidth': _roundValue(wallWidth, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'wallArea': _roundValue(wallArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'netArea': _roundValue(netArea, 3),
      'blockThickness': blockThickness.toDouble(),
      'blockHeight': blockHeight.toDouble(),
      'blockLength': blockLength.toDouble(),
      'blockFaceArea': _roundValue(blockFaceArea, 6),
      'blocksPerSqm': _roundValue(blocksPerSqm, 3),
      'blocksNet': _roundValue(blocksNet, 3),
      'blocksWithReserve': blocksWithReserve.toDouble(),
      'volume': volume,
      'glueKg': glueKg,
      'glueBags': glueBags.toDouble(),
      'rows': rows.toDouble(),
      'rebarRows': rebarRows.toDouble(),
      'perimeter': _roundValue(perimeter, 3),
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
