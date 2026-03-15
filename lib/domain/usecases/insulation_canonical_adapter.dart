import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── Spec model classes ─── */

class InsulationTypeSpec {
  final int id;
  final String key;
  final String label;
  final int dowelsPerSqm;

  const InsulationTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.dowelsPerSqm,
  });
}

class InsulationPlateSizeSpec {
  final int id;
  final String key;
  final String label;
  final double areaM2;

  const InsulationPlateSizeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.areaM2,
  });
}

class InsulationPackagingRules {
  final String plateUnit;
  final String ecowoolUnit;

  const InsulationPackagingRules({
    required this.plateUnit,
    required this.ecowoolUnit,
  });
}

class InsulationMaterialRules {
  final double plateReserve;
  final double dowelReserve;
  final double membraneReserve;
  final double aluTapeM2PerM2;
  final double aluTapeRollM;
  final double glueKgPerM2;
  final double glueBagKg;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCanL;
  final double ecowoolDensity;
  final double ecowoolWaste;
  final double ecowoolBagKg;

  const InsulationMaterialRules({
    required this.plateReserve,
    required this.dowelReserve,
    required this.membraneReserve,
    required this.aluTapeM2PerM2,
    required this.aluTapeRollM,
    required this.glueKgPerM2,
    required this.glueBagKg,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCanL,
    required this.ecowoolDensity,
    required this.ecowoolWaste,
    required this.ecowoolBagKg,
  });
}

class InsulationWarningRules {
  final double thinThicknessThresholdMm;
  final double ecowoolSettleThresholdMm;
  final double professionalAreaThresholdM2;

  const InsulationWarningRules({
    required this.thinThicknessThresholdMm,
    required this.ecowoolSettleThresholdMm,
    required this.professionalAreaThresholdM2,
  });
}

class InsulationCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<InsulationTypeSpec> insulationTypes;
  final List<InsulationPlateSizeSpec> plateSizes;
  final InsulationPackagingRules packagingRules;
  final InsulationMaterialRules materialRules;
  final InsulationWarningRules warningRules;

  const InsulationCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.insulationTypes,
    required this.plateSizes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── Default spec (mirrors insulation-canonical.v1.json) ─── */

const InsulationCanonicalSpec insulationCanonicalSpecV1 = InsulationCanonicalSpec(
  calculatorId: 'insulation',
  formulaVersion: 'insulation-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 40, min: 1, max: 500),
    CanonicalInputField(key: 'insulationType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 100, min: 50, max: 200),
    CanonicalInputField(key: 'plateSize', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'reserve', unit: '%', defaultValue: 5, min: 0, max: 15),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  insulationTypes: [
    InsulationTypeSpec(id: 0, key: 'mineral_wool', label: 'Минеральная вата', dowelsPerSqm: 7),
    InsulationTypeSpec(id: 1, key: 'epps', label: 'ЭППС / пеноплекс', dowelsPerSqm: 5),
    InsulationTypeSpec(id: 2, key: 'eps', label: 'ЕПС / пенопласт', dowelsPerSqm: 6),
    InsulationTypeSpec(id: 3, key: 'ecowool', label: 'Эковата', dowelsPerSqm: 0),
  ],
  plateSizes: [
    InsulationPlateSizeSpec(id: 0, key: '1200x600', label: '1200×600', areaM2: 0.72),
    InsulationPlateSizeSpec(id: 1, key: '1000x500', label: '1000×500', areaM2: 0.50),
    InsulationPlateSizeSpec(id: 2, key: '2000x1000', label: '2000×1000', areaM2: 2.00),
  ],
  packagingRules: InsulationPackagingRules(
    plateUnit: 'шт',
    ecowoolUnit: 'мешков',
  ),
  materialRules: InsulationMaterialRules(
    plateReserve: 1.05,
    dowelReserve: 1.05,
    membraneReserve: 1.15,
    aluTapeM2PerM2: 2,
    aluTapeRollM: 50,
    glueKgPerM2: 2.5,
    glueBagKg: 25,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCanL: 10,
    ecowoolDensity: 35,
    ecowoolWaste: 1.10,
    ecowoolBagKg: 15,
  ),
  warningRules: InsulationWarningRules(
    thinThicknessThresholdMm: 50,
    ecowoolSettleThresholdMm: 150,
    professionalAreaThresholdM2: 100,
  ),
);

/* ─── Constants (must match TS engine exactly) ─── */

const Map<int, double> _plateAreas = {0: 0.72, 1: 0.50, 2: 2.00};
const Map<int, String> _plateLabels = {0: '1200×600', 1: '1000×500', 2: '2000×1000'};
const double _plateReserve = 1.05;

const Map<int, int> _dowelsPerSqm = {0: 7, 1: 5, 2: 6, 3: 0};
const double _dowelReserve = 1.05;

const double _membraneReserve = 1.15;
const double _aluTapeM2PerM2 = 2;
const double _aluTapeRollM = 50;

const double _glueKgPerM2 = 2.5;
const double _glueBagKg = 25;

const double _primerLPerM2 = 0.15;
const double _primerReserve = 1.15;
const double _primerCanL = 10;

const double _ecowoolDensity = 35;
const double _ecowoolWaste = 1.10;
const double _ecowoolBagKg = 15;

/* ─── Factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _insulationTypeLabels = {
  0: 'Минеральная вата',
  1: 'ЭППС / пеноплекс',
  2: 'ЕПС / пенопласт',
  3: 'Эковата',
};

/* ─── Helpers ─── */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(InsulationCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(InsulationCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(InsulationCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── Main calculator ─── */

CanonicalCalculatorContractResult calculateCanonicalInsulation(
  Map<String, double> inputs, {
  InsulationCanonicalSpec spec = insulationCanonicalSpecV1,
}) {
  final area = (inputs['area'] ?? _defaultFor(spec, 'area', 40)).clamp(1, 500).toDouble();
  final insulationType = (inputs['insulationType'] ?? _defaultFor(spec, 'insulationType', 0)).round().clamp(0, 3);
  final thickness = (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 100)).clamp(50, 200).toDouble();
  final plateSize = (inputs['plateSize'] ?? _defaultFor(spec, 'plateSize', 0)).round().clamp(0, 2);
  final reserve = (inputs['reserve'] ?? _defaultFor(spec, 'reserve', 5)).clamp(0, 15).toDouble();

  final areaWithReserve = area * (1 + reserve / 100);
  final plateArea = _plateAreas[plateSize] ?? 0.72;

  /* ── plate-based types (0, 1, 2) ── */
  var platesNeeded = 0;
  var dowelsNeeded = 0;
  var membraneArea = 0;
  var aluTapeRolls = 0;
  var glueKg = 0.0;
  var glueBags = 0;

  if (insulationType <= 2) {
    platesNeeded = (areaWithReserve / plateArea).ceil();
    dowelsNeeded = (area * (_dowelsPerSqm[insulationType] ?? 0) * _dowelReserve).ceil();
  }

  if (insulationType == 0) {
    membraneArea = (area * _membraneReserve).ceil();
    aluTapeRolls = ((area * _aluTapeM2PerM2) / _aluTapeRollM).ceil();
  }

  if (insulationType == 1 || insulationType == 2) {
    glueKg = area * _glueKgPerM2;
    glueBags = (glueKg / _glueBagKg).ceil();
  }

  /* ── primer (all types) ── */
  final primerCans = (area * _primerLPerM2 * _primerReserve / _primerCanL).ceil();

  /* ── ecowool (type 3) ── */
  var ecowoolVolume = 0.0;
  var ecowoolKg = 0;
  var ecowoolBags = 0;

  if (insulationType == 3) {
    ecowoolVolume = area * (thickness / 1000);
    ecowoolKg = (ecowoolVolume * _ecowoolDensity * _ecowoolWaste).ceil();
    ecowoolBags = (ecowoolKg / _ecowoolBagKg).ceil();
  }

  /* ── scenarios ── */
  final basePrimary = insulationType <= 2 ? platesNeeded.toDouble() : ecowoolBags.toDouble();
  const packageSize = 1.0;
  final packageUnit = insulationType <= 2 ? 'шт' : 'мешков';
  final packageLabel = insulationType <= 2
      ? 'insulation-plate-${_plateLabels[plateSize]}'
      : 'ecowool-bag-15kg';

  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packages = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packages * packageSize, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'plateSize:$plateSize',
        'reserve:${reserve.toInt()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packages,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ── build materials list ── */
  final materials = <CanonicalMaterialResult>[];

  if (insulationType <= 2) {
    materials.add(CanonicalMaterialResult(
      name: '${_insulationTypeLabels[insulationType]} (${_plateLabels[plateSize]} мм)',
      quantity: _roundValue(recScenario.exactNeed, 6),
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceil().toDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Основное',
    ));

    materials.add(CanonicalMaterialResult(
      name: 'Дюбели тарельчатые',
      quantity: dowelsNeeded.toDouble(),
      unit: 'шт',
      withReserve: dowelsNeeded.toDouble(),
      purchaseQty: dowelsNeeded,
      category: 'Крепёж',
    ));
  }

  if (insulationType == 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Пароизоляционная мембрана',
      quantity: membraneArea.toDouble(),
      unit: 'м²',
      withReserve: membraneArea.toDouble(),
      purchaseQty: membraneArea,
      category: 'Изоляция',
    ));

    materials.add(CanonicalMaterialResult(
      name: 'Алюминиевая лента (скотч)',
      quantity: aluTapeRolls.toDouble(),
      unit: 'рулонов',
      withReserve: aluTapeRolls.toDouble(),
      purchaseQty: aluTapeRolls,
      category: 'Изоляция',
    ));
  }

  if (insulationType == 1 || insulationType == 2) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для ${insulationType == 1 ? "ЭППС" : "ЕПС"} (${_glueBagKg.toInt()} кг)',
      quantity: _roundValue(glueKg, 3),
      unit: 'кг',
      withReserve: (glueBags * _glueBagKg).toDouble(),
      purchaseQty: glueBags,
      category: 'Клей',
    ));
  }

  if (insulationType == 3) {
    materials.add(CanonicalMaterialResult(
      name: 'Эковата (${_ecowoolBagKg.toInt()} кг)',
      quantity: ecowoolKg.toDouble(),
      unit: 'кг',
      withReserve: (ecowoolBags * _ecowoolBagKg).toDouble(),
      purchaseQty: ecowoolBags,
      category: 'Основное',
    ));
  }

  materials.add(CanonicalMaterialResult(
    name: 'Грунтовка (${_primerCanL.toInt()} л)',
    quantity: _roundValue(area * _primerLPerM2 * _primerReserve, 3),
    unit: 'л',
    withReserve: (primerCans * _primerCanL).toDouble(),
    purchaseQty: primerCans,
    category: 'Подготовка',
  ));

  /* ── warnings ── */
  final warnings = <String>[];
  if (thickness < spec.warningRules.thinThicknessThresholdMm) {
    warnings.add('Толщина менее 50 мм — недостаточно для наружных стен');
  }
  if (insulationType == 3 && thickness > spec.warningRules.ecowoolSettleThresholdMm) {
    warnings.add('Эковата при толщине более 150 мм оседает — рекомендуется укладка в 2 слоя');
  }
  if (area > spec.warningRules.professionalAreaThresholdM2) {
    warnings.add('При площади более 100 м² рекомендуется профессиональный монтаж');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': _roundValue(area, 3),
      'insulationType': insulationType.toDouble(),
      'thickness': _roundValue(thickness, 3),
      'plateSize': plateSize.toDouble(),
      'reserve': reserve,
      'areaWithReserve': _roundValue(areaWithReserve, 3),
      'plateArea': plateArea,
      'platesNeeded': insulationType <= 2 ? platesNeeded.toDouble() : 0,
      'dowelsNeeded': insulationType <= 2 ? dowelsNeeded.toDouble() : 0,
      'membraneArea': insulationType == 0 ? membraneArea.toDouble() : 0,
      'aluTapeRolls': insulationType == 0 ? aluTapeRolls.toDouble() : 0,
      'glueKg': insulationType == 1 || insulationType == 2 ? _roundValue(glueKg, 3) : 0,
      'glueBags': insulationType == 1 || insulationType == 2 ? glueBags.toDouble() : 0,
      'primerCans': primerCans.toDouble(),
      'ecowoolVolume': insulationType == 3 ? _roundValue(ecowoolVolume, 6) : 0,
      'ecowoolKg': insulationType == 3 ? ecowoolKg.toDouble() : 0,
      'ecowoolBags': insulationType == 3 ? ecowoolBags.toDouble() : 0,
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
