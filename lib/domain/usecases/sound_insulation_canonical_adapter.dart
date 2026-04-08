import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


CanonicalCalculatorContractResult calculateCanonicalSoundInsulation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(soundInsulationSpecData);

  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? defaultFor(spec, 'area', 30)));
  final surfaceType = (inputs['surfaceType'] ?? defaultFor(spec, 'surfaceType', 0)).round().clamp(0, 2);
  final system = (inputs['system'] ?? defaultFor(spec, 'system', 0)).round().clamp(0, 3);

  final perim = math.sqrt(area) * 4;
  final materials = <CanonicalMaterialResult>[];
  var primaryQty = 0;
  var primaryUnit = '\u0448\u0442';
  var primaryLabel = 'sound-insulation';

  // System 0: Basic GKL + Rockwool
  if (system == 0) {
    final rockwoolPlates = (area * spec.materialRule<num>('rockwool_reserve').toDouble() / spec.materialRule<num>('rockwool_plate').toDouble()).ceil();
    final gklSheets = (area * spec.materialRule<num>('rockwool_reserve').toDouble() * spec.materialRule<num>('gkl_reserve2layers').toDouble() / spec.materialRule<num>('gkl_sheet').toDouble()).ceil();
    final ppPcs = ((area / spec.materialRule<num>('pp_spacing').toDouble()) * spec.materialRule<num>('pp_length').toDouble() * spec.materialRule<num>('rockwool_reserve').toDouble() / spec.materialRule<num>('pp_length').toDouble()).ceil();
    final vibro = (area * spec.materialRule<num>('vibro_per_m2').toDouble() * spec.materialRule<num>('vibro_reserve').toDouble()).ceil();
    final vibroTape = ((area / spec.materialRule<num>('pp_spacing').toDouble()) * spec.materialRule<num>('pp_length').toDouble() * spec.materialRule<num>('rockwool_reserve').toDouble() / spec.materialRule<num>('vibro_tape_roll').toDouble()).ceil();
    final screws = (gklSheets * 25 / 200).ceil();

    primaryQty = rockwoolPlates;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'rockwool-plate';

    materials.addAll([
      CanonicalMaterialResult(name: 'Rockwool \u043f\u043b\u0438\u0442\u044b', quantity: rockwoolPlates.toDouble(), unit: '\u0448\u0442', withReserve: rockwoolPlates.toDouble(), purchaseQty: rockwoolPlates.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0413\u041a\u041b \u043b\u0438\u0441\u0442\u044b', quantity: gklSheets.toDouble(), unit: '\u0448\u0442', withReserve: gklSheets.toDouble(), purchaseQty: gklSheets.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u041f\u041f 3\u043c', quantity: ppPcs.toDouble(), unit: '\u0448\u0442', withReserve: ppPcs.toDouble(), purchaseQty: ppPcs.toDouble(), category: '\u041a\u0430\u0440\u043a\u0430\u0441'),
      CanonicalMaterialResult(name: '\u0412\u0438\u0431\u0440\u043e\u043f\u043e\u0434\u0432\u0435\u0441\u044b', quantity: vibro.toDouble(), unit: '\u0448\u0442', withReserve: vibro.toDouble(), purchaseQty: vibro.toDouble(), category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
      CanonicalMaterialResult(name: '\u0412\u0438\u0431\u0440\u043e\u043b\u0435\u043d\u0442\u0430', quantity: vibroTape.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: vibroTape.toDouble(), purchaseQty: vibroTape.toDouble(), category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f'),
      CanonicalMaterialResult(name: '\u0421\u0430\u043c\u043e\u0440\u0435\u0437\u044b (\u0443\u043f\u0430\u043a\u043e\u0432\u043a\u0438 \u043f\u043e 200)', quantity: screws.toDouble(), unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a', withReserve: screws.toDouble(), purchaseQty: screws.toDouble(), category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
    ]);
  }

  // System 1: ZIPS panels
  if (system == 1) {
    final zipsPanels = (area * spec.materialRule<num>('zips_reserve').toDouble() / spec.materialRule<num>('zips_plate').toDouble()).ceil();
    final dubels = (zipsPanels * spec.materialRule<num>('zips_dubels_per_panel').toDouble() * spec.materialRule<num>('zips_dubel_reserve').toDouble()).ceil();
    final gklOverlay = (area * spec.materialRule<num>('zips_reserve').toDouble() / spec.materialRule<num>('gkl_sheet').toDouble()).ceil();

    primaryQty = zipsPanels;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'zips-panel';

    materials.addAll([
      CanonicalMaterialResult(name: '\u0417\u0418\u041f\u0421 \u043f\u0430\u043d\u0435\u043b\u0438', quantity: zipsPanels.toDouble(), unit: '\u0448\u0442', withReserve: zipsPanels.toDouble(), purchaseQty: zipsPanels.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0414\u044e\u0431\u0435\u043b\u0438 \u0434\u043b\u044f \u0417\u0418\u041f\u0421', quantity: dubels.toDouble(), unit: '\u0448\u0442', withReserve: dubels.toDouble(), purchaseQty: dubels.toDouble(), category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
      CanonicalMaterialResult(name: '\u0413\u041a\u041b \u043e\u0431\u043b\u0438\u0446\u043e\u0432\u043a\u0430', quantity: gklOverlay.toDouble(), unit: '\u0448\u0442', withReserve: gklOverlay.toDouble(), purchaseQty: gklOverlay.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
    ]);
  }

  // System 2: Floating floor
  if (system == 2) {
    final mats = (area * spec.materialRule<num>('float_reserve').toDouble() / spec.materialRule<num>('float_mat_roll').toDouble()).ceil();
    final dampTape = (perim / spec.materialRule<num>('damp_tape_roll').toDouble()).ceil();
    final screedBags = (area * spec.materialRule<num>('screed_thickness').toDouble() * spec.materialRule<num>('screed_density').toDouble() / spec.materialRule<num>('screed_bag').toDouble()).ceil();

    primaryQty = mats;
    primaryUnit = '\u0440\u0443\u043b\u043e\u043d\u043e\u0432';
    primaryLabel = 'float-mat';

    materials.addAll([
      CanonicalMaterialResult(name: '\u0417\u0432\u0443\u043a\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u043e\u043d\u043d\u044b\u0435 \u043c\u0430\u0442\u044b', quantity: mats.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: mats.toDouble(), purchaseQty: mats.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0414\u0435\u043c\u043f\u0444\u0435\u0440\u043d\u0430\u044f \u043b\u0435\u043d\u0442\u0430', quantity: dampTape.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: dampTape.toDouble(), purchaseQty: dampTape.toDouble(), category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f'),
      CanonicalMaterialResult(name: '\u0421\u0442\u044f\u0436\u043a\u0430 50 \u043a\u0433', quantity: screedBags.toDouble(), unit: '\u043c\u0435\u0448\u043a\u043e\u0432', withReserve: screedBags.toDouble(), purchaseQty: screedBags.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
    ]);
  }

  // System 3: Acoustic ceiling
  if (system == 3) {
    final rockwoolPlates = (area * spec.materialRule<num>('rockwool_reserve').toDouble() / spec.materialRule<num>('rockwool_plate').toDouble()).ceil();
    final gklSheets = (area * spec.materialRule<num>('rockwool_reserve').toDouble() * spec.materialRule<num>('gkl_reserve2layers').toDouble() / spec.materialRule<num>('gkl_sheet').toDouble()).ceil();
    final vibro = (area * spec.materialRule<num>('vibro_per_m2').toDouble() * spec.materialRule<num>('vibro_reserve').toDouble()).ceil();

    primaryQty = rockwoolPlates;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'acoustic-ceiling';

    materials.addAll([
      CanonicalMaterialResult(name: 'Rockwool \u043f\u043b\u0438\u0442\u044b', quantity: rockwoolPlates.toDouble(), unit: '\u0448\u0442', withReserve: rockwoolPlates.toDouble(), purchaseQty: rockwoolPlates.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0413\u041a\u041b \u043b\u0438\u0441\u0442\u044b', quantity: gklSheets.toDouble(), unit: '\u0448\u0442', withReserve: gklSheets.toDouble(), purchaseQty: gklSheets.toDouble(), category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0412\u0438\u0431\u0440\u043e\u043f\u043e\u0434\u0432\u0435\u0441\u044b', quantity: vibro.toDouble(), unit: '\u0448\u0442', withReserve: vibro.toDouble(), purchaseQty: vibro.toDouble(), category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
    ]);
  }

  // Common: sealant + sealing tape
  final sealant = (perim * 2 / spec.materialRule<num>('sealant_per_perim').toDouble()).ceil();
  final sealTape = (perim * 2 * spec.materialRule<num>('seal_tape_reserve').toDouble() / spec.materialRule<num>('seal_tape_roll').toDouble()).ceil();

  materials.addAll([
    CanonicalMaterialResult(name: '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u043a', quantity: sealant.toDouble(), unit: '\u0442\u044e\u0431\u0438\u043a\u043e\u0432', withReserve: sealant.toDouble(), purchaseQty: sealant.toDouble(), category: '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u0437\u0430\u0446\u0438\u044f'),
    CanonicalMaterialResult(name: '\u0423\u043f\u043b\u043e\u0442\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u0430\u044f \u043b\u0435\u043d\u0442\u0430 30\u043c', quantity: sealTape.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: sealTape.toDouble(), purchaseQty: sealTape.toDouble(), category: '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u0437\u0430\u0446\u0438\u044f'),
  ]);

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('insulation', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(primaryQty * accuracyMult * multiplier, 6);
    final packageSize = spec.packagingRule<num>('package_size').toDouble();
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packageSize, 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'surfaceType:$surfaceType',
        'system:$system',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
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
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }
  if (system == 1) {
    warnings.add('\u0421\u0438\u0441\u0442\u0435\u043c\u0430 \u0417\u0418\u041f\u0421 \u0442\u0440\u0435\u0431\u0443\u0435\u0442 \u0440\u043e\u0432\u043d\u043e\u0433\u043e \u043e\u0441\u043d\u043e\u0432\u0430\u043d\u0438\u044f');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': roundValue(area, 3),
      'surfaceType': surfaceType.toDouble(),
      'system': system.toDouble(),
      'perim': roundValue(perim, 3),
      'primaryQty': primaryQty.toDouble(),
      'sealant': sealant.toDouble(),
      'sealTape': sealTape.toDouble(),
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
