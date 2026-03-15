import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class SoundInsulationPackagingRules {
  final String unit;
  final double packageSize;

  const SoundInsulationPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class SoundInsulationMaterialRules {
  final double rockwoolPlate;
  final double rockwoolReserve;
  final double gklSheet;
  final double gklReserve2layers;
  final double ppSpacing;
  final double ppLength;
  final double vibroPerM2;
  final double vibroReserve;
  final double vibroTapeRoll;
  final double zipsPlate;
  final double zipsReserve;
  final double zipsDubelsPerPanel;
  final double zipsDubelReserve;
  final double floatMatRoll;
  final double floatReserve;
  final double dampTapeRoll;
  final double screedThickness;
  final double screedDensity;
  final double screedBag;
  final double sealantPerPerim;
  final double sealTapeRoll;
  final double sealTapeReserve;

  const SoundInsulationMaterialRules({
    required this.rockwoolPlate,
    required this.rockwoolReserve,
    required this.gklSheet,
    required this.gklReserve2layers,
    required this.ppSpacing,
    required this.ppLength,
    required this.vibroPerM2,
    required this.vibroReserve,
    required this.vibroTapeRoll,
    required this.zipsPlate,
    required this.zipsReserve,
    required this.zipsDubelsPerPanel,
    required this.zipsDubelReserve,
    required this.floatMatRoll,
    required this.floatReserve,
    required this.dampTapeRoll,
    required this.screedThickness,
    required this.screedDensity,
    required this.screedBag,
    required this.sealantPerPerim,
    required this.sealTapeRoll,
    required this.sealTapeReserve,
  });
}

class SoundInsulationWarningRules {
  final double largeAreaThresholdM2;
  final bool professionalSystemNote;

  const SoundInsulationWarningRules({
    required this.largeAreaThresholdM2,
    required this.professionalSystemNote,
  });
}

class SoundInsulationCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final SoundInsulationPackagingRules packagingRules;
  final SoundInsulationMaterialRules materialRules;
  final SoundInsulationWarningRules warningRules;

  const SoundInsulationCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const SoundInsulationCanonicalSpec soundInsulationCanonicalSpecV1 = SoundInsulationCanonicalSpec(
  calculatorId: 'sound-insulation',
  formulaVersion: 'sound-insulation-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 30, min: 1, max: 500),
    CanonicalInputField(key: 'surfaceType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'system', defaultValue: 0, min: 0, max: 3),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: SoundInsulationPackagingRules(
    unit: '\u0448\u0442',
    packageSize: 1,
  ),
  materialRules: SoundInsulationMaterialRules(
    rockwoolPlate: 0.6,
    rockwoolReserve: 1.1,
    gklSheet: 3,
    gklReserve2layers: 2,
    ppSpacing: 0.6,
    ppLength: 3,
    vibroPerM2: 2,
    vibroReserve: 1.05,
    vibroTapeRoll: 30,
    zipsPlate: 0.72,
    zipsReserve: 1.1,
    zipsDubelsPerPanel: 6,
    zipsDubelReserve: 1.05,
    floatMatRoll: 20,
    floatReserve: 1.1,
    dampTapeRoll: 25,
    screedThickness: 0.05,
    screedDensity: 1800,
    screedBag: 50,
    sealantPerPerim: 20,
    sealTapeRoll: 30,
    sealTapeReserve: 1.1,
  ),
  warningRules: SoundInsulationWarningRules(
    largeAreaThresholdM2: 200,
    professionalSystemNote: true,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(SoundInsulationCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(SoundInsulationCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(SoundInsulationCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalSoundInsulation(
  Map<String, double> inputs, {
  SoundInsulationCanonicalSpec spec = soundInsulationCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? _defaultFor(spec, 'area', 30)));
  final surfaceType = (inputs['surfaceType'] ?? _defaultFor(spec, 'surfaceType', 0)).round().clamp(0, 2);
  final system = (inputs['system'] ?? _defaultFor(spec, 'system', 0)).round().clamp(0, 3);

  final perim = math.sqrt(area) * 4;
  final materials = <CanonicalMaterialResult>[];
  var primaryQty = 0;
  var primaryUnit = '\u0448\u0442';
  var primaryLabel = 'sound-insulation';

  // System 0: Basic GKL + Rockwool
  if (system == 0) {
    final rockwoolPlates = (area * spec.materialRules.rockwoolReserve / spec.materialRules.rockwoolPlate).ceil();
    final gklSheets = (area * spec.materialRules.rockwoolReserve * spec.materialRules.gklReserve2layers / spec.materialRules.gklSheet).ceil();
    final ppPcs = ((area / spec.materialRules.ppSpacing) * spec.materialRules.ppLength * spec.materialRules.rockwoolReserve / spec.materialRules.ppLength).ceil();
    final vibro = (area * spec.materialRules.vibroPerM2 * spec.materialRules.vibroReserve).ceil();
    final vibroTape = ((area / spec.materialRules.ppSpacing) * spec.materialRules.ppLength * spec.materialRules.rockwoolReserve / spec.materialRules.vibroTapeRoll).ceil();
    final screws = (gklSheets * 25 / 200).ceil();

    primaryQty = rockwoolPlates;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'rockwool-plate';

    materials.addAll([
      CanonicalMaterialResult(name: 'Rockwool \u043f\u043b\u0438\u0442\u044b', quantity: rockwoolPlates.toDouble(), unit: '\u0448\u0442', withReserve: rockwoolPlates.toDouble(), purchaseQty: rockwoolPlates, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0413\u041a\u041b \u043b\u0438\u0441\u0442\u044b', quantity: gklSheets.toDouble(), unit: '\u0448\u0442', withReserve: gklSheets.toDouble(), purchaseQty: gklSheets, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u041f\u041f 3\u043c', quantity: ppPcs.toDouble(), unit: '\u0448\u0442', withReserve: ppPcs.toDouble(), purchaseQty: ppPcs, category: '\u041a\u0430\u0440\u043a\u0430\u0441'),
      CanonicalMaterialResult(name: '\u0412\u0438\u0431\u0440\u043e\u043f\u043e\u0434\u0432\u0435\u0441\u044b', quantity: vibro.toDouble(), unit: '\u0448\u0442', withReserve: vibro.toDouble(), purchaseQty: vibro, category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
      CanonicalMaterialResult(name: '\u0412\u0438\u0431\u0440\u043e\u043b\u0435\u043d\u0442\u0430', quantity: vibroTape.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: vibroTape.toDouble(), purchaseQty: vibroTape, category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f'),
      CanonicalMaterialResult(name: '\u0421\u0430\u043c\u043e\u0440\u0435\u0437\u044b (\u0443\u043f\u0430\u043a\u043e\u0432\u043a\u0438 \u043f\u043e 200)', quantity: screws.toDouble(), unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a', withReserve: screws.toDouble(), purchaseQty: screws, category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
    ]);
  }

  // System 1: ZIPS panels
  if (system == 1) {
    final zipsPanels = (area * spec.materialRules.zipsReserve / spec.materialRules.zipsPlate).ceil();
    final dubels = (zipsPanels * spec.materialRules.zipsDubelsPerPanel * spec.materialRules.zipsDubelReserve).ceil();
    final gklOverlay = (area * spec.materialRules.zipsReserve / spec.materialRules.gklSheet).ceil();

    primaryQty = zipsPanels;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'zips-panel';

    materials.addAll([
      CanonicalMaterialResult(name: '\u0417\u0418\u041f\u0421 \u043f\u0430\u043d\u0435\u043b\u0438', quantity: zipsPanels.toDouble(), unit: '\u0448\u0442', withReserve: zipsPanels.toDouble(), purchaseQty: zipsPanels, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0414\u044e\u0431\u0435\u043b\u0438 \u0434\u043b\u044f \u0417\u0418\u041f\u0421', quantity: dubels.toDouble(), unit: '\u0448\u0442', withReserve: dubels.toDouble(), purchaseQty: dubels, category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
      CanonicalMaterialResult(name: '\u0413\u041a\u041b \u043e\u0431\u043b\u0438\u0446\u043e\u0432\u043a\u0430', quantity: gklOverlay.toDouble(), unit: '\u0448\u0442', withReserve: gklOverlay.toDouble(), purchaseQty: gklOverlay, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
    ]);
  }

  // System 2: Floating floor
  if (system == 2) {
    final mats = (area * spec.materialRules.floatReserve / spec.materialRules.floatMatRoll).ceil();
    final dampTape = (perim / spec.materialRules.dampTapeRoll).ceil();
    final screedBags = (area * spec.materialRules.screedThickness * spec.materialRules.screedDensity / spec.materialRules.screedBag).ceil();

    primaryQty = mats;
    primaryUnit = '\u0440\u0443\u043b\u043e\u043d\u043e\u0432';
    primaryLabel = 'float-mat';

    materials.addAll([
      CanonicalMaterialResult(name: '\u0417\u0432\u0443\u043a\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u043e\u043d\u043d\u044b\u0435 \u043c\u0430\u0442\u044b', quantity: mats.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: mats.toDouble(), purchaseQty: mats, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0414\u0435\u043c\u043f\u0444\u0435\u0440\u043d\u0430\u044f \u043b\u0435\u043d\u0442\u0430', quantity: dampTape.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: dampTape.toDouble(), purchaseQty: dampTape, category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f'),
      CanonicalMaterialResult(name: '\u0421\u0442\u044f\u0436\u043a\u0430 50 \u043a\u0433', quantity: screedBags.toDouble(), unit: '\u043c\u0435\u0448\u043a\u043e\u0432', withReserve: screedBags.toDouble(), purchaseQty: screedBags, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
    ]);
  }

  // System 3: Acoustic ceiling
  if (system == 3) {
    final rockwoolPlates = (area * spec.materialRules.rockwoolReserve / spec.materialRules.rockwoolPlate).ceil();
    final gklSheets = (area * spec.materialRules.rockwoolReserve * spec.materialRules.gklReserve2layers / spec.materialRules.gklSheet).ceil();
    final vibro = (area * spec.materialRules.vibroPerM2 * spec.materialRules.vibroReserve).ceil();

    primaryQty = rockwoolPlates;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'acoustic-ceiling';

    materials.addAll([
      CanonicalMaterialResult(name: 'Rockwool \u043f\u043b\u0438\u0442\u044b', quantity: rockwoolPlates.toDouble(), unit: '\u0448\u0442', withReserve: rockwoolPlates.toDouble(), purchaseQty: rockwoolPlates, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0413\u041a\u041b \u043b\u0438\u0441\u0442\u044b', quantity: gklSheets.toDouble(), unit: '\u0448\u0442', withReserve: gklSheets.toDouble(), purchaseQty: gklSheets, category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435'),
      CanonicalMaterialResult(name: '\u0412\u0438\u0431\u0440\u043e\u043f\u043e\u0434\u0432\u0435\u0441\u044b', quantity: vibro.toDouble(), unit: '\u0448\u0442', withReserve: vibro.toDouble(), purchaseQty: vibro, category: '\u041a\u0440\u0435\u043f\u0451\u0436'),
    ]);
  }

  // Common: sealant + sealing tape
  final sealant = (perim * 2 / spec.materialRules.sealantPerPerim).ceil();
  final sealTape = (perim * 2 * spec.materialRules.sealTapeReserve / spec.materialRules.sealTapeRoll).ceil();

  materials.addAll([
    CanonicalMaterialResult(name: '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u043a', quantity: sealant.toDouble(), unit: '\u0442\u044e\u0431\u0438\u043a\u043e\u0432', withReserve: sealant.toDouble(), purchaseQty: sealant, category: '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u0437\u0430\u0446\u0438\u044f'),
    CanonicalMaterialResult(name: '\u0423\u043f\u043b\u043e\u0442\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u0430\u044f \u043b\u0435\u043d\u0442\u0430 30\u043c', quantity: sealTape.toDouble(), unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432', withReserve: sealTape.toDouble(), purchaseQty: sealTape, category: '\u0413\u0435\u0440\u043c\u0435\u0442\u0438\u0437\u0430\u0446\u0438\u044f'),
  ]);

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(primaryQty * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'surfaceType:$surfaceType',
        'system:$system',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
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
  if (area > spec.warningRules.largeAreaThresholdM2) {
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
      'area': _roundValue(area, 3),
      'surfaceType': surfaceType.toDouble(),
      'system': system.toDouble(),
      'perim': _roundValue(perim, 3),
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
