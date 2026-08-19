import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */

const Map<int, String> _masticTypeLabels = {
  0: 'Готовая полимерная гидроизоляция типа CL 51',
  1: 'Жидкая резина',
  2: 'Полимерная мастика',
};

bool hasCanonicalWaterproofingInputs(Map<String, double> inputs) {
  return inputs.containsKey('masticType') ||
      inputs.containsKey('layers') ||
      inputs.containsKey('wallHeight');
}

Map<String, double> normalizeLegacyWaterproofingInputs(
  Map<String, double> inputs,
) {
  final normalized = Map<String, double>.from(inputs);
  normalized['floorArea'] = (inputs['floorArea'] ?? 6).toDouble();
  normalized['wallHeight'] = (inputs['wallHeight'] ?? 200).toDouble();
  normalized['roomPerimeter'] = (inputs['roomPerimeter'] ?? 10).toDouble();
  normalized['masticType'] = (inputs['masticType'] ?? 0).toDouble();
  normalized['layers'] = (inputs['layers'] ?? 2).toDouble();
  return normalized;
}

CanonicalCalculatorContractResult calculateCanonicalWaterproofing(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(waterproofingSpecData);

  final normalized = hasCanonicalWaterproofingInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyWaterproofingInputs(inputs);

  final floorArea = math.max(
    1.0,
    math.min(
      50.0,
      (normalized['floorArea'] ?? defaultFor(spec, 'floorArea', 6)).toDouble(),
    ),
  );
  final wallHeightMm = math.max(
    0.0,
    math.min(
      2000.0,
      (normalized['wallHeight'] ?? defaultFor(spec, 'wallHeight', 200))
          .toDouble(),
    ),
  );
  final roomPerimeter = math.max(
    4.0,
    math.min(
      40.0,
      (normalized['roomPerimeter'] ?? defaultFor(spec, 'roomPerimeter', 10))
          .toDouble(),
    ),
  );
  final masticType =
      (normalized['masticType'] ?? defaultFor(spec, 'masticType', 0))
          .round()
          .clamp(0, 2);
  final layers = (normalized['layers'] ?? defaultFor(spec, 'layers', 2))
      .round()
      .clamp(1, 3);
  final pipePenetrations =
      (normalized['pipePenetrations'] ??
              defaultFor(spec, 'pipePenetrations', 0))
          .round()
          .clamp(0, 20);
  final insetCount =
      (normalized['insetCount'] ?? defaultFor(spec, 'insetCount', 0))
          .round()
          .clamp(0, 10);
  final floorCurvatureClass =
      (normalized['floorCurvatureClass'] ??
              defaultFor(spec, 'floorCurvatureClass', 0))
          .round()
          .clamp(0, 2);

  // Areas
  final wallArea = roundValue(roomPerimeter * (wallHeightMm / 1000), 3);
  final totalArea = roundValue(floorArea + wallArea, 3);

  // Mastic
  final consumption =
      (spec.materialRule<Map>('consumption_per_layer')['$masticType'] as num?)
          ?.toDouble() ??
      1.0;
  final bucketKg =
      (spec.materialRule<Map>('bucket_kg')['$masticType'] as num?)
          ?.toDouble() ??
      15.0;
  final curvatureMultipliers = spec.materialRule<Map>(
    'floor_curvature_multipliers',
    const {'0': 1.0, '1': 1.1, '2': 1.2},
  );
  final curvatureMult =
      (curvatureMultipliers['$floorCurvatureClass'] as num?)?.toDouble() ?? 1.0;
  final extraMasticKg =
      pipePenetrations *
          spec
              .materialRule<num>('mastic_per_pipe_penetration_kg', 1.0)
              .toDouble() +
      insetCount *
          spec.materialRule<num>('mastic_per_inset_kg', 1.5).toDouble();
  final masticKg = roundValue(
    totalArea * consumption * layers * curvatureMult + extraMasticKg,
    3,
  );
  final masticBuckets = (masticKg / bucketKg).ceil();

  // Tape
  final penetrationTapeM = pipePenetrations * 0.5 + insetCount * 2.0;
  final tapeM = roundValue(
    (roomPerimeter +
            (wallHeightMm > 0 ? roomPerimeter * 1.2 : 0) +
            penetrationTapeM) *
        spec.materialRule<num>('tape_reserve').toDouble(),
    3,
  );
  final tapeRolls = (tapeM / 10).ceil();

  // Silicone
  final siliconeTubes =
      (roomPerimeter / spec.materialRule<num>('silicone_m_per_tube').toDouble())
          .ceil() +
      1;

  // Primer / bitumen
  var primerKg = 0.0;
  var primerCans = 0;
  var bitumenL = 0.0;
  var bitumenCans = 0;

  if (masticType == 0) {
    primerKg = roundValue(
      totalArea * spec.materialRule<num>('primer_kg_per_m2').toDouble() * 1.1,
      3,
    );
    primerCans = (primerKg / spec.materialRule<num>('primer_can_kg').toDouble())
        .ceil();
  } else {
    bitumenL = roundValue(
      totalArea * spec.materialRule<num>('bitumen_l_per_m2').toDouble() * 1.1,
      3,
    );
    bitumenCans =
        (bitumenL / spec.materialRule<num>('bitumen_can_l').toDouble()).ceil();
  }

  // Joint sealant
  final jointTubes =
      (roomPerimeter *
              0.5 /
              spec.materialRule<num>('joint_sealant_m_per_tube').toDouble())
          .ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('waterproofing', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(masticBuckets * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'masticType:$masticType',
        'layers:$layers',
        'packaging:mastic-bucket-${bucketKg.round()}kg',
      ],
      keyFactors: {
        ...buildKeyFactors(
          spec.enabledFactors,
          defaultFactorTable,
          scenarioName,
        ),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'mastic-bucket-${bucketKg.round()}kg',
        packageSize: 1,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (layers < spec.warningRule<num>('min_layers_residential').toDouble()) {
    warnings.add('Один слой допускается только для нежилых помещений');
  }
  if (wallHeightMm == 0) {
    warnings.add(
      'Обработка стен обязательна минимум на ${spec.warningRule<num>('min_wall_height_mm').toDouble()} мм от пола',
    );
  }
  if (pipePenetrations == 0 && insetCount == 0 && floorArea > 3) {
    warnings.add(
      'Не указаны примыкания труб и инсталляций. В реальном санузле обычно 3-5 примыканий (стояк, подвод воды, слив, душ) — без них расчёт занижен на 15-25%. Укажите pipePenetrations.',
    );
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name:
          '${_masticTypeLabels[masticType] ?? "Мастика"} (${bucketKg.round()} кг)',
      quantity: masticKg,
      unit: 'кг',
      withReserve: (masticBuckets * bucketKg).toDouble(),
      purchaseQty: (masticBuckets * bucketKg).toDouble(),
      packageInfo: {
        'count': masticBuckets,
        'size': bucketKg,
        'packageUnit': 'вёдер',
      },
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Системная эластичная гидроизоляционная лента (10 м)',
      quantity: tapeM,
      unit: 'м',
      withReserve: (tapeRolls * 10).toDouble(),
      purchaseQty: (tapeRolls * 10).toDouble(),
      packageInfo: {'count': tapeRolls, 'size': 10, 'packageUnit': 'рулонов'},
      category: 'Лента',
    ),
    CanonicalMaterialResult(
      name: 'Санитарный нейтральный силиконовый герметик, 280–310 мл',
      quantity: siliconeTubes.toDouble(),
      unit: 'туб',
      withReserve: siliconeTubes.toDouble(),
      purchaseQty: siliconeTubes.toDouble(),
      category: 'Герметик',
    ),
  ];

  if (masticType == 0) {
    materials.add(
      CanonicalMaterialResult(
        name:
            'Грунтовка под полимерную гидроизоляцию (${spec.materialRule<num>('primer_can_kg').toDouble().round()} кг)',
        quantity: primerKg,
        unit: 'кг',
        withReserve:
            (primerCans * spec.materialRule<num>('primer_can_kg').toDouble()),
        purchaseQty:
            (primerCans * spec.materialRule<num>('primer_can_kg').toDouble())
                .toDouble(),
        packageInfo: {
          'count': primerCans,
          'size': spec.materialRule<num>('primer_can_kg').toDouble(),
          'packageUnit': 'банок',
        },
        category: 'Подготовка',
      ),
    );
  } else {
    materials.add(
      CanonicalMaterialResult(
        name:
            'Битумный праймер (${spec.materialRule<num>('bitumen_can_l').toDouble().round()} л)',
        quantity: bitumenL,
        unit: 'л',
        withReserve:
            (bitumenCans * spec.materialRule<num>('bitumen_can_l').toDouble()),
        purchaseQty:
            (bitumenCans * spec.materialRule<num>('bitumen_can_l').toDouble())
                .toDouble(),
        packageInfo: {
          'count': bitumenCans,
          'size': spec.materialRule<num>('bitumen_can_l').toDouble(),
          'packageUnit': 'канистр',
        },
        category: 'Подготовка',
      ),
    );
  }

  materials.add(
    CanonicalMaterialResult(
      name: 'Эластичный герметик для примыканий, 280–310 мл',
      quantity: jointTubes.toDouble(),
      unit: 'туб',
      withReserve: jointTubes.toDouble(),
      purchaseQty: jointTubes.toDouble(),
      category: 'Герметик',
    ),
  );

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'floorArea': roundValue(floorArea, 3),
      'wallHeightMm': wallHeightMm,
      'roomPerimeter': roundValue(roomPerimeter, 3),
      'masticType': masticType.toDouble(),
      'layers': layers.toDouble(),
      'pipePenetrations': pipePenetrations.toDouble(),
      'insetCount': insetCount.toDouble(),
      'floorCurvatureClass': floorCurvatureClass.toDouble(),
      'curvatureMult': curvatureMult,
      'extraMasticKg': extraMasticKg.toDouble(),
      'penetrationTapeM': penetrationTapeM.toDouble(),
      'wallArea': wallArea,
      'totalArea': totalArea,
      'masticKg': masticKg,
      'masticBuckets': masticBuckets.toDouble(),
      'tapeM': tapeM,
      'tapeRolls': tapeRolls.toDouble(),
      'siliconeTubes': siliconeTubes.toDouble(),
      'primerKg': primerKg,
      'primerCans': primerCans.toDouble(),
      'bitumenL': bitumenL,
      'bitumenCans': bitumenCans.toDouble(),
      'jointTubes': jointTubes.toDouble(),
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
