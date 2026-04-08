import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


CanonicalCalculatorContractResult calculateCanonicalFasteners(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(fastenersSpecData);

  final materialType = (inputs['materialType'] ?? defaultFor(spec, 'materialType', 0)).round().clamp(0, 3);
  final sheetCount = math.max(1, math.min(200, (inputs['sheetCount'] ?? defaultFor(spec, 'sheetCount', 10)).round()));
  final fastenerStep = math.max(150, math.min(300, (inputs['fastenerStep'] ?? defaultFor(spec, 'fastenerStep', 200)).round()));
  final withFrameScrews = (inputs['withFrameScrews'] ?? defaultFor(spec, 'withFrameScrews', 0)).round() == 1 ? 1 : 0;
  final withDubels = (inputs['withDubels'] ?? defaultFor(spec, 'withDubels', 0)).round() == 1 ? 1 : 0;

  // Formulas
  final baseStep = (spec.materialRule<Map>('base_step')['$materialType'] as num?)?.toDouble() ?? (spec.materialRule<Map>('base_step')['0'] as num?)?.toDouble() ?? 0.0;
  final stepCoeff = baseStep / fastenerStep;
  final baseScrews = (spec.materialRule<Map>('screws_per_unit')['$materialType'] as num?)?.toDouble() ?? (spec.materialRule<Map>('screws_per_unit')['0'] as num?)?.toDouble() ?? 0.0;
  final screwsPerUnit = (baseScrews * stepCoeff).ceil();
  var totalScrews = (sheetCount * screwsPerUnit * spec.materialRule<num>('screw_reserve').toDouble()).ceil();

  // Klaimers for paneling
  final klaimers = materialType == 3 ? (totalScrews * spec.materialRule<num>('klaymer_multiplier').toDouble()).ceil() : 0;
  if (materialType == 3) {
    totalScrews = klaimers;
  }

  // Frame screws
  final frameScrews = withFrameScrews == 1
      ? (sheetCount * spec.materialRule<num>('frame_screws_per_unit').toDouble() * spec.materialRule<num>('frame_screw_reserve').toDouble()).ceil()
      : 0;

  // Dubels
  final dubels = withDubels == 1
      ? (sheetCount * 2 / spec.materialRule<num>('dubel_step').toDouble() * spec.materialRule<num>('dubel_reserve').toDouble()).ceil()
      : 0;

  // Bits
  final bits = (totalScrews / spec.materialRule<num>('bits_per_screws').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('fasteners', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(totalScrews * accuracyMult * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    const packageLabel = 'fastener-unit';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'materialType:$materialType',
        'fastenerStep:$fastenerStep',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
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
  if (sheetCount > spec.warningRule<num>('bulk_threshold').toDouble()) {
    warnings.add('Большой объём — рассмотрите оптовую упаковку');
  }
  if (materialType == 3) {
    warnings.add('Для вагонки используются кляймеры вместо саморезов');
  }

  final screwLabel = materialType == 3
      ? 'Кляймеры'
      : 'Саморезы ${(spec.materialRule<Map>('screw_sizes')['$materialType'] as num?)?.toDouble()}';

  // PER_KG conversion: 0=1000, 1=600, 2=250, 3=0 (klaimers stay in шт)
  const perKgMap = {0: 1000, 1: 600, 2: 250, 3: 0};
  final perKg = perKgMap[materialType] ?? 0;
  final useKg = perKg > 0;
  final screwQtyKg = useKg ? (recScenario.exactNeed / perKg * 10).ceil() / 10 : 0.0;

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: screwLabel,
      quantity: useKg ? screwQtyKg : recScenario.exactNeed,
      unit: useKg ? 'кг' : 'шт',
      withReserve: useKg ? screwQtyKg : recScenario.exactNeed,
      purchaseQty: useKg ? screwQtyKg.ceil().toDouble() : recScenario.exactNeed.ceil().toDouble(),
      category: 'Крепёж',
    ),
  ];

  if (frameScrews > 0) {
    final frameScrewsKg = (frameScrews / 1000 * 10).ceil() / 10;
    materials.add(CanonicalMaterialResult(
      name: 'Саморезы каркасные',
      quantity: frameScrewsKg,
      unit: 'кг',
      withReserve: frameScrewsKg,
      purchaseQty: frameScrewsKg.ceil().toDouble(),
      category: 'Крепёж',
    ));
  }

  if (dubels > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Дюбели',
      quantity: dubels.toDouble(),
      unit: 'шт',
      withReserve: dubels.toDouble(),
      purchaseQty: dubels.toDouble(),
      category: 'Крепёж',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Биты для шуруповёрта',
    quantity: bits.toDouble(),
    unit: 'шт',
    withReserve: bits.toDouble(),
    purchaseQty: bits.toDouble(),
    category: 'Инструмент',
  ));

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'materialType': materialType.toDouble(),
      'sheetCount': sheetCount.toDouble(),
      'fastenerStep': fastenerStep.toDouble(),
      'withFrameScrews': withFrameScrews.toDouble(),
      'withDubels': withDubels.toDouble(),
      'stepCoeff': roundValue(stepCoeff, 3),
      'screwsPerUnit': screwsPerUnit.toDouble(),
      'totalScrews': totalScrews.toDouble(),
      'klaimers': klaimers.toDouble(),
      'frameScrews': frameScrews.toDouble(),
      'dubels': dubels.toDouble(),
      'bits': bits.toDouble(),
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
