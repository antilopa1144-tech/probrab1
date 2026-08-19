import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

CanonicalCalculatorContractResult calculateCanonicalWarmFloor(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(warmFloorSpecData);
  final normalized = normalizeLegacyWarmFloorInputs(inputs, spec);

  final roomArea = (normalized['roomArea'] ?? defaultFor(spec, 'roomArea', 10))
      .clamp(1.0, 100.0);
  final furnitureArea =
      (normalized['furnitureArea'] ?? defaultFor(spec, 'furnitureArea', 2))
          .clamp(0.0, roomArea);
  final heatingType =
      (normalized['heatingType'] ?? defaultFor(spec, 'heatingType', 0))
          .round()
          .clamp(0, 2);
  final powerDensity =
      (normalized['powerDensity'] ?? defaultFor(spec, 'powerDensity', 150))
          .clamp(100.0, 200.0);

  final heatingArea = math.max(0.0, roomArea - furnitureArea);
  final totalPowerW = heatingArea * powerDensity;
  final totalPowerKW = roundValue(totalPowerW / 1000, 3);

  /* ─── per-type calculations ─── */
  double basePrimary;
  List<CanonicalMaterialResult> materials;

  int mats = 0,
      cableLength = 0,
      mountingTapeRolls = 0,
      epsSheets = 0,
      screedBags = 0;
  int pipeLength = 0, circuits = 0;
  double meshArea = 0, cableStepMm = 0;
  int substrateRolls = 0, adhesiveBags = 0;

  if (heatingType == 0) {
    // Mats
    mats = (heatingArea / spec.materialRule<num>('mat_area').toDouble()).ceil();
    substrateRolls =
        (heatingArea *
                spec.materialRule<num>('substrate_reserve').toDouble() /
                spec.materialRule<num>('substrate_roll_m2').toDouble())
            .ceil();
    adhesiveBags =
        (heatingArea *
                spec.materialRule<num>('tile_adhesive_kg_per_m2').toDouble() /
                spec.materialRule<num>('tile_adhesive_bag_kg').toDouble())
            .ceil();

    basePrimary = mats.toDouble();
    materials = [
      CanonicalMaterialResult(
        name:
            'Нагревательный мат ${powerDensity.round()} Вт/м², комплект на ${spec.materialRule<num>('mat_area').toDouble().round()} м²',
        quantity: mats.toDouble(),
        unit: 'шт',
        withReserve: mats.toDouble(),
        purchaseQty: mats.toDouble(),
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Терморегулятор с выносным датчиком температуры пола',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1.0,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Гофротрубка Ø16 мм с заглушкой для датчика пола',
        quantity: spec.materialRule<num>('corrugated_tube_m').toDouble(),
        unit: 'м',
        withReserve: spec.materialRule<num>('corrugated_tube_m').toDouble(),
        purchaseQty: spec
            .materialRule<num>('corrugated_tube_m')
            .toDouble()
            .ceil()
            .toDouble(),
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name:
            'Теплоизоляционная подложка, рулон ${spec.materialRule<num>('substrate_roll_m2').toDouble().round()} м²',
        quantity: substrateRolls.toDouble(),
        unit: 'рулонов',
        withReserve: substrateRolls.toDouble(),
        purchaseQty: substrateRolls.toDouble(),
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name:
            'Эластичный плиточный клей для тёплого пола, мешок ${spec.materialRule<num>('tile_adhesive_bag_kg').toDouble().round()} кг',
        quantity: roundValue(
          heatingArea *
              spec.materialRule<num>('tile_adhesive_kg_per_m2').toDouble(),
          3,
        ),
        unit: 'кг',
        withReserve:
            (adhesiveBags *
            spec.materialRule<num>('tile_adhesive_bag_kg').toDouble()),
        purchaseQty:
            (adhesiveBags *
                    spec.materialRule<num>('tile_adhesive_bag_kg').toDouble())
                .toDouble(),
        packageInfo: {
          'count': adhesiveBags,
          'size': spec.materialRule<num>('tile_adhesive_bag_kg').toDouble(),
          'packageUnit': 'мешков',
        },
        category: 'Основное',
      ),
    ];
  } else if (heatingType == 1) {
    // Cable in screed
    final cableLinearPower = spec
        .materialRule<num>('cable_linear_power_w_per_m')
        .toDouble();
    cableLength =
        (totalPowerW /
                cableLinearPower *
                spec.materialRule<num>('cable_reserve').toDouble())
            .ceil();
    cableStepMm = cableLength > 0
        ? roundValue(heatingArea / cableLength * 1000, 1)
        : 0;
    mountingTapeRolls =
        (cableLength /
                spec.materialRule<num>('mounting_tape_roll_m').toDouble())
            .ceil();
    epsSheets =
        (heatingArea *
                spec.materialRule<num>('eps_reserve').toDouble() /
                spec.materialRule<num>('eps_sheet_m2').toDouble())
            .ceil();
    screedBags =
        (heatingArea *
                spec.materialRule<num>('screed_thickness_m').toDouble() *
                spec.materialRule<num>('screed_density').toDouble() /
                spec.materialRule<num>('screed_bag_kg').toDouble())
            .ceil();

    basePrimary = cableLength.toDouble();
    materials = [
      CanonicalMaterialResult(
        name:
            'Двухжильный нагревательный кабель ${cableLinearPower.round()} Вт/м',
        quantity: cableLength.toDouble(),
        unit: 'м',
        withReserve: cableLength.toDouble(),
        purchaseQty: cableLength.toDouble(),
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Терморегулятор с выносным датчиком температуры пола',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1.0,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name:
            'Металлическая монтажная лента для греющего кабеля, рулон ${spec.materialRule<num>('mounting_tape_roll_m').toDouble().round()} м',
        quantity: mountingTapeRolls.toDouble(),
        unit: 'рулонов',
        withReserve: mountingTapeRolls.toDouble(),
        purchaseQty: mountingTapeRolls.toDouble(),
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name:
            'Теплоизоляционные плиты для пола 1200×600 мм (${spec.materialRule<num>('eps_sheet_m2').toDouble()} м²)',
        quantity: epsSheets.toDouble(),
        unit: 'листов',
        withReserve: epsSheets.toDouble(),
        purchaseQty: epsSheets.toDouble(),
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name:
            'Сухая смесь для стяжки тёплого пола, мешок ${spec.materialRule<num>('screed_bag_kg').toDouble().round()} кг',
        quantity: roundValue(
          heatingArea *
              spec.materialRule<num>('screed_thickness_m').toDouble() *
              spec.materialRule<num>('screed_density').toDouble(),
          3,
        ),
        unit: 'кг',
        withReserve:
            (screedBags * spec.materialRule<num>('screed_bag_kg').toDouble()),
        purchaseQty:
            (screedBags * spec.materialRule<num>('screed_bag_kg').toDouble())
                .toDouble(),
        packageInfo: {
          'count': screedBags,
          'size': spec.materialRule<num>('screed_bag_kg').toDouble(),
          'packageUnit': 'мешков',
        },
        category: 'Основное',
      ),
    ];
  } else {
    // Water pipes
    pipeLength =
        (heatingArea /
                spec.materialRule<num>('pipe_step_m').toDouble() *
                spec.materialRule<num>('pipe_reserve').toDouble())
            .ceil();
    circuits = pipeLength > 0
        ? (pipeLength / spec.materialRule<num>('max_circuit_m').toDouble())
              .ceil()
        : 0;
    meshArea = heatingArea * spec.materialRule<num>('mesh_reserve').toDouble();

    basePrimary = pipeLength.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Труба PE-Xa или PE-RT 16×2 мм для тёплого пола',
        quantity: pipeLength.toDouble(),
        unit: 'м',
        withReserve: pipeLength.toDouble(),
        purchaseQty: pipeLength.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name:
            'Коллекторная группа для тёплого пола на $circuits ${circuits == 1 ? 'контур' : 'контура'}',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1.0,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Евроконусы 3/4″×16 мм для подключения трубы к коллектору',
        quantity: (circuits * 2).toDouble(),
        unit: 'шт',
        withReserve: (circuits * 2).toDouble(),
        purchaseQty: (circuits * 2).toDouble(),
        category: 'Подключение',
      ),
      CanonicalMaterialResult(
        name: 'Стальная армирующая сетка для стяжки',
        quantity: roundValue(meshArea, 3),
        unit: 'м²',
        withReserve: meshArea.ceil().toDouble(),
        purchaseQty: meshArea.ceil().toDouble(),
        category: 'Армирование',
      ),
    ];
  }

  /* ─── scenarios ─── */
  final scenarios = <String, CanonicalScenarioResult>{};
  final packageLabel = heatingType == 0
      ? 'warm-floor-mat'
      : heatingType == 1
      ? 'warm-floor-cable-m'
      : 'warm-floor-pipe-m';
  final packageUnit = heatingType == 0 ? 'шт' : 'м';

  final accuracyMode = parseAccuracyMode(normalized);
  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      defaultFactorTable,
      scenarioName,
    );
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    final purchaseQuantity = roundValue(packageCount.toDouble(), 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'heatingType:$heatingType',
        'powerDensity:$powerDensity',
        'packaging:$packageLabel',
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
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (heatingType != 2 &&
      totalPowerKW >
          spec.warningRule<num>('separate_breaker_kw_threshold').toDouble()) {
    warnings.add(
      'Электрическая мощность выше допустимой для типового терморегулятора — нужна отдельная линия и проверка схемы электриком',
    );
  }
  if (roomArea > 0 &&
      heatingArea / roomArea <
          spec.warningRule<num>('ineffective_coverage_ratio').toDouble()) {
    warnings.add('Обогреваемая площадь менее 50% — неэффективное покрытие');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roomArea': roundValue(roomArea, 3),
      'furnitureArea': roundValue(furnitureArea, 3),
      'heatingArea': roundValue(heatingArea, 3),
      'heatingType': heatingType.toDouble(),
      'powerDensity': powerDensity,
      'totalPowerW': roundValue(totalPowerW, 3),
      'totalPowerKW': totalPowerKW,
      'thermostat': heatingType == 2 ? 0.0 : 1.0,
      'mats': mats.toDouble(),
      'cableLength': cableLength.toDouble(),
      'mountingTapeRolls': mountingTapeRolls.toDouble(),
      'epsSheets': epsSheets.toDouble(),
      'screedBags': screedBags.toDouble(),
      'pipeLength': pipeLength.toDouble(),
      'circuits': circuits.toDouble(),
      'cableStepMm': cableStepMm,
      'meshArea': roundValue(meshArea, 3),
      'substrateRolls': substrateRolls.toDouble(),
      'adhesiveBags': adhesiveBags.toDouble(),
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
