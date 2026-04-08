import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */



const Map<int, String> _brickTypeLabels = {
  0: 'Кирпич облицовочный одинарный (65 мм)',
  1: 'Кирпич облицовочный полуторный (88 мм)',
  2: 'Кирпич облицовочный двойной (138 мм)',
  3: 'Клинкерный кирпич (65 мм)',
};

const Map<int, String> _tieTypeLabels = {
  1: 'Связи стеклопластиковые',
  2: 'Связи нержавеющие',
};


bool hasCanonicalFacadeBrickInputs(Map<String, double> inputs) {
  return inputs.containsKey('brickType') ||
      inputs.containsKey('jointThickness') ||
      inputs.containsKey('withTie');
}

Map<String, double> normalizeLegacyFacadeBrickInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 80).toDouble();
  normalized['brickType'] = (inputs['brickType'] ?? 0).toDouble();
  normalized['jointThickness'] = (inputs['jointThickness'] ?? 10).toDouble();
  normalized['withTie'] = (inputs['withTie'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalFacadeBrick(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(facadeBrickSpecData);

  final normalized = hasCanonicalFacadeBrickInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFacadeBrickInputs(inputs);

  final area = math.max(5.0, math.min(1000.0, (normalized['area'] ?? defaultFor(spec, 'area', 80)).toDouble()));
  final brickType = (normalized['brickType'] ?? defaultFor(spec, 'brickType', 0)).round().clamp(0, 3);
  final jointThickness = math.max(8.0, math.min(12.0, (normalized['jointThickness'] ?? defaultFor(spec, 'jointThickness', 10)).toDouble()));
  final withTie = (normalized['withTie'] ?? defaultFor(spec, 'withTie', 0)).round().clamp(0, 2);

  // Bricks
  final dimMap = spec.materialRule<Map>('brick_dims')['$brickType'] as Map? ?? spec.materialRule<Map>('brick_dims')['0'] as Map? ?? {'l': 250, 'h': 65};
  final jointMm = jointThickness;
  final l = (((dimMap['l'] as num?)?.toDouble() ?? 250) + jointMm) / 1000;
  final h = (((dimMap['h'] as num?)?.toDouble() ?? 65) + jointMm) / 1000;
  final bricksPerM2 = roundValue(1 / (l * h), 3);
  final totalBricks = roundValue(area * bricksPerM2, 3);
  final bricksWithReserve = (totalBricks * spec.materialRule<num>('brick_reserve').toDouble()).ceil();

  // Mortar / cement / sand
  final masonryVolume = roundValue(area * spec.materialRule<num>('masonry_thickness').toDouble(), 6);
  final mortarVolume = roundValue(masonryVolume * spec.materialRule<num>('mortar_volume_coeff').toDouble(), 6);
  final cementBags = (mortarVolume * spec.materialRule<num>('cement_kg_per_m3_mortar').toDouble() / spec.materialRule<num>('cement_bag_kg').toDouble()).ceil();
  final sandM3 = roundValue((mortarVolume * spec.materialRule<num>('sand_coeff').toDouble() * 10).ceil() / 10, 1);

  // Ties
  final tiesCount = withTie > 0
      ? (area * spec.materialRule<num>('ties_per_sqm').toDouble() * spec.materialRule<num>('ties_reserve').toDouble()).ceil()
      : 0;

  // Hydro isolation
  final perimeterEst = roundValue(math.sqrt(area) * 4, 3);
  final hydroArea = roundValue(perimeterEst * spec.materialRule<num>('hydro_coeff').toDouble() * spec.materialRule<num>('hydro_reserve').toDouble(), 3);
  final hydroRolls = (hydroArea / spec.materialRule<num>('hydro_roll_m2').toDouble()).ceil();

  // Vent boxes
  final ventBoxes = (perimeterEst / spec.materialRule<num>('vent_box_step_m').toDouble()).ceil();

  // Grout
  final groutBags = (area * spec.materialRule<num>('grout_kg_per_m2').toDouble() / spec.materialRule<num>('grout_bag_kg').toDouble()).ceil();

  // Hydrophobizer
  final hydrophobCans = (area * spec.materialRule<num>('hydrophob_l_per_m2').toDouble() * spec.materialRule<num>('hydrophob_reserve').toDouble() / spec.materialRule<num>('hydrophob_can_l').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('concrete', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(bricksWithReserve * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'brickType:$brickType',
        'jointThickness:${jointThickness.round()}',
        'withTie:$withTie',
        'packaging:facade-brick-piece',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'facade-brick-piece',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (brickType == 3 && jointThickness > spec.warningRule<num>('clinker_max_joint_mm').toDouble()) {
    warnings.add('Клинкерный кирпич обычно кладётся с швом 8–10 мм');
  }
  if (withTie == 0) {
    warnings.add('Облицовочная кладка должна иметь конструктивное крепление к основной стене (гибкие связи)');
  }
  warnings.add('Необходим вентиляционный зазор 20–40 мм между облицовкой и несущей стеной (СП 15.13330)');

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: _brickTypeLabels[brickType] ?? 'Кирпич облицовочный',
      quantity: totalBricks,
      unit: 'шт',
      withReserve: bricksWithReserve.toDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Цемент М400 (${spec.materialRule<num>('cement_bag_kg').toDouble().round()} кг)',
      quantity: cementBags.toDouble(),
      unit: 'мешков',
      withReserve: cementBags.toDouble(),
      purchaseQty: cementBags.toDouble(),
      category: 'Раствор',
    ),
    CanonicalMaterialResult(
      name: 'Песок строительный',
      quantity: sandM3,
      unit: 'м³',
      withReserve: sandM3,
      purchaseQty: sandM3.ceil().toDouble(),
      category: 'Раствор',
    ),
  ];

  if (withTie > 0) {
    materials.add(CanonicalMaterialResult(
      name: _tieTypeLabels[withTie] ?? 'Связи гибкие',
      quantity: tiesCount.toDouble(),
      unit: 'шт',
      withReserve: tiesCount.toDouble(),
      purchaseQty: tiesCount.toDouble(),
      category: 'Крепёж',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Гидроизоляция рулонная',
      quantity: hydroArea,
      unit: 'м²',
      withReserve: (hydroRolls * spec.materialRule<num>('hydro_roll_m2').toDouble()),
      purchaseQty: (hydroRolls * spec.materialRule<num>('hydro_roll_m2').toDouble()).toDouble(),
      category: 'Изоляция',
      packageInfo: {'count': hydroRolls, 'unitSize': spec.materialRule<num>('hydro_roll_m2').toDouble(), 'packageUnit': 'рулонов'},
    ),
    CanonicalMaterialResult(
      name: 'Вентиляционные коробки',
      quantity: ventBoxes.toDouble(),
      unit: 'шт',
      withReserve: ventBoxes.toDouble(),
      purchaseQty: ventBoxes.toDouble(),
      category: 'Вентиляция',
    ),
    CanonicalMaterialResult(
      name: 'Затирка для швов (${spec.materialRule<num>('grout_bag_kg').toDouble().round()} кг)',
      quantity: groutBags.toDouble(),
      unit: 'мешков',
      withReserve: groutBags.toDouble(),
      purchaseQty: groutBags.toDouble(),
      category: 'Финишная',
    ),
    CanonicalMaterialResult(
      name: 'Гидрофобизатор (${spec.materialRule<num>('hydrophob_can_l').toDouble().round()} л)',
      quantity: hydrophobCans.toDouble(),
      unit: 'канистр',
      withReserve: hydrophobCans.toDouble(),
      purchaseQty: hydrophobCans.toDouble(),
      category: 'Защита',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'brickType': brickType.toDouble(),
      'jointThickness': jointThickness,
      'withTie': withTie.toDouble(),
      'brickLengthM': roundValue(l, 4),
      'brickHeightM': roundValue(h, 4),
      'bricksPerM2': bricksPerM2,
      'totalBricks': totalBricks,
      'bricksWithReserve': bricksWithReserve.toDouble(),
      'masonryVolume': masonryVolume,
      'mortarVolume': mortarVolume,
      'cementBags': cementBags.toDouble(),
      'sandM3': sandM3,
      'tiesCount': tiesCount.toDouble(),
      'perimeterEst': perimeterEst,
      'hydroArea': hydroArea,
      'hydroRolls': hydroRolls.toDouble(),
      'ventBoxes': ventBoxes.toDouble(),
      'groutBags': groutBags.toDouble(),
      'hydrophobCans': hydrophobCans.toDouble(),
      'minExactNeedBricks': scenarios['MIN']!.exactNeed,
      'recExactNeedBricks': recScenario.exactNeed,
      'maxExactNeedBricks': scenarios['MAX']!.exactNeed,
      'minPurchaseBricks': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseBricks': recScenario.purchaseQuantity,
      'maxPurchaseBricks': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
