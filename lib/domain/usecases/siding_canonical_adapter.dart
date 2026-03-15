import 'dart:math' as math;

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

const Map<int, String> _sidingTypeLabels = {
  0: 'Виниловый сайдинг (0.732 м\u00b2)',
  1: 'Металлический сайдинг (0.9 м\u00b2)',
  2: 'Фиброцементный сайдинг (0.63 м\u00b2)',
};


bool hasCanonicalSidingInputs(Map<String, double> inputs) {
  return inputs.containsKey('sidingType') ||
      inputs.containsKey('facadeArea') ||
      inputs.containsKey('exteriorCorners');
}

Map<String, double> normalizeLegacySidingInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['facadeArea'] = (inputs['facadeArea'] ?? 100).toDouble();
  normalized['openingsArea'] = (inputs['openingsArea'] ?? 10).toDouble();
  normalized['perimeter'] = (inputs['perimeter'] ?? 40).toDouble();
  normalized['height'] = (inputs['height'] ?? 5).toDouble();
  normalized['sidingType'] = (inputs['sidingType'] ?? 0).toDouble();
  normalized['exteriorCorners'] = (inputs['exteriorCorners'] ?? 4).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalSiding(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(sidingSpecData);

  final normalized = hasCanonicalSidingInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacySidingInputs(inputs);

  final facadeArea = (normalized['facadeArea'] ?? defaultFor(spec, 'facadeArea', 100)).round().clamp(10, 1000);
  final openingsArea = (normalized['openingsArea'] ?? defaultFor(spec, 'openingsArea', 10)).round().clamp(0, 100);
  final perimeter = (normalized['perimeter'] ?? defaultFor(spec, 'perimeter', 40)).round().clamp(10, 200);
  final height = (normalized['height'] ?? defaultFor(spec, 'height', 5)).round().clamp(2, 15);
  final sidingType = (normalized['sidingType'] ?? defaultFor(spec, 'sidingType', 0)).round().clamp(0, 2);
  final exteriorCorners = (normalized['exteriorCorners'] ?? defaultFor(spec, 'exteriorCorners', 4)).round().clamp(0, 20);

  // Panel area
  final panelArea = (spec.materialRule<Map>('panel_areas')['$sidingType'] as num?)?.toDouble() ?? 0.732;

  // Formulas
  final netArea = facadeArea - openingsArea;
  final panels = (netArea / panelArea * spec.materialRule<num>('panel_reserve').toDouble()).ceil();
  final starter = ((perimeter + math.sqrt(openingsArea) * 4) / spec.materialRule<num>('starter_length').toDouble()).ceil();
  final jProfile = ((math.sqrt(openingsArea) * 4 * 2 + perimeter) * spec.materialRule<num>('j_reserve').toDouble() / spec.materialRule<num>('j_profile_length').toDouble()).ceil();
  final corners = (height * exteriorCorners * spec.materialRule<num>('corner_reserve').toDouble() / spec.materialRule<num>('corner_length').toDouble()).ceil();
  final finish = (perimeter * spec.materialRule<num>('starter_reserve').toDouble() / spec.materialRule<num>('finish_length').toDouble()).ceil();
  final screws = (netArea * spec.materialRule<num>('screws_per_m2').toDouble() * spec.materialRule<num>('screw_reserve').toDouble()).ceil();
  final battens = (netArea / spec.materialRule<num>('batten_step').toDouble() * spec.materialRule<num>('batten_reserve').toDouble()).ceil();
  final membrane = (netArea * spec.materialRule<num>('membrane_reserve').toDouble() / spec.materialRule<num>('membrane_roll').toDouble()).ceil();
  final sealant = (math.sqrt(netArea) * 4 / spec.materialRule<num>('sealant_per_perim').toDouble()).ceil();

  // Scenarios
  const packageLabel = 'siding-panel';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(panels * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'sidingType:$sidingType',
        'exteriorCorners:$exteriorCorners',
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
  if (netArea > spec.warningRule<num>('large_net_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку сайдинга');
  }
  if (openingsArea > facadeArea * spec.warningRule<num>('high_openings_ratio').toDouble()) {
    warnings.add('Большая площадь проёмов — проверьте количество доборных элементов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_sidingTypeLabels[sidingType]}',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Стартовая планка (${spec.materialRule<num>('starter_length').toDouble()} м)',
      quantity: starter.toDouble(),
      unit: 'шт',
      withReserve: starter.toDouble(),
      purchaseQty: starter.toInt(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'J-профиль (${spec.materialRule<num>('j_profile_length').toDouble()} м)',
      quantity: jProfile.toDouble(),
      unit: 'шт',
      withReserve: jProfile.toDouble(),
      purchaseQty: jProfile.toInt(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Наружный угол (${spec.materialRule<num>('corner_length').toDouble()} м)',
      quantity: corners.toDouble(),
      unit: 'шт',
      withReserve: corners.toDouble(),
      purchaseQty: corners.toInt(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Финишная планка (${spec.materialRule<num>('finish_length').toDouble()} м)',
      quantity: finish.toDouble(),
      unit: 'шт',
      withReserve: finish.toDouble(),
      purchaseQty: finish.toInt(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы',
      quantity: screws.toDouble(),
      unit: 'шт',
      withReserve: screws.toDouble(),
      purchaseQty: screws.toInt(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Обрешётка (м.п.)',
      quantity: battens.toDouble(),
      unit: 'м.п.',
      withReserve: battens.toDouble(),
      purchaseQty: battens.toInt(),
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Мембрана (${spec.materialRule<num>('membrane_roll').toDouble().round()} м\u00b2)',
      quantity: membrane.toDouble(),
      unit: 'рулонов',
      withReserve: membrane.toDouble(),
      purchaseQty: membrane.toInt(),
      category: 'Изоляция',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealant.toDouble(),
      unit: 'шт',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant.toInt(),
      category: 'Монтаж',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'facadeArea': facadeArea.toDouble(),
      'openingsArea': openingsArea.toDouble(),
      'perimeter': perimeter.toDouble(),
      'height': height.toDouble(),
      'sidingType': sidingType.toDouble(),
      'exteriorCorners': exteriorCorners.toDouble(),
      'panelArea': panelArea,
      'netArea': netArea.toDouble(),
      'panels': panels.toDouble(),
      'starter': starter.toDouble(),
      'jProfile': jProfile.toDouble(),
      'corners': corners.toDouble(),
      'finish': finish.toDouble(),
      'screws': screws.toDouble(),
      'battens': battens.toDouble(),
      'membrane': membrane.toDouble(),
      'sealant': sealant.toDouble(),
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
