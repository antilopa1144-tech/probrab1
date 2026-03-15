import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class BasementPackagingRules {
  final String unit;
  final int packageSize;

  const BasementPackagingRules({required this.unit, required this.packageSize});
}

class BasementMaterialRules {
  final double floorRebarKgPerM2;
  final double wallRebarKgPerM2;
  final double wireRatio;
  final double formworkSheetM2;
  final double formworkReserve;
  final double geotextileRoll;
  final double drainageMembraneRoll;
  final double masticKgPerM2;
  final int masticLayers;
  final double rollReserve;
  final double rollM2;
  final double penKgPerM2;
  final double penReserve;
  final double ventPerArea;
  final int minVents;
  final double gravelLayer;
  final double sandLayer;
  final double eppsPlate;
  final double eppsReserve;

  const BasementMaterialRules({
    required this.floorRebarKgPerM2,
    required this.wallRebarKgPerM2,
    required this.wireRatio,
    required this.formworkSheetM2,
    required this.formworkReserve,
    required this.geotextileRoll,
    required this.drainageMembraneRoll,
    required this.masticKgPerM2,
    required this.masticLayers,
    required this.rollReserve,
    required this.rollM2,
    required this.penKgPerM2,
    required this.penReserve,
    required this.ventPerArea,
    required this.minVents,
    required this.gravelLayer,
    required this.sandLayer,
    required this.eppsPlate,
    required this.eppsReserve,
  });
}

class BasementWarningRules {
  final double deepBasementThresholdM;
  final int thinWallThresholdMm;

  const BasementWarningRules({
    required this.deepBasementThresholdM,
    required this.thinWallThresholdMm,
  });
}

class BasementCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final BasementPackagingRules packagingRules;
  final BasementMaterialRules materialRules;
  final BasementWarningRules warningRules;

  const BasementCanonicalSpec({
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

const BasementCanonicalSpec basementCanonicalSpecV1 = BasementCanonicalSpec(
  calculatorId: 'basement',
  formulaVersion: 'basement-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 8, min: 3, max: 30),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 6, min: 3, max: 20),
    CanonicalInputField(key: 'depth', unit: 'm', defaultValue: 2.5, min: 1.5, max: 4),
    CanonicalInputField(key: 'wallThickness', unit: 'mm', defaultValue: 200, min: 150, max: 300),
    CanonicalInputField(key: 'floorThickness', unit: 'mm', defaultValue: 150, min: 100, max: 200),
    CanonicalInputField(key: 'waterproofType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: BasementPackagingRules(unit: 'м³', packageSize: 1),
  materialRules: BasementMaterialRules(
    floorRebarKgPerM2: 22,
    wallRebarKgPerM2: 18,
    wireRatio: 0.01,
    formworkSheetM2: 2.88,
    formworkReserve: 1.15,
    geotextileRoll: 50,
    drainageMembraneRoll: 20,
    masticKgPerM2: 1.5,
    masticLayers: 2,
    rollReserve: 1.15,
    rollM2: 10,
    penKgPerM2: 0.4,
    penReserve: 1.1,
    ventPerArea: 10,
    minVents: 4,
    gravelLayer: 0.15,
    sandLayer: 0.1,
    eppsPlate: 0.72,
    eppsReserve: 1.05,
  ),
  warningRules: BasementWarningRules(
    deepBasementThresholdM: 3,
    thinWallThresholdMm: 200,
  ),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _waterproofLabels = {
  0: 'Обмазочная (мастика)',
  1: 'Рулонная (наплавляемая)',
  2: 'Проникающая',
};

/* ─── helpers ─── */

bool hasCanonicalBasementInputs(Map<String, double> inputs) {
  return inputs.containsKey('depth') ||
      inputs.containsKey('wallThickness') ||
      inputs.containsKey('waterproofType');
}

Map<String, double> normalizeLegacyBasementInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['length'] = (inputs['length'] ?? 8).toDouble();
  normalized['width'] = (inputs['width'] ?? 6).toDouble();
  normalized['depth'] = (inputs['depth'] ?? 2.5).toDouble();
  normalized['wallThickness'] = (inputs['wallThickness'] ?? 200).toDouble();
  normalized['floorThickness'] = (inputs['floorThickness'] ?? 150).toDouble();
  normalized['waterproofType'] = (inputs['waterproofType'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(BasementCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(BasementCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(BasementCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalBasement(
  Map<String, double> inputs, {
  BasementCanonicalSpec spec = basementCanonicalSpecV1,
}) {
  final normalized = hasCanonicalBasementInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyBasementInputs(inputs);

  final length = math.max(3.0, math.min(30.0, (normalized['length'] ?? _defaultFor(spec, 'length', 8)).toDouble()));
  final width = math.max(3.0, math.min(20.0, (normalized['width'] ?? _defaultFor(spec, 'width', 6)).toDouble()));
  final depth = math.max(1.5, math.min(4.0, (normalized['depth'] ?? _defaultFor(spec, 'depth', 2.5)).toDouble()));
  final wallThickness = math.max(150.0, math.min(300.0, (normalized['wallThickness'] ?? _defaultFor(spec, 'wallThickness', 200)).toDouble()));
  final floorThickness = math.max(100.0, math.min(200.0, (normalized['floorThickness'] ?? _defaultFor(spec, 'floorThickness', 150)).toDouble()));
  final waterproofType = (normalized['waterproofType'] ?? _defaultFor(spec, 'waterproofType', 0)).round().clamp(0, 2);

  // Geometry
  final floorArea = length * width;
  final wallPerim = 2.0 * (length + width);
  final wallArea = wallPerim * depth;
  final floorVol = floorArea * (floorThickness / 1000.0);
  final wallVol = wallArea * (wallThickness / 1000.0);

  // Concrete
  final floorConcrete = (floorVol * 1.05 * 10).ceil() / 10.0;
  final wallConcrete = (wallVol * 1.03 * 10).ceil() / 10.0;

  // Rebar
  final floorRebar = _roundValue(floorArea * spec.materialRules.floorRebarKgPerM2, 2);
  final wallRebar = _roundValue(wallArea * spec.materialRules.wallRebarKgPerM2, 2);
  final wire = ((floorRebar + wallRebar) * spec.materialRules.wireRatio).ceil();

  // Formwork
  final formwork = (wallArea * 2 * spec.materialRules.formworkReserve / spec.materialRules.formworkSheetM2).ceil();

  // Ventilation
  final ventCount = math.max(spec.materialRules.minVents, (floorArea / spec.materialRules.ventPerArea).ceil());

  // Waterproofing
  final totalWpArea = wallArea + floorArea;
  var masticKg = 0.0;
  var rollCount = 0;
  var penKg = 0.0;

  if (waterproofType == 0) {
    masticKg = _roundValue(totalWpArea * spec.materialRules.masticLayers * spec.materialRules.masticKgPerM2, 2);
  } else if (waterproofType == 1) {
    final rollArea = totalWpArea * spec.materialRules.rollReserve;
    rollCount = (rollArea / spec.materialRules.rollM2 * 2).ceil();
  } else {
    penKg = _roundValue(totalWpArea * spec.materialRules.penKgPerM2 * spec.materialRules.penReserve, 2);
  }

  // Scenarios
  final totalConcrete = _roundValue(floorConcrete + wallConcrete, 3);
  final basePrimary = totalConcrete;
  final packageLabel = 'concrete-m3';
  final packageUnit = 'м³';

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
        'waterproofType:$waterproofType',
        'wallThickness:${wallThickness.round()}',
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
  if (depth > spec.warningRules.deepBasementThresholdM) {
    warnings.add('Глубина подвала более 3 м — требуется проект и расчёт несущей способности');
  }
  if (wallThickness < spec.warningRules.thinWallThresholdMm) {
    warnings.add('Толщина стен менее 200 мм — допустима только для неглубоких погребов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон на пол (${floorThickness.round()} мм)',
      quantity: floorConcrete,
      unit: 'м³',
      withReserve: floorConcrete,
      purchaseQty: (floorConcrete * 10).ceil(),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Бетон на стены (${wallThickness.round()} мм)',
      quantity: wallConcrete,
      unit: 'м³',
      withReserve: wallConcrete,
      purchaseQty: (wallConcrete * 10).ceil(),
      category: 'Бетон',
    ),
    CanonicalMaterialResult(
      name: 'Арматура на пол',
      quantity: floorRebar,
      unit: 'кг',
      withReserve: floorRebar,
      purchaseQty: floorRebar.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Арматура на стены',
      quantity: wallRebar,
      unit: 'кг',
      withReserve: wallRebar,
      purchaseQty: wallRebar.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Вязальная проволока',
      quantity: wire.toDouble(),
      unit: 'кг',
      withReserve: wire.toDouble(),
      purchaseQty: wire,
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Опалубка (${spec.materialRules.formworkSheetM2} м²/лист)',
      quantity: formwork.toDouble(),
      unit: 'листов',
      withReserve: formwork.toDouble(),
      purchaseQty: formwork,
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Продухи (вент. отверстия)',
      quantity: ventCount.toDouble(),
      unit: 'шт',
      withReserve: ventCount.toDouble(),
      purchaseQty: ventCount,
      category: 'Вентиляция',
    ),
  ];

  // Waterproofing materials
  if (waterproofType == 0) {
    materials.add(CanonicalMaterialResult(
      name: '${_waterproofLabels[0]}',
      quantity: masticKg,
      unit: 'кг',
      withReserve: masticKg,
      purchaseQty: masticKg.ceil(),
      category: 'Гидроизоляция',
    ));
  } else if (waterproofType == 1) {
    materials.add(CanonicalMaterialResult(
      name: '${_waterproofLabels[1]} (${spec.materialRules.rollM2.round()} м²/рулон)',
      quantity: rollCount.toDouble(),
      unit: 'рулонов',
      withReserve: rollCount.toDouble(),
      purchaseQty: rollCount,
      category: 'Гидроизоляция',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: '${_waterproofLabels[2]}',
      quantity: penKg,
      unit: 'кг',
      withReserve: penKg,
      purchaseQty: penKg.ceil(),
      category: 'Гидроизоляция',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': _roundValue(length, 3),
      'width': _roundValue(width, 3),
      'depth': _roundValue(depth, 3),
      'wallThickness': wallThickness,
      'floorThickness': floorThickness,
      'waterproofType': waterproofType.toDouble(),
      'floorArea': _roundValue(floorArea, 3),
      'wallPerim': _roundValue(wallPerim, 3),
      'wallArea': _roundValue(wallArea, 3),
      'floorVol': _roundValue(floorVol, 4),
      'wallVol': _roundValue(wallVol, 4),
      'floorConcrete': floorConcrete,
      'wallConcrete': wallConcrete,
      'totalConcrete': totalConcrete,
      'floorRebar': floorRebar,
      'wallRebar': wallRebar,
      'wire': wire.toDouble(),
      'formwork': formwork.toDouble(),
      'ventCount': ventCount.toDouble(),
      'masticKg': masticKg,
      'rollCount': rollCount.toDouble(),
      'penKg': penKg,
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
