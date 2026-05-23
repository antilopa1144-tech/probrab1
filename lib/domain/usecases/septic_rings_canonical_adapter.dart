import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalSepticRings(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(septicRingsSpecData);
  final residents = (inputs['residents'] ?? defaultFor(spec, 'residents', 4))
      .round()
      .clamp(1, 20)
      .toInt();
  final chambersCount =
      (inputs['chambersCount'] ?? defaultFor(spec, 'chambersCount', 3))
          .round()
          .clamp(1, 3)
          .toInt();
  final ringDiameter =
      (inputs['ringDiameter'] ?? defaultFor(spec, 'ringDiameter', 1000))
          .round()
          .clamp(1000, 2000)
          .toInt();
  final groundType = (inputs['groundType'] ?? defaultFor(spec, 'groundType', 1))
      .round()
      .clamp(0, 2)
      .toInt();
  final withFilterWell =
      (inputs['withFilterWell'] ?? defaultFor(spec, 'withFilterWell', 1))
          .round()
          .clamp(0, 1)
          .toInt();
  final pipeLengthFromHouse =
      (inputs['pipeLengthFromHouse'] ??
              defaultFor(spec, 'pipeLengthFromHouse', 8))
          .clamp(2.0, 50.0)
          .toDouble();

  final dailyVolumeLiters =
      residents * spec.materialRule<num>('liters_per_person_per_day').toDouble();
  final reserveDays =
      residents > spec.materialRule<num>('large_family_threshold').round()
          ? spec.materialRule<num>('reserve_days_large_family').toDouble()
          : spec.materialRule<num>('reserve_days_small_family').toDouble();
  final totalVolumeLiters = dailyVolumeLiters * reserveDays;
  final totalVolume = totalVolumeLiters / 1000;
  final volumePerChamber = totalVolume / chambersCount;
  final ringVolumes =
      spec.materialRule<Map<String, dynamic>>('ring_volumes_m3', const {});
  final ringVolume =
      (ringVolumes['$ringDiameter'] as num?)?.toDouble() ??
      (ringVolumes['1000'] as num?)?.toDouble() ??
      0.71;
  final ringsPerChamber = math.max(1, (volumePerChamber / ringVolume).ceil());
  final totalRings = ringsPerChamber * chambersCount;
  final sealedChambers =
      withFilterWell == 1 ? math.max(1, chambersCount - 1) : chambersCount;
  final bottomPlates = sealedChambers;
  final topPlates = chambersCount;
  final covers = chambersCount;
  final neckRings =
      chambersCount * spec.materialRule<num>('neck_rings_per_chamber').round();
  final sealRings =
      totalRings +
      math.max(0, topPlates - spec.materialRule<num>('seal_rings_factor').round());

  final diameterM = ringDiameter / 1000;
  final sealedSurfaceM2 =
      math.pi *
      diameterM *
      spec.materialRule<num>('ring_height_m').toDouble() *
      ringsPerChamber *
      sealedChambers;
  final masticKg =
      sealedSurfaceM2 *
      spec.materialRule<num>('mastic_kg_per_m2').toDouble() *
      spec.materialRule<num>('mastic_layers').toDouble();
  final masticCans =
      (masticKg / spec.materialRule<num>('mastic_can_kg').toDouble()).ceil();
  final bitumenSheetRolls =
      (sealRings *
              spec.materialRule<num>('bitumen_sheet_m_per_joint').toDouble() /
              spec.materialRule<num>('bitumen_sheet_roll_m').toDouble())
          .ceil();
  final filterArea = math.pi * math.pow(diameterM / 2, 2);
  final filterGravelM3 =
      withFilterWell == 1
          ? filterArea *
              spec.materialRule<num>('filter_gravel_layer_m').toDouble() *
              spec.materialRule<num>('filter_gravel_compaction').toDouble()
          : 0.0;
  final filterSandM3 =
      withFilterWell == 1
          ? filterArea *
              spec.materialRule<num>('filter_sand_layer_m').toDouble() *
              spec.materialRule<num>('filter_sand_compaction').toDouble()
          : 0.0;
  final pipeWithReserveM =
      pipeLengthFromHouse * spec.materialRule<num>('pipe_reserve').toDouble();
  final pipeSections =
      (pipeWithReserveM / spec.materialRule<num>('pipe_section_m').toDouble())
          .ceil();
  final pipeElbows = spec.materialRule<num>('pipe_elbow_count').round();
  final floorPlates =
      spec.materialRule<Map<String, dynamic>>('well_floor_plates', const {});
  final topPlateLabels =
      spec.materialRule<Map<String, dynamic>>('well_top_plates', const {});
  final floorPlateLabel = floorPlates['$ringDiameter'] as String? ?? 'ПН-10';
  final topPlateLabel = topPlateLabels['$ringDiameter'] as String? ?? 'ПП-10';

  final scenarios = _buildScenarios(
    spec,
    inputs,
    primaryQuantity: totalRings.toDouble(),
    packageLabel: 'septic-ring-$ringDiameter',
    unit: 'шт',
    extraAssumptions: [
      'chambersCount:$chambersCount',
      'ringDiameter:$ringDiameter',
      'groundType:$groundType',
      'withFilterWell:$withFilterWell',
    ],
  );

  final warnings = <String>[];
  if (residents >
      spec.warningRule<num>('biotreatment_recommended_residents').round()) {
    warnings.add('Более 10 жителей — рекомендуется станция биологической очистки');
  }
  if (chambersCount == 1 &&
      residents > spec.warningRule<num>('single_chamber_max_residents').round()) {
    warnings.add('Для семьи больше 3 человек одной камеры недостаточно');
  }
  if (groundType ==
          spec.warningRule<num>('clay_ground_filter_well_problematic').round() &&
      withFilterWell == 1) {
    warnings.add('Фильтрационный колодец плохо работает на глинистом грунте');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: 'КС-${ringDiameter ~/ 100}-9 (Ø$ringDiameter мм, h=900)',
        quantity: totalRings.toDouble(),
        unit: 'шт',
        withReserve: totalRings.toDouble(),
        purchaseQty: totalRings.toDouble(),
        category: 'Кольца',
      ),
      CanonicalMaterialResult(
        name: 'Днище $floorPlateLabel (Ø$ringDiameter мм)',
        quantity: bottomPlates.toDouble(),
        unit: 'шт',
        withReserve: bottomPlates.toDouble(),
        purchaseQty: bottomPlates.toDouble(),
        category: 'Колодец',
      ),
      CanonicalMaterialResult(
        name: 'Плита перекрытия $topPlateLabel (Ø$ringDiameter мм)',
        quantity: topPlates.toDouble(),
        unit: 'шт',
        withReserve: topPlates.toDouble(),
        purchaseQty: topPlates.toDouble(),
        category: 'Колодец',
      ),
      CanonicalMaterialResult(
        name: spec.materialRule<String>('neck_ring_label'),
        quantity: neckRings.toDouble(),
        unit: 'шт',
        withReserve: neckRings.toDouble(),
        purchaseQty: neckRings.toDouble(),
        category: 'Колодец',
      ),
      CanonicalMaterialResult(
        name: spec.materialRule<String>('manhole_label'),
        quantity: covers.toDouble(),
        unit: 'шт',
        withReserve: covers.toDouble(),
        purchaseQty: covers.toDouble(),
        category: 'Колодец',
      ),
      CanonicalMaterialResult(
        name: 'Уплотнительные кольца / резиновые манжеты',
        quantity: sealRings.toDouble(),
        unit: 'шт',
        withReserve: sealRings.toDouble(),
        purchaseQty: sealRings.toDouble(),
        category: 'Герметизация',
      ),
      CanonicalMaterialResult(
        name: 'Битумная мастика (20 кг)',
        quantity: roundValue(masticKg, 3),
        unit: 'кг',
        withReserve: roundValue(masticKg, 3),
        purchaseQty: masticCans.toDouble(),
        category: 'Гидроизоляция',
      ),
      CanonicalMaterialResult(
        name: 'Гидростеклоизол (полоса 300 мм, 10 м рулон)',
        quantity: bitumenSheetRolls.toDouble(),
        unit: 'рулон',
        withReserve: bitumenSheetRolls.toDouble(),
        purchaseQty: bitumenSheetRolls.toDouble(),
        category: 'Гидроизоляция',
      ),
      if (withFilterWell == 1)
        CanonicalMaterialResult(
          name: 'Щебень фр. 20-40 мм (фильтрующий слой)',
          quantity: roundValue(filterGravelM3, 3),
          unit: 'м³',
          withReserve: roundValue(filterGravelM3, 3),
          purchaseQty: roundValue(filterGravelM3, 3),
          category: 'Фильтр',
        ),
      if (withFilterWell == 1)
        CanonicalMaterialResult(
          name: 'Песок (подложка фильтра)',
          quantity: roundValue(filterSandM3, 3),
          unit: 'м³',
          withReserve: roundValue(filterSandM3, 3),
          purchaseQty: roundValue(filterSandM3, 3),
          category: 'Фильтр',
        ),
      CanonicalMaterialResult(
        name:
            'Труба ПВХ Ø${spec.materialRule<num>('pipe_diameter_mm').round()} (секции 3 м)',
        quantity: pipeSections.toDouble(),
        unit: 'шт',
        withReserve: pipeSections.toDouble(),
        purchaseQty: pipeSections.toDouble(),
        category: 'Трубопровод',
      ),
      CanonicalMaterialResult(
        name: 'Отводы Ø${spec.materialRule<num>('pipe_diameter_mm').round()}',
        quantity: pipeElbows.toDouble(),
        unit: 'шт',
        withReserve: pipeElbows.toDouble(),
        purchaseQty: pipeElbows.toDouble(),
        category: 'Трубопровод',
      ),
    ],
    totals: {
      'residents': residents.toDouble(),
      'chambersCount': chambersCount.toDouble(),
      'ringDiameter': ringDiameter.toDouble(),
      'groundType': groundType.toDouble(),
      'withFilterWell': withFilterWell.toDouble(),
      'pipeLengthFromHouse': roundValue(pipeLengthFromHouse, 3),
      'dailyVolumeLiters': dailyVolumeLiters.toDouble(),
      'totalVolumeLiters': totalVolumeLiters.toDouble(),
      'totalVolume': roundValue(totalVolume, 3),
      'volumePerChamber': roundValue(volumePerChamber, 3),
      'ringsPerChamber': ringsPerChamber.toDouble(),
      'totalRings': totalRings.toDouble(),
      'bottomPlates': bottomPlates.toDouble(),
      'topPlates': topPlates.toDouble(),
      'covers': covers.toDouble(),
      'neckRings': neckRings.toDouble(),
      'sealRings': sealRings.toDouble(),
      'sealedChambers': sealedChambers.toDouble(),
      'sealedSurfaceM2': roundValue(sealedSurfaceM2, 3),
      'masticKg': roundValue(masticKg, 3),
      'masticCans': masticCans.toDouble(),
      'bitumenSheetRolls': bitumenSheetRolls.toDouble(),
      'filterGravelM3': roundValue(filterGravelM3, 3),
      'filterSandM3': roundValue(filterSandM3, 3),
      'pipeWithReserveM': roundValue(pipeWithReserveM, 3),
      'pipeSections': pipeSections.toDouble(),
      'pipeElbows': pipeElbows.toDouble(),
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
