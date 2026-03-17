import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};


CanonicalCalculatorContractResult calculateCanonicalDecorStone(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(decorStoneSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 4)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).clamp(0.5, 10.0);
  final stoneType = (inputs['stoneType'] ?? defaultFor(spec, 'stoneType', 0)).round().clamp(0, 2);
  final jointWidth = (inputs['jointWidth'] ?? defaultFor(spec, 'jointWidth', 10)).clamp(0.0, 20.0);
  final needGrout = (inputs['needGrout'] ?? defaultFor(spec, 'needGrout', 1)).round() == 1 ? 1 : 0;
  final needPrimer = (inputs['needPrimer'] ?? defaultFor(spec, 'needPrimer', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? roundValue(wallWidth * wallHeight, 3) : areaInput;

  // Stone
  final stoneM2 = area * spec.materialRule<num>('stone_reserve').toDouble();

  // Glue
  final glueKgMap = spec.materialRule<Map>('glue_kg_per_m2');
  final glueRate = (glueKgMap['$stoneType'] as num?)?.toDouble() ?? (glueKgMap['0'] as num?)?.toDouble() ?? 3.0;
  final glueKg = area * glueRate * spec.materialRule<num>('glue_reserve').toDouble();
  final glueBags = (glueKg / spec.materialRule<num>('glue_bag').toDouble()).ceil();

  // Grout (conditional)
  final groutKg = needGrout == 1
      ? area * (jointWidth / 5) * spec.materialRule<num>('grout_base_factor').toDouble() * spec.materialRule<num>('grout_reserve').toDouble()
      : 0.0;
  final groutBags = (groutKg / spec.materialRule<num>('grout_bag').toDouble()).ceil();

  // Primer (conditional)
  final primerL = needPrimer == 1
      ? area * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble()
      : 0.0;
  final primerCans = (primerL / spec.materialRule<num>('primer_can').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(stoneM2 * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'stoneType:$stoneType',
        'jointWidth:$jointWidth',
        'needGrout:$needGrout',
        'needPrimer:$needPrimer',
        'packaging:decor-stone-m2',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'decor-stone-m2',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'м\u00b2',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (stoneType == 2) {
    warnings.add('Натуральный камень тяжёлый — убедитесь в несущей способности стены');
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку камня');
  }
  if (jointWidth == 0 && needGrout == 1) {
    warnings.add('Шов 0 мм — затирка не требуется при бесшовной укладке');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Декоративный камень',
      quantity: roundValue(recScenario.exactNeed, 3),
      unit: 'м\u00b2',
      withReserve: roundValue(recScenario.exactNeed, 3),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Клей (${spec.materialRule<num>('glue_bag').toDouble().round()} кг)',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags.toDouble(),
      category: 'Монтаж',
    ),
  ];

  if (needGrout == 1 && groutBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Затирка (${spec.materialRule<num>('grout_bag').toDouble().round()} кг)',
      quantity: groutBags.toDouble(),
      unit: 'мешков',
      withReserve: groutBags.toDouble(),
      purchaseQty: groutBags.toDouble(),
      category: 'Отделка',
    ));
  }

  if (needPrimer == 1 && primerCans > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Грунтовка (${spec.materialRule<num>('primer_can').toDouble().round()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toDouble(),
      category: 'Грунтовка',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'wallWidth': roundValue(wallWidth, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'stoneType': stoneType.toDouble(),
      'jointWidth': jointWidth,
      'needGrout': needGrout.toDouble(),
      'needPrimer': needPrimer.toDouble(),
      'stoneM2': roundValue(stoneM2, 3),
      'glueKg': roundValue(glueKg, 3),
      'glueBags': glueBags.toDouble(),
      'groutKg': roundValue(groutKg, 3),
      'groutBags': groutBags.toDouble(),
      'primerL': roundValue(primerL, 3),
      'primerCans': primerCans.toDouble(),
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
