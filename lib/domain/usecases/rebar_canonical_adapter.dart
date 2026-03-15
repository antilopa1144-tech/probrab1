import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

// ─── Rebar-specific spec classes ───

class RebarPackagingRules {
  final String unit;
  final double packageSize;

  const RebarPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class RebarMaterialRules {
  final double slabMainReserveFactor;
  final double slabVerticalTieSpacingM;
  final double slabVerticalTieExtraM;
  final double slabFixatorsPerM2;
  final int stripRodCount;
  final double stripStirrupSpacingM;
  final double stripAssumedWidthM;
  final int stripStirrupDiameter;
  final int beltRodCount;
  final double beltHeightM;
  final double beltWidthM;
  final double beltStirrupSpacingM;
  final int beltStirrupDiameter;
  final double floorMainReserveFactor;
  final int floorSecondaryDiameter;
  final int floorSecondaryStepMultiplier;

  const RebarMaterialRules({
    required this.slabMainReserveFactor,
    required this.slabVerticalTieSpacingM,
    required this.slabVerticalTieExtraM,
    required this.slabFixatorsPerM2,
    required this.stripRodCount,
    required this.stripStirrupSpacingM,
    required this.stripAssumedWidthM,
    required this.stripStirrupDiameter,
    required this.beltRodCount,
    required this.beltHeightM,
    required this.beltWidthM,
    required this.beltStirrupSpacingM,
    required this.beltStirrupDiameter,
    required this.floorMainReserveFactor,
    required this.floorSecondaryDiameter,
    required this.floorSecondaryStepMultiplier,
  });
}

class RebarWarningRules {
  final double slabMinHeightForDoubleGridM;
  final int minDiameterForFoundationMm;
  final int wideStepThresholdMm;

  const RebarWarningRules({
    required this.slabMinHeightForDoubleGridM,
    required this.minDiameterForFoundationMm,
    required this.wideStepThresholdMm,
  });
}

class RebarCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final Map<int, double> weightPerMeter;
  final double standardRodLengthM;
  final double wireLengthPerIntersectionM;
  final double wireKgPerM;
  final double rebarOverlapFactor;
  final List<int> allowedDiameters;
  final List<int> allowedGridSteps;
  final RebarPackagingRules packagingRules;
  final RebarMaterialRules materialRules;
  final RebarWarningRules warningRules;

  const RebarCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.weightPerMeter,
    required this.standardRodLengthM,
    required this.wireLengthPerIntersectionM,
    required this.wireKgPerM,
    required this.rebarOverlapFactor,
    required this.allowedDiameters,
    required this.allowedGridSteps,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

// ─── Spec constant ───

const RebarCanonicalSpec rebarCanonicalSpecV1 = RebarCanonicalSpec(
  calculatorId: 'rebar',
  formulaVersion: 'rebar-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'structureType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 10, min: 1, max: 50),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 8, min: 1, max: 50),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 0.3, min: 0.1, max: 1.5),
    CanonicalInputField(key: 'mainDiameter', unit: 'mm', defaultValue: 12, min: 6, max: 16),
    CanonicalInputField(key: 'gridStep', unit: 'mm', defaultValue: 200, min: 100, max: 300),
  ],
  enabledFactors: [
    'geometry_complexity',
    'worker_skill',
    'waste_factor',
  ],
  weightPerMeter: {
    6: 0.222,
    8: 0.395,
    10: 0.617,
    12: 0.888,
    14: 1.21,
    16: 1.58,
  },
  standardRodLengthM: 11.7,
  wireLengthPerIntersectionM: 0.3,
  wireKgPerM: 0.006,
  rebarOverlapFactor: 1.12,
  allowedDiameters: [6, 8, 10, 12, 14, 16],
  allowedGridSteps: [100, 150, 200, 250, 300],
  packagingRules: RebarPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: RebarMaterialRules(
    slabMainReserveFactor: 1.05,
    slabVerticalTieSpacingM: 0.6,
    slabVerticalTieExtraM: 0.2,
    slabFixatorsPerM2: 5,
    stripRodCount: 4,
    stripStirrupSpacingM: 0.4,
    stripAssumedWidthM: 0.3,
    stripStirrupDiameter: 8,
    beltRodCount: 4,
    beltHeightM: 0.25,
    beltWidthM: 0.30,
    beltStirrupSpacingM: 0.4,
    beltStirrupDiameter: 6,
    floorMainReserveFactor: 1.05,
    floorSecondaryDiameter: 6,
    floorSecondaryStepMultiplier: 2,
  ),
  warningRules: RebarWarningRules(
    slabMinHeightForDoubleGridM: 0.15,
    minDiameterForFoundationMm: 10,
    wideStepThresholdMm: 250,
  ),
);


// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

// ─── GOST 5781-82 constants (must match TS and JSON) ───

const Map<int, double> _weightPerMeter = {
  6: 0.222,
  8: 0.395,
  10: 0.617,
  12: 0.888,
  14: 1.21,
  16: 1.58,
};

const double _standardRodLengthM = 11.7;
const double _wireLengthPerIntersectionM = 0.3;
const double _wireKgPerM = 0.006;
const double _rebarOverlapFactor = 1.12;

const List<int> _allowedDiameters = [6, 8, 10, 12, 14, 16];
const List<int> _allowedGridSteps = [100, 150, 200, 250, 300];

// ─── Detection & normalization ───

bool hasCanonicalRebarInputs(Map<String, double> inputs) {
  final hasLength = inputs.containsKey('length');
  final hasWidth = inputs.containsKey('width');
  if (!hasLength || !hasWidth) return false;

  const canonicalKeys = [
    'structureType',
    'mainDiameter',
    'gridStep',
    'height',
  ];
  return canonicalKeys.any(inputs.containsKey);
}

Map<String, double> normalizeLegacyRebarInputs(Map<String, double> inputs) {
  final structureType = (inputs['structureType'] ?? 0).round().clamp(0, 3);
  final length = math.max(1.0, inputs['length'] ?? 10);
  final width = math.max(1.0, inputs['width'] ?? 8);
  final height = (inputs['height'] ?? 0.3).clamp(0.1, 1.5);
  final mainDiameter = _clampToNearest((inputs['mainDiameter'] ?? 12).round(), _allowedDiameters, 12);
  final gridStep = _clampToNearest((inputs['gridStep'] ?? 200).round(), _allowedGridSteps, 200);

  return {
    'structureType': structureType.toDouble(),
    'length': length.toDouble(),
    'width': width.toDouble(),
    'height': height.toDouble(),
    'mainDiameter': mainDiameter.toDouble(),
    'gridStep': gridStep.toDouble(),
  };
}

// ─── Helpers ───

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(RebarCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

int _clampToNearest(int value, List<int> allowed, int fallback) {
  if (allowed.contains(value)) return value;
  var closest = fallback;
  var minDist = 999999;
  for (final v in allowed) {
    final dist = (v - value).abs();
    if (dist < minDist) {
      minDist = dist;
      closest = v;
    }
  }
  return closest;
}

Map<String, double> _keyFactors(RebarCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(RebarCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

// ─── Per-structure-type calculations ───

class _RebarCalcResult {
  final double mainRebarLength;
  final double tieRebarLength;
  final int intersections;
  final int fixators;
  final int secondaryDiameter;
  final int barsAlongLength;
  final int barsAlongWidth;
  final int verticalTieCount;
  final int stirrupCount;

  const _RebarCalcResult({
    required this.mainRebarLength,
    required this.tieRebarLength,
    required this.intersections,
    required this.fixators,
    required this.secondaryDiameter,
    required this.barsAlongLength,
    required this.barsAlongWidth,
    required this.verticalTieCount,
    required this.stirrupCount,
  });
}

_RebarCalcResult _computeSlabRebar(
  double length,
  double width,
  double height,
  double gridStepM,
  int mainDiameter,
) {
  final barsAlongLength = (width / gridStepM).ceil() + 1;
  final barsAlongWidth = (length / gridStepM).ceil() + 1;
  final mainRebarLength = 2 * (barsAlongLength * length + barsAlongWidth * width) * 1.05;
  final verticalTieCount = (length / 0.6).ceil() * (width / 0.6).ceil();
  final verticalTieLength = (height + 0.2) * verticalTieCount;
  final secondaryDiameter = math.max(6, mainDiameter - 4);
  final intersections = barsAlongLength * barsAlongWidth * 2 + verticalTieCount * 2;
  final fixators = (length * width * 5).ceil();

  return _RebarCalcResult(
    mainRebarLength: mainRebarLength,
    tieRebarLength: verticalTieLength,
    intersections: intersections,
    fixators: fixators,
    secondaryDiameter: secondaryDiameter,
    barsAlongLength: barsAlongLength,
    barsAlongWidth: barsAlongWidth,
    verticalTieCount: verticalTieCount,
    stirrupCount: 0,
  );
}

_RebarCalcResult _computeStripFoundationRebar(
  double length,
  double width,
  double height,
) {
  final perimeter = 2 * (length + width);
  final mainRebarLength = perimeter * 4 * _rebarOverlapFactor;
  final stirrupCount = (perimeter / 0.4).ceil();
  final sectionPerimeter = 2.0 * (0.3 + height - 0.1);
  final tieRebarLength = (stirrupCount * math.max(0.8, sectionPerimeter)).toDouble();
  const stirrupDiameter = 8;
  final intersections = stirrupCount * 4;

  return _RebarCalcResult(
    mainRebarLength: mainRebarLength,
    tieRebarLength: tieRebarLength,
    intersections: intersections,
    fixators: 0,
    secondaryDiameter: stirrupDiameter,
    barsAlongLength: 0,
    barsAlongWidth: 0,
    verticalTieCount: 0,
    stirrupCount: stirrupCount,
  );
}

_RebarCalcResult _computeArmorBeltRebar(
  double length,
  double width,
) {
  final perimeter = 2 * (length + width);
  final mainRebarLength = perimeter * 4 * _rebarOverlapFactor;
  const beltHeight = 0.25;
  const beltWidth = 0.30;
  final stirrupCount = (perimeter / 0.4).ceil();
  final tieRebarLength = stirrupCount * 2 * (beltWidth + beltHeight - 0.1);
  const stirrupDiameter = 6;

  return _RebarCalcResult(
    mainRebarLength: mainRebarLength,
    tieRebarLength: tieRebarLength,
    intersections: stirrupCount * 4,
    fixators: 0,
    secondaryDiameter: stirrupDiameter,
    barsAlongLength: 0,
    barsAlongWidth: 0,
    verticalTieCount: 0,
    stirrupCount: stirrupCount,
  );
}

_RebarCalcResult _computeFloorSlabRebar(
  double length,
  double width,
  double gridStepM,
) {
  final barsAlongLength = (width / gridStepM).ceil() + 1;
  final barsAlongWidth = (length / gridStepM).ceil() + 1;
  final mainRebarLength = (barsAlongLength * length + barsAlongWidth * width) * 1.05;
  final secondaryStep = gridStepM * 2;
  final secBarsL = (width / secondaryStep).ceil() + 1;
  final secBarsW = (length / secondaryStep).ceil() + 1;
  final secondaryLength = (secBarsL * length + secBarsW * width) * 1.05;
  final intersections = barsAlongLength * barsAlongWidth;

  return _RebarCalcResult(
    mainRebarLength: mainRebarLength,
    tieRebarLength: secondaryLength,
    intersections: intersections,
    fixators: 0,
    secondaryDiameter: 6,
    barsAlongLength: barsAlongLength,
    barsAlongWidth: barsAlongWidth,
    verticalTieCount: 0,
    stirrupCount: 0,
  );
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalRebar(
  Map<String, double> inputs, {
  RebarCanonicalSpec spec = rebarCanonicalSpecV1,
}) {
  final structureType = (inputs['structureType'] ?? _defaultFor(spec, 'structureType', 0)).round().clamp(0, 3);
  final length = math.max(1.0, math.min(50.0, inputs['length'] ?? _defaultFor(spec, 'length', 10)));
  final width = math.max(1.0, math.min(50.0, inputs['width'] ?? _defaultFor(spec, 'width', 8)));
  final height = (inputs['height'] ?? _defaultFor(spec, 'height', 0.3)).clamp(0.1, 1.5).toDouble();
  final mainDiameter = _clampToNearest(
    (inputs['mainDiameter'] ?? _defaultFor(spec, 'mainDiameter', 12)).round(),
    _allowedDiameters,
    12,
  );
  final gridStep = _clampToNearest(
    (inputs['gridStep'] ?? _defaultFor(spec, 'gridStep', 200)).round(),
    _allowedGridSteps,
    200,
  );

  final gridStepM = gridStep / 1000.0;

  _RebarCalcResult calc;

  switch (structureType) {
    case 0:
      calc = _computeSlabRebar(length, width, height, gridStepM, mainDiameter);
      break;
    case 1:
      calc = _computeStripFoundationRebar(length, width, height);
      break;
    case 2:
      calc = _computeArmorBeltRebar(length, width);
      break;
    case 3:
      calc = _computeFloorSlabRebar(length, width, gridStepM);
      break;
    default:
      calc = _computeSlabRebar(length, width, height, gridStepM, mainDiameter);
  }

  final wireLength = calc.intersections * _wireLengthPerIntersectionM;
  final wireKg = wireLength * _wireKgPerM;
  final mainWeightPerM = _weightPerMeter[mainDiameter] ?? _weightPerMeter[12]!;
  final mainRebarKg = calc.mainRebarLength * mainWeightPerM;
  final mainRods = (calc.mainRebarLength / _standardRodLengthM).ceil();
  final tieWeightPerM = _weightPerMeter[calc.secondaryDiameter] ?? _weightPerMeter[6]!;
  final tieRebarKg = calc.tieRebarLength * tieWeightPerM;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(mainRebarKg * multiplier, 6);
    final rodCount = (mainRods * multiplier).ceil();
    const packageLabel = 'rebar-rod-${_standardRodLengthM}m';

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: rodCount.toDouble(),
      leftover: _roundValue(rodCount.toDouble() - (mainRods * multiplier), 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'structureType:$structureType',
        'mainDiameter:$mainDiameter',
        'gridStep:$gridStep',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: rodCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (structureType == 0 && height < 0.15) {
    warnings.add('Толщина плиты менее 150 мм — слишком тонкая для двойной сетки армирования');
  }
  if (mainDiameter < 10 && structureType <= 1) {
    warnings.add('Для фундаментов рекомендуется арматура диаметром не менее 10 мм');
  }
  if (gridStep > 250) {
    warnings.add('Шаг сетки более 250 мм снижает несущую способность конструкции');
  }

  // Secondary label
  final secondaryLabel = structureType <= 2
      ? 'Арматура для хомутов Ø${calc.secondaryDiameter} А500С'
      : 'Арматура вторичная Ø${calc.secondaryDiameter} А240';

  // Materials list
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Арматура основная Ø$mainDiameter А500С',
      quantity: _roundValue(calc.mainRebarLength, 1),
      unit: 'м.п.',
      withReserve: _roundValue(mainRebarKg, 1),
      purchaseQty: mainRods,
      category: 'Арматура',
    ),
    CanonicalMaterialResult(
      name: secondaryLabel,
      quantity: _roundValue(calc.tieRebarLength, 1),
      unit: 'м.п.',
      withReserve: _roundValue(tieRebarKg, 1),
      purchaseQty: (calc.tieRebarLength / _standardRodLengthM).ceil(),
      category: 'Арматура',
    ),
    CanonicalMaterialResult(
      name: 'Проволока вязальная Ø1.2',
      quantity: _roundValue(wireKg, 2),
      unit: 'кг',
      withReserve: _roundValue(wireKg, 2),
      purchaseQty: wireKg.ceil(),
      category: 'Расходные материалы',
    ),
  ];

  if (calc.fixators > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Фиксаторы пластиковые',
      quantity: calc.fixators.toDouble(),
      unit: 'шт',
      withReserve: calc.fixators.toDouble(),
      purchaseQty: calc.fixators,
      category: 'Расходные материалы',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'structureType': structureType.toDouble(),
      'length': _roundValue(length, 3),
      'width': _roundValue(width, 3),
      'height': _roundValue(height, 3),
      'mainDiameter': mainDiameter.toDouble(),
      'gridStep': gridStep.toDouble(),
      'gridStepM': _roundValue(gridStepM, 4),
      'mainRebarLength': _roundValue(calc.mainRebarLength, 1),
      'mainRebarKg': _roundValue(mainRebarKg, 1),
      'mainRods': mainRods.toDouble(),
      'tieRebarLength': _roundValue(calc.tieRebarLength, 1),
      'tieRebarKg': _roundValue(tieRebarKg, 1),
      'secondaryDiameter': calc.secondaryDiameter.toDouble(),
      'intersections': calc.intersections.toDouble(),
      'wireLength': _roundValue(wireLength, 1),
      'wireKg': _roundValue(wireKg, 2),
      'fixators': calc.fixators.toDouble(),
      'barsAlongLength': calc.barsAlongLength.toDouble(),
      'barsAlongWidth': calc.barsAlongWidth.toDouble(),
      'verticalTieCount': calc.verticalTieCount.toDouble(),
      'stirrupCount': calc.stirrupCount.toDouble(),
      'minExactNeedKg': scenarios['MIN']!.exactNeed,
      'recExactNeedKg': recScenario.exactNeed,
      'maxExactNeedKg': scenarios['MAX']!.exactNeed,
      'minPurchaseRods': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseRods': recScenario.purchaseQuantity,
      'maxPurchaseRods': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
