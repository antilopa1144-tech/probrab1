import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalLawn(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(lawnSpecData);
  final area = (inputs['area'] ?? defaultFor(spec, 'area', 50))
      .clamp(5.0, 2000.0)
      .toDouble();
  final lawnType = (inputs['lawnType'] ?? defaultFor(spec, 'lawnType', 0))
      .round()
      .clamp(0, 1)
      .toInt();
  final soilThickness =
      (inputs['soilThickness'] ?? defaultFor(spec, 'soilThickness', 12))
          .clamp(8.0, 25.0)
          .toDouble();
  final groundType = (inputs['groundType'] ?? defaultFor(spec, 'groundType', 1))
      .round()
      .clamp(0, 2)
      .toInt();
  final usageIntensity =
      (inputs['usageIntensity'] ?? defaultFor(spec, 'usageIntensity', 1))
          .round()
          .clamp(0, 2)
          .toInt();
  final withDrainage =
      (inputs['withDrainage'] ?? defaultFor(spec, 'withDrainage', 0))
          .round()
          .clamp(0, 1)
          .toInt();
  final withGeotextile =
      (inputs['withGeotextile'] ?? defaultFor(spec, 'withGeotextile', 0))
          .round()
          .clamp(0, 1)
          .toInt();

  final seedRatePerM2 = switch (usageIntensity) {
    0 => spec.materialRule<num>('seed_rate_g_per_m2_decor').toDouble(),
    1 => spec.materialRule<num>('seed_rate_g_per_m2_normal').toDouble(),
    _ => spec.materialRule<num>('seed_rate_g_per_m2_sport').toDouble(),
  };
  final seedKg =
      lawnType == 0
          ? area *
              seedRatePerM2 /
              1000 *
              spec.materialRule<num>('seed_reserve').toDouble()
          : 0.0;
  final seedPacks =
      seedKg > 0
          ? (seedKg / spec.materialRule<num>('seed_pack_kg').toDouble()).ceil()
          : 0;
  final rollsCount =
      lawnType == 1
          ? (area *
                  spec.materialRule<num>('roll_reserve').toDouble() /
                  spec.materialRule<num>('roll_size_m2').toDouble())
              .ceil()
          : 0;
  final topsoilM3 =
      area *
      soilThickness /
      100 *
      spec.materialRule<num>('topsoil_compaction_factor').toDouble();
  final drainageSandM3 =
      withDrainage == 1
          ? area *
              spec.materialRule<num>('drainage_sand_layer_m').toDouble() *
              spec.materialRule<num>('drainage_sand_compaction').toDouble()
          : 0.0;
  final geotextileRolls =
      withGeotextile == 1
          ? (area *
                  spec.materialRule<num>('geotextile_reserve').toDouble() /
                  spec.materialRule<num>('geotextile_roll_m2').toDouble())
              .ceil()
          : 0;
  final fertilizerKg =
      area *
      spec.materialRule<num>('fertilizer_starter_g_per_m2').toDouble() /
      1000 *
      spec.materialRule<num>('fertilizer_reserve').toDouble();
  final fertilizerPacks =
      (fertilizerKg / spec.materialRule<num>('fertilizer_pack_kg').toDouble())
          .ceil();
  final stimulatorMl =
      lawnType == 1
          ? area * spec.materialRule<num>('rooting_stimulator_ml_per_m2').toDouble()
          : 0.0;
  final stimulatorCans =
      stimulatorMl > 0
          ? (stimulatorMl /
                  (spec.materialRule<num>('rooting_stimulator_can_l').toDouble() *
                      1000))
              .ceil()
          : 0;

  final scenarios = _buildScenarios(
    spec,
    inputs,
    primaryQuantity: lawnType == 1 ? rollsCount.toDouble() : area,
    packageLabel: lawnType == 1 ? 'lawn-roll' : 'lawn-area',
    unit: lawnType == 1 ? 'рулон' : 'м²',
    extraAssumptions: [
      'lawnType:$lawnType',
      'groundType:$groundType',
      'usageIntensity:$usageIntensity',
    ],
  );

  final warnings = <String>[];
  if (soilThickness <
      spec.warningRule<num>('min_topsoil_thickness_cm').toDouble()) {
    warnings.add('Плодородный слой меньше 10 см — газон будет слабым');
  }
  if (usageIntensity == 2 &&
      soilThickness <
          spec.warningRule<num>('thin_topsoil_for_sport_cm').toDouble()) {
    warnings.add('Для спортивного газона нужен слой грунта не менее 15 см');
  }
  if (groundType == spec.warningRule<num>('clay_ground_needs_drainage').round() &&
      withDrainage == 0) {
    warnings.add('На глинистом грунте рекомендуется дренажный песчаный слой');
  }

  final materials = <CanonicalMaterialResult>[
    if (lawnType == 0)
      CanonicalMaterialResult(
        name: 'Семена газона (${seedRatePerM2.round()} г/м², пачка 1 кг)',
        quantity: roundValue(seedKg, 3),
        unit: 'кг',
        withReserve: roundValue(seedKg, 3),
        purchaseQty: seedPacks.toDouble(),
        category: 'Газон',
      )
    else
      CanonicalMaterialResult(
        name: 'Рулонный газон (0.8 м²)',
        quantity: rollsCount.toDouble(),
        unit: 'рулон',
        withReserve: rollsCount.toDouble(),
        purchaseQty: rollsCount.toDouble(),
        category: 'Газон',
      ),
    CanonicalMaterialResult(
      name: 'Плодородный грунт (растительная земля)',
      quantity: roundValue(topsoilM3, 3),
      unit: 'м³',
      withReserve: roundValue(topsoilM3, 3),
      purchaseQty: roundValue(topsoilM3, 3),
      category: 'Грунт',
    ),
    if (withDrainage == 1)
      CanonicalMaterialResult(
        name: 'Песок для дренажного слоя',
        quantity: roundValue(drainageSandM3, 3),
        unit: 'м³',
        withReserve: roundValue(drainageSandM3, 3),
        purchaseQty: roundValue(drainageSandM3, 3),
        category: 'Дренаж',
      ),
    if (withGeotextile == 1)
      CanonicalMaterialResult(
        name: 'Геотекстиль Дорнит 150 г/м² (50 м²)',
        quantity: geotextileRolls.toDouble(),
        unit: 'рулон',
        withReserve: geotextileRolls.toDouble(),
        purchaseQty: geotextileRolls.toDouble(),
        category: 'Дренаж',
      ),
    CanonicalMaterialResult(
      name: 'Удобрение стартовое NPK (5 кг)',
      quantity: roundValue(fertilizerKg, 3),
      unit: 'кг',
      withReserve: roundValue(fertilizerKg, 3),
      purchaseQty: fertilizerPacks.toDouble(),
      category: 'Удобрения',
    ),
    if (lawnType == 1)
      CanonicalMaterialResult(
        name: 'Стимулятор укоренения (5 л)',
        quantity: roundValue(stimulatorMl / 1000, 3),
        unit: 'л',
        withReserve: roundValue(stimulatorMl / 1000, 3),
        purchaseQty: stimulatorCans.toDouble(),
        category: 'Удобрения',
      ),
    CanonicalMaterialResult(
      name: 'Каток для прикатывания газона (50-75 кг)',
      quantity: spec.materialRule<num>('lawn_roller_min_pieces').toDouble(),
      unit: 'шт',
      withReserve: spec.materialRule<num>('lawn_roller_min_pieces').toDouble(),
      purchaseQty: spec.materialRule<num>('lawn_roller_min_pieces').toDouble(),
      category: 'Инструмент',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'lawnType': lawnType.toDouble(),
      'soilThickness': roundValue(soilThickness, 3),
      'groundType': groundType.toDouble(),
      'usageIntensity': usageIntensity.toDouble(),
      'withDrainage': withDrainage.toDouble(),
      'withGeotextile': withGeotextile.toDouble(),
      'seedRatePerM2': seedRatePerM2,
      'seedKg': roundValue(seedKg, 3),
      'seedPacks': seedPacks.toDouble(),
      'rollsCount': rollsCount.toDouble(),
      'topsoilM3': roundValue(topsoilM3, 3),
      'drainageSandM3': roundValue(drainageSandM3, 3),
      'geotextileRolls': geotextileRolls.toDouble(),
      'fertilizerKg': roundValue(fertilizerKg, 3),
      'fertilizerPacks': fertilizerPacks.toDouble(),
      'stimulatorMl': roundValue(stimulatorMl, 3),
      'stimulatorCans': stimulatorCans.toDouble(),
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
