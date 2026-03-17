import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

CanonicalCalculatorContractResult calculateCanonicalSoftRoofing(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(softRoofingSpecData);

  final roofArea = math.max(10.0, math.min(500.0, inputs['roofArea'] ?? defaultFor(spec, 'roofArea', 80)));
  final slope = math.max(12.0, math.min(60.0, inputs['slope'] ?? defaultFor(spec, 'slope', 30)));
  final ridgeLength = math.max(0.0, math.min(50.0, inputs['ridgeLength'] ?? defaultFor(spec, 'ridgeLength', 8)));
  final eaveLength = math.max(0.0, math.min(100.0, inputs['eaveLength'] ?? defaultFor(spec, 'eaveLength', 20)));
  final valleyLength = math.max(0.0, math.min(30.0, inputs['valleyLength'] ?? defaultFor(spec, 'valleyLength', 0)));

  // Packs
  final packs = (roofArea / spec.materialRule<num>('pack_area').toDouble() * spec.materialRule<num>('pack_reserve').toDouble()).ceil();

  // Underlayment
  int underlaymentRolls;
  if (slope < spec.materialRule<num>('slope_threshold').toDouble()) {
    underlaymentRolls = (roofArea * spec.materialRule<num>('underlayment_full_reserve').toDouble() / spec.materialRule<num>('underlayment_roll').toDouble()).ceil();
  } else {
    final criticalArea = (eaveLength + valleyLength + ridgeLength) * spec.materialRule<num>('critical_zone_width').toDouble() * spec.materialRule<num>('underlayment_full_reserve').toDouble();
    underlaymentRolls = (criticalArea / spec.materialRule<num>('underlayment_roll').toDouble()).ceil();
  }

  // Valley
  final valleyRolls = valleyLength > 0 ? (valleyLength * spec.materialRule<num>('valley_reserve').toDouble() / spec.materialRule<num>('valley_roll').toDouble()).ceil() : 0;

  // Mastic
  final masticKg = (ridgeLength + eaveLength + valleyLength) * spec.materialRule<num>('mastic_linear_rate').toDouble() + roofArea * spec.materialRule<num>('mastic_area_rate').toDouble();
  final masticBuckets = (masticKg / spec.materialRule<num>('mastic_bucket').toDouble()).ceil();

  // Nails
  final nailsKg = (roofArea * spec.materialRule<num>('nails_per_m2').toDouble() / spec.materialRule<num>('nails_per_kg').toDouble() * spec.materialRule<num>('nail_reserve').toDouble()).ceil();

  // Eave strips
  final eaveStrips = (eaveLength / spec.materialRule<num>('eave_strip_length').toDouble() * spec.materialRule<num>('eave_reserve').toDouble()).ceil();

  // Wind strips
  final windStrips = (eaveLength * spec.materialRule<num>('wind_strip_ratio').toDouble() / spec.materialRule<num>('eave_strip_length').toDouble() * spec.materialRule<num>('eave_reserve').toDouble()).ceil();

  // Ridge shingles
  final ridgeShingles = (ridgeLength / spec.materialRule<num>('ridge_shingle_step').toDouble() * spec.materialRule<num>('ridge_reserve').toDouble()).ceil();

  // OSB sheets
  final osbSheets = (roofArea / spec.materialRule<num>('osb_sheet').toDouble() * spec.materialRule<num>('osb_reserve').toDouble()).ceil();

  // Vent outputs
  final ventOutputs = (roofArea / spec.materialRule<num>('vent_per_area').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(packs * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    const packageLabel = 'shingle-pack';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'slope:${slope.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (slope < spec.warningRule<num>('low_slope_threshold').toDouble()) {
    warnings.add('Уклон менее 18\u00b0 — подкладочный ковёр укладывается по всей площади');
  }
  if (valleyLength > 0) {
    warnings.add('Ендовы — наиболее уязвимые места, рекомендуется усиленная гидроизоляция');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Гибкая черепица (${spec.materialRule<num>('pack_area').toDouble()} м\u00b2/уп)',
      quantity: recScenario.exactNeed,
      unit: 'упаковок',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Подкладочный ковёр (${spec.materialRule<num>('underlayment_roll').toInt()} м\u00b2)',
      quantity: underlaymentRolls.toDouble(),
      unit: 'рулонов',
      withReserve: underlaymentRolls.toDouble(),
      purchaseQty: underlaymentRolls.toDouble(),
      category: 'Подкладка',
    ),
  ];

  if (valleyRolls > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Ендовный ковёр (${spec.materialRule<num>('valley_roll').toInt()} м)',
      quantity: valleyRolls.toDouble(),
      unit: 'рулонов',
      withReserve: valleyRolls.toDouble(),
      purchaseQty: valleyRolls.toDouble(),
      category: 'Подкладка',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Мастика (ведро ${spec.materialRule<num>('mastic_bucket').toInt()} кг)',
      quantity: masticBuckets.toDouble(),
      unit: 'вёдер',
      withReserve: masticBuckets.toDouble(),
      purchaseQty: masticBuckets.toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Гвозди кровельные',
      quantity: nailsKg.toDouble(),
      unit: 'кг',
      withReserve: nailsKg.toDouble(),
      purchaseQty: nailsKg.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Карнизные планки (${spec.materialRule<num>('eave_strip_length').toInt()} м)',
      quantity: eaveStrips.toDouble(),
      unit: 'шт',
      withReserve: eaveStrips.toDouble(),
      purchaseQty: eaveStrips.toDouble(),
      category: 'Доборные',
    ),
    CanonicalMaterialResult(
      name: 'Ветровые планки (${spec.materialRule<num>('eave_strip_length').toInt()} м)',
      quantity: windStrips.toDouble(),
      unit: 'шт',
      withReserve: windStrips.toDouble(),
      purchaseQty: windStrips.toDouble(),
      category: 'Доборные',
    ),
    CanonicalMaterialResult(
      name: 'Коньково-карнизная черепица',
      quantity: ridgeShingles.toDouble(),
      unit: 'шт',
      withReserve: ridgeShingles.toDouble(),
      purchaseQty: ridgeShingles.toDouble(),
      category: 'Доборные',
    ),
    CanonicalMaterialResult(
      name: 'ОСП (${spec.materialRule<num>('osb_sheet').toDouble()} м\u00b2)',
      quantity: osbSheets.toDouble(),
      unit: 'листов',
      withReserve: osbSheets.toDouble(),
      purchaseQty: osbSheets.toDouble(),
      category: 'Основание',
    ),
    CanonicalMaterialResult(
      name: 'Вентиляционные выходы',
      quantity: ventOutputs.toDouble(),
      unit: 'шт',
      withReserve: ventOutputs.toDouble(),
      purchaseQty: ventOutputs.toDouble(),
      category: 'Вентиляция',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofArea': roundValue(roofArea, 3),
      'slope': slope,
      'ridgeLength': roundValue(ridgeLength, 3),
      'eaveLength': roundValue(eaveLength, 3),
      'valleyLength': roundValue(valleyLength, 3),
      'packs': packs.toDouble(),
      'underlaymentRolls': underlaymentRolls.toDouble(),
      'valleyRolls': valleyRolls.toDouble(),
      'masticKg': roundValue(masticKg, 3),
      'masticBuckets': masticBuckets.toDouble(),
      'nailsKg': nailsKg.toDouble(),
      'eaveStrips': eaveStrips.toDouble(),
      'windStrips': windStrips.toDouble(),
      'ridgeShingles': ridgeShingles.toDouble(),
      'osbSheets': osbSheets.toDouble(),
      'ventOutputs': ventOutputs.toDouble(),
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
