import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class DecorPlasterPackagingRules {
  final String unit;
  final int packageSize;

  const DecorPlasterPackagingRules({required this.unit, required this.packageSize});
}

class DecorPlasterMaterialRules {
  final Map<int, double> consumptionKgPerM2;
  final double plasterReserve;
  final double primerDeepLPerM2;
  final double primerDeepReserve;
  final double primerCan;
  final double tintedPrimerLPerM2;
  final double tintedCan;
  final int pigmentPer25Kg;
  final double waxLPerM2;
  final double waxCan;

  const DecorPlasterMaterialRules({
    required this.consumptionKgPerM2,
    required this.plasterReserve,
    required this.primerDeepLPerM2,
    required this.primerDeepReserve,
    required this.primerCan,
    required this.tintedPrimerLPerM2,
    required this.tintedCan,
    required this.pigmentPer25Kg,
    required this.waxLPerM2,
    required this.waxCan,
  });
}

class DecorPlasterWarningRules {
  final double largeAreaThresholdM2;
  final int venetianFacadeTextureId;

  const DecorPlasterWarningRules({required this.largeAreaThresholdM2, required this.venetianFacadeTextureId});
}

class DecorPlasterCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final DecorPlasterPackagingRules packagingRules;
  final DecorPlasterMaterialRules materialRules;
  final DecorPlasterWarningRules warningRules;

  const DecorPlasterCanonicalSpec({
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

const DecorPlasterCanonicalSpec decorPlasterCanonicalSpecV1 = DecorPlasterCanonicalSpec(
  calculatorId: 'decor-plaster',
  formulaVersion: 'decor-plaster-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 50, min: 1, max: 1000),
    CanonicalInputField(key: 'texture', defaultValue: 0, min: 0, max: 4),
    CanonicalInputField(key: 'surface', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'bagWeight', unit: 'kg', defaultValue: 25, min: 15, max: 25),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: DecorPlasterPackagingRules(unit: 'мешков', packageSize: 1),
  materialRules: DecorPlasterMaterialRules(
    consumptionKgPerM2: {0: 2.5, 1: 3.5, 2: 3.0, 3: 4.0, 4: 1.2},
    plasterReserve: 1.05,
    primerDeepLPerM2: 0.2,
    primerDeepReserve: 1.15,
    primerCan: 10,
    tintedPrimerLPerM2: 0.15,
    tintedCan: 5,
    pigmentPer25Kg: 1,
    waxLPerM2: 0.1,
    waxCan: 1,
  ),
  warningRules: DecorPlasterWarningRules(largeAreaThresholdM2: 200, venetianFacadeTextureId: 4),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _textureLabels = {
  0: 'Короед 2 мм',
  1: 'Короед 3 мм',
  2: 'Камешковая',
  3: 'Шуба',
  4: 'Венецианская',
};

/* ─── helpers ─── */

bool hasCanonicalDecorPlasterInputs(Map<String, double> inputs) {
  return inputs.containsKey('texture') ||
      inputs.containsKey('area') ||
      inputs.containsKey('surface');
}

Map<String, double> normalizeLegacyDecorPlasterInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 50).toDouble();
  normalized['texture'] = (inputs['texture'] ?? 0).toDouble();
  normalized['surface'] = (inputs['surface'] ?? 0).toDouble();
  normalized['bagWeight'] = (inputs['bagWeight'] ?? 25).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(DecorPlasterCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(DecorPlasterCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(DecorPlasterCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalDecorPlaster(
  Map<String, double> inputs, {
  DecorPlasterCanonicalSpec spec = decorPlasterCanonicalSpecV1,
}) {
  final normalized = hasCanonicalDecorPlasterInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyDecorPlasterInputs(inputs);

  final area = (normalized['area'] ?? _defaultFor(spec, 'area', 50)).round().clamp(1, 1000);
  final texture = (normalized['texture'] ?? _defaultFor(spec, 'texture', 0)).round().clamp(0, 4);
  final surface = (normalized['surface'] ?? _defaultFor(spec, 'surface', 0)).round().clamp(0, 1);
  final bagWeightRaw = (normalized['bagWeight'] ?? _defaultFor(spec, 'bagWeight', 25)).round();
  final bagWeight = bagWeightRaw == 15 ? 15 : 25;

  // Consumption
  final consumption = spec.materialRules.consumptionKgPerM2[texture] ?? 2.5;

  // Formulas
  final totalKg = area * consumption * spec.materialRules.plasterReserve;
  final bags = (totalKg / bagWeight).ceil();
  final primerCans = (area * spec.materialRules.primerDeepLPerM2 * spec.materialRules.primerDeepReserve / spec.materialRules.primerCan).ceil();
  final tintedPrimer = (area * spec.materialRules.tintedPrimerLPerM2 / spec.materialRules.tintedCan).ceil();
  final pigmentBanks = (totalKg / 25).ceil();
  final waxCans = texture == spec.warningRules.venetianFacadeTextureId ? (area * spec.materialRules.waxLPerM2 / spec.materialRules.waxCan).ceil() : 0;

  // Scenarios
  final packageLabel = 'decor-plaster-bag-${bagWeight}kg';
  const packageUnit = 'мешков';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(bags * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'texture:$texture',
        'surface:$surface',
        'bagWeight:$bagWeight',
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
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку');
  }
  if (texture == spec.warningRules.venetianFacadeTextureId && surface == 0) {
    warnings.add('Венецианская штукатурка на фасаде — требуется защитный лак');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_textureLabels[texture]} (мешки $bagWeight кг)',
      quantity: recScenario.exactNeed,
      unit: 'мешков',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Штукатурка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка глубокого проникновения (${spec.materialRules.primerCan.round()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Тонированная грунтовка (${spec.materialRules.tintedCan.round()} л)',
      quantity: tintedPrimer.toDouble(),
      unit: 'канистр',
      withReserve: tintedPrimer.toDouble(),
      purchaseQty: tintedPrimer,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Пигмент / колер (банки)',
      quantity: pigmentBanks.toDouble(),
      unit: 'шт',
      withReserve: pigmentBanks.toDouble(),
      purchaseQty: pigmentBanks,
      category: 'Отделка',
    ),
  ];

  if (waxCans > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Воск для венецианской штукатурки (${spec.materialRules.waxCan.round()} л)',
      quantity: waxCans.toDouble(),
      unit: 'банок',
      withReserve: waxCans.toDouble(),
      purchaseQty: waxCans,
      category: 'Отделка',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area.toDouble(),
      'texture': texture.toDouble(),
      'surface': surface.toDouble(),
      'bagWeight': bagWeight.toDouble(),
      'consumption': consumption,
      'totalKg': _roundValue(totalKg, 4),
      'bags': bags.toDouble(),
      'primerCans': primerCans.toDouble(),
      'tintedPrimer': tintedPrimer.toDouble(),
      'pigmentBanks': pigmentBanks.toDouble(),
      'waxCans': waxCans.toDouble(),
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
