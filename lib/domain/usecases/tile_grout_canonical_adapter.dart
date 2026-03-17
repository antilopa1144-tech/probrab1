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

CanonicalCalculatorContractResult calculateCanonicalTileGrout(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(tileGroutSpecData);

  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 20)));
  final tileWidth = math.max(50, math.min(1200, (inputs['tileWidth'] ?? defaultFor(spec, 'tileWidth', 300)).round()));
  final tileHeight = math.max(50, math.min(1200, (inputs['tileHeight'] ?? defaultFor(spec, 'tileHeight', 300)).round()));
  final tileThickness = math.max(6, math.min(25, (inputs['tileThickness'] ?? defaultFor(spec, 'tileThickness', 8)).round()));
  final jointWidth = math.max(1, math.min(20, (inputs['jointWidth'] ?? defaultFor(spec, 'jointWidth', 3)).round()));
  final groutType = (inputs['groutType'] ?? defaultFor(spec, 'groutType', 0)).round().clamp(0, 2);
  final bagSizeRaw = inputs['bagSize'] ?? defaultFor(spec, 'bagSize', 2);
  final bagSize = [1.0, 2.0, 5.0].contains(bagSizeRaw) ? bagSizeRaw : 2.0;

  // Joint length per m2
  final jointLenPerM2 = (1000 / tileWidth) + (1000 / tileHeight);

  // Joint volume per m2 in liters
  final jointVolPerM2 = jointLenPerM2 * (jointWidth / 1000) * (tileThickness / 1000) * 1000;

  // Density in kg/L
  final density = ((spec.materialRule<Map>('grout_density')['$groutType'] as num?)?.toDouble() ?? (spec.materialRule<Map>('grout_density')['0'] as num?)?.toDouble() ?? 0.0) / 1000;

  final kgPerM2 = jointVolPerM2 * density;
  final totalKg = area * kgPerM2 * spec.materialRule<num>('grout_reserve').toDouble();
  final bags = (totalKg / bagSize).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(totalKg * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / bagSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * bagSize, 6);
    final packageLabel = 'grout-bag-${bagSize.toInt()}kg';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'groutType:$groutType',
        'bagSize:${bagSize.toInt()}',
        'tileWidth:$tileWidth',
        'tileHeight:$tileHeight',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: bagSize,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final groutTypeLabels = <int, String>{
    0: 'Затирка цементная',
    1: 'Затирка эпоксидная',
    2: 'Затирка полиуретановая',
  };

  final warnings = <String>[];
  if (groutType == 1) {
    warnings.add('Эпоксидная затирка требует быстрого нанесения — готовьте небольшими порциями');
  }
  if (jointWidth >= spec.warningRule<num>('wide_joint_threshold_mm').toDouble()) {
    warnings.add('Широкие швы — рекомендуется крупнозернистая затирка');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${groutTypeLabels[groutType]} ${bagSize.toInt()}кг',
      quantity: recScenario.exactNeed,
      unit: 'кг',
      withReserve: recScenario.exactNeed,
      purchaseQty: (recScenario.purchaseQuantity / bagSize).ceil() * bagSize,
      packageInfo: {'count': (recScenario.purchaseQuantity / bagSize).ceil(), 'size': bagSize, 'packageUnit': 'мешков'},
      category: 'Основное',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'tileWidth': tileWidth.toDouble(),
      'tileHeight': tileHeight.toDouble(),
      'tileThickness': tileThickness.toDouble(),
      'jointWidth': jointWidth.toDouble(),
      'groutType': groutType.toDouble(),
      'bagSize': bagSize,
      'jointLenPerM2': roundValue(jointLenPerM2, 6),
      'jointVolPerM2': roundValue(jointVolPerM2, 6),
      'density': roundValue(density, 3),
      'kgPerM2': roundValue(kgPerM2, 6),
      'totalKg': roundValue(totalKg, 3),
      'bags': bags.toDouble(),
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
