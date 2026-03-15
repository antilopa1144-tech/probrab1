import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class TileAdhesivePackagingRules {
  final String unit;
  final double defaultBagWeight;
  final List<double> allowedBagWeights;

  const TileAdhesivePackagingRules({
    required this.unit,
    required this.defaultBagWeight,
    required this.allowedBagWeights,
  });
}

class TileAdhesiveMaterialRules {
  final Map<int, double> baseConsumption;
  final double wallFactor;
  final double streetFactor;
  final double oldTileFactor;
  final double adhesiveReserve;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final Map<int, double> tileSizesForCross;
  final int crossesPerTile;
  final double crossReserve;
  final int crossPack;

  const TileAdhesiveMaterialRules({
    required this.baseConsumption,
    required this.wallFactor,
    required this.streetFactor,
    required this.oldTileFactor,
    required this.adhesiveReserve,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.tileSizesForCross,
    required this.crossesPerTile,
    required this.crossReserve,
    required this.crossPack,
  });
}

class TileAdhesiveWarningRules {
  final bool largeTileWarning;
  final bool oldTilePrimerWarning;

  const TileAdhesiveWarningRules({
    required this.largeTileWarning,
    required this.oldTilePrimerWarning,
  });
}

class TileAdhesiveCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final TileAdhesivePackagingRules packagingRules;
  final TileAdhesiveMaterialRules materialRules;
  final TileAdhesiveWarningRules warningRules;

  const TileAdhesiveCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const TileAdhesiveCanonicalSpec tileAdhesiveCanonicalSpecV1 = TileAdhesiveCanonicalSpec(
  calculatorId: 'tile-adhesive',
  formulaVersion: 'tile-adhesive-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 20, min: 1, max: 500),
    CanonicalInputField(key: 'tileSize', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'laying', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'base', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'bagWeight', unit: 'kg', defaultValue: 25, min: 5, max: 25),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: TileAdhesivePackagingRules(
    unit: 'мешков',
    defaultBagWeight: 25,
    allowedBagWeights: [5, 25],
  ),
  materialRules: TileAdhesiveMaterialRules(
    baseConsumption: {0: 3.0, 1: 5.0, 2: 7.5},
    wallFactor: 0.85,
    streetFactor: 1.3,
    oldTileFactor: 1.2,
    adhesiveReserve: 1.1,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCan: 10,
    tileSizesForCross: {0: 0.3, 1: 0.45, 2: 0.6},
    crossesPerTile: 4,
    crossReserve: 1.1,
    crossPack: 200,
  ),
  warningRules: TileAdhesiveWarningRules(
    largeTileWarning: true,
    oldTilePrimerWarning: true,
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

double _defaultFor(TileAdhesiveCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(TileAdhesiveCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(TileAdhesiveCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalTileAdhesive(
  Map<String, double> inputs, {
  TileAdhesiveCanonicalSpec spec = tileAdhesiveCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? _defaultFor(spec, 'area', 20)));
  final tileSize = (inputs['tileSize'] ?? _defaultFor(spec, 'tileSize', 0)).round().clamp(0, 2);
  final laying = (inputs['laying'] ?? _defaultFor(spec, 'laying', 0)).round().clamp(0, 2);
  final base = (inputs['base'] ?? _defaultFor(spec, 'base', 0)).round().clamp(0, 2);
  final bagWeightRaw = inputs['bagWeight'] ?? _defaultFor(spec, 'bagWeight', 25);
  final bagWeight = bagWeightRaw == 5 ? 5.0 : 25.0;

  // Adjusted rate
  var adjustedRate = spec.materialRules.baseConsumption[tileSize] ?? spec.materialRules.baseConsumption[0]!;
  if (laying == 1) adjustedRate *= spec.materialRules.wallFactor;
  if (laying == 2) adjustedRate *= spec.materialRules.streetFactor;
  if (base == 2) adjustedRate *= spec.materialRules.oldTileFactor;

  final totalKg = area * adjustedRate * spec.materialRules.adhesiveReserve;
  final bags = (totalKg / bagWeight).ceil();

  // Primer
  final primer = (area * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCan).ceil();

  // Crosses
  final tileSideM = spec.materialRules.tileSizesForCross[tileSize] ?? spec.materialRules.tileSizesForCross[0]!;
  final tilesPerM2 = 1 / (tileSideM * tileSideM);
  final crosses = (area * tilesPerM2 * spec.materialRules.crossesPerTile * spec.materialRules.crossReserve).ceil();
  final crossPacks = (crosses / spec.materialRules.crossPack).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalKg * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * bagWeight, 6);
    final packageLabel = 'adhesive-bag-${bagWeight.toInt()}kg';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'tileSize:$tileSize',
        'laying:$laying',
        'base:$base',
        'bagWeight:${bagWeight.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: bagWeight,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (tileSize == 2) {
    warnings.add('Крупноформатная плитка — рекомендуется гребёнка 12 мм');
  }
  if (base == 2) {
    warnings.add('Укладка на старую плитку — обязателен контактный грунт');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Плиточный клей ${bagWeight.toInt()}кг',
      quantity: recScenario.exactNeed,
      unit: 'кг',
      withReserve: recScenario.exactNeed,
      purchaseQty: (recScenario.purchaseQuantity / bagWeight).ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRules.primerCan.toInt()} л)',
      quantity: primer.toDouble(),
      unit: 'канистр',
      withReserve: primer.toDouble(),
      purchaseQty: primer,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Крестики (упаковка ${spec.materialRules.crossPack} шт)',
      quantity: crossPacks.toDouble(),
      unit: 'упаковок',
      withReserve: crossPacks.toDouble(),
      purchaseQty: crossPacks,
      category: 'Расходники',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'tileSize': tileSize.toDouble(),
      'laying': laying.toDouble(),
      'base': base.toDouble(),
      'bagWeight': bagWeight,
      'adjustedRate': _roundValue(adjustedRate, 3),
      'totalKg': _roundValue(totalKg, 3),
      'bags': bags.toDouble(),
      'primer': primer.toDouble(),
      'tilesPerM2': _roundValue(tilesPerM2, 3),
      'crosses': crosses.toDouble(),
      'crossPacks': crossPacks.toDouble(),
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
