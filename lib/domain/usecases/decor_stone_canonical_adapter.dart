import '../models/canonical_calculator_contract.dart';

/* ─── spec instance ─── */

const DecorStoneCanonicalSpec decorStoneCanonicalSpecV1 = DecorStoneCanonicalSpec(
  calculatorId: 'decor-stone',
  formulaVersion: 'decor-stone-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 15, min: 1, max: 500),
    CanonicalInputField(key: 'wallWidth', unit: 'm', defaultValue: 4, min: 0.5, max: 30),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 0.5, max: 10),
    CanonicalInputField(key: 'stoneType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'jointWidth', unit: 'mm', defaultValue: 10, min: 0, max: 20),
    CanonicalInputField(key: 'needGrout', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'needPrimer', defaultValue: 1, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: DecorStonePackagingRules(unit: 'м\u00b2', packageSize: 1),
  materialRules: DecorStoneMaterialRules(
    stoneReserve: 1.10,
    glueKgPerM2: [3.0, 5.0, 7.0],
    glueReserve: 1.10,
    glueBag: 25,
    primerLPerM2: 0.15,
    primerReserve: 1.10,
    primerCan: 10,
    groutBaseFactor: 0.2,
    groutReserve: 1.10,
    groutBag: 5,
  ),
  warningRules: DecorStoneWarningRules(largeAreaThresholdM2: 50),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(DecorStoneCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(DecorStoneCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(DecorStoneCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalDecorStone(
  Map<String, double> inputs, {
  DecorStoneCanonicalSpec spec = decorStoneCanonicalSpecV1,
}) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? _defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? _defaultFor(spec, 'wallWidth', 4)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7)).clamp(0.5, 10.0);
  final stoneType = (inputs['stoneType'] ?? _defaultFor(spec, 'stoneType', 0)).round().clamp(0, 2);
  final jointWidth = (inputs['jointWidth'] ?? _defaultFor(spec, 'jointWidth', 10)).clamp(0.0, 20.0);
  final needGrout = (inputs['needGrout'] ?? _defaultFor(spec, 'needGrout', 1)).round() == 1 ? 1 : 0;
  final needPrimer = (inputs['needPrimer'] ?? _defaultFor(spec, 'needPrimer', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? _roundValue(wallWidth * wallHeight, 3) : areaInput;

  // Stone
  final stoneM2 = area * spec.materialRules.stoneReserve;

  // Glue
  final glueRate = stoneType < spec.materialRules.glueKgPerM2.length
      ? spec.materialRules.glueKgPerM2[stoneType]
      : spec.materialRules.glueKgPerM2[0];
  final glueKg = area * glueRate * spec.materialRules.glueReserve;
  final glueBags = (glueKg / spec.materialRules.glueBag).ceil();

  // Grout (conditional)
  final groutKg = needGrout == 1
      ? area * (jointWidth / 5) * spec.materialRules.groutBaseFactor * spec.materialRules.groutReserve
      : 0.0;
  final groutBags = (groutKg / spec.materialRules.groutBag).ceil();

  // Primer (conditional)
  final primerL = needPrimer == 1
      ? area * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve
      : 0.0;
  final primerCans = (primerL / spec.materialRules.primerCan).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(stoneM2 * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'stoneType:$stoneType',
        'jointWidth:$jointWidth',
        'needGrout:$needGrout',
        'needPrimer:$needPrimer',
        'packaging:decor-stone-m2',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'decor-stone-m2',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'м\u00b2',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (stoneType == 2) {
    warnings.add('Натуральный камень тяжёлый — убедитесь в несущей способности стены');
  }
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку камня');
  }
  if (jointWidth == 0 && needGrout == 1) {
    warnings.add('Шов 0 мм — затирка не требуется при бесшовной укладке');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Декоративный камень',
      quantity: _roundValue(recScenario.exactNeed, 3),
      unit: 'м\u00b2',
      withReserve: _roundValue(recScenario.exactNeed, 3),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Клей (${spec.materialRules.glueBag.round()} кг)',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags,
      category: 'Монтаж',
    ),
  ];

  if (needGrout == 1 && groutBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Затирка (${spec.materialRules.groutBag.round()} кг)',
      quantity: groutBags.toDouble(),
      unit: 'мешков',
      withReserve: groutBags.toDouble(),
      purchaseQty: groutBags,
      category: 'Отделка',
    ));
  }

  if (needPrimer == 1 && primerCans > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Грунтовка (${spec.materialRules.primerCan.round()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Грунтовка',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'wallWidth': _roundValue(wallWidth, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'stoneType': stoneType.toDouble(),
      'jointWidth': jointWidth,
      'needGrout': needGrout.toDouble(),
      'needPrimer': needPrimer.toDouble(),
      'stoneM2': _roundValue(stoneM2, 3),
      'glueKg': _roundValue(glueKg, 3),
      'glueBags': glueBags.toDouble(),
      'groutKg': _roundValue(groutKg, 3),
      'groutBags': groutBags.toDouble(),
      'primerL': _roundValue(primerL, 3),
      'primerCans': primerCans.toDouble(),
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
