import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class BlindAreaPackagingRules {
  final String unit;
  final int packageSize;

  const BlindAreaPackagingRules({required this.unit, required this.packageSize});
}

class BlindAreaMaterialRules {
  final double concreteReserve;
  final double meshReserve;
  final double damperReserve;
  final double gravelLayer;
  final double sandLayer;
  final double tileReserve;
  final double tileMixKgPerM2;
  final double borderLength;
  final double membraneReserve;
  final double geotextileRoll;
  final double eppsPlate;
  final double eppsReserve;

  const BlindAreaMaterialRules({
    required this.concreteReserve,
    required this.meshReserve,
    required this.damperReserve,
    required this.gravelLayer,
    required this.sandLayer,
    required this.tileReserve,
    required this.tileMixKgPerM2,
    required this.borderLength,
    required this.membraneReserve,
    required this.geotextileRoll,
    required this.eppsPlate,
    required this.eppsReserve,
  });
}

class BlindAreaWarningRules {
  final double narrowWidthThresholdM;
  final int thinConcreteThresholdMm;

  const BlindAreaWarningRules({
    required this.narrowWidthThresholdM,
    required this.thinConcreteThresholdMm,
  });
}

class BlindAreaCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final BlindAreaPackagingRules packagingRules;
  final BlindAreaMaterialRules materialRules;
  final BlindAreaWarningRules warningRules;

  const BlindAreaCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── spec instance ─── */

const BlindAreaCanonicalSpec blindAreaCanonicalSpecV1 = BlindAreaCanonicalSpec(
  calculatorId: 'blind-area',
  formulaVersion: 'blind-area-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'perimeter', unit: 'm', defaultValue: 40, min: 10, max: 200),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 1.0, min: 0.6, max: 1.5),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 100, min: 70, max: 150),
    CanonicalInputField(key: 'materialType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'withInsulation', unit: 'mm', defaultValue: 0, min: 0, max: 100),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: BlindAreaPackagingRules(unit: 'м²', packageSize: 1),
  materialRules: BlindAreaMaterialRules(
    concreteReserve: 1.05,
    meshReserve: 1.1,
    damperReserve: 1.05,
    gravelLayer: 0.15,
    sandLayer: 0.1,
    tileReserve: 1.08,
    tileMixKgPerM2: 6,
    borderLength: 0.5,
    membraneReserve: 1.15,
    geotextileRoll: 50,
    eppsPlate: 0.72,
    eppsReserve: 1.05,
  ),
  warningRules: BlindAreaWarningRules(
    narrowWidthThresholdM: 0.8,
    thinConcreteThresholdMm: 100,
  ),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

bool hasCanonicalBlindAreaInputs(Map<String, double> inputs) {
  return inputs.containsKey('perimeter') ||
      inputs.containsKey('materialType') ||
      inputs.containsKey('withInsulation');
}

Map<String, double> normalizeLegacyBlindAreaInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['perimeter'] = (inputs['perimeter'] ?? 40).toDouble();
  normalized['width'] = (inputs['width'] ?? 1.0).toDouble();
  normalized['thickness'] = (inputs['thickness'] ?? 100).toDouble();
  normalized['materialType'] = (inputs['materialType'] ?? 0).toDouble();
  normalized['withInsulation'] = (inputs['withInsulation'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(BlindAreaCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(BlindAreaCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(BlindAreaCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalBlindArea(
  Map<String, double> inputs, {
  BlindAreaCanonicalSpec spec = blindAreaCanonicalSpecV1,
}) {
  final normalized = hasCanonicalBlindAreaInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBlindAreaInputs(inputs);

  final perimeter = math.max(10.0, math.min(200.0, (normalized['perimeter'] ?? _defaultFor(spec, 'perimeter', 40)).toDouble()));
  final width = math.max(0.6, math.min(1.5, (normalized['width'] ?? _defaultFor(spec, 'width', 1.0)).toDouble()));
  final thickness = math.max(70.0, math.min(150.0, (normalized['thickness'] ?? _defaultFor(spec, 'thickness', 100)).toDouble()));
  final materialType = (normalized['materialType'] ?? _defaultFor(spec, 'materialType', 0)).round().clamp(0, 2);
  final withInsulation = math.max(0.0, math.min(100.0, (normalized['withInsulation'] ?? _defaultFor(spec, 'withInsulation', 0)).toDouble()));

  // Base geometry
  final area = perimeter * width;

  // Type-specific
  var concreteM3 = 0.0;
  var meshPcs = 0;
  var damperM = 0.0;
  var tileM2 = 0;
  var mixBags = 0;
  var borderPcs = 0;
  var membraneM2 = 0;
  var decorGravelM3 = 0.0;

  if (materialType == 0) {
    // Concrete
    concreteM3 = (area * (thickness / 1000.0) * spec.materialRules.concreteReserve * 10).ceil() / 10.0;
    meshPcs = thickness >= 100 ? (area * spec.materialRules.meshReserve).ceil() : 0;
    damperM = _roundValue(perimeter * spec.materialRules.damperReserve, 2);
  } else if (materialType == 1) {
    // Tile
    tileM2 = (area * spec.materialRules.tileReserve).ceil();
    mixBags = (area * spec.materialRules.tileMixKgPerM2 / 50).ceil();
    borderPcs = (perimeter / spec.materialRules.borderLength).ceil();
  } else {
    // Soft membrane
    membraneM2 = (area * spec.materialRules.membraneReserve).ceil();
    decorGravelM3 = _roundValue(area * 0.1, 3);
  }

  // Common layers
  final gravel = _roundValue(area * spec.materialRules.gravelLayer, 3);
  final sand = _roundValue(area * spec.materialRules.sandLayer, 3);
  final geotextileRolls = (area * 1.15 / spec.materialRules.geotextileRoll).ceil();
  final eppsPlates = withInsulation > 0 ? (area * spec.materialRules.eppsReserve / spec.materialRules.eppsPlate).ceil() : 0;

  // Scenarios
  final basePrimary = materialType == 0 ? concreteM3 : materialType == 1 ? tileM2.toDouble() : membraneM2.toDouble();
  final packageLabel = materialType == 0
      ? 'concrete-m3'
      : materialType == 1
          ? 'tile-m2'
          : 'membrane-m2';
  final packageUnit = materialType == 0 ? 'м³' : 'м²';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'materialType:$materialType',
        'thickness:${thickness.round()}',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
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
  if (width < spec.warningRules.narrowWidthThresholdM) {
    warnings.add('Ширина отмостки менее 0.8 м — может не обеспечить достаточной защиты фундамента');
  }
  if (materialType == 0 && thickness < spec.warningRules.thinConcreteThresholdMm) {
    warnings.add('Толщина бетона менее 100 мм — рекомендуется армосетка при увеличении толщины');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[];

  if (materialType == 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Бетон (${thickness.round()} мм)',
      quantity: recScenario.exactNeed,
      unit: 'м³',
      withReserve: concreteM3,
      purchaseQty: (concreteM3 * 10).ceil(),
      category: 'Бетон',
    ));
    if (meshPcs > 0) {
      materials.add(CanonicalMaterialResult(
        name: 'Армосетка',
        quantity: meshPcs.toDouble(),
        unit: 'шт',
        withReserve: meshPcs.toDouble(),
        purchaseQty: meshPcs,
        category: 'Армирование',
      ));
    }
    materials.add(CanonicalMaterialResult(
      name: 'Демпферная лента',
      quantity: damperM,
      unit: 'м',
      withReserve: damperM,
      purchaseQty: damperM.ceil(),
      category: 'Расходные',
    ));
  } else if (materialType == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Тротуарная плитка',
        quantity: recScenario.exactNeed,
        unit: 'м²',
        withReserve: tileM2.toDouble(),
        purchaseQty: tileM2,
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Смесь для укладки (50 кг)',
        quantity: mixBags.toDouble(),
        unit: 'мешков',
        withReserve: mixBags.toDouble(),
        purchaseQty: mixBags,
        category: 'Смеси',
      ),
      CanonicalMaterialResult(
        name: 'Бордюр (0.5 м)',
        quantity: borderPcs.toDouble(),
        unit: 'шт',
        withReserve: borderPcs.toDouble(),
        purchaseQty: borderPcs,
        category: 'Покрытие',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Профилированная мембрана',
        quantity: recScenario.exactNeed,
        unit: 'м²',
        withReserve: membraneM2.toDouble(),
        purchaseQty: membraneM2,
        category: 'Покрытие',
      ),
      CanonicalMaterialResult(
        name: 'Декоративный щебень',
        quantity: decorGravelM3,
        unit: 'м³',
        withReserve: decorGravelM3,
        purchaseQty: (decorGravelM3 * 10).ceil(),
        category: 'Покрытие',
      ),
    ]);
  }

  // Common materials
  materials.addAll([
    CanonicalMaterialResult(
      name: 'Щебень (подушка)',
      quantity: gravel,
      unit: 'м³',
      withReserve: gravel,
      purchaseQty: (gravel * 10).ceil(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Песок (подушка)',
      quantity: sand,
      unit: 'м³',
      withReserve: sand,
      purchaseQty: (sand * 10).ceil(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Геотекстиль (${spec.materialRules.geotextileRoll.round()} м²)',
      quantity: geotextileRolls.toDouble(),
      unit: 'рулонов',
      withReserve: geotextileRolls.toDouble(),
      purchaseQty: geotextileRolls,
      category: 'Подготовка',
    ),
  ]);

  if (eppsPlates > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'ЭППС утеплитель (${withInsulation.round()} мм)',
      quantity: eppsPlates.toDouble(),
      unit: 'шт',
      withReserve: eppsPlates.toDouble(),
      purchaseQty: eppsPlates,
      category: 'Утепление',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'perimeter': _roundValue(perimeter, 3),
      'width': _roundValue(width, 3),
      'area': _roundValue(area, 3),
      'thickness': thickness,
      'materialType': materialType.toDouble(),
      'withInsulation': withInsulation,
      'concreteM3': concreteM3,
      'meshPcs': meshPcs.toDouble(),
      'damperM': damperM,
      'tileM2': tileM2.toDouble(),
      'mixBags': mixBags.toDouble(),
      'borderPcs': borderPcs.toDouble(),
      'membraneM2': membraneM2.toDouble(),
      'decorGravelM3': decorGravelM3,
      'gravel': gravel,
      'sand': sand,
      'geotextileRolls': geotextileRolls.toDouble(),
      'eppsPlates': eppsPlates.toDouble(),
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
