import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';




CanonicalCalculatorContractResult calculateCanonicalPanels3d(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(panels3dSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 10)).clamp(1.0, 500.0);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 4)).clamp(1.0, 12.0);
  final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.7)).clamp(2.0, 4.0);
  final panelSize = (inputs['panelSize'] ?? defaultFor(spec, 'panelSize', 50)).clamp(25.0, 100.0);
  final paintable = (inputs['paintable'] ?? defaultFor(spec, 'paintable', 0)).round() == 1 ? 1 : 0;
  final withVarnish = (inputs['withVarnish'] ?? defaultFor(spec, 'withVarnish', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? roundValue(length * height, 3) : areaInput;

  // Panels
  final panelArea = (panelSize / 100) * (panelSize / 100);
  final panels = (area / panelArea * spec.materialRule<num>('panel_reserve').toDouble()).ceil();

  // Glue
  final glueKg = area * spec.materialRule<num>('glue_kg_per_m2').toDouble();
  final glueBags = (glueKg / spec.materialRule<num>('glue_bag').toDouble()).ceil();

  // Primer
  final primerL = area * spec.materialRule<num>('primer_l_per_m2').toDouble();
  final primerCans = (primerL / spec.materialRule<num>('primer_can').toDouble()).ceil();

  // Putty
  final puttyKg = area * spec.materialRule<num>('putty_kg_per_m2').toDouble();
  final puttyBags = (puttyKg / spec.materialRule<num>('putty_bag').toDouble()).ceil();

  // Paint (conditional)
  final paintL = paintable == 1 ? area * spec.materialRule<num>('paint_l_per_m2').toDouble() : 0.0;
  final paintCans = paintable == 1 ? (paintL / spec.materialRule<num>('paint_can').toDouble()).ceil() : 0;

  // Varnish (conditional)
  final varnishL = withVarnish == 1 ? area * spec.materialRule<num>('varnish_l_per_m2').toDouble() : 0.0;
  final varnishCans = withVarnish == 1 ? (varnishL / spec.materialRule<num>('varnish_can').toDouble()).ceil() : 0;

  // Molding
  final perimeter = inputMode == 1
      ? 2 * (length + height / 2.7 * length)
      : 4 * math.sqrt(area);
  final moldingM = perimeter;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(panels * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'panelSize:$panelSize',
        'paintable:$paintable',
        'withVarnish:$withVarnish',
        'packaging:3d-panel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: '3d-panel',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку панелей');
  }
  if (paintable == 1 && withVarnish == 1) {
    warnings.add('Покраска и лакировка одновременно — убедитесь в совместимости составов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '3D-панели',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Клей для панелей (${spec.materialRule<num>('glue_bag').toDouble().round()} кг)',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags.toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (${spec.materialRule<num>('primer_can').toDouble().round()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toDouble(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка (${spec.materialRule<num>('putty_bag').toDouble().round()} кг)',
      quantity: puttyBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyBags.toDouble(),
      purchaseQty: puttyBags.toDouble(),
      category: 'Отделка',
    ),
  ];

  if (paintable == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Краска (${spec.materialRule<num>('paint_can').toDouble().round()} л)',
      quantity: paintCans.toDouble(),
      unit: 'банок',
      withReserve: paintCans.toDouble(),
      purchaseQty: paintCans.toDouble(),
      category: 'Отделка',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Молдинги (п.м.)',
    quantity: roundValue(moldingM, 2),
    unit: 'п.м.',
    withReserve: moldingM.ceilToDouble(),
    purchaseQty: moldingM.ceil().toDouble(),
    category: 'Профиль',
  ));

  if (withVarnish == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Лак (${spec.materialRule<num>('varnish_can').toDouble().round()} л)',
      quantity: varnishCans.toDouble(),
      unit: 'банок',
      withReserve: varnishCans.toDouble(),
      purchaseQty: varnishCans.toDouble(),
      category: 'Отделка',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'panelSize': panelSize,
      'panelArea': roundValue(panelArea, 4),
      'paintable': paintable.toDouble(),
      'withVarnish': withVarnish.toDouble(),
      'panels': panels.toDouble(),
      'glueKg': roundValue(glueKg, 3),
      'glueBags': glueBags.toDouble(),
      'primerL': roundValue(primerL, 3),
      'primerCans': primerCans.toDouble(),
      'puttyKg': roundValue(puttyKg, 3),
      'puttyBags': puttyBags.toDouble(),
      'paintL': roundValue(paintL, 3),
      'paintCans': paintCans.toDouble(),
      'varnishL': roundValue(varnishL, 3),
      'varnishCans': varnishCans.toDouble(),
      'perimeter': roundValue(perimeter, 3),
      'moldingM': roundValue(moldingM, 3),
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
