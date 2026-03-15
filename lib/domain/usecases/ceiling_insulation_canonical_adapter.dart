import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class CeilingInsulationPackagingRules {
  final String unit;
  final double packageSize;

  const CeilingInsulationPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class CeilingInsulationMaterialRules {
  final double platePackM2;
  final Map<int, double> rollAreas;
  final double eppsPlate;
  final double ecowoolDensity;
  final double ecowoolBag;
  final double plateReserve;
  final double vaporRoll;
  final double vaporReserve;
  final double tapePerArea;

  const CeilingInsulationMaterialRules({
    required this.platePackM2,
    required this.rollAreas,
    required this.eppsPlate,
    required this.ecowoolDensity,
    required this.ecowoolBag,
    required this.plateReserve,
    required this.vaporRoll,
    required this.vaporReserve,
    required this.tapePerArea,
  });
}

class CeilingInsulationWarningRules {
  final double thinInsulationThresholdMm;
  final double largeAreaThresholdM2;

  const CeilingInsulationWarningRules({
    required this.thinInsulationThresholdMm,
    required this.largeAreaThresholdM2,
  });
}

class CeilingInsulationCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final CeilingInsulationPackagingRules packagingRules;
  final CeilingInsulationMaterialRules materialRules;
  final CeilingInsulationWarningRules warningRules;

  const CeilingInsulationCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const CeilingInsulationCanonicalSpec ceilingInsulationCanonicalSpecV1 = CeilingInsulationCanonicalSpec(
  calculatorId: 'ceiling-insulation',
  formulaVersion: 'ceiling-insulation-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm\u00b2', defaultValue: 40, min: 1, max: 500),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 100, min: 50, max: 200),
    CanonicalInputField(key: 'insulationType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'layers', defaultValue: 1, min: 1, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: CeilingInsulationPackagingRules(
    unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a',
    packageSize: 1,
  ),
  materialRules: CeilingInsulationMaterialRules(
    platePackM2: 6,
    rollAreas: {50: 9, 100: 5},
    eppsPlate: 0.72,
    ecowoolDensity: 35,
    ecowoolBag: 15,
    plateReserve: 1.05,
    vaporRoll: 50,
    vaporReserve: 1.15,
    tapePerArea: 50,
  ),
  warningRules: CeilingInsulationWarningRules(
    thinInsulationThresholdMm: 50,
    largeAreaThresholdM2: 200,
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

double _defaultFor(CeilingInsulationCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(CeilingInsulationCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(CeilingInsulationCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalCeilingInsulation(
  Map<String, double> inputs, {
  CeilingInsulationCanonicalSpec spec = ceilingInsulationCanonicalSpecV1,
}) {
  final area = math.max(1.0, math.min(500.0, inputs['area'] ?? _defaultFor(spec, 'area', 40)));
  final thicknessRaw = (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 100)).round();
  final allowedThick = [50, 100, 150, 200];
  final thickness = allowedThick.contains(thicknessRaw) ? thicknessRaw : 100;
  final insulationType = (inputs['insulationType'] ?? _defaultFor(spec, 'insulationType', 0)).round().clamp(0, 3);
  final layersRaw = (inputs['layers'] ?? _defaultFor(spec, 'layers', 1)).round();
  final layers = layersRaw == 2 ? 2 : 1;

  final materials = <CanonicalMaterialResult>[];
  var primaryQty = 0;
  var primaryUnit = '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a';
  var primaryLabel = 'insulation-pack';

  // Mineral plates (type 0)
  if (insulationType == 0) {
    final packs = (area * spec.materialRules.plateReserve * layers / spec.materialRules.platePackM2).ceil();
    primaryQty = packs;
    primaryUnit = '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a';
    primaryLabel = 'mineral-plate-pack';
    materials.add(CanonicalMaterialResult(
      name: '\u041c\u0438\u043d\u0435\u0440\u0430\u043b\u043e\u0432\u0430\u0442\u043d\u044b\u0435 \u043f\u043b\u0438\u0442\u044b',
      quantity: packs.toDouble(),
      unit: '\u0443\u043f\u0430\u043a\u043e\u0432\u043e\u043a',
      withReserve: packs.toDouble(),
      purchaseQty: packs,
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // Mineral rolls (type 1)
  if (insulationType == 1) {
    final rollArea = spec.materialRules.rollAreas[thickness] ?? spec.materialRules.rollAreas[100] ?? 5;
    final rolls = (area * spec.materialRules.plateReserve * layers / rollArea).ceil();
    primaryQty = rolls;
    primaryUnit = '\u0440\u0443\u043b\u043e\u043d\u043e\u0432';
    primaryLabel = 'mineral-roll';
    materials.add(CanonicalMaterialResult(
      name: '\u041c\u0438\u043d\u0435\u0440\u0430\u043b\u043e\u0432\u0430\u0442\u043d\u044b\u0435 \u0440\u0443\u043b\u043e\u043d\u044b',
      quantity: rolls.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: rolls.toDouble(),
      purchaseQty: rolls,
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // EPPS (type 2)
  if (insulationType == 2) {
    final plates = (area * spec.materialRules.plateReserve * layers / spec.materialRules.eppsPlate).ceil();
    primaryQty = plates;
    primaryUnit = '\u0448\u0442';
    primaryLabel = 'epps-plate';
    materials.add(CanonicalMaterialResult(
      name: '\u042d\u041f\u041f\u0421 \u043f\u043b\u0438\u0442\u044b',
      quantity: plates.toDouble(),
      unit: '\u0448\u0442',
      withReserve: plates.toDouble(),
      purchaseQty: plates,
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // Ecowool (type 3)
  if (insulationType == 3) {
    final kg = area * (thickness / 1000.0) * spec.materialRules.ecowoolDensity * layers;
    final bags = (kg / spec.materialRules.ecowoolBag).ceil();
    primaryQty = bags;
    primaryUnit = '\u043c\u0435\u0448\u043a\u043e\u0432';
    primaryLabel = 'ecowool-bag';
    materials.add(CanonicalMaterialResult(
      name: '\u042d\u043a\u043e\u0432\u0430\u0442\u0430 15 \u043a\u0433',
      quantity: bags.toDouble(),
      unit: '\u043c\u0435\u0448\u043a\u043e\u0432',
      withReserve: bags.toDouble(),
      purchaseQty: bags,
      category: '\u041e\u0441\u043d\u043e\u0432\u043d\u043e\u0435',
    ));
  }

  // Vapor barrier (mineral types only)
  var vaporRolls = 0;
  if (insulationType == 0 || insulationType == 1) {
    vaporRolls = (area * spec.materialRules.vaporReserve / spec.materialRules.vaporRoll).ceil();
    materials.add(CanonicalMaterialResult(
      name: '\u041f\u0430\u0440\u043e\u0438\u0437\u043e\u043b\u044f\u0446\u0438\u044f 50 \u043c\u00b2',
      quantity: vaporRolls.toDouble(),
      unit: '\u0440\u0443\u043b\u043e\u043d\u043e\u0432',
      withReserve: vaporRolls.toDouble(),
      purchaseQty: vaporRolls,
      category: '\u0418\u0437\u043e\u043b\u044f\u0446\u0438\u044f',
    ));
  }

  // Tape
  final tapeRolls = (area / spec.materialRules.tapePerArea).ceil() * 10;
  materials.add(CanonicalMaterialResult(
    name: '\u0421\u043a\u043e\u0442\u0447 \u0441\u043e\u0435\u0434\u0438\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439',
    quantity: tapeRolls.toDouble(),
    unit: '\u043c',
    withReserve: tapeRolls.toDouble(),
    purchaseQty: tapeRolls,
    category: '\u0420\u0430\u0441\u0445\u043e\u0434\u043d\u044b\u0435',
  ));

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
        'insulationType:$insulationType',
        'thickness:$thickness',
        'layers:$layers',
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
  if (thickness < spec.warningRules.thinInsulationThresholdMm) {
    warnings.add('\u0422\u043e\u043d\u043a\u0438\u0439 \u0441\u043b\u043e\u0439 \u0443\u0442\u0435\u043f\u043b\u0438\u0442\u0435\u043b\u044f \u2014 \u044d\u0444\u0444\u0435\u043a\u0442\u0438\u0432\u043d\u043e\u0441\u0442\u044c \u0441\u043d\u0438\u0436\u0435\u043d\u0430');
  }
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('\u0411\u043e\u043b\u044c\u0448\u0430\u044f \u043f\u043b\u043e\u0449\u0430\u0434\u044c \u2014 \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0444\u0435\u0441\u0441\u0438\u043e\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u043e\u043d\u0442\u0430\u0436');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
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
