import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';




CanonicalCalculatorContractResult calculateCanonicalDecorStone(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(decorStoneSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 1)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 4)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).clamp(0.5, 10.0);
  final openingsAreaInput = (inputs['openingsArea'] ?? defaultFor(spec, 'openingsArea', 0)).clamp(0.0, 200.0);
  final stoneType = (inputs['stoneType'] ?? defaultFor(spec, 'stoneType', 0)).round().clamp(0, 2);
  final reservePercent = (inputs['reservePercent'] ?? defaultFor(spec, 'reservePercent', 10)).clamp(0.0, 30.0);
  final packArea = (inputs['packArea'] ?? defaultFor(spec, 'packArea', 1)).clamp(0.1, 20.0);
  final glueRate = (inputs['glueRate'] ?? defaultFor(spec, 'glueRate', 5)).clamp(0.1, 20.0);
  final glueBag = (inputs['glueBag'] ?? defaultFor(spec, 'glueBag', 25)).clamp(1.0, 50.0);
  final needGrout = (inputs['needGrout'] ?? defaultFor(spec, 'needGrout', 1)).round() == 1 ? 1 : 0;
  final groutRate = (inputs['groutRate'] ?? defaultFor(spec, 'groutRate', 0.4)).clamp(0.01, 5.0);
  final groutBag = (inputs['groutBag'] ?? defaultFor(spec, 'groutBag', 5)).clamp(0.5, 25.0);
  final needPrimer = (inputs['needPrimer'] ?? defaultFor(spec, 'needPrimer', 1)).round() == 1 ? 1 : 0;
  final primerRate = (inputs['primerRate'] ?? defaultFor(spec, 'primerRate', 0.15)).clamp(0.01, 1.0);
  final primerLayers = (inputs['primerLayers'] ?? defaultFor(spec, 'primerLayers', 1)).round().clamp(1, 3);
  final primerCan = (inputs['primerCan'] ?? defaultFor(spec, 'primerCan', 10)).clamp(0.5, 20.0);

  // Area
  final grossArea = inputMode == 0 ? wallWidth * wallHeight : areaInput;
  final openingsArea = inputMode == 0 ? math.min(openingsAreaInput, grossArea) : 0.0;
  final area = roundValue(math.max(0, grossArea - openingsArea), 3);

  // Stone
  final recommendedMaxReserve = math.max(
    reservePercent,
    ((spec.raw['scenario_policy'] as Map<String, dynamic>?)?['recommended_max_reserve_percent'] as num?)?.toDouble() ?? 15,
  );

  // Glue
  final glueKg = roundValue(area * glueRate, 6);
  final glueBags = glueKg > 0 ? (glueKg / glueBag).ceil() : 0;

  // Grout (conditional)
  final groutKg = needGrout == 1 ? roundValue(area * groutRate, 6) : 0.0;
  final groutBags = groutKg > 0 ? (groutKg / groutBag).ceil() : 0;

  // Primer (conditional)
  final primerL = needPrimer == 1 ? roundValue(area * primerRate * primerLayers, 6) : 0.0;
  final primerCans = primerL > 0 ? (primerL / primerCan).ceil() : 0;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final scenarioReservePercent = scenarioName == 'MIN'
        ? 0.0
        : scenarioName == 'MAX'
            ? recommendedMaxReserve
            : reservePercent;
    final multiplier = 1 + scenarioReservePercent / 100;
    final exactNeed = roundValue(area * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / packArea).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packArea, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'reserve_percent:$scenarioReservePercent',
        'scenario_policy:single_explicit_stone_reserve',
        'packaging:decor-stone-pack',
      ],
      keyFactors: {
        'reserve_percent': roundValue(scenarioReservePercent, 3),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'decor-stone-pack',
        packageSize: packArea,
        packagesCount: packageCount,
        unit: 'м\u00b2',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (inputMode == 0 && openingsAreaInput >= grossArea) {
    warnings.add('Площадь проёмов должна быть меньше общей площади стены');
  }
  if (stoneType == 2) {
    warnings.add('Для тяжёлого натурального камня проверьте несущую способность основания и монтажную систему');
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — сверьте фасовку и предусмотрите материал из одной партии');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Декоративный камень (${roundValue(packArea, 3)} м²/уп.)',
      quantity: roundValue(recScenario.exactNeed, 3),
      unit: 'м\u00b2',
      withReserve: roundValue(recScenario.purchaseQuantity, 3),
      purchaseQty: roundValue(recScenario.purchaseQuantity, 3),
      packageInfo: {
        'count': recScenario.buyPlan.packagesCount,
        'size': packArea,
        'packageUnit': 'упаковок',
      },
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Клей (${roundValue(glueBag, 3)} кг)',
      quantity: roundValue(glueKg, 3),
      unit: 'кг',
      withReserve: roundValue(glueBags * glueBag, 3),
      purchaseQty: roundValue(glueBags * glueBag, 3),
      packageInfo: {
        'count': glueBags,
        'size': glueBag,
        'packageUnit': 'мешков',
      },
      category: 'Монтаж',
    ),
  ];

  if (needGrout == 1 && groutBags > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Затирка (${roundValue(groutBag, 3)} кг)',
      quantity: roundValue(groutKg, 3),
      unit: 'кг',
      withReserve: roundValue(groutBags * groutBag, 3),
      purchaseQty: roundValue(groutBags * groutBag, 3),
      packageInfo: {
        'count': groutBags,
        'size': groutBag,
        'packageUnit': 'мешков',
      },
      category: 'Отделка',
    ));
  }

  if (needPrimer == 1 && primerCans > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Грунтовка (${roundValue(primerCan, 3)} л)',
      quantity: roundValue(primerL, 3),
      unit: 'л',
      withReserve: roundValue(primerCans * primerCan, 3),
      purchaseQty: roundValue(primerCans * primerCan, 3),
      packageInfo: {
        'count': primerCans,
        'size': primerCan,
        'packageUnit': 'канистр',
      },
      category: 'Подготовка',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'grossArea': roundValue(grossArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'inputMode': inputMode.toDouble(),
      'wallWidth': roundValue(wallWidth, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'stoneType': stoneType.toDouble(),
      'reservePercent': roundValue(reservePercent, 3),
      'packArea': roundValue(packArea, 3),
      'needGrout': needGrout.toDouble(),
      'needPrimer': needPrimer.toDouble(),
      'stoneM2': roundValue(recScenario.exactNeed, 3),
      'stoneArea': roundValue(recScenario.exactNeed, 3),
      'stonePackages': recScenario.buyPlan.packagesCount.toDouble(),
      'glueRate': roundValue(glueRate, 3),
      'glueBag': roundValue(glueBag, 3),
      'glueKg': roundValue(glueKg, 3),
      'glueBags': glueBags.toDouble(),
      'groutRate': roundValue(groutRate, 3),
      'groutBag': roundValue(groutBag, 3),
      'groutKg': roundValue(groutKg, 3),
      'groutBags': groutBags.toDouble(),
      'primerRate': roundValue(primerRate, 3),
      'primerLayers': primerLayers.toDouble(),
      'primerCan': roundValue(primerCan, 3),
      'primerL': roundValue(primerL, 3),
      'primerLiters': roundValue(primerL, 3),
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
