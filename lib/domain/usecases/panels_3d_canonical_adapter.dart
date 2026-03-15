import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec instance ─── */

const Panels3dCanonicalSpec panels3dCanonicalSpecV1 = Panels3dCanonicalSpec(
  calculatorId: 'panels-3d',
  formulaVersion: 'panels-3d-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 10, min: 1, max: 500),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 4, min: 1, max: 12),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 4),
    CanonicalInputField(key: 'panelSize', unit: 'cm', defaultValue: 50, min: 25, max: 100),
    CanonicalInputField(key: 'paintable', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'withVarnish', defaultValue: 1, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: Panels3dPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: Panels3dMaterialRules(
    panelReserve: 1.10,
    glueKgPerM2: 5.0,
    primerLPerM2: 0.18,
    puttyKgPerM2: 1.0,
    paintLPerM2: 0.24,
    varnishLPerM2: 0.08,
    glueBag: 5,
    primerCan: 5,
    puttyBag: 5,
    paintCan: 3,
    varnishCan: 1,
  ),
  warningRules: Panels3dWarningRules(largeAreaThresholdM2: 100),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(Panels3dCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(Panels3dCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(Panels3dCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalPanels3d(
  Map<String, double> inputs, {
  Panels3dCanonicalSpec spec = panels3dCanonicalSpecV1,
}) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? _defaultFor(spec, 'area', 10)).clamp(1.0, 500.0);
  final length = (inputs['length'] ?? _defaultFor(spec, 'length', 4)).clamp(1.0, 12.0);
  final height = (inputs['height'] ?? _defaultFor(spec, 'height', 2.7)).clamp(2.0, 4.0);
  final panelSize = (inputs['panelSize'] ?? _defaultFor(spec, 'panelSize', 50)).clamp(25.0, 100.0);
  final paintable = (inputs['paintable'] ?? _defaultFor(spec, 'paintable', 0)).round() == 1 ? 1 : 0;
  final withVarnish = (inputs['withVarnish'] ?? _defaultFor(spec, 'withVarnish', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? _roundValue(length * height, 3) : areaInput;

  // Panels
  final panelArea = (panelSize / 100) * (panelSize / 100);
  final panels = (area / panelArea * spec.materialRules.panelReserve).ceil();

  // Glue
  final glueKg = area * spec.materialRules.glueKgPerM2;
  final glueBags = (glueKg / spec.materialRules.glueBag).ceil();

  // Primer
  final primerL = area * spec.materialRules.primerLPerM2;
  final primerCans = (primerL / spec.materialRules.primerCan).ceil();

  // Putty
  final puttyKg = area * spec.materialRules.puttyKgPerM2;
  final puttyBags = (puttyKg / spec.materialRules.puttyBag).ceil();

  // Paint (conditional)
  final paintL = paintable == 1 ? area * spec.materialRules.paintLPerM2 : 0.0;
  final paintCans = paintable == 1 ? (paintL / spec.materialRules.paintCan).ceil() : 0;

  // Varnish (conditional)
  final varnishL = withVarnish == 1 ? area * spec.materialRules.varnishLPerM2 : 0.0;
  final varnishCans = withVarnish == 1 ? (varnishL / spec.materialRules.varnishCan).ceil() : 0;

  // Molding
  final perimeter = inputMode == 1
      ? 2 * (length + height / 2.7 * length)
      : 4 * math.sqrt(area);
  final moldingM = perimeter;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(panels * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'panelSize:$panelSize',
        'paintable:$paintable',
        'withVarnish:$withVarnish',
        'packaging:3d-panel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
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
  if (area > spec.warningRules.largeAreaThresholdM2) {
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
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Клей для панелей (${spec.materialRules.glueBag.round()} кг)',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags,
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (${spec.materialRules.primerCan.round()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Шпаклёвка (${spec.materialRules.puttyBag.round()} кг)',
      quantity: puttyBags.toDouble(),
      unit: 'мешков',
      withReserve: puttyBags.toDouble(),
      purchaseQty: puttyBags,
      category: 'Отделка',
    ),
  ];

  if (paintable == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Краска (${spec.materialRules.paintCan.round()} л)',
      quantity: paintCans.toDouble(),
      unit: 'банок',
      withReserve: paintCans.toDouble(),
      purchaseQty: paintCans,
      category: 'Отделка',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Молдинги (п.м.)',
    quantity: _roundValue(moldingM, 2),
    unit: 'п.м.',
    withReserve: moldingM.ceilToDouble(),
    purchaseQty: moldingM.ceil(),
    category: 'Профиль',
  ));

  if (withVarnish == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Лак (${spec.materialRules.varnishCan.round()} л)',
      quantity: varnishCans.toDouble(),
      unit: 'банок',
      withReserve: varnishCans.toDouble(),
      purchaseQty: varnishCans,
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
      'panelArea': _roundValue(panelArea, 4),
      'paintable': paintable.toDouble(),
      'withVarnish': withVarnish.toDouble(),
      'panels': panels.toDouble(),
      'glueKg': _roundValue(glueKg, 3),
      'glueBags': glueBags.toDouble(),
      'primerL': _roundValue(primerL, 3),
      'primerCans': primerCans.toDouble(),
      'puttyKg': _roundValue(puttyKg, 3),
      'puttyBags': puttyBags.toDouble(),
      'paintL': _roundValue(paintL, 3),
      'paintCans': paintCans.toDouble(),
      'varnishL': _roundValue(varnishL, 3),
      'varnishCans': varnishCans.toDouble(),
      'perimeter': _roundValue(perimeter, 3),
      'moldingM': _roundValue(moldingM, 3),
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
