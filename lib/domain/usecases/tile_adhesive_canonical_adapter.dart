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

CanonicalCalculatorContractResult calculateCanonicalTileAdhesive(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(tileAdhesiveSpecData);

  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 20)));
  final tileSize = (inputs['tileSize'] ?? defaultFor(spec, 'tileSize', 0)).round().clamp(0, 2);
  final laying = (inputs['laying'] ?? defaultFor(spec, 'laying', 0)).round().clamp(0, 2);
  final base = (inputs['base'] ?? defaultFor(spec, 'base', 0)).round().clamp(0, 2);
  final bagWeightRaw = inputs['bagWeight'] ?? defaultFor(spec, 'bagWeight', 25);
  final bagWeight = bagWeightRaw == 5 ? 5.0 : 25.0;

  // Adjusted rate
  var adjustedRate = (spec.materialRule<Map>('base_consumption')['$tileSize'] as num?)?.toDouble() ?? (spec.materialRule<Map>('base_consumption')['0'] as num?)?.toDouble() ?? 3.0;
  if (laying == 1) adjustedRate *= spec.materialRule<num>('wall_factor').toDouble();
  if (laying == 2) adjustedRate *= spec.materialRule<num>('street_factor').toDouble();
  if (base == 2) adjustedRate *= spec.materialRule<num>('old_tile_factor').toDouble();

  final totalKg = area * adjustedRate * spec.materialRule<num>('adhesive_reserve').toDouble();
  final bags = (totalKg / bagWeight).ceil();

  // Primer
  final primer = (area * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();

  // Crosses
  final tileSideM = (spec.materialRule<Map>('tile_sizes_for_cross')['$tileSize'] as num?)?.toDouble() ?? (spec.materialRule<Map>('tile_sizes_for_cross')['0'] as num?)?.toDouble() ?? 0.3;
  final tilesPerM2 = 1 / (tileSideM * tileSideM);
  final crosses = (area * tilesPerM2 * spec.materialRule<num>('crosses_per_tile').toDouble() * spec.materialRule<num>('cross_reserve').toDouble()).ceil();
  final crossPacks = (crosses / spec.materialRule<num>('cross_pack').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(totalKg * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * bagWeight, 6);
    final packageLabel = 'adhesive-bag-${bagWeight.toInt()}kg';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'tileSize:$tileSize',
        'laying:$laying',
        'base:$base',
        'bagWeight:${bagWeight.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: bagWeight,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
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
      purchaseQty: (recScenario.purchaseQuantity / bagWeight).ceil() * bagWeight,
      packageInfo: {'count': (recScenario.purchaseQuantity / bagWeight).ceil(), 'size': bagWeight, 'packageUnit': 'мешков'},
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRule<num>('primer_can').toInt()} л)',
      quantity: primer.toDouble(),
      unit: 'канистр',
      withReserve: primer.toDouble(),
      purchaseQty: primer.toDouble(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Крестики (упаковка ${spec.materialRule<num>('cross_pack').toDouble()} шт)',
      quantity: crossPacks.toDouble(),
      unit: 'упаковок',
      withReserve: crossPacks.toDouble(),
      purchaseQty: crossPacks.toDouble(),
      category: 'Расходники',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'tileSize': tileSize.toDouble(),
      'laying': laying.toDouble(),
      'base': base.toDouble(),
      'bagWeight': bagWeight,
      'adjustedRate': roundValue(adjustedRate, 3),
      'totalKg': roundValue(totalKg, 3),
      'bags': bags.toDouble(),
      'primer': primer.toDouble(),
      'tilesPerM2': roundValue(tilesPerM2, 3),
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
