import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalPavingTiles(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(pavingTilesSpecData);
  final area = (inputs['area'] ?? defaultFor(spec, 'area', 50))
      .clamp(5.0, 2000.0)
      .toDouble();
  final perimeter = (inputs['perimeter'] ?? defaultFor(spec, 'perimeter', 30))
      .clamp(4.0, 500.0)
      .toDouble();
  final foundationType =
      (inputs['foundationType'] ?? defaultFor(spec, 'foundationType', 1))
          .round()
          .clamp(0, 2)
          .toInt();
  final tileThickness =
      (inputs['tileThickness'] ?? defaultFor(spec, 'tileThickness', 60))
          .round()
          .clamp(30, 80)
          .toInt();
  final borderEnabled =
      (inputs['borderEnabled'] ?? defaultFor(spec, 'borderEnabled', 1))
          .round()
          .clamp(0, 1)
          .toInt();

  final tileM2 = area * spec.materialRule<num>('tile_reserve').toDouble();
  final sandLayer =
      foundationType == 0
          ? spec.materialRule<num>('sand_bedding_layer_m_auto').toDouble()
          : spec.materialRule<num>('sand_bedding_layer_m').toDouble();
  final sandBeddingM3 =
      area * sandLayer * spec.materialRule<num>('compaction_factor_sand').toDouble();
  final gravelM3 =
      foundationType == 0
          ? 0.0
          : area *
              spec.materialRule<num>('gravel_layer_m').toDouble() *
              spec.materialRule<num>('compaction_factor_gravel').toDouble();
  final cementSandMixM3 =
      foundationType == 1
          ? area *
              spec.materialRule<num>('cement_sand_mix_layer_m').toDouble() *
              spec.materialRule<num>('compaction_factor_cement_sand').toDouble()
          : 0.0;
  final cementBags =
      cementSandMixM3 > 0
          ? (cementSandMixM3 *
                  spec.materialRule<num>('cement_sand_mix_kg_per_m3').toDouble() /
                  5 /
                  spec.materialRule<num>('cement_bag_kg').toDouble())
              .ceil()
          : 0;
  final concreteM3 =
      foundationType == 2
          ? area *
              spec.materialRule<num>('concrete_layer_m').toDouble() *
              spec.materialRule<num>('concrete_reserve').toDouble()
          : 0.0;
  final jointSandBags =
      (area *
              spec.materialRule<num>('joint_sand_kg_per_m2').toDouble() *
              spec.materialRule<num>('joint_sand_reserve').toDouble() /
              spec.materialRule<num>('joint_sand_bag_kg').toDouble())
          .ceil();
  final borderPcs =
      borderEnabled == 1
          ? (perimeter *
                  spec.materialRule<num>('border_reserve').toDouble() /
                  spec.materialRule<num>('border_length_m').toDouble())
              .ceil()
          : 0;
  final borderConcreteM3 =
      borderEnabled == 1
          ? perimeter * spec.materialRule<num>('border_concrete_m_per_m').toDouble()
          : 0.0;
  final geotextileRolls =
      (area *
              spec.materialRule<num>('geotextile_reserve').toDouble() /
              spec.materialRule<num>('geotextile_roll_m2').toDouble())
          .ceil();
  final primaryTileQuantity = tileM2.ceilToDouble();

  final scenarios = _buildScenarios(
    spec,
    inputs,
    primaryQuantity: primaryTileQuantity,
    packageLabel: 'paving-tiles-m2',
    unit: 'м²',
    extraAssumptions: [
      'foundationType:$foundationType',
      'tileThickness:$tileThickness',
      'borderEnabled:$borderEnabled',
    ],
  );

  final warnings = <String>[];
  if (foundationType == 2 &&
      tileThickness < spec.warningRule<num>('min_tile_for_vehicle_mm').round()) {
    warnings.add('Для автомобильной нагрузки нужна плитка не тоньше 60 мм');
  }
  if (perimeter / area <
      spec.warningRule<num>('min_perimeter_to_area_ratio').toDouble()) {
    warnings.add('Проверьте периметр: он слишком мал относительно площади');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: 'Тротуарная плитка $tileThickness мм',
        quantity: roundValue(tileM2, 3),
        unit: 'м²',
        withReserve: roundValue(tileM2, 3),
        purchaseQty: primaryTileQuantity,
        category: 'Покрытие',
      ),
      if (gravelM3 > 0)
        CanonicalMaterialResult(
          name: 'Щебень фр. 20-40 мм (подушка)',
          quantity: roundValue(gravelM3, 3),
          unit: 'м³',
          withReserve: roundValue(gravelM3, 3),
          purchaseQty: roundValue(gravelM3, 3),
          category: 'Основание',
        ),
      CanonicalMaterialResult(
        name: 'Песок строительный (подушка)',
        quantity: roundValue(sandBeddingM3, 3),
        unit: 'м³',
        withReserve: roundValue(sandBeddingM3, 3),
        purchaseQty: roundValue(sandBeddingM3, 3),
        category: 'Основание',
      ),
      if (cementSandMixM3 > 0)
        CanonicalMaterialResult(
          name: 'ЦПС (цементно-песчаная смесь)',
          quantity: roundValue(cementSandMixM3, 3),
          unit: 'м³',
          withReserve: roundValue(cementSandMixM3, 3),
          purchaseQty: roundValue(cementSandMixM3, 3),
          category: 'Основание',
        ),
      if (cementBags > 0)
        CanonicalMaterialResult(
          name: 'Цемент М400 (50 кг)',
          quantity: cementBags.toDouble(),
          unit: 'мешок',
          withReserve: cementBags.toDouble(),
          purchaseQty: cementBags.toDouble(),
          category: 'Основание',
        ),
      if (concreteM3 > 0)
        CanonicalMaterialResult(
          name: 'Бетон М200',
          quantity: roundValue(concreteM3, 3),
          unit: 'м³',
          withReserve: roundValue(concreteM3, 3),
          purchaseQty: roundValue(concreteM3, 3),
          category: 'Основание',
        ),
      CanonicalMaterialResult(
        name: 'Кварцевый песок для швов (25 кг)',
        quantity: jointSandBags.toDouble(),
        unit: 'мешок',
        withReserve: jointSandBags.toDouble(),
        purchaseQty: jointSandBags.toDouble(),
        category: 'Швы',
      ),
      if (borderEnabled == 1)
        CanonicalMaterialResult(
          name: 'Бордюрный камень БР100.30.18 (1.0 м)',
          quantity: borderPcs.toDouble(),
          unit: 'шт',
          withReserve: borderPcs.toDouble(),
          purchaseQty: borderPcs.toDouble(),
          category: 'Бордюр',
        ),
      if (borderEnabled == 1)
        CanonicalMaterialResult(
          name: 'Бетон М200 для бордюра',
          quantity: roundValue(borderConcreteM3, 3),
          unit: 'м³',
          withReserve: roundValue(borderConcreteM3, 3),
          purchaseQty: roundValue(borderConcreteM3, 3),
          category: 'Бордюр',
        ),
      CanonicalMaterialResult(
        name: 'Геотекстиль (50 м²)',
        quantity: geotextileRolls.toDouble(),
        unit: 'рулон',
        withReserve: geotextileRolls.toDouble(),
        purchaseQty: geotextileRolls.toDouble(),
        category: 'Геотекстиль',
      ),
    ],
    totals: {
      'area': roundValue(area, 3),
      'perimeter': roundValue(perimeter, 3),
      'foundationType': foundationType.toDouble(),
      'tileThickness': tileThickness.toDouble(),
      'borderEnabled': borderEnabled.toDouble(),
      'tileM2': roundValue(tileM2, 3),
      'sandBeddingM3': roundValue(sandBeddingM3, 3),
      'gravelM3': roundValue(gravelM3, 3),
      'cementSandMixM3': roundValue(cementSandMixM3, 3),
      'cementBags': cementBags.toDouble(),
      'concreteM3': roundValue(concreteM3, 3),
      'jointSandBags': jointSandBags.toDouble(),
      'borderPcs': borderPcs.toDouble(),
      'borderConcreteM3': roundValue(borderConcreteM3, 3),
      'geotextileRolls': geotextileRolls.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}

Map<String, CanonicalScenarioResult> _buildScenarios(
  SpecReader spec,
  Map<String, double> inputs, {
  required double primaryQuantity,
  required String packageLabel,
  required String unit,
  List<String> extraAssumptions = const [],
}) {
  final scenarios = <String, CanonicalScenarioResult>{};
  final accuracyMult = accuracyPrimaryMultiplier(
    'generic',
    parseAccuracyMode(inputs),
  );
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(primaryQuantity * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'packaging:$packageLabel',
        ...extraAssumptions,
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: unit,
      ),
    );
  }
  return scenarios;
}
