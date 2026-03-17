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

CanonicalCalculatorContractResult calculateCanonicalCeilingInsulation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(ceilingInsulationSpecData);

  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 40)));
  final thicknessRaw = (inputs['thickness'] ?? defaultFor(spec, 'thickness', 100)).round();
  final allowedThick = [50, 100, 150, 200];
  final thickness = allowedThick.contains(thicknessRaw) ? thicknessRaw : 100;
  final insulationType = (inputs['insulationType'] ?? defaultFor(spec, 'insulationType', 0)).round().clamp(0, 3);
  final layersRaw = (inputs['layers'] ?? defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;

  final materials = <CanonicalMaterialResult>[];
  var primaryQty = 0;
  var primaryUnit = '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a';
  var primaryLabel = 'insulation-pack';

  // Mineral plates (type 0)
  if (insulationType == 0) {
    final packs = (area * spec.materialRule<num>('plate_reserve').toDouble() * layers / spec.materialRule<num>('plate_pack_m2').toDouble()).ceil();
    primaryQty = packs;
    primaryUnit = '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a';
    primaryLabel = 'mineral-plate-pack';
    materials.add(CanonicalMaterialResult(
      name: '\u041c\u0438\u043d\u0435\u0440\u0430\u043b\u043e\u0432\u0430\u0442\u043d\u044b\u0435 \u043f\u043b\u0438\u0442\u044b',
      quantity: packs.toDouble(),
      unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a',
      withReserve: packs.toDouble(),
      purchaseQty: packs.toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // Mineral rolls (type 1)
  if (insulationType == 1) {
    final rollArea = (spec.materialRule<Map>('roll_areas')['$thickness'] as num?)?.toDouble() ?? (spec.materialRule<Map>('roll_areas')['100'] as num?)?.toDouble() ?? 5;
    final rolls = (area * spec.materialRule<num>('plate_reserve').toDouble() * layers / rollArea).ceil();
    primaryQty = rolls;
    primaryUnit = '\u0440\u0443\u043b\u043e\u043d\u043e\u0432';
    primaryLabel = 'mineral-roll';
    materials.add(CanonicalMaterialResult(
      name: '\u041c\u0438\u043d\u0435\u0440\u0430\u043b\u043e\u0432\u0430\u0442\u043d\u044b\u0435 \u0440\u0443\u043b\u043e\u043d\u044b',
      quantity: rolls.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: rolls.toDouble(),
      purchaseQty: rolls.toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // EPPS (type 2)
  if (insulationType == 2) {
    final plates = (area * spec.materialRule<num>('plate_reserve').toDouble() * layers / spec.materialRule<num>('epps_plate').toDouble()).ceil();
    primaryQty = plates;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'epps-plate';
    materials.add(CanonicalMaterialResult(
      name: '\u042d\u041f\u041f\u0421 \u043f\u043b\u0438\u0442\u044b',
      quantity: plates.toDouble(),
      unit: '\u0448\u0442',
      withReserve: plates.toDouble(),
      purchaseQty: plates.toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // Ecowool (type 3)
  if (insulationType == 3) {
    final kg = area * (thickness / 1000.0) * spec.materialRule<num>('ecowool_density').toDouble() * layers;
    final bags = (kg / spec.materialRule<num>('ecowool_bag').toDouble()).ceil();
    primaryQty = bags;
    primaryUnit = '\u043c\u0435\u0448\u043a\u043e\u0432';
    primaryLabel = 'ecowool-bag';
    materials.add(CanonicalMaterialResult(
      name: '\u042d\u043a\u043e\u0432\u0430\u0442\u0430 15 \u043a\u0433',
      quantity: bags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: bags.toDouble(),
      purchaseQty: bags.toDouble(),
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // Vapor barrier (mineral types only)
  var vaporRolls = 0;
  if (insulationType == 0 || insulationType == 1) {
    vaporRolls = (area * spec.materialRule<num>('vapor_reserve').toDouble() / spec.materialRule<num>('vapor_roll').toDouble()).ceil();
    materials.add(CanonicalMaterialResult(
      name: '\u041f\u0430\u0440\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u044f 50 \u043c\u00b2',
      quantity: vaporRolls.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: vaporRolls.toDouble(),
      purchaseQty: vaporRolls.toDouble(),
      category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f',
    ));
  }

  // Tape
  final tapeRolls = (area / spec.materialRule<num>('tape_per_area').toDouble()).ceil() * 10;
  materials.add(CanonicalMaterialResult(
    name: '\u0421\u043a\u043e\u0442\u0447 \u0441\u043e\u0435\u0434\u0438\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439',
    quantity: tapeRolls.toDouble(),
    unit: '\u043c',
    withReserve: tapeRolls.toDouble(),
    purchaseQty: tapeRolls.toDouble(),
    category: '\u0420\u0430\u0441\u0445\u043e\u0434\u043d\u044b\u0435',
  ));

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(primaryQty * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'thickness:$thickness',
        'layers:$layers',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: primaryLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: primaryUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (thickness < spec.warningRule<num>('thin_insulation_threshold_mm').toDouble()) {
    warnings.add('\u0422\u043e\u043d\u043a\u0438\u0439 \u0441\u043b\u043e\u0439 \u0443\u0442\u0435\u043f\u043b\u0438\u0442\u0435\u043b\u044f \u2014 \u044d\u0444\u0444\u0435\u043a\u0442\u0438\u0432\u043d\u043e\u0441\u0442\u044c \u0441\u043d\u0438\u0436\u0435\u043d\u0430');
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'thickness': thickness.toDouble(),
      'insulationType': insulationType.toDouble(),
      'layers': layers.toDouble(),
      'primaryQty': primaryQty.toDouble(),
      'vaporRolls': vaporRolls.toDouble(),
      'tapeRolls': tapeRolls.toDouble(),
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
