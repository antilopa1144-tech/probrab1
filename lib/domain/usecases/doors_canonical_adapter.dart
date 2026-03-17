import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

/* ─── spec types ─── */


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};


bool hasCanonicalDoorsInputs(Map<String, double> inputs) {
  return inputs.containsKey('doorType') ||
      inputs.containsKey('doorCount') ||
      inputs.containsKey('wallThickness');
}

Map<String, double> normalizeLegacyDoorsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['doorCount'] = (inputs['doorCount'] ?? 3).toDouble();
  normalized['doorType'] = (inputs['doorType'] ?? 0).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 120).toDouble();
  normalized['withNalichnik'] = (inputs['withNalichnik'] ?? 1).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalDoors(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(doorsSpecData);

  final normalized = hasCanonicalDoorsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyDoorsInputs(inputs);

  final doorCount = (normalized['doorCount'] ?? defaultFor(spec, 'doorCount', 3)).round().clamp(1, 20);
  final doorType = (normalized['doorType'] ?? defaultFor(spec, 'doorType', 0)).round().clamp(0, 4);
  final wallThickness = (normalized['wallThickness'] ?? defaultFor(spec, 'wallThickness', 120)).round().clamp(80, 380);
  final withNalichnik = (normalized['withNalichnik'] ?? defaultFor(spec, 'withNalichnik', 1)).round().clamp(0, 1);

  // Door dimensions
  final dimsMap = spec.materialRule<Map>('door_dims')['$doorType'] as Map? ?? {'w': 700, 'h': 2000};
  final doorW = (dimsMap['w'] as num?)?.toDouble() ?? 700;
  final doorH = (dimsMap['h'] as num?)?.toDouble() ?? 2000;
  final perimM = 2 * (doorW + doorH) / 1000;

  // Foam
  final foamPerDoor = perimM * spec.materialRule<num>('foam_ml_per_m').toDouble() / 1000;
  final foamCans = (doorCount * foamPerDoor * spec.materialRule<num>('foam_reserve').toDouble() / (spec.materialRule<num>('foam_can_ml').toDouble() / 1000)).ceil();

  // Dobor
  final needDobor = wallThickness > spec.materialRule<num>('box_depth').toDouble();
  final doborWidth = needDobor ? wallThickness - spec.materialRule<num>('box_depth').toDouble() : 0;
  var doborPcs = 0;
  if (needDobor) {
    final doborLenPerDoor = (2 * doorH + doorW) / 1000 * 1.05;
    doborPcs = (doborLenPerDoor / (spec.materialRule<num>('dobor_standard_h').toDouble() / 1000)).ceil() * doorCount;
  }

  // Nalichnik
  var nalichnikPcs = 0;
  if (withNalichnik == 1) {
    final nalichnikLenPerDoor = (2 * doorH + doorW) / 1000 * 1.05;
    nalichnikPcs = (nalichnikLenPerDoor / (spec.materialRule<num>('nalichnik_standard_h').toDouble() / 1000)).ceil() * doorCount * 2;
  }

  // Glue
  final glueCarts = (doorCount * spec.materialRule<num>('glue_cartridge_per_door').toDouble()).ceil();

  // Fasteners (in kg)
  final screwsPcs = (doorCount * spec.materialRule<num>('screws_per_door').toDouble()).round();
  final screwsKg = (screwsPcs / 600 * 10).ceil() / 10; // 4×40 мм: 600 шт/кг
  final dubelPacks = (doorCount * spec.materialRule<num>('dubels_per_door').toDouble() / spec.materialRule<num>('dubel_pack').toDouble()).ceil();

  // Scenarios
  final basePrimary = foamCans;
  const packageLabel = 'foam-can-750ml';
  const packageUnit = 'баллонов';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'doorType:$doorType',
        'wallThickness:$wallThickness',
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

  // Warnings
  final warnings = <String>[];
  if (wallThickness >= spec.warningRule<num>('thick_wall_threshold_mm').toDouble()) {
    warnings.add('При толстых стенах проверьте ширину доборов в магазине');
  }
  if (doorCount > spec.warningRule<num>('bulk_door_threshold').toDouble()) {
    warnings.add('Большое количество дверей — рассмотрите оптовую закупку');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Монтажная пена (750 мл)',
      quantity: recScenario.exactNeed,
      unit: 'баллонов',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы монтажные',
      quantity: screwsKg,
      unit: 'кг',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Дюбели (упаковка ${spec.materialRule<num>('dubel_pack').toDouble()} шт)',
      quantity: (doorCount * spec.materialRule<num>('dubels_per_door').toDouble()),
      unit: 'шт',
      withReserve: (dubelPacks * spec.materialRule<num>('dubel_pack').toDouble()),
      purchaseQty: (dubelPacks * spec.materialRule<num>('dubel_pack').toDouble()).toDouble(),
      category: 'Крепёж',
      packageInfo: {'count': dubelPacks, 'unitSize': spec.materialRule<num>('dubel_pack').toDouble(), 'packageUnit': 'упаковок'},
    ),
    CanonicalMaterialResult(
      name: 'Клей-герметик (картриджи)',
      quantity: glueCarts.toDouble(),
      unit: 'шт',
      withReserve: glueCarts.toDouble(),
      purchaseQty: glueCarts.toDouble(),
      category: 'Монтаж',
    ),
  ];

  if (needDobor) {
    materials.add(CanonicalMaterialResult(
      name: 'Доборы (ширина $doborWidth мм)',
      quantity: doborPcs.toDouble(),
      unit: 'шт',
      withReserve: doborPcs.toDouble(),
      purchaseQty: doborPcs.toDouble(),
      category: 'Комплектация',
    ));
  }

  if (withNalichnik == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Наличники',
      quantity: nalichnikPcs.toDouble(),
      unit: 'шт',
      withReserve: nalichnikPcs.toDouble(),
      purchaseQty: nalichnikPcs.toDouble(),
      category: 'Комплектация',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'doorCount': doorCount.toDouble(),
      'doorType': doorType.toDouble(),
      'wallThickness': wallThickness.toDouble(),
      'withNalichnik': withNalichnik.toDouble(),
      'doorW': doorW.toDouble(),
      'doorH': doorH.toDouble(),
      'perimM': roundValue(perimM, 3),
      'foamPerDoor': roundValue(foamPerDoor, 4),
      'foamCans': foamCans.toDouble(),
      'needDobor': needDobor ? 1.0 : 0.0,
      'doborWidth': doborWidth.toDouble(),
      'doborPcs': doborPcs.toDouble(),
      'nalichnikPcs': nalichnikPcs.toDouble(),
      'glueCarts': glueCarts.toDouble(),
      'screwsKg': screwsKg,
      'dubelPacks': dubelPacks.toDouble(),
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
