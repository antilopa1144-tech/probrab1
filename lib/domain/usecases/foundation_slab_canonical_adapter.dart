import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

// ─── Foundation Slab spec classes ───

class FoundationSlabPackagingRules {
  final String unit;
  final double volumeStepM3;

  const FoundationSlabPackagingRules({
    required this.unit,
    required this.volumeStepM3,
  });
}

class FoundationSlabMaterialRules {
  final Map<int, double> weightPerMeter;
  final double wirePerJoint;
  final double eppsPlateM2;
  final double geotextileReserve;
  final double formworkReserve;
  final double concreteReserve;
  final double gravelLayer;
  final double sandLayer;
  final double insulationReserve;

  const FoundationSlabMaterialRules({
    required this.weightPerMeter,
    required this.wirePerJoint,
    required this.eppsPlateM2,
    required this.geotextileReserve,
    required this.formworkReserve,
    required this.concreteReserve,
    required this.gravelLayer,
    required this.sandLayer,
    required this.insulationReserve,
  });
}

class FoundationSlabWarningRules {
  final double largeAreaThresholdM2;
  final int thinSlabThresholdMm;

  const FoundationSlabWarningRules({
    required this.largeAreaThresholdM2,
    required this.thinSlabThresholdMm,
  });
}

class FoundationSlabCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FoundationSlabPackagingRules packagingRules;
  final FoundationSlabMaterialRules materialRules;
  final FoundationSlabWarningRules warningRules;

  const FoundationSlabCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

// ─── Spec constant ───

const FoundationSlabCanonicalSpec foundationSlabCanonicalSpecV1 = FoundationSlabCanonicalSpec(
  calculatorId: 'foundation-slab',
  formulaVersion: 'foundation-slab-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 60, min: 10, max: 500),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 200, min: 150, max: 300),
    CanonicalInputField(key: 'rebarDiam', unit: 'mm', defaultValue: 12, min: 10, max: 16),
    CanonicalInputField(key: 'rebarStep', unit: 'mm', defaultValue: 200, min: 150, max: 250),
    CanonicalInputField(key: 'insulationThickness', unit: 'mm', defaultValue: 0, min: 0, max: 150),
  ],
  enabledFactors: [
    'geometry_complexity',
    'worker_skill',
    'waste_factor',
  ],
  packagingRules: FoundationSlabPackagingRules(
    unit: 'м³',
    volumeStepM3: 0.1,
  ),
  materialRules: FoundationSlabMaterialRules(
    weightPerMeter: {10: 0.617, 12: 0.888, 14: 1.208, 16: 1.578},
    wirePerJoint: 0.02,
    eppsPlateM2: 0.72,
    geotextileReserve: 1.2,
    formworkReserve: 1.1,
    concreteReserve: 1.05,
    gravelLayer: 0.15,
    sandLayer: 0.1,
    insulationReserve: 1.05,
  ),
  warningRules: FoundationSlabWarningRules(
    largeAreaThresholdM2: 200,
    thinSlabThresholdMm: 150,
  ),
);

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

// ─── Helpers ───

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FoundationSlabCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FoundationSlabCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FoundationSlabCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

Map<String, dynamic> _pickPackage(double exactNeed, double stepSize, String unit) {
  final count = exactNeed > 0 ? (exactNeed / stepSize).ceil() : 0;
  final purchase = _roundValue(count * stepSize, 6);
  final leftover = _roundValue(purchase - exactNeed, 6);
  return {
    'size': stepSize,
    'count': count,
    'purchase': purchase,
    'leftover': leftover,
    'label': 'foundation-slab-$stepSize$unit',
  };
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalFoundationSlab(
  Map<String, double> inputs, {
  FoundationSlabCanonicalSpec spec = foundationSlabCanonicalSpecV1,
}) {
  final area = math.max(10, inputs['area'] ?? _defaultFor(spec, 'area', 60)).toDouble().clamp(10, 500).toDouble();
  final thickness = (inputs['thickness'] ?? _defaultFor(spec, 'thickness', 200)).clamp(150, 300).toDouble();
  final rebarDiam = (inputs['rebarDiam'] ?? _defaultFor(spec, 'rebarDiam', 12)).round().clamp(10, 16);
  final rebarStep = (inputs['rebarStep'] ?? _defaultFor(spec, 'rebarStep', 200)).clamp(150, 250).toDouble();
  final insulationThickness = (inputs['insulationThickness'] ?? _defaultFor(spec, 'insulationThickness', 0)).clamp(0, 150).toDouble();

  final weightPerMeter = spec.materialRules.weightPerMeter[rebarDiam] ?? 0.888;
  final side = math.sqrt(area);
  final perimeter = side * 4;
  final concreteM3 = _roundValue(area * (thickness / 1000) * spec.materialRules.concreteReserve, 6);
  final barsPerDir = (side / (rebarStep / 1000)).ceil() + 1;
  final totalBarLen = barsPerDir * side * 2 * 2;
  final rebarKg = _roundValue(totalBarLen * weightPerMeter, 6);
  final wireKg = _roundValue(barsPerDir * barsPerDir * 2 * spec.materialRules.wirePerJoint, 6);
  final formworkArea = _roundValue(perimeter * (thickness / 1000) * spec.materialRules.formworkReserve, 6);
  final geotextile = _roundValue(area * spec.materialRules.geotextileReserve, 6);
  final gravel = _roundValue(area * spec.materialRules.gravelLayer, 6);
  final sand = _roundValue(area * spec.materialRules.sandLayer, 6);
  final eppsPlates = insulationThickness > 0
      ? (area * spec.materialRules.insulationReserve / spec.materialRules.eppsPlateM2).ceil()
      : 0;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(concreteM3 * multiplier, 6);
    final package = _pickPackage(exactNeed, spec.packagingRules.volumeStepM3, spec.packagingRules.unit);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'rebarDiam:$rebarDiam',
        'rebarStep:${rebarStep.toInt()}',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (thickness <= spec.warningRules.thinSlabThresholdMm) {
    warnings.add('Тонкая плита — убедитесь, что расчёт соответствует нагрузкам');
  }
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь плиты — рекомендуется профессиональный расчёт нагрузок');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон М300',
      quantity: _roundValue(concreteM3, 3),
      unit: 'м³',
      withReserve: _roundValue(concreteM3, 3),
      purchaseQty: concreteM3.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Арматура ∅$rebarDiam мм',
      quantity: _roundValue(rebarKg, 3),
      unit: 'кг',
      withReserve: rebarKg.ceil().toDouble(),
      purchaseQty: rebarKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Проволока вязальная',
      quantity: _roundValue(wireKg, 3),
      unit: 'кг',
      withReserve: wireKg.ceil().toDouble(),
      purchaseQty: wireKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Опалубка (доска)',
      quantity: _roundValue(formworkArea, 3),
      unit: 'м²',
      withReserve: formworkArea.ceil().toDouble(),
      purchaseQty: formworkArea.ceil(),
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Геотекстиль',
      quantity: _roundValue(geotextile, 3),
      unit: 'м²',
      withReserve: geotextile.ceil().toDouble(),
      purchaseQty: geotextile.ceil(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Щебень (подушка)',
      quantity: _roundValue(gravel, 3),
      unit: 'м³',
      withReserve: _roundValue(gravel, 3),
      purchaseQty: gravel.ceil(),
      category: 'Подготовка',
    ),
    CanonicalMaterialResult(
      name: 'Песок (подушка)',
      quantity: _roundValue(sand, 3),
      unit: 'м³',
      withReserve: _roundValue(sand, 3),
      purchaseQty: sand.ceil(),
      category: 'Подготовка',
    ),
  ];

  if (insulationThickness > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'ЭППС утеплитель',
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
      'area': _roundValue(area, 3),
      'thickness': _roundValue(thickness, 3),
      'rebarDiam': rebarDiam.toDouble(),
      'rebarStep': _roundValue(rebarStep, 3),
      'insulationThickness': _roundValue(insulationThickness, 3),
      'side': _roundValue(side, 3),
      'perimeter': _roundValue(perimeter, 3),
      'concreteM3': _roundValue(concreteM3, 3),
      'barsPerDir': barsPerDir.toDouble(),
      'totalBarLen': _roundValue(totalBarLen, 3),
      'rebarKg': _roundValue(rebarKg, 3),
      'wireKg': _roundValue(wireKg, 3),
      'formworkArea': _roundValue(formworkArea, 3),
      'geotextile': _roundValue(geotextile, 3),
      'gravel': _roundValue(gravel, 3),
      'sand': _roundValue(sand, 3),
      'eppsPlates': eppsPlates.toDouble(),
      'minExactNeedM3': scenarios['MIN']!.exactNeed,
      'recExactNeedM3': recScenario.exactNeed,
      'maxExactNeedM3': scenarios['MAX']!.exactNeed,
      'minPurchaseM3': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseM3': recScenario.purchaseQuantity,
      'maxPurchaseM3': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
