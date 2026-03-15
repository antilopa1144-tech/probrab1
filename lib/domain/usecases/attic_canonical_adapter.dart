import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class AtticPackagingRules {
  final String unit;
  final int packageSize;

  const AtticPackagingRules({required this.unit, required this.packageSize});
}

class AtticMaterialRules {
  final Map<int, int> plateThickness;
  final Map<int, double> plateArea;
  final double windMembraneRoll;
  final double vaporRoll;
  final double tapeRoll;
  final double plateReserve;
  final double membraneReserve;
  final double tapeAreaCoeff;
  final double panelArea;
  final double panelReserve;
  final double battenPitch;
  final double gklSheet;
  final double gklReserve;
  final double profileStep;
  final double puttyKgPerM2;
  final double puttyBag;

  const AtticMaterialRules({
    required this.plateThickness,
    required this.plateArea,
    required this.windMembraneRoll,
    required this.vaporRoll,
    required this.tapeRoll,
    required this.plateReserve,
    required this.membraneReserve,
    required this.tapeAreaCoeff,
    required this.panelArea,
    required this.panelReserve,
    required this.battenPitch,
    required this.gklSheet,
    required this.gklReserve,
    required this.profileStep,
    required this.puttyKgPerM2,
    required this.puttyBag,
  });
}

class AtticWarningRules {
  final int thinInsulationThresholdMm;

  const AtticWarningRules({required this.thinInsulationThresholdMm});
}

class AtticCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final AtticPackagingRules packagingRules;
  final AtticMaterialRules materialRules;
  final AtticWarningRules warningRules;

  const AtticCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── spec instance ─── */

const AtticCanonicalSpec atticCanonicalSpecV1 = AtticCanonicalSpec(
  calculatorId: 'attic',
  formulaVersion: 'attic-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'roofArea', unit: 'm2', defaultValue: 60, min: 10, max: 300),
    CanonicalInputField(key: 'insulationThickness', unit: 'mm', defaultValue: 200, min: 150, max: 250),
    CanonicalInputField(key: 'insulationType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'finishType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'withVapourBarrier', defaultValue: 1, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: AtticPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: AtticMaterialRules(
    plateThickness: {0: 100, 1: 150, 2: 100},
    plateArea: {0: 0.6, 1: 0.6, 2: 0.72},
    windMembraneRoll: 70,
    vaporRoll: 70,
    tapeRoll: 25,
    plateReserve: 1.05,
    membraneReserve: 1.15,
    tapeAreaCoeff: 40,
    panelArea: 0.288,
    panelReserve: 1.12,
    battenPitch: 0.4,
    gklSheet: 3.0,
    gklReserve: 1.1,
    profileStep: 0.6,
    puttyKgPerM2: 0.5,
    puttyBag: 25,
  ),
  warningRules: AtticWarningRules(thinInsulationThresholdMm: 200),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _insulationTypeLabels = {
  0: 'Минвата плиты',
  1: 'Минвата рулоны',
  2: 'ЭППС',
};

const Map<int, String> _finishTypeLabels = {
  0: 'Деревянная вагонка',
  1: 'ГКЛ',
  2: 'Без отделки',
};

const Map<int, String> _vapourLabels = {
  0: 'Без пароизоляции',
  1: 'Стандартная',
  2: 'Армированная',
};

/* ─── helpers ─── */

bool hasCanonicalAtticInputs(Map<String, double> inputs) {
  return inputs.containsKey('roofArea') ||
      inputs.containsKey('insulationType') ||
      inputs.containsKey('finishType');
}

Map<String, double> normalizeLegacyAtticInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['roofArea'] = (inputs['roofArea'] ?? 60).toDouble();
  normalized['insulationThickness'] = (inputs['insulationThickness'] ?? 200).toDouble();
  normalized['insulationType'] = (inputs['insulationType'] ?? 0).toDouble();
  normalized['finishType'] = (inputs['finishType'] ?? 0).toDouble();
  normalized['withVapourBarrier'] = (inputs['withVapourBarrier'] ?? 1).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(AtticCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(AtticCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(AtticCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalAttic(
  Map<String, double> inputs, {
  AtticCanonicalSpec spec = atticCanonicalSpecV1,
}) {
  final normalized = hasCanonicalAtticInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyAtticInputs(inputs);

  final roofArea = math.max(10.0, math.min(300.0, (normalized['roofArea'] ?? _defaultFor(spec, 'roofArea', 60)).toDouble()));
  final insulationThickness = math.max(150.0, math.min(250.0, (normalized['insulationThickness'] ?? _defaultFor(spec, 'insulationThickness', 200)).toDouble()));
  final insulationType = (normalized['insulationType'] ?? _defaultFor(spec, 'insulationType', 0)).round().clamp(0, 2);
  final finishType = (normalized['finishType'] ?? _defaultFor(spec, 'finishType', 0)).round().clamp(0, 2);
  final withVapourBarrier = (normalized['withVapourBarrier'] ?? _defaultFor(spec, 'withVapourBarrier', 1)).round().clamp(0, 2);

  // Insulation
  final plateThickness = spec.materialRules.plateThickness[insulationType] ?? 100;
  final plateArea = spec.materialRules.plateArea[insulationType] ?? 0.6;
  final layerCount = (insulationThickness / plateThickness).ceil();
  final insPlates = (roofArea * spec.materialRules.plateReserve / plateArea).ceil() * layerCount;
  final windRolls = (roofArea * spec.materialRules.membraneReserve / spec.materialRules.windMembraneRoll).ceil();
  final vbRolls = withVapourBarrier > 0 ? (roofArea * spec.materialRules.membraneReserve / spec.materialRules.vaporRoll).ceil() : 0;
  final tapeRolls = (roofArea / spec.materialRules.tapeAreaCoeff).ceil();

  // Finish: wood
  var panels = 0;
  var battenPcs = 0;
  var antisepticCans = 0;

  // Finish: GKL
  var gklSheets = 0;
  var profilePcs = 0;
  var puttyBags = 0;

  if (finishType == 0) {
    panels = (roofArea * spec.materialRules.panelReserve / spec.materialRules.panelArea).ceil();
    battenPcs = (roofArea / spec.materialRules.battenPitch).ceil();
    antisepticCans = (roofArea * 0.15 * 1.1 / 5).ceil();
  } else if (finishType == 1) {
    gklSheets = (roofArea * spec.materialRules.gklReserve / spec.materialRules.gklSheet).ceil();
    profilePcs = (roofArea / spec.materialRules.profileStep / 3).ceil();
    puttyBags = (roofArea * spec.materialRules.puttyKgPerM2 / spec.materialRules.puttyBag).ceil();
  }

  // Scenarios
  final basePrimary = insPlates;
  final packageLabel = 'insulation-plate';
  final packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'insulationThickness:${insulationThickness.round()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (insulationThickness < spec.warningRules.thinInsulationThresholdMm) {
    warnings.add('Толщина утеплителя менее 200 мм — рекомендуется увеличить для средней полосы России');
  }
  if (withVapourBarrier == 0) {
    warnings.add('Без пароизоляции утеплитель подвержен намоканию и потере свойств');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_insulationTypeLabels[insulationType]} (${insulationThickness.round()} мм, $layerCount сл.)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Ветрозащитная мембрана (70 м²)',
      quantity: windRolls.toDouble(),
      unit: 'рулонов',
      withReserve: windRolls.toDouble(),
      purchaseQty: windRolls,
      category: 'Мембраны',
    ),
  ];

  if (withVapourBarrier > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Пароизоляция ${_vapourLabels[withVapourBarrier]} (70 м²)',
      quantity: vbRolls.toDouble(),
      unit: 'рулонов',
      withReserve: vbRolls.toDouble(),
      purchaseQty: vbRolls,
      category: 'Мембраны',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Скотч соединительный (25 м)',
    quantity: tapeRolls.toDouble(),
    unit: 'рулонов',
    withReserve: tapeRolls.toDouble(),
    purchaseQty: tapeRolls,
    category: 'Расходные',
  ));

  if (finishType == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Вагонка деревянная',
        quantity: panels.toDouble(),
        unit: 'шт',
        withReserve: panels.toDouble(),
        purchaseQty: panels,
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Обрешётка (рейки)',
        quantity: battenPcs.toDouble(),
        unit: 'шт',
        withReserve: battenPcs.toDouble(),
        purchaseQty: battenPcs,
        category: 'Каркас',
      ),
      CanonicalMaterialResult(
        name: 'Антисептик (5 л)',
        quantity: antisepticCans.toDouble(),
        unit: 'канистр',
        withReserve: antisepticCans.toDouble(),
        purchaseQty: antisepticCans,
        category: 'Защита',
      ),
    ]);
  } else if (finishType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ГКЛ (3 м²)',
        quantity: gklSheets.toDouble(),
        unit: 'листов',
        withReserve: gklSheets.toDouble(),
        purchaseQty: gklSheets,
        category: 'Отделка',
      ),
      CanonicalMaterialResult(
        name: 'Профиль направляющий',
        quantity: profilePcs.toDouble(),
        unit: 'шт',
        withReserve: profilePcs.toDouble(),
        purchaseQty: profilePcs,
        category: 'Каркас',
      ),
      CanonicalMaterialResult(
        name: 'Шпаклёвка (25 кг)',
        quantity: puttyBags.toDouble(),
        unit: 'мешков',
        withReserve: puttyBags.toDouble(),
        purchaseQty: puttyBags,
        category: 'Отделка',
      ),
    ]);
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofArea': _roundValue(roofArea, 3),
      'insulationThickness': insulationThickness,
      'insulationType': insulationType.toDouble(),
      'finishType': finishType.toDouble(),
      'withVapourBarrier': withVapourBarrier.toDouble(),
      'layerCount': layerCount.toDouble(),
      'insPlates': insPlates.toDouble(),
      'windRolls': windRolls.toDouble(),
      'vbRolls': vbRolls.toDouble(),
      'tapeRolls': tapeRolls.toDouble(),
      'panels': panels.toDouble(),
      'battenPcs': battenPcs.toDouble(),
      'antisepticCans': antisepticCans.toDouble(),
      'gklSheets': gklSheets.toDouble(),
      'profilePcs': profilePcs.toDouble(),
      'puttyBags': puttyBags.toDouble(),
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
