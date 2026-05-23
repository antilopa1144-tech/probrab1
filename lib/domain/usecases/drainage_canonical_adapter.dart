import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalDrainage(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(drainageSpecData);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 40))
      .clamp(5.0, 500.0)
      .toDouble();
  final pipeDiameter =
      (inputs['pipeDiameter'] ?? defaultFor(spec, 'pipeDiameter', 110))
          .round()
          .clamp(110, 160)
          .toInt();
  final drainageType =
      (inputs['drainageType'] ?? defaultFor(spec, 'drainageType', 1))
          .round()
          .clamp(0, 2)
          .toInt();
  final groundwaterRisk =
      (inputs['groundwaterRisk'] ?? defaultFor(spec, 'groundwaterRisk', 1))
          .round()
          .clamp(0, 2)
          .toInt();
  final withCollector =
      (inputs['withCollector'] ?? defaultFor(spec, 'withCollector', 1))
          .round()
          .clamp(0, 1)
          .toInt();

  final branchFactor = switch (drainageType) {
    0 => 1.0,
    1 => 1.5,
    _ => 2.0,
  };
  final groundwaterFactor =
      groundwaterRisk == 2
          ? spec.materialRule<num>('extra_geotextile_high_groundwater').toDouble()
          : 1.0;
  final totalTrenchLength = length * branchFactor;
  final pipeWithReserveM =
      totalTrenchLength * spec.materialRule<num>('pipe_reserve').toDouble();
  final sandM3 =
      totalTrenchLength *
      spec.materialRule<num>('trench_width_m').toDouble() *
      spec.materialRule<num>('sand_bedding_thickness_m').toDouble() *
      spec.materialRule<num>('compaction_factor_sand').toDouble();
  final gravelM3 =
      totalTrenchLength *
      spec.materialRule<num>('trench_width_m').toDouble() *
      (spec.materialRule<num>('gravel_top_thickness_m').toDouble() +
          spec.materialRule<num>('gravel_side_thickness_m').toDouble()) *
      spec.materialRule<num>('compaction_factor_gravel').toDouble() *
      groundwaterFactor;
  final geotextileM2 =
      totalTrenchLength *
      spec.materialRule<num>('geotextile_perimeter_factor').toDouble() *
      spec.materialRule<num>('geotextile_reserve').toDouble() *
      groundwaterFactor;
  final geotextileRolls =
      (geotextileM2 / spec.materialRule<num>('geotextile_roll_m2').toDouble())
          .ceil();
  final wellCount = math.max(
    spec.warningRule<num>('min_well_count').round(),
    (totalTrenchLength / spec.materialRule<num>('well_step_m').toDouble()).ceil(),
  );
  final collectorCount = withCollector == 1 ? 1 : 0;
  final elbowCount = switch (drainageType) {
    0 => spec.materialRule<num>('elbow_count_type0').round(),
    1 => spec.materialRule<num>('elbow_count_type1').round(),
    _ => spec.materialRule<num>('elbow_count_type2').round(),
  };
  final teeCount =
      drainageType == 1
          ? spec.materialRule<num>('tee_count_per_branch_type1').round()
          : 0;
  final pipeCoils =
      (pipeWithReserveM /
              spec.materialRule<num>('pipe_coil_length_m').toDouble())
          .ceil();

  final scenarios = _buildScenarios(
    spec,
    inputs,
    primaryQuantity: pipeWithReserveM,
    packageLabel: 'drainage-pipe-${pipeDiameter}mm',
    unit: 'м',
    extraAssumptions: [
      'pipeDiameter:$pipeDiameter',
      'drainageType:$drainageType',
      'groundwaterRisk:$groundwaterRisk',
    ],
  );

  final warnings = <String>[];
  if (withCollector == 1 &&
      length < spec.warningRule<num>('min_length_for_collector').toDouble()) {
    warnings.add('При длине менее 20 м приёмный колодец обычно не требуется');
  }
  if (pipeDiameter == 110 &&
      totalTrenchLength > spec.warningRule<num>('max_length_d110_m').toDouble()) {
    warnings.add('Для длинной трассы Ø110 мм нужен промежуточный сброс или Ø160 мм');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: 'Дренажная труба гофрированная Ø$pipeDiameter мм с фильтром',
        quantity: roundValue(pipeWithReserveM, 3),
        unit: 'м',
        withReserve: roundValue(pipeWithReserveM, 3),
        purchaseQty: pipeWithReserveM.ceilToDouble(),
        category: 'Трубы',
      ),
      CanonicalMaterialResult(
        name: 'Песок строительный (подсыпка под трубу)',
        quantity: roundValue(sandM3, 3),
        unit: 'м³',
        withReserve: roundValue(sandM3, 3),
        purchaseQty: roundValue(sandM3, 3),
        category: 'Основание',
      ),
      CanonicalMaterialResult(
        name: 'Щебень фр. 5-20 мм (обсыпка трубы)',
        quantity: roundValue(gravelM3, 3),
        unit: 'м³',
        withReserve: roundValue(gravelM3, 3),
        purchaseQty: roundValue(gravelM3, 3),
        category: 'Дренаж',
      ),
      CanonicalMaterialResult(
        name: 'Геотекстиль Дорнит 200 г/м² (50 м² рулон)',
        quantity: roundValue(geotextileM2, 3),
        unit: 'м²',
        withReserve: roundValue(geotextileM2, 3),
        purchaseQty: geotextileRolls.toDouble(),
        category: 'Геотекстиль',
      ),
      CanonicalMaterialResult(
        name: 'Колодцы смотровые Ø${spec.materialRule<num>('well_diameter_mm').round()} мм',
        quantity: wellCount.toDouble(),
        unit: 'шт',
        withReserve: wellCount.toDouble(),
        purchaseQty: wellCount.toDouble(),
        category: 'Колодцы',
      ),
      if (withCollector == 1)
        CanonicalMaterialResult(
          name:
              'Приёмный колодец-накопитель Ø${spec.materialRule<num>('collector_well_diameter_mm').round()} мм',
          quantity: collectorCount.toDouble(),
          unit: 'шт',
          withReserve: collectorCount.toDouble(),
          purchaseQty: collectorCount.toDouble(),
          category: 'Колодцы',
        ),
      CanonicalMaterialResult(
        name: 'Отводы дренажные 90°/45° Ø$pipeDiameter',
        quantity: elbowCount.toDouble(),
        unit: 'шт',
        withReserve: elbowCount.toDouble(),
        purchaseQty: elbowCount.toDouble(),
        category: 'Фасонные',
      ),
      if (teeCount > 0)
        CanonicalMaterialResult(
          name: 'Тройники дренажные Ø$pipeDiameter',
          quantity: teeCount.toDouble(),
          unit: 'шт',
          withReserve: teeCount.toDouble(),
          purchaseQty: teeCount.toDouble(),
          category: 'Фасонные',
        ),
    ],
    totals: {
      'length': roundValue(length, 3),
      'pipeDiameter': pipeDiameter.toDouble(),
      'drainageType': drainageType.toDouble(),
      'groundwaterRisk': groundwaterRisk.toDouble(),
      'withCollector': withCollector.toDouble(),
      'totalTrenchLength': roundValue(totalTrenchLength, 3),
      'pipeWithReserveM': roundValue(pipeWithReserveM, 3),
      'sandM3': roundValue(sandM3, 3),
      'gravelM3': roundValue(gravelM3, 3),
      'geotextileM2': roundValue(geotextileM2, 3),
      'geotextileRolls': geotextileRolls.toDouble(),
      'wellCount': wellCount.toDouble(),
      'collectorCount': collectorCount.toDouble(),
      'elbowCount': elbowCount.toDouble(),
      'teeCount': teeCount.toDouble(),
      'pipeCoils': pipeCoils.toDouble(),
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
