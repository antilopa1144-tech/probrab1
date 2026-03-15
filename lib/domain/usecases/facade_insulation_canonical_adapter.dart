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

CanonicalCalculatorContractResult calculateCanonicalFacadeInsulation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(facadeInsulationSpecData);

  final area = math.max(10.0, math.min(2000.0, inputs['area'] ?? defaultFor(spec, 'area', 100)));
  final thickness = math.max(50.0, math.min(200.0, (inputs['thickness'] ?? defaultFor(spec, 'thickness', 100)).roundToDouble()));
  final insulationType = (inputs['insulationType'] ?? defaultFor(spec, 'insulationType', 0)).round().clamp(0, 1);
  final finishType = (inputs['finishType'] ?? defaultFor(spec, 'finishType', 0)).round().clamp(0, 2);

  // Plates
  final plates = (area * spec.materialRule<num>('plate_reserve').toDouble() / spec.materialRule<num>('plate_m2').toDouble()).ceil();

  // Glue
  final glueRate = (spec.materialRule<Map>('glue_kg_per_m2')['$insulationType'] as num?)?.toDouble() ?? (spec.materialRule<Map>('glue_kg_per_m2')['0'] as num?)?.toDouble() ?? 0.0;
  final glueBags = (area * glueRate / spec.materialRule<num>('glue_bag').toDouble()).ceil();

  // Dowels
  final dowelsPerM2 = (spec.materialRule<Map>('dowels_per_m2')['$insulationType'] as num?)?.toDouble() ?? (spec.materialRule<Map>('dowels_per_m2')['0'] as num?)?.toDouble() ?? 0.0;
  final dowels = (area * dowelsPerM2 * spec.materialRule<num>('dowel_reserve').toDouble()).ceil();

  // Mesh
  final meshRolls = (area * spec.materialRule<num>('mesh_reserve').toDouble() / spec.materialRule<num>('mesh_roll').toDouble()).ceil();

  // Armor
  final armorBags = (area * spec.materialRule<num>('armor_kg_per_m2').toDouble() / spec.materialRule<num>('armor_bag').toDouble()).ceil();

  // Primer
  final primerCans = (area * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can_l').toDouble()).ceil();

  // Decorative finish
  final decorConsumption = (spec.materialRule<Map>('decor_consumption')['$finishType'] as num?)?.toDouble() ?? (spec.materialRule<Map>('decor_consumption')['0'] as num?)?.toDouble() ?? 0.0;
  final decorBags = (area * decorConsumption / spec.materialRule<num>('decor_bag').toDouble()).ceil();

  // Starter profile
  final starterPcs = (math.sqrt(area) * 4 * spec.materialRule<num>('starter_reserve').toDouble() / spec.materialRule<num>('starter_length').toDouble()).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(plates * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    const packageLabel = 'insulation-plate';
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'finishType:$finishType',
        'thickness:${thickness.toInt()}',
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

  final insulationLabel = insulationType == 0 ? 'Минеральная вата' : 'ЭППС';
  final finishLabels = <int, String>{
    0: 'Декоративная штукатурка \u00abкороед\u00bb',
    1: 'Декоративная штукатурка \u00abшуба\u00bb',
    2: 'Тонкослойная штукатурка',
  };

  final warnings = <String>[];
  if (thickness >= spec.warningRule<num>('thick_insulation_threshold_mm').toDouble()) {
    warnings.add('Толстый утеплитель — рекомендуется двухслойная укладка');
  }
  if (insulationType == 1 && finishType != 2) {
    warnings.add('ЭППС — обязательна обработка поверхности для адгезии штукатурки');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '$insulationLabel (плиты ${spec.materialRule<num>('plate_m2').toDouble()} м\u00b2)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Клей для утеплителя 25кг',
      quantity: glueBags.toDouble(),
      unit: 'мешков',
      withReserve: glueBags.toDouble(),
      purchaseQty: glueBags.toInt(),
      category: 'Клей',
    ),
    CanonicalMaterialResult(
      name: 'Тарельчатые дюбели',
      quantity: dowels.toDouble(),
      unit: 'шт',
      withReserve: dowels.toDouble(),
      purchaseQty: dowels.toInt(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Армирующая сетка (${spec.materialRule<num>('mesh_roll').toInt()} м\u00b2)',
      quantity: meshRolls.toDouble(),
      unit: 'рулонов',
      withReserve: meshRolls.toDouble(),
      purchaseQty: meshRolls.toInt(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Армирующая шпаклёвка 25кг',
      quantity: armorBags.toDouble(),
      unit: 'мешков',
      withReserve: armorBags.toDouble(),
      purchaseQty: armorBags.toInt(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRule<num>('primer_can_l').toInt()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toInt(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: '${finishLabels[finishType]} 25кг',
      quantity: decorBags.toDouble(),
      unit: 'мешков',
      withReserve: decorBags.toDouble(),
      purchaseQty: decorBags.toInt(),
      category: 'Отделка',
    ),
    CanonicalMaterialResult(
      name: 'Стартовый профиль (${spec.materialRule<num>('starter_length').toInt()} м)',
      quantity: starterPcs.toDouble(),
      unit: 'шт',
      withReserve: starterPcs.toDouble(),
      purchaseQty: starterPcs.toInt(),
      category: 'Профиль',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'thickness': thickness,
      'insulationType': insulationType.toDouble(),
      'finishType': finishType.toDouble(),
      'plates': plates.toDouble(),
      'glueBags': glueBags.toDouble(),
      'dowels': dowels.toDouble(),
      'meshRolls': meshRolls.toDouble(),
      'armorBags': armorBags.toDouble(),
      'primerCans': primerCans.toDouble(),
      'decorBags': decorBags.toDouble(),
      'starterPcs': starterPcs.toDouble(),
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
