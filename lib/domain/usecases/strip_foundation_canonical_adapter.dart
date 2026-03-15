import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

// ─── Strip Foundation spec classes ───

class StripFoundationPackagingRules {
  final String unit;
  final double volumeStepM3;

  const StripFoundationPackagingRules({
    required this.unit,
    required this.volumeStepM3,
  });
}

class StripFoundationMaterialRules {
  final Map<int, int> rebarDiameters;
  final Map<int, int> rebarThreads;
  final Map<int, double> weightPerM;
  final double clampWeight;
  final double clampStep;
  final Map<int, double> techLoss;
  final double concreteReserve;
  final double overlap;

  const StripFoundationMaterialRules({
    required this.rebarDiameters,
    required this.rebarThreads,
    required this.weightPerM,
    required this.clampWeight,
    required this.clampStep,
    required this.techLoss,
    required this.concreteReserve,
    required this.overlap,
  });
}

class StripFoundationWarningRules {
  final int shallowDepthThresholdMm;
  final int largePerimeterThresholdM;

  const StripFoundationWarningRules({
    required this.shallowDepthThresholdMm,
    required this.largePerimeterThresholdM,
  });
}

class StripFoundationCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final StripFoundationPackagingRules packagingRules;
  final StripFoundationMaterialRules materialRules;
  final StripFoundationWarningRules warningRules;

  const StripFoundationCanonicalSpec({
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

const StripFoundationCanonicalSpec stripFoundationCanonicalSpecV1 = StripFoundationCanonicalSpec(
  calculatorId: 'strip-foundation',
  formulaVersion: 'strip-foundation-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'perimeter', unit: 'm', defaultValue: 40, min: 10, max: 200),
    CanonicalInputField(key: 'width', unit: 'mm', defaultValue: 400, min: 200, max: 600),
    CanonicalInputField(key: 'depth', unit: 'mm', defaultValue: 700, min: 300, max: 2000),
    CanonicalInputField(key: 'aboveGround', unit: 'mm', defaultValue: 300, min: 0, max: 600),
    CanonicalInputField(key: 'reinforcement', defaultValue: 1, min: 0, max: 3),
    CanonicalInputField(key: 'deliveryMethod', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: [
    'geometry_complexity',
    'worker_skill',
    'waste_factor',
  ],
  packagingRules: StripFoundationPackagingRules(
    unit: 'м³',
    volumeStepM3: 0.1,
  ),
  materialRules: StripFoundationMaterialRules(
    rebarDiameters: {0: 12, 1: 12, 2: 14, 3: 12},
    rebarThreads: {0: 2, 1: 4, 2: 4, 3: 6},
    weightPerM: {12: 0.888, 14: 1.21},
    clampWeight: 0.395,
    clampStep: 0.4,
    techLoss: {0: 0.5, 1: 0, 2: 0},
    concreteReserve: 1.07,
    overlap: 1.12,
  ),
  warningRules: StripFoundationWarningRules(
    shallowDepthThresholdMm: 400,
    largePerimeterThresholdM: 100,
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

double _defaultFor(StripFoundationCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(StripFoundationCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(StripFoundationCanonicalSpec spec, String scenario) {
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
    'label': 'strip-foundation-$stepSize$unit',
  };
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalStripFoundation(
  Map<String, double> inputs, {
  StripFoundationCanonicalSpec spec = stripFoundationCanonicalSpecV1,
}) {
  final perimeter = math.max(10, inputs['perimeter'] ?? _defaultFor(spec, 'perimeter', 40)).toDouble().clamp(10, 200).toDouble();
  final width = (inputs['width'] ?? _defaultFor(spec, 'width', 400)).clamp(200, 600).toDouble();
  final depth = (inputs['depth'] ?? _defaultFor(spec, 'depth', 700)).clamp(300, 2000).toDouble();
  final aboveGround = (inputs['aboveGround'] ?? _defaultFor(spec, 'aboveGround', 300)).clamp(0, 600).toDouble();
  final reinforcement = (inputs['reinforcement'] ?? _defaultFor(spec, 'reinforcement', 1)).round().clamp(0, 3);
  final deliveryMethod = (inputs['deliveryMethod'] ?? _defaultFor(spec, 'deliveryMethod', 0)).round().clamp(0, 2);

  final rebarDiam = spec.materialRules.rebarDiameters[reinforcement] ?? 12;
  final threads = spec.materialRules.rebarThreads[reinforcement] ?? 4;
  final weightPerM = spec.materialRules.weightPerM[rebarDiam] ?? 0.888;

  final totalH = (depth + aboveGround) / 1000;
  final vol = perimeter * (width / 1000) * totalH;
  final techLoss = spec.materialRules.techLoss[deliveryMethod] ?? 0;
  final volReserve = _roundValue((vol + techLoss) * spec.materialRules.concreteReserve, 6);

  final longLen = _roundValue(perimeter * threads * spec.materialRules.overlap, 6);
  final longWeightKg = _roundValue(longLen * weightPerM, 6);

  final clampCount = (perimeter / spec.materialRules.clampStep).ceil();
  final clampPerim = 2 * ((width / 1000) - 0.1 + totalH - 0.1) + 0.3;
  final clampLen = _roundValue(clampCount * math.max(0.8, clampPerim) * 1.05, 6);
  final clampWeightKg = _roundValue(clampLen * spec.materialRules.clampWeight, 6);

  final wireKg = _roundValue((clampCount * threads * 0.05 * 1.1 * 10).ceil() / 10, 6);

  final formwork = _roundValue(2 * perimeter * (aboveGround / 1000 + 0.1), 6);
  final boards = (formwork / (0.15 * 6)).ceil();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(volReserve * multiplier, 6);
    final package = _pickPackage(exactNeed, spec.packagingRules.volumeStepM3, spec.packagingRules.unit);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'reinforcement:$reinforcement',
        'deliveryMethod:$deliveryMethod',
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
  if (depth <= spec.warningRules.shallowDepthThresholdMm) {
    warnings.add('Мелкое заглубление — убедитесь, что глубина ниже уровня промерзания грунта');
  }
  if (perimeter > spec.warningRules.largePerimeterThresholdM) {
    warnings.add('Большой периметр — рекомендуется разделить на секции с деформационными швами');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Бетон М300',
      quantity: _roundValue(volReserve, 3),
      unit: 'м³',
      withReserve: _roundValue(volReserve, 3),
      purchaseQty: volReserve.ceil(),
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Арматура продольная ∅$rebarDiam мм',
      quantity: _roundValue(longWeightKg, 3),
      unit: 'кг',
      withReserve: longWeightKg.ceil().toDouble(),
      purchaseQty: longWeightKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Арматура поперечная (хомуты)',
      quantity: _roundValue(clampWeightKg, 3),
      unit: 'кг',
      withReserve: clampWeightKg.ceil().toDouble(),
      purchaseQty: clampWeightKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Проволока вязальная',
      quantity: _roundValue(wireKg, 3),
      unit: 'кг',
      withReserve: _roundValue(wireKg, 3),
      purchaseQty: wireKg.ceil(),
      category: 'Армирование',
    ),
    CanonicalMaterialResult(
      name: 'Опалубка (доска обрезная)',
      quantity: _roundValue(formwork, 3),
      unit: 'м²',
      withReserve: formwork.ceil().toDouble(),
      purchaseQty: formwork.ceil(),
      category: 'Опалубка',
    ),
    CanonicalMaterialResult(
      name: 'Доска обрезная 150×6000 мм',
      quantity: boards.toDouble(),
      unit: 'шт',
      withReserve: boards.toDouble(),
      purchaseQty: boards,
      category: 'Опалубка',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'perimeter': _roundValue(perimeter, 3),
      'width': _roundValue(width, 3),
      'depth': _roundValue(depth, 3),
      'aboveGround': _roundValue(aboveGround, 3),
      'reinforcement': reinforcement.toDouble(),
      'deliveryMethod': deliveryMethod.toDouble(),
      'totalH': _roundValue(totalH, 3),
      'vol': _roundValue(vol, 3),
      'volReserve': _roundValue(volReserve, 3),
      'rebarDiam': rebarDiam.toDouble(),
      'threads': threads.toDouble(),
      'longLen': _roundValue(longLen, 3),
      'longWeightKg': _roundValue(longWeightKg, 3),
      'clampCount': clampCount.toDouble(),
      'clampLen': _roundValue(clampLen, 3),
      'clampWeightKg': _roundValue(clampWeightKg, 3),
      'wireKg': _roundValue(wireKg, 3),
      'formwork': _roundValue(formwork, 3),
      'boards': boards.toDouble(),
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
