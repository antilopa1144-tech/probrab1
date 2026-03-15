import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

// ─── Stairs spec classes ───

class StairsPackagingRules {
  final String unit;
  final double packageSize;

  const StairsPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class StairsMaterialRules {
  final String stringerBoard;
  final String treadBoard;
  final String riserBoard;
  final int stringersCount;
  final double railingSpacing;
  final double concreteDensityForStairs;
  final double rebarKgPerStepWidth;

  const StairsMaterialRules({
    required this.stringerBoard,
    required this.treadBoard,
    required this.riserBoard,
    required this.stringersCount,
    required this.railingSpacing,
    required this.concreteDensityForStairs,
    required this.rebarKgPerStepWidth,
  });
}

class StairsWarningRules {
  final int steepStepThresholdMm;
  final int maxStepsPerFlight;

  const StairsWarningRules({
    required this.steepStepThresholdMm,
    required this.maxStepsPerFlight,
  });
}

class StairsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final StairsPackagingRules packagingRules;
  final StairsMaterialRules materialRules;
  final StairsWarningRules warningRules;

  const StairsCanonicalSpec({
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

const StairsCanonicalSpec stairsCanonicalSpecV1 = StairsCanonicalSpec(
  calculatorId: 'stairs',
  formulaVersion: 'stairs-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'floorHeight', unit: 'm', defaultValue: 2.8, min: 2.0, max: 6.0),
    CanonicalInputField(key: 'stepHeight', unit: 'mm', defaultValue: 170, min: 150, max: 200),
    CanonicalInputField(key: 'stepWidth', unit: 'mm', defaultValue: 280, min: 250, max: 320),
    CanonicalInputField(key: 'stairWidth', unit: 'm', defaultValue: 1.0, min: 0.6, max: 2.0),
    CanonicalInputField(key: 'materialType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: [
    'geometry_complexity',
    'worker_skill',
    'waste_factor',
  ],
  packagingRules: StairsPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: StairsMaterialRules(
    stringerBoard: '50×250',
    treadBoard: '40×300',
    riserBoard: '20×170',
    stringersCount: 2,
    railingSpacing: 0.15,
    concreteDensityForStairs: 2400,
    rebarKgPerStepWidth: 10,
  ),
  warningRules: StairsWarningRules(
    steepStepThresholdMm: 190,
    maxStepsPerFlight: 18,
  ),
);

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];
const List<String> _materialLabels = ['wood', 'concrete', 'metal'];

// ─── Helpers ───

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(StairsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(StairsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(StairsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalStairs(
  Map<String, double> inputs, {
  StairsCanonicalSpec spec = stairsCanonicalSpecV1,
}) {
  final floorHeight = (inputs['floorHeight'] ?? _defaultFor(spec, 'floorHeight', 2.8)).clamp(2.0, 6.0).toDouble();
  final stepHeight = (inputs['stepHeight'] ?? _defaultFor(spec, 'stepHeight', 170)).clamp(150, 200).toDouble();
  final stepWidth = (inputs['stepWidth'] ?? _defaultFor(spec, 'stepWidth', 280)).clamp(250, 320).toDouble();
  final stairWidth = (inputs['stairWidth'] ?? _defaultFor(spec, 'stairWidth', 1.0)).clamp(0.6, 2.0).toDouble();
  final materialType = (inputs['materialType'] ?? _defaultFor(spec, 'materialType', 0)).round().clamp(0, 2);

  final stepCount = (floorHeight / (stepHeight / 1000)).round();
  final realStepH = _roundValue(floorHeight / stepCount, 6);
  final horizLen = _roundValue((stepCount - 1) * (stepWidth / 1000), 6);
  final stringerLen = _roundValue(math.sqrt(floorHeight * floorHeight + horizLen * horizLen), 6);
  final railingLen = _roundValue(horizLen * 2, 6);
  final balyasiny = (railingLen / spec.materialRules.railingSpacing).ceil();

  final materialKey = materialType < _materialLabels.length ? _materialLabels[materialType] : 'wood';

  // Build materials based on material type
  final materials = <CanonicalMaterialResult>[];

  if (materialType == 0) {
    // Wood
    final stringerBoard = (stringerLen * 1.1).ceil() * spec.materialRules.stringersCount;
    final screws = stepCount * 8;
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Тетива/косоур (${spec.materialRules.stringerBoard})',
        quantity: stringerBoard.toDouble(),
        unit: 'п.м',
        withReserve: stringerBoard.toDouble(),
        purchaseQty: stringerBoard,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Ступени (${spec.materialRules.treadBoard})',
        quantity: stepCount.toDouble(),
        unit: 'шт',
        withReserve: stepCount.toDouble(),
        purchaseQty: stepCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Подступенки (${spec.materialRules.riserBoard})',
        quantity: stepCount.toDouble(),
        unit: 'шт',
        withReserve: stepCount.toDouble(),
        purchaseQty: stepCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Саморезы',
        quantity: screws.toDouble(),
        unit: 'шт',
        withReserve: screws.toDouble(),
        purchaseQty: screws,
        category: 'Крепёж',
      ),
    ]);
  } else if (materialType == 1) {
    // Concrete
    final vol = _roundValue(stairWidth * (stepWidth / 1000) * (stepHeight / 1000) / 2 * stepCount, 6);
    final rebarKg = _roundValue(stepCount * stairWidth * spec.materialRules.rebarKgPerStepWidth, 3);
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Бетон М300',
        quantity: _roundValue(vol, 3),
        unit: 'м³',
        withReserve: _roundValue(vol, 3),
        purchaseQty: vol.ceil(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Арматура',
        quantity: rebarKg,
        unit: 'кг',
        withReserve: rebarKg.ceil().toDouble(),
        purchaseQty: rebarKg.ceil(),
        category: 'Армирование',
      ),
    ]);
  } else {
    // Metal
    final channelLen = _roundValue(stringerLen * 2 * 1.1, 3);
    final bolts = stepCount * 4;
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Швеллер (каркас)',
        quantity: channelLen,
        unit: 'п.м',
        withReserve: channelLen.ceil().toDouble(),
        purchaseQty: channelLen.ceil(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Болты крепёжные',
        quantity: bolts.toDouble(),
        unit: 'шт',
        withReserve: bolts.toDouble(),
        purchaseQty: bolts,
        category: 'Крепёж',
      ),
    ]);
  }

  // Railing materials (common for all types)
  materials.addAll([
    CanonicalMaterialResult(
      name: 'Перила (поручень)',
      quantity: _roundValue(railingLen, 3),
      unit: 'п.м',
      withReserve: railingLen.ceil().toDouble(),
      purchaseQty: railingLen.ceil(),
      category: 'Ограждение',
    ),
    CanonicalMaterialResult(
      name: 'Балясины',
      quantity: balyasiny.toDouble(),
      unit: 'шт',
      withReserve: balyasiny.toDouble(),
      purchaseQty: balyasiny,
      category: 'Ограждение',
    ),
  ]);

  // Scenarios
  final baseExactNeed = stepCount;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeed * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'stairs-step-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'material:$materialKey',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (stepHeight > spec.warningRules.steepStepThresholdMm) {
    warnings.add('Высота ступени выше нормы — лестница может быть некомфортной');
  }
  if (stepCount > spec.warningRules.maxStepsPerFlight) {
    warnings.add('Большое количество ступеней — рекомендуется устройство промежуточной площадки');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'floorHeight': _roundValue(floorHeight, 3),
      'stepHeight': _roundValue(stepHeight, 3),
      'stepWidth': _roundValue(stepWidth, 3),
      'stairWidth': _roundValue(stairWidth, 3),
      'materialType': materialType.toDouble(),
      'stepCount': stepCount.toDouble(),
      'realStepH': _roundValue(realStepH, 6),
      'horizLen': _roundValue(horizLen, 3),
      'stringerLen': _roundValue(stringerLen, 3),
      'railingLen': _roundValue(railingLen, 3),
      'balyasiny': balyasiny.toDouble(),
      'minExactNeedSteps': scenarios['MIN']!.exactNeed,
      'recExactNeedSteps': recScenario.exactNeed,
      'maxExactNeedSteps': scenarios['MAX']!.exactNeed,
      'minPurchaseSteps': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseSteps': recScenario.purchaseQuantity,
      'maxPurchaseSteps': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
