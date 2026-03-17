import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
// ─── Stairs spec classes ───

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const List<String> _materialLabels = ['wood', 'concrete', 'metal'];

// ─── Helpers ───

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalStairs(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(stairsSpecData);

  final floorHeight = (inputs['floorHeight'] ?? defaultFor(spec, 'floorHeight', 2.8)).clamp(2.0, 6.0).toDouble();
  final stepHeight = (inputs['stepHeight'] ?? defaultFor(spec, 'stepHeight', 170)).clamp(150, 200).toDouble();
  final stepWidth = (inputs['stepWidth'] ?? defaultFor(spec, 'stepWidth', 280)).clamp(250, 320).toDouble();
  final stairWidth = (inputs['stairWidth'] ?? defaultFor(spec, 'stairWidth', 1.0)).clamp(0.6, 2.0).toDouble();
  final materialType = (inputs['materialType'] ?? defaultFor(spec, 'materialType', 0)).round().clamp(0, 2);

  final stepCount = (floorHeight / (stepHeight / 1000)).round();
  final realStepH = roundValue(floorHeight / stepCount, 6);
  final horizLen = roundValue((stepCount - 1) * (stepWidth / 1000), 6);
  final stringerLen = roundValue(math.sqrt(floorHeight * floorHeight + horizLen * horizLen), 6);
  final railingLen = roundValue(horizLen * 2, 6);
  final balyasiny = (railingLen / spec.materialRule<num>('railing_spacing').toDouble()).ceil();

  final materialKey = materialType < _materialLabels.length ? _materialLabels[materialType] : 'wood';

  // Build materials based on material type
  final materials = <CanonicalMaterialResult>[];

  if (materialType == 0) {
    // Wood
    final stringerBoard = (stringerLen * 1.1).ceil() * spec.materialRule<num>('stringers_count').toDouble();
    final screwsPcs = stepCount * 8;
    final screwsKg = (screwsPcs / 600 * 10).ceil() / 10; // 3.5×35 мм: 600 шт/кг
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Тетива/косоур (${spec.materialRule<num>('stringer_board').toDouble()})',
        quantity: stringerBoard.toDouble(),
        unit: 'п.м',
        withReserve: stringerBoard.toDouble(),
        purchaseQty: stringerBoard.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Ступени (${spec.materialRule<num>('tread_board').toDouble()})',
        quantity: stepCount.toDouble(),
        unit: 'шт',
        withReserve: stepCount.toDouble(),
        purchaseQty: stepCount.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Подступенки (${spec.materialRule<num>('riser_board').toDouble()})',
        quantity: stepCount.toDouble(),
        unit: 'шт',
        withReserve: stepCount.toDouble(),
        purchaseQty: stepCount.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы',
        quantity: screwsKg,
        unit: 'кг',
        withReserve: screwsKg,
        purchaseQty: screwsKg.ceil().toDouble(),
        category: 'Крепёж',
      ),
    ]);
  } else if (materialType == 1) {
    // Concrete
    final vol = roundValue(stairWidth * (stepWidth / 1000) * (stepHeight / 1000) / 2 * stepCount, 6);
    final rebarKg = roundValue(stepCount * stairWidth * spec.materialRule<num>('rebar_kg_per_step_width').toDouble(), 3);
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Бетон М300',
        quantity: roundValue(vol, 3),
        unit: 'м³',
        withReserve: roundValue(vol, 3),
        purchaseQty: vol.ceil().toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Арматура',
        quantity: rebarKg,
        unit: 'кг',
        withReserve: rebarKg.ceil().toDouble(),
        purchaseQty: rebarKg.ceil().toDouble(),
        category: 'Армирование',
      ),
    ]);
  } else {
    // Metal
    final channelLen = roundValue(stringerLen * 2 * 1.1, 3);
    final bolts = stepCount * 4;
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Швеллер (каркас)',
        quantity: channelLen,
        unit: 'п.м',
        withReserve: channelLen.ceil().toDouble(),
        purchaseQty: channelLen.ceil().toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Болты крепёжные',
        quantity: bolts.toDouble(),
        unit: 'шт',
        withReserve: bolts.toDouble(),
        purchaseQty: bolts.toDouble(),
        category: 'Крепёж',
      ),
    ]);
  }

  // Railing materials (common for all types)
  materials.addAll([
    CanonicalMaterialResult(
      name: 'Перила (поручень)',
      quantity: roundValue(railingLen, 3),
      unit: 'п.м',
      withReserve: railingLen.ceil().toDouble(),
      purchaseQty: railingLen.ceil().toDouble(),
      category: 'Ограждение',
    ),
    CanonicalMaterialResult(
      name: 'Балясины',
      quantity: balyasiny.toDouble(),
      unit: 'шт',
      withReserve: balyasiny.toDouble(),
      purchaseQty: balyasiny.toDouble(),
      category: 'Ограждение',
    ),
  ]);

  // Scenarios
  final baseExactNeed = stepCount;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeed * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'stairs-step-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'material:$materialKey',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
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

  // Warnings
  final warnings = <String>[];
  if (stepHeight > spec.warningRule<num>('steep_step_threshold_mm').toDouble()) {
    warnings.add('Высота ступени выше нормы — лестница может быть некомфортной');
  }
  if (stepCount > spec.warningRule<num>('max_steps_per_flight').toDouble()) {
    warnings.add('Большое количество ступеней — рекомендуется устройство промежуточной площадки');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'floorHeight': roundValue(floorHeight, 3),
      'stepHeight': roundValue(stepHeight, 3),
      'stepWidth': roundValue(stepWidth, 3),
      'stairWidth': roundValue(stairWidth, 3),
      'materialType': materialType.toDouble(),
      'stepCount': stepCount.toDouble(),
      'realStepH': roundValue(realStepH, 6),
      'horizLen': roundValue(horizLen, 3),
      'stringerLen': roundValue(stringerLen, 3),
      'railingLen': roundValue(railingLen, 3),
      'balyasiny': balyasiny.toDouble(),
      'minExactNeedSteps': scenarios['MIN']!.exactNeed,
      'recExactNeedSteps': recScenario.exactNeed,
      'maxExactNeedSteps': scenarios['MAX']!.exactNeed,
      'minPurchaseSteps': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseSteps': recScenario.purchaseQuantity,
      'maxPurchaseSteps': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
