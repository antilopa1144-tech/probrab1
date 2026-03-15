import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

CanonicalCalculatorContractResult calculateCanonicalWarmFloor(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(warmFloorSpecData);

  final roomArea = (inputs['roomArea'] ?? defaultFor(spec, 'roomArea', 10)).clamp(1.0, 100.0);
  final furnitureArea = (inputs['furnitureArea'] ?? defaultFor(spec, 'furnitureArea', 2)).clamp(0.0, 50.0);
  final heatingType = (inputs['heatingType'] ?? defaultFor(spec, 'heatingType', 0)).round().clamp(0, 2);
  final powerDensity = (inputs['powerDensity'] ?? defaultFor(spec, 'powerDensity', 150)).clamp(100.0, 200.0);

  final heatingArea = math.max(0.0, roomArea - furnitureArea);
  final totalPowerW = heatingArea * powerDensity;
  final totalPowerKW = roundValue(totalPowerW / 1000, 3);

  /* ─── per-type calculations ─── */
  double basePrimary;
  List<CanonicalMaterialResult> materials;

  int mats = 0, cableLength = 0, mountingTapeRolls = 0, epsSheets = 0, screedBags = 0;
  int pipeLength = 0, circuits = 0;
  double pipeInsulation = 0, meshArea = 0;
  int substrateRolls = 0, adhesiveBags = 0;

  if (heatingType == 0) {
    // Mats
    mats = (heatingArea / spec.materialRule<num>('mat_area').toDouble()).ceil();
    substrateRolls = (heatingArea * spec.materialRule<num>('substrate_reserve').toDouble() / spec.materialRule<num>('substrate_roll_m2').toDouble()).ceil();
    adhesiveBags = (heatingArea * spec.materialRule<num>('tile_adhesive_kg_per_m2').toDouble() / spec.materialRule<num>('tile_adhesive_bag_kg').toDouble()).ceil();

    basePrimary = mats.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Нагревательный мат',
        quantity: mats.toDouble(),
        unit: 'шт',
        withReserve: mats.toDouble(),
        purchaseQty: mats.toInt(),
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Терморегулятор',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Гофротрубка для датчика',
        quantity: spec.materialRule<num>('corrugated_tube_m').toDouble(),
        unit: 'м',
        withReserve: spec.materialRule<num>('corrugated_tube_m').toDouble(),
        purchaseQty: spec.materialRule<num>('corrugated_tube_m').toDouble().ceil(),
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name: 'Подложка (рулоны)',
        quantity: substrateRolls.toDouble(),
        unit: 'рулонов',
        withReserve: substrateRolls.toDouble(),
        purchaseQty: substrateRolls.toInt(),
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Плиточный клей (мешки 25 кг)',
        quantity: roundValue(heatingArea * spec.materialRule<num>('tile_adhesive_kg_per_m2').toDouble(), 3),
        unit: 'кг',
        withReserve: (adhesiveBags * spec.materialRule<num>('tile_adhesive_bag_kg').toDouble()),
        purchaseQty: adhesiveBags.toInt(),
        category: 'Основное',
      ),
    ];
  } else if (heatingType == 1) {
    // Cable in screed
    cableLength = (heatingArea / spec.materialRule<num>('cable_step_m').toDouble() * spec.materialRule<num>('cable_reserve').toDouble()).ceil();
    mountingTapeRolls = (cableLength / spec.materialRule<num>('mounting_tape_roll_m').toDouble()).ceil();
    epsSheets = (heatingArea * spec.materialRule<num>('eps_reserve').toDouble() / spec.materialRule<num>('eps_sheet_m2').toDouble()).ceil();
    screedBags = (heatingArea * spec.materialRule<num>('screed_thickness_m').toDouble() * spec.materialRule<num>('screed_density').toDouble() / spec.materialRule<num>('screed_bag_kg').toDouble()).ceil();

    basePrimary = cableLength.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Нагревательный кабель',
        quantity: cableLength.toDouble(),
        unit: 'м',
        withReserve: cableLength.toDouble(),
        purchaseQty: cableLength.toInt(),
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Терморегулятор',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Монтажная лента (рулоны)',
        quantity: mountingTapeRolls.toDouble(),
        unit: 'рулонов',
        withReserve: mountingTapeRolls.toDouble(),
        purchaseQty: mountingTapeRolls.toInt(),
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name: 'Утеплитель ЕПС (листы 1200×600)',
        quantity: epsSheets.toDouble(),
        unit: 'листов',
        withReserve: epsSheets.toDouble(),
        purchaseQty: epsSheets.toInt(),
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name: 'Стяжка ЦПС (мешки 50 кг)',
        quantity: roundValue(heatingArea * spec.materialRule<num>('screed_thickness_m').toDouble() * spec.materialRule<num>('screed_density').toDouble(), 3),
        unit: 'кг',
        withReserve: (screedBags * spec.materialRule<num>('screed_bag_kg').toDouble()),
        purchaseQty: screedBags.toInt(),
        category: 'Основное',
      ),
    ];
  } else {
    // Water pipes
    pipeLength = (heatingArea / spec.materialRule<num>('pipe_step_m').toDouble() * spec.materialRule<num>('pipe_reserve').toDouble()).ceil();
    circuits = math.max(1, (pipeLength / spec.materialRule<num>('max_circuit_m').toDouble()).ceil());
    pipeInsulation = pipeLength * spec.materialRule<num>('pipe_insulation_reserve').toDouble();
    meshArea = heatingArea * spec.materialRule<num>('mesh_reserve').toDouble();

    basePrimary = pipeLength.toDouble();
    materials = [
      CanonicalMaterialResult(
        name: 'Труба для тёплого пола',
        quantity: pipeLength.toDouble(),
        unit: 'м',
        withReserve: pipeLength.toDouble(),
        purchaseQty: pipeLength.toInt(),
        category: 'Основное',
      ),
      const CanonicalMaterialResult(
        name: 'Коллектор',
        quantity: 1,
        unit: 'шт',
        withReserve: 1,
        purchaseQty: 1,
        category: 'Управление',
      ),
      CanonicalMaterialResult(
        name: 'Теплоизоляция трубы',
        quantity: pipeInsulation,
        unit: 'м',
        withReserve: pipeInsulation,
        purchaseQty: pipeInsulation.ceil(),
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name: 'Армирующая сетка',
        quantity: roundValue(meshArea, 3),
        unit: 'м²',
        withReserve: meshArea.ceil().toDouble(),
        purchaseQty: meshArea.ceil(),
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

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
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
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
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
  if (totalPowerKW > spec.warningRule<num>('separate_breaker_kw_threshold').toDouble()) {
    warnings.add('Мощность более 3.5 кВт — требуется отдельный автомат');
  }
  if (roomArea > 0 && heatingArea / roomArea < spec.warningRule<num>('ineffective_coverage_ratio').toDouble()) {
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
      'thermostat': 1.0,
      'mats': mats.toDouble(),
      'cableLength': cableLength.toDouble(),
      'mountingTapeRolls': mountingTapeRolls.toDouble(),
      'epsSheets': epsSheets.toDouble(),
      'screedBags': screedBags.toDouble(),
      'pipeLength': pipeLength.toDouble(),
      'circuits': circuits.toDouble(),
      'pipeInsulation': pipeInsulation,
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
