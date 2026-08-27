import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<int, String> _fenceTypeLabels = {
  0: 'Профнастил',
  1: 'Сетка-рабица',
  2: 'Деревянный штакетник',
};

bool hasCanonicalFenceInputs(Map<String, double> inputs) {
  final hasLegacyKeys =
      inputs.containsKey('postSpacing') ||
      inputs.containsKey('gates') ||
      inputs.containsKey('wickets');
  return !hasLegacyKeys;
}

Map<String, double> normalizeLegacyFenceInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final legacyFenceType = (inputs['fenceType'] ?? 0).round();
  normalized['fenceLength'] = (inputs['fenceLength'] ?? 50).toDouble();
  normalized['fenceHeight'] = (inputs['fenceHeight'] ?? 2).toDouble();
  normalized['fenceType'] = switch (legacyFenceType) {
    1 => 2,
    2 => 1,
    _ => 0,
  };
  normalized['postStep'] = (inputs['postStep'] ?? inputs['postSpacing'] ?? 2.5)
      .toDouble();
  normalized['gatesCount'] = (inputs['gatesCount'] ?? inputs['gates'] ?? 1)
      .toDouble();
  normalized['wicketsCount'] =
      (inputs['wicketsCount'] ?? inputs['wickets'] ?? 1).toDouble();
  return normalized;
}

CanonicalCalculatorContractResult calculateCanonicalFence(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(fenceSpecData);
  final normalized = hasCanonicalFenceInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFenceInputs(inputs);

  final fenceLength = math.max(
    5.0,
    math.min(
      500.0,
      (normalized['fenceLength'] ?? defaultFor(spec, 'fenceLength', 50))
          .toDouble(),
    ),
  );
  final fenceHeight = math.max(
    1.0,
    math.min(
      3.0,
      (normalized['fenceHeight'] ?? defaultFor(spec, 'fenceHeight', 2))
          .toDouble(),
    ),
  );
  final fenceType =
      (normalized['fenceType'] ?? defaultFor(spec, 'fenceType', 0))
          .round()
          .clamp(0, 2);
  final postStep = math.max(
    2.0,
    math.min(
      3.0,
      (normalized['postStep'] ?? defaultFor(spec, 'postStep', 2.5)).toDouble(),
    ),
  );
  final gatesCount =
      (normalized['gatesCount'] ?? defaultFor(spec, 'gatesCount', 1))
          .round()
          .clamp(0, 5);
  final wicketsCount =
      (normalized['wicketsCount'] ?? defaultFor(spec, 'wicketsCount', 1))
          .round()
          .clamp(0, 5);
  final sheetWorkingWidthMm = math.max(
    500.0,
    math.min(
      1500.0,
      (normalized['sheetWorkingWidthMm'] ??
              defaultFor(spec, 'sheetWorkingWidthMm', 1150))
          .toDouble(),
    ),
  );
  final coverReservePercent = math.max(
    0.0,
    (normalized['coverReservePercent'] ??
            defaultFor(spec, 'coverReservePercent', 0))
        .toDouble(),
  );
  final screwsPerSheet = math.max(
    0.0,
    (normalized['screwsPerSheet'] ?? defaultFor(spec, 'screwsPerSheet', 6))
        .toDouble(),
  );
  final screwReservePercent = math.max(
    0.0,
    (normalized['screwReservePercent'] ??
            defaultFor(spec, 'screwReservePercent', 5))
        .toDouble(),
  );
  final screwPackCount = math.max(
    1,
    (normalized['screwPackCount'] ?? defaultFor(spec, 'screwPackCount', 200))
        .round(),
  );

  final gateWidth = spec.materialRule<num>('gate_width').toDouble();
  final wicketWidth = spec.materialRule<num>('wicket_width').toDouble();
  final netLength = math.max(
    1.0,
    fenceLength - gatesCount * gateWidth - wicketsCount * wicketWidth,
  );
  final postsCount =
      (netLength / postStep).ceil() + 1 + gatesCount * 2 + wicketsCount * 2;
  final lagsPerSpan = fenceHeight > 2 ? 3 : 2;
  final lagSpans = (netLength / postStep).ceil();
  final lagsCount = lagSpans * lagsPerSpan;
  final postLength = roundValue(
    fenceHeight + spec.materialRule<num>('post_burial_m').toDouble(),
    2,
  );
  final concrete = roundValue(
    postsCount * spec.materialRule<num>('post_concrete_m3').toDouble(),
    3,
  );
  final caps = (postsCount * spec.materialRule<num>('caps_reserve').toDouble())
      .ceil();

  final sheetWorkingWidthM = sheetWorkingWidthMm / 1000.0;
  final sheetExactNeed = netLength / sheetWorkingWidthM;
  final rabicaRollM = spec.materialRule<num>('rabica_roll_m').toDouble();
  final rabicaExactNeed = netLength / rabicaRollM;
  final slatPitch =
      spec.materialRule<num>('slat_width').toDouble() +
      spec.materialRule<num>('slat_gap').toDouble();
  final slatExactNeed = netLength / slatPitch;
  final baseCoverExact = switch (fenceType) {
    0 => sheetExactNeed,
    1 => rabicaExactNeed,
    _ => slatExactNeed,
  };
  final packageLabel = switch (fenceType) {
    0 => 'profnastil-sheet',
    1 => 'rabica-roll',
    _ => 'wooden-slat',
  };
  final packageUnit = fenceType == 1 ? 'рулонов' : 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final reservePercent = scenarioName == 'MIN'
        ? 0.0
        : scenarioName == 'MAX'
        ? coverReservePercent +
              spec.materialRule<num>('max_extra_cover_percent').toDouble()
        : coverReservePercent;
    final scenarioMultiplierValue = 1 + reservePercent / 100.0;
    final exactNeed = roundValue(baseCoverExact * scenarioMultiplierValue, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'fence_type:$fenceType',
        'working_width_mm:${sheetWorkingWidthMm.round()}',
        'scenario_policy:explicit_cover_reserve',
      ],
      keyFactors: {
        'field_multiplier': roundValue(scenarioMultiplierValue, 6),
        'reserve_percent': roundValue(reservePercent, 3),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final sheets = fenceType == 0 ? recScenario.purchaseQuantity : 0.0;
  final screwsBaseCount = fenceType == 0 ? sheets * screwsPerSheet : 0.0;
  final screwsWithReserve = screwsBaseCount * (1 + screwReservePercent / 100.0);
  final screwPacks = screwsWithReserve > 0
      ? (screwsWithReserve / screwPackCount).ceil()
      : 0;
  final screwsPurchase = screwPacks * screwPackCount;
  final primerCans = fenceType == 0
      ? (fenceLength /
                spec.materialRule<num>('primer_spray_m_per_can').toDouble())
            .ceil()
      : 0;
  final rolls = fenceType == 1 ? recScenario.purchaseQuantity : 0.0;
  final tensionWireReserve = spec
      .materialRule<num>('tension_wire_reserve')
      .toDouble();
  final wireLength = fenceType == 1
      ? netLength * lagsPerSpan * tensionWireReserve
      : 0.0;
  final slats = fenceType == 2 ? recScenario.purchaseQuantity : 0.0;
  final antisepticCanL = spec.materialRule<num>('antiseptic_can_l').toDouble();
  final antisepticBaseL = fenceType == 2
      ? netLength *
            fenceHeight *
            2 *
            spec.materialRule<num>('antiseptic_l_per_m2').toDouble()
      : 0.0;
  final antisepticCans = antisepticBaseL > 0
      ? (antisepticBaseL / antisepticCanL).ceil()
      : 0;

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Столбы выбранной системы ($postLength м)',
      quantity: postsCount.toDouble(),
      unit: 'шт',
      withReserve: postsCount.toDouble(),
      purchaseQty: postsCount.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Поперечные лаги выбранной системы',
      quantity: lagsCount.toDouble(),
      unit: 'пролётов',
      withReserve: lagsCount.toDouble(),
      purchaseQty: lagsCount.toDouble(),
      category: 'Каркас',
    ),
  ];

  if (fenceType == 0) {
    materials.add(
      CanonicalMaterialResult(
        name:
            '${_fenceTypeLabels[0]}, рабочая ширина ${sheetWorkingWidthMm.round()} мм ($fenceHeight м)',
        quantity: roundValue(sheetExactNeed, 6),
        unit: 'шт',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        category: 'Покрытие',
        packageInfo: {
          'count': recScenario.buyPlan.packagesCount,
          'size': 1.0,
          'packageUnit': 'листов',
        },
      ),
    );
    if (screwsBaseCount > 0) {
      materials.add(
        CanonicalMaterialResult(
          name: 'Саморезы для профлиста',
          quantity: roundValue(screwsBaseCount, 6),
          unit: 'шт',
          withReserve: roundValue(screwsWithReserve, 6),
          purchaseQty: screwsPurchase.toDouble(),
          category: 'Крепёж',
          packageInfo: {
            'count': screwPacks,
            'size': screwPackCount.toDouble(),
            'packageUnit': 'упаковок',
          },
        ),
      );
    }
    materials.add(
      CanonicalMaterialResult(
        name: 'Грунт-спрей для срезов',
        quantity: primerCans.toDouble(),
        unit: 'баллонов',
        withReserve: primerCans.toDouble(),
        purchaseQty: primerCans.toDouble(),
        category: 'Защита',
      ),
    );
  } else if (fenceType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_fenceTypeLabels[1]} ($fenceHeight м, рулон $rabicaRollM м)',
        quantity: roundValue(rabicaExactNeed, 6),
        unit: 'рулонов',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        category: 'Покрытие',
        packageInfo: {
          'count': recScenario.buyPlan.packagesCount,
          'size': 1.0,
          'packageUnit': 'рулонов',
        },
      ),
      CanonicalMaterialResult(
        name: 'Проволока натяжная',
        quantity: roundValue(wireLength / tensionWireReserve, 6),
        unit: 'м',
        withReserve: roundValue(wireLength, 6),
        purchaseQty: wireLength.ceilToDouble(),
        category: 'Крепёж',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: '${_fenceTypeLabels[2]} ($fenceHeight м)',
        quantity: roundValue(slatExactNeed, 6),
        unit: 'шт',
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.purchaseQuantity,
        category: 'Покрытие',
        packageInfo: {
          'count': recScenario.buyPlan.packagesCount,
          'size': 1.0,
          'packageUnit': 'штакетин',
        },
      ),
      CanonicalMaterialResult(
        name: 'Антисептик ($antisepticCanL л)',
        quantity: roundValue(antisepticBaseL, 6),
        unit: 'л',
        withReserve: roundValue(antisepticBaseL, 6),
        purchaseQty: antisepticCans * antisepticCanL,
        category: 'Защита',
        packageInfo: {
          'count': antisepticCans,
          'size': antisepticCanL,
          'packageUnit': 'канистр',
        },
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Бетон для столбов',
      quantity: concrete,
      unit: 'м³',
      withReserve: concrete,
      purchaseQty: (concrete * 10).ceil() / 10,
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Заглушки для столбов',
      quantity: postsCount.toDouble(),
      unit: 'шт',
      withReserve: caps.toDouble(),
      purchaseQty: caps.toDouble(),
      category: 'Каркас',
    ),
  ]);

  final warnings = <String>[];
  if (gatesCount > 0) {
    warnings.add(
      'При наличии ворот нужны отдельный расчёт усиленных опор, фундамента и закладных',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'fenceLength': roundValue(fenceLength, 3),
      'fenceHeight': roundValue(fenceHeight, 3),
      'fenceType': fenceType.toDouble(),
      'postStep': roundValue(postStep, 2),
      'gatesCount': gatesCount.toDouble(),
      'wicketsCount': wicketsCount.toDouble(),
      'netLength': roundValue(netLength, 3),
      'postsCount': postsCount.toDouble(),
      'lagsPerSpan': lagsPerSpan.toDouble(),
      'lagSpans': lagSpans.toDouble(),
      'lagsCount': lagsCount.toDouble(),
      'postLength': postLength,
      'concrete': concrete,
      'caps': caps.toDouble(),
      'sheetWorkingWidthMm': sheetWorkingWidthMm,
      'sheetExactNeed': roundValue(sheetExactNeed, 6),
      'coverReservePercent': roundValue(coverReservePercent, 3),
      'sheets': sheets,
      'screwsPerSheet': roundValue(screwsPerSheet, 3),
      'screws': roundValue(screwsWithReserve, 6),
      'screwPacks': screwPacks.toDouble(),
      'screwsPurchase': screwsPurchase.toDouble(),
      'primerCans': primerCans.toDouble(),
      'rolls': rolls,
      'wireLength': roundValue(wireLength, 6),
      'slats': slats,
      'antisepticCans': antisepticCans.toDouble(),
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
