import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class SoftRoofingPackagingRules {
  final String unit;
  final double packageSize;

  const SoftRoofingPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class SoftRoofingMaterialRules {
  final double packArea;
  final double packReserve;
  final double underlaymentRoll;
  final double underlaymentFullReserve;
  final double slopeThreshold;
  final double criticalZoneWidth;
  final double valleyRoll;
  final double valleyReserve;
  final double masticLinearRate;
  final double masticAreaRate;
  final double masticBucket;
  final double nailsPerM2;
  final double nailsPerKg;
  final double nailReserve;
  final double eaveStripLength;
  final double eaveReserve;
  final double windStripRatio;
  final double ridgeShingleStep;
  final double ridgeReserve;
  final double osbSheet;
  final double osbReserve;
  final double ventPerArea;

  const SoftRoofingMaterialRules({
    required this.packArea,
    required this.packReserve,
    required this.underlaymentRoll,
    required this.underlaymentFullReserve,
    required this.slopeThreshold,
    required this.criticalZoneWidth,
    required this.valleyRoll,
    required this.valleyReserve,
    required this.masticLinearRate,
    required this.masticAreaRate,
    required this.masticBucket,
    required this.nailsPerM2,
    required this.nailsPerKg,
    required this.nailReserve,
    required this.eaveStripLength,
    required this.eaveReserve,
    required this.windStripRatio,
    required this.ridgeShingleStep,
    required this.ridgeReserve,
    required this.osbSheet,
    required this.osbReserve,
    required this.ventPerArea,
  });
}

class SoftRoofingWarningRules {
  final double lowSlopeThreshold;
  final bool valleyWarning;

  const SoftRoofingWarningRules({
    required this.lowSlopeThreshold,
    required this.valleyWarning,
  });
}

class SoftRoofingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final SoftRoofingPackagingRules packagingRules;
  final SoftRoofingMaterialRules materialRules;
  final SoftRoofingWarningRules warningRules;

  const SoftRoofingCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const SoftRoofingCanonicalSpec softRoofingCanonicalSpecV1 = SoftRoofingCanonicalSpec(
  calculatorId: 'soft-roofing',
  formulaVersion: 'soft-roofing-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'roofArea', unit: 'm\u00b2', defaultValue: 80, min: 10, max: 500),
    CanonicalInputField(key: 'slope', unit: '\u00b0', defaultValue: 30, min: 12, max: 60),
    CanonicalInputField(key: 'ridgeLength', unit: 'm', defaultValue: 8, min: 0, max: 50),
    CanonicalInputField(key: 'eaveLength', unit: 'm', defaultValue: 20, min: 0, max: 100),
    CanonicalInputField(key: 'valleyLength', unit: 'm', defaultValue: 0, min: 0, max: 30),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: SoftRoofingPackagingRules(
    unit: 'упаковок',
    packageSize: 1,
  ),
  materialRules: SoftRoofingMaterialRules(
    packArea: 3.0,
    packReserve: 1.05,
    underlaymentRoll: 15,
    underlaymentFullReserve: 1.15,
    slopeThreshold: 18,
    criticalZoneWidth: 1.0,
    valleyRoll: 10,
    valleyReserve: 1.15,
    masticLinearRate: 0.1,
    masticAreaRate: 0.1,
    masticBucket: 3,
    nailsPerM2: 80,
    nailsPerKg: 400,
    nailReserve: 1.05,
    eaveStripLength: 2,
    eaveReserve: 1.05,
    windStripRatio: 0.4,
    ridgeShingleStep: 0.5,
    ridgeReserve: 1.05,
    osbSheet: 3.125,
    osbReserve: 1.05,
    ventPerArea: 25,
  ),
  warningRules: SoftRoofingWarningRules(
    lowSlopeThreshold: 18,
    valleyWarning: true,
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

double _defaultFor(SoftRoofingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(SoftRoofingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(SoftRoofingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalSoftRoofing(
  Map<String, double> inputs, {
  SoftRoofingCanonicalSpec spec = softRoofingCanonicalSpecV1,
}) {
  final roofArea = math.max(10.0, math.min(500.0, inputs['roofArea'] ?? _defaultFor(spec, 'roofArea', 80)));
  final slope = math.max(12.0, math.min(60.0, inputs['slope'] ?? _defaultFor(spec, 'slope', 30)));
  final ridgeLength = math.max(0.0, math.min(50.0, inputs['ridgeLength'] ?? _defaultFor(spec, 'ridgeLength', 8)));
  final eaveLength = math.max(0.0, math.min(100.0, inputs['eaveLength'] ?? _defaultFor(spec, 'eaveLength', 20)));
  final valleyLength = math.max(0.0, math.min(30.0, inputs['valleyLength'] ?? _defaultFor(spec, 'valleyLength', 0)));

  // Packs
  final packs = (roofArea / spec.materialRules.packArea * spec.materialRules.packReserve).ceil();

  // Underlayment
  int underlaymentRolls;
  if (slope < spec.materialRules.slopeThreshold) {
    underlaymentRolls = (roofArea * spec.materialRules.underlaymentFullReserve / spec.materialRules.underlaymentRoll).ceil();
  } else {
    final criticalArea = (eaveLength + valleyLength + ridgeLength) * spec.materialRules.criticalZoneWidth * spec.materialRules.underlaymentFullReserve;
    underlaymentRolls = (criticalArea / spec.materialRules.underlaymentRoll).ceil();
  }

  // Valley
  final valleyRolls = valleyLength > 0 ? (valleyLength * spec.materialRules.valleyReserve / spec.materialRules.valleyRoll).ceil() : 0;

  // Mastic
  final masticKg = (ridgeLength + eaveLength + valleyLength) * spec.materialRules.masticLinearRate + roofArea * spec.materialRules.masticAreaRate;
  final masticBuckets = (masticKg / spec.materialRules.masticBucket).ceil();

  // Nails
  final nailsKg = (roofArea * spec.materialRules.nailsPerM2 / spec.materialRules.nailsPerKg * spec.materialRules.nailReserve).ceil();

  // Eave strips
  final eaveStrips = (eaveLength / spec.materialRules.eaveStripLength * spec.materialRules.eaveReserve).ceil();

  // Wind strips
  final windStrips = (eaveLength * spec.materialRules.windStripRatio / spec.materialRules.eaveStripLength * spec.materialRules.eaveReserve).ceil();

  // Ridge shingles
  final ridgeShingles = (ridgeLength / spec.materialRules.ridgeShingleStep * spec.materialRules.ridgeReserve).ceil();

  // OSB sheets
  final osbSheets = (roofArea / spec.materialRules.osbSheet * spec.materialRules.osbReserve).ceil();

  // Vent outputs
  final ventOutputs = (roofArea / spec.materialRules.ventPerArea).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(packs * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    const packageLabel = 'shingle-pack';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'slope:${slope.toInt()}',
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
  if (slope < spec.warningRules.lowSlopeThreshold) {
    warnings.add('Уклон менее 18\u00b0 — подкладочный ковёр укладывается по всей площади');
  }
  if (valleyLength > 0) {
    warnings.add('Ендовы — наиболее уязвимые места, рекомендуется усиленная гидроизоляция');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Гибкая черепица (${spec.materialRules.packArea} м\u00b2/уп)',
      quantity: recScenario.exactNeed,
      unit: 'упаковок',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Подкладочный ковёр (${spec.materialRules.underlaymentRoll.toInt()} м\u00b2)',
      quantity: underlaymentRolls.toDouble(),
      unit: 'рулонов',
      withReserve: underlaymentRolls.toDouble(),
      purchaseQty: underlaymentRolls,
      category: 'Подкладка',
    ),
  ];

  if (valleyRolls > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Ендовный ковёр (${spec.materialRules.valleyRoll.toInt()} м)',
      quantity: valleyRolls.toDouble(),
      unit: 'рулонов',
      withReserve: valleyRolls.toDouble(),
      purchaseQty: valleyRolls,
      category: 'Подкладка',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Мастика (ведро ${spec.materialRules.masticBucket.toInt()} кг)',
      quantity: masticBuckets.toDouble(),
      unit: 'вёдер',
      withReserve: masticBuckets.toDouble(),
      purchaseQty: masticBuckets,
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Гвозди кровельные',
      quantity: nailsKg.toDouble(),
      unit: 'кг',
      withReserve: nailsKg.toDouble(),
      purchaseQty: nailsKg,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Карнизные планки (${spec.materialRules.eaveStripLength.toInt()} м)',
      quantity: eaveStrips.toDouble(),
      unit: 'шт',
      withReserve: eaveStrips.toDouble(),
      purchaseQty: eaveStrips,
      category: 'Доборные',
    ),
    CanonicalMaterialResult(
      name: 'Ветровые планки (${spec.materialRules.eaveStripLength.toInt()} м)',
      quantity: windStrips.toDouble(),
      unit: 'шт',
      withReserve: windStrips.toDouble(),
      purchaseQty: windStrips,
      category: 'Доборные',
    ),
    CanonicalMaterialResult(
      name: 'Коньково-карнизная черепица',
      quantity: ridgeShingles.toDouble(),
      unit: 'шт',
      withReserve: ridgeShingles.toDouble(),
      purchaseQty: ridgeShingles,
      category: 'Доборные',
    ),
    CanonicalMaterialResult(
      name: 'ОСП (${spec.materialRules.osbSheet} м\u00b2)',
      quantity: osbSheets.toDouble(),
      unit: 'листов',
      withReserve: osbSheets.toDouble(),
      purchaseQty: osbSheets,
      category: 'Основание',
    ),
    CanonicalMaterialResult(
      name: 'Вентиляционные выходы',
      quantity: ventOutputs.toDouble(),
      unit: 'шт',
      withReserve: ventOutputs.toDouble(),
      purchaseQty: ventOutputs,
      category: 'Вентиляция',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofArea': _roundValue(roofArea, 3),
      'slope': slope,
      'ridgeLength': _roundValue(ridgeLength, 3),
      'eaveLength': _roundValue(eaveLength, 3),
      'valleyLength': _roundValue(valleyLength, 3),
      'packs': packs.toDouble(),
      'underlaymentRolls': underlaymentRolls.toDouble(),
      'valleyRolls': valleyRolls.toDouble(),
      'masticKg': _roundValue(masticKg, 3),
      'masticBuckets': masticBuckets.toDouble(),
      'nailsKg': nailsKg.toDouble(),
      'eaveStrips': eaveStrips.toDouble(),
      'windStrips': windStrips.toDouble(),
      'ridgeShingles': ridgeShingles.toDouble(),
      'osbSheets': osbSheets.toDouble(),
      'ventOutputs': ventOutputs.toDouble(),
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
