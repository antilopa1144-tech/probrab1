import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
// ─── Strip Foundation spec classes ───

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

// ─── Helpers ───

Map<String, dynamic> _pickPackage(double exactNeed, double stepSize, String unit) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = roundValue(count * stepSize, 6);
  final leftover = roundValue(purchase - exactNeed, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': leftover,
    'label': 'strip-foundation-$stepSize$unit',
  };
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalStripFoundation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(stripFoundationSpecData);

  final perimeter = math.max(10, inputs['perimeter'] ?? defaultFor(spec, 'perimeter', 40)).toDouble().clamp(10, 200).toDouble();
  final width = (inputs['width'] ?? defaultFor(spec, 'width', 400)).clamp(200, 600).toDouble();
  final depth = (inputs['depth'] ?? defaultFor(spec, 'depth', 700)).clamp(300, 2000).toDouble();
  final aboveGround = (inputs['aboveGround'] ?? defaultFor(spec, 'aboveGround', 300)).clamp(0, 600).toDouble();
  final reinforcement = (inputs['reinforcement'] ?? defaultFor(spec, 'reinforcement', 1)).round().clamp(0, 3);
  final deliveryMethod = (inputs['deliveryMethod'] ?? defaultFor(spec, 'deliveryMethod', 0)).round().clamp(0, 2);

  final rebarDiam = (spec.materialRule<Map>('rebar_diameters')['$reinforcement'] as num?)?.toDouble() ?? 12;
  final threads = (spec.materialRule<Map>('rebar_threads')['$reinforcement'] as num?)?.toDouble() ?? 4;
  final weightPerM = (spec.materialRule<Map>('weight_per_m')['$rebarDiam'] as num?)?.toDouble() ?? 0.888;

  final totalH = (depth + aboveGround) / 1000;
  final vol = perimeter * (width / 1000) * totalH;
  final techLoss = (spec.materialRule<Map>('tech_loss')['$deliveryMethod'] as num?)?.toDouble() ?? 0;
  final volReserve = roundValue((vol + techLoss) * spec.materialRule<num>('concrete_reserve').toDouble(), 6);

  final longLen = roundValue(perimeter * threads * spec.materialRule<num>('overlap').toDouble(), 6);
  final longWeightKg = roundValue(longLen * weightPerM, 6);

  final clampCount = (perimeter / spec.materialRule<num>('clamp_step').toDouble()).ceil();
  final clampPerim = 2 * ((width / 1000) - 0.1 + totalH - 0.1) + 0.3;
  final clampLen = roundValue(clampCount * math.max(0.8, clampPerim) * 1.05, 6);
  final clampWeightKg = roundValue(clampLen * spec.materialRule<num>('clamp_weight').toDouble(), 6);

  final wireKg = roundValue((clampCount * threads * 0.05 * 1.1 * 10).ceil() / 10, 6);

  final formwork = roundValue(2 * perimeter * (aboveGround / 1000 + 0.1), 6);
  final boards = (formwork / (0.15 * 6)).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(volReserve * multiplier, 6);
    final package = _pickPackage(exactNeed, spec.packagingRule<num>('volume_step_m3').toDouble(), spec.packagingRule<String>('unit'));

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'reinforcement:$reinforcement',
        'deliveryMethod:$deliveryMethod',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (depth <= spec.warningRule<num>('shallow_depth_threshold_mm').toDouble()) {
    warnings.add('Мелкое заглубление — убедитесь, что глубина ниже уровня промерзания грунта');
  }
  if (perimeter > spec.warningRule<num>('large_perimeter_threshold_m').toDouble()) {
    warnings.add('Большой периметр — рекомендуется разделить на секции с деформационными швами');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон М300',
      quantity: roundValue(volReserve, 3),
      unit: 'м³',
      withReserve: roundValue(volReserve, 3),
      purchaseQty: volReserve.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Арматура продольная ∅$rebarDiam мм',
      quantity: roundValue(longWeightKg, 3),
      unit: 'кг',
      withReserve: longWeightKg.ceil().toDouble(),
      purchaseQty: longWeightKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Арматура поперечная (хомуты)',
      quantity: roundValue(clampWeightKg, 3),
      unit: 'кг',
      withReserve: clampWeightKg.ceil().toDouble(),
      purchaseQty: clampWeightKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Проволока вязальная',
      quantity: roundValue(wireKg, 3),
      unit: 'кг',
      withReserve: roundValue(wireKg, 3),
      purchaseQty: wireKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Опалубка (доска обрезная)',
      quantity: roundValue(formwork, 3),
      unit: 'м²',
      withReserve: formwork.ceil().toDouble(),
      purchaseQty: formwork.ceil(),
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Доска обрезная 150×6000 мм',
      quantity: boards.toDouble(),
      unit: 'шт',
      withReserve: boards.toDouble(),
      purchaseQty: boards.toInt(),
      category: 'Опалубка',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'perimeter': roundValue(perimeter, 3),
      'width': roundValue(width, 3),
      'depth': roundValue(depth, 3),
      'aboveGround': roundValue(aboveGround, 3),
      'reinforcement': reinforcement.toDouble(),
      'deliveryMethod': deliveryMethod.toDouble(),
      'totalH': roundValue(totalH, 3),
      'vol': roundValue(vol, 3),
      'volReserve': roundValue(volReserve, 3),
      'rebarDiam': rebarDiam.toDouble(),
      'threads': threads.toDouble(),
      'longLen': roundValue(longLen, 3),
      'longWeightKg': roundValue(longWeightKg, 3),
      'clampCount': clampCount.toDouble(),
      'clampLen': roundValue(clampLen, 3),
      'clampWeightKg': roundValue(clampWeightKg, 3),
      'wireKg': roundValue(wireKg, 3),
      'formwork': roundValue(formwork, 3),
      'boards': boards.toDouble(),
      'minExactNeedM3': scenarios['MIN']!.exactNeed,
      'recExactNeedM3': recScenario.exactNeed,
      'maxExactNeedM3': scenarios['MAX']!.exactNeed,
      'minPurchaseM3': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseM3': recScenario.purchaseQuantity,
      'maxPurchaseM3': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
