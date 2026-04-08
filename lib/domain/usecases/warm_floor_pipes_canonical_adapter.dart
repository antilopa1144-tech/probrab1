import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


const Map<int, String> _pipeTypeLabels = {
  0: 'PEX-a',
  1: 'PEX-b',
  2: 'PE-RT',
  3: 'Металлопластик',
};

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(1.0, 30.0);
    final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(1.0, 30.0);
    return {
      'inputMode': 0.0,
      'area': roundValue(length * width, 3),
      'perimeter': roundValue(2 * (length + width), 3),
      'length': length,
      'width': width,
    };
  }
  final area = (inputs['area'] ?? defaultFor(spec, 'area', 20)).clamp(1.0, 300.0);
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'perimeter': roundValue(math.sqrt(area) * 4, 3),
    'length': 0.0,
    'width': 0.0,
  };
}

CanonicalCalculatorContractResult calculateCanonicalWarmFloorPipes(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(warmFloorPipesSpecData);

  final areaInfo = _resolveArea(spec, inputs);
  final area = areaInfo['area']!;
  final perimeter = areaInfo['perimeter']!;

  final pipeStep = (inputs['pipeStep'] ?? defaultFor(spec, 'pipeStep', 200)).clamp(100.0, 300.0);
  final pipeType = (inputs['pipeType'] ?? defaultFor(spec, 'pipeType', 0)).round().clamp(0, 3);

  /* ─── core formulas ─── */
  final usefulArea = roundValue(area * spec.materialRule<num>('furniture_reduction').toDouble(), 3);
  final pipeStepM = pipeStep / 1000;
  final pipeLength = roundValue(usefulArea / pipeStepM + spec.materialRule<num>('collector_addition_m').toDouble(), 3);
  final circuits = math.max(1, (pipeLength / spec.materialRule<num>('max_circuit_m').toDouble()).ceil());
  final totalPipe = roundValue(pipeLength * spec.materialRule<num>('pipe_reserve').toDouble(), 3);
  final coils = (totalPipe / spec.materialRule<num>('pipe_coil_m').toDouble()).ceil();

  /* ─── ancillary materials ─── */
  final eppsSheets = (area * spec.materialRule<num>('epps_reserve').toDouble() / spec.materialRule<num>('epps_sheet_m2').toDouble()).ceil();
  final damperTapeRolls = (perimeter * spec.materialRule<num>('damper_reserve').toDouble() / spec.materialRule<num>('damper_tape_roll_m').toDouble()).ceil();
  final anchorTotal = (totalPipe / spec.materialRule<num>('anchor_step_m').toDouble() * spec.materialRule<num>('anchor_reserve').toDouble()).ceil();
  final anchorPacks = (anchorTotal / spec.materialRule<num>('anchor_pack').toDouble()).ceil();
  final screedBags = (area * spec.materialRule<num>('screed_thickness_m').toDouble() * spec.materialRule<num>('screed_density').toDouble() / spec.materialRule<num>('screed_bag_kg').toDouble()).ceil();

  /* ─── scenarios ─── */
  final basePrimary = totalPipe;
  final scenarios = <String, CanonicalScenarioResult>{};

final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
    final packageSize = spec.materialRule<num>('pipe_coil_m').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    final packageLabel = 'pipe-coil-${packageSize.toInt()}m';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'pipeType:$pipeType',
        'pipeStep:${pipeStep.toInt()}',
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

  /* ─── materials list ─── */
  final pipeTypeLabel = _pipeTypeLabels[pipeType] ?? 'PEX-a';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Труба $pipeTypeLabel (бухты ${spec.materialRule<num>('pipe_coil_m').toInt()} м)',
      quantity: roundValue(totalPipe, 3),
      unit: 'м',
      withReserve: (coils * spec.materialRule<num>('pipe_coil_m').toDouble()),
      purchaseQty: (coils * spec.materialRule<num>('pipe_coil_m').toDouble()).toDouble(),
      category: 'Основное',
      packageInfo: {'count': coils, 'unitSize': spec.materialRule<num>('pipe_coil_m').toDouble(), 'packageUnit': 'бухт'},
    ),
    CanonicalMaterialResult(
      name: 'Утеплитель ЭППС (листы 1200×600)',
      quantity: eppsSheets.toDouble(),
      unit: 'листов',
      withReserve: eppsSheets.toDouble(),
      purchaseQty: eppsSheets.toDouble(),
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Демпферная лента (рулоны)',
      quantity: damperTapeRolls.toDouble(),
      unit: 'рулонов',
      withReserve: damperTapeRolls.toDouble(),
      purchaseQty: damperTapeRolls.toDouble(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Якорные клипсы (упаковки по 100 шт)',
      quantity: anchorTotal.toDouble(),
      unit: 'шт',
      withReserve: (anchorPacks * spec.materialRule<num>('anchor_pack').toDouble()),
      purchaseQty: (anchorPacks * spec.materialRule<num>('anchor_pack').toDouble()).toDouble(),
      category: 'Крепёж',
      packageInfo: {'count': anchorPacks, 'unitSize': spec.materialRule<num>('anchor_pack').toDouble(), 'packageUnit': 'упаковок'},
    ),
    CanonicalMaterialResult(
      name: 'Коллектор ($circuits контуров)',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Управление',
    ),
    CanonicalMaterialResult(
      name: 'Стяжка полусухая (мешки 25 кг)',
      quantity: roundValue(area * spec.materialRule<num>('screed_thickness_m').toDouble() * spec.materialRule<num>('screed_density').toDouble(), 3),
      unit: 'кг',
      withReserve: (screedBags * spec.materialRule<num>('screed_bag_kg').toDouble()),
      purchaseQty: (screedBags * spec.materialRule<num>('screed_bag_kg').toDouble()).toDouble(),
      category: 'Основное',
      packageInfo: {'count': screedBags, 'unitSize': spec.materialRule<num>('screed_bag_kg').toDouble(), 'packageUnit': 'мешков'},
    ),
  ];

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (pipeLength > spec.warningRule<num>('multiple_circuits_pipe_threshold_m').toDouble()) {
    warnings.add('Длина трубы более 80 м — рекомендуется несколько контуров');
  }
  if (area > spec.warningRule<num>('professional_heat_loss_area_threshold_m2').toDouble()) {
    warnings.add('Площадь более 40 м² — рекомендуется профессиональный расчёт теплопотерь');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'inputMode': areaInfo['inputMode']!,
      'area': area,
      'perimeter': perimeter,
      'length': areaInfo['length']!,
      'width': areaInfo['width']!,
      'pipeStep': pipeStep,
      'pipeType': pipeType.toDouble(),
      'usefulArea': usefulArea,
      'pipeStepM': roundValue(pipeStepM, 4),
      'pipeLength': roundValue(pipeLength, 3),
      'circuits': circuits.toDouble(),
      'totalPipe': totalPipe,
      'coils': coils.toDouble(),
      'eppsSheets': eppsSheets.toDouble(),
      'damperTapeRolls': damperTapeRolls.toDouble(),
      'anchorTotal': anchorTotal.toDouble(),
      'anchorPacks': anchorPacks.toDouble(),
      'screedBags': screedBags.toDouble(),
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
