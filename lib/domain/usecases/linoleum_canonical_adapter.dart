import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

const LinoleumCanonicalSpec linoleumCanonicalSpecV1 = LinoleumCanonicalSpec(
  calculatorId: 'linoleum',
  formulaVersion: 'linoleum-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 30),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 500),
    CanonicalInputField(key: 'roomWidth', unit: 'm', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'perimeter', unit: 'm', defaultValue: 0, min: 0, max: 200),
    CanonicalInputField(key: 'rollWidth', unit: 'm', defaultValue: 3, min: 1.5, max: 5),
    CanonicalInputField(key: 'hasPattern', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'patternRepeatCm', unit: 'cm', defaultValue: 30, min: 0, max: 100),
    CanonicalInputField(key: 'needGlue', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'needPlinth', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'needTape', defaultValue: 1, min: 0, max: 1),
  ],
  enabledFactors: ['geometry_complexity', 'installation_method'],
  packagingRules: LinoleumPackagingRules(
    linearMeterUnit: 'м.п.',
    linearMeterStepM: 0.1,
    plinthPieceLengthM: 2.5,
    primerCanLiters: 10,
    glueBucketKg: 10,
    coldWeldingTubeLinearM: 20,
  ),
  materialRules: LinoleumMaterialRules(
    trimAllowanceM: 0.1,
    roomMarginM: 0.2,
    glueKgPerM2: 0.4,
    primerLitersPerM2: 0.15,
    plinthReservePercent: 5,
    defaultDoorOpeningWidthM: 0.9,
    tapeExtraPerimeterRun: 1,
  ),
  warningRules: LinoleumWarningRules(
    highWastePercentThreshold: 25,
    maxSingleRollWidthM: 5,
    lowRollWidthWarningThresholdM: 3,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

bool hasCanonicalLinoleumInputs(Map<String, double> inputs) {
  final hasLegacyAliases = inputs.containsKey('roomLength') ||
      inputs.containsKey('withGlue') ||
      inputs.containsKey('withPlinth') ||
      inputs.containsKey('patternRepeat');
  if (hasLegacyAliases) return false;

  return inputs.containsKey('patternRepeatCm') ||
      inputs.containsKey('needGlue') ||
      inputs.containsKey('needPlinth') ||
      inputs.containsKey('needTape');
}

Map<String, double> normalizeLegacyLinoleumInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final hasRoomDimensions = (inputs['roomLength'] ?? 0) > 0 && (inputs['roomWidth'] ?? 0) > 0;
  final hasLegacyV2Signals = inputs.containsKey('marginCm') || inputs.containsKey('rollLength') || inputs.containsKey('needTape');

  if (!normalized.containsKey('length') && (inputs['roomLength'] ?? 0) > 0) {
    normalized['length'] = (inputs['roomLength'] ?? 0).toDouble();
  }
  if (!normalized.containsKey('width') && hasRoomDimensions) {
    normalized['width'] = (inputs['roomWidth'] ?? 0).toDouble();
  }

  if (!normalized.containsKey('inputMode')) {
    if (hasRoomDimensions || ((inputs['length'] ?? 0) > 0 && (inputs['width'] ?? 0) > 0)) {
      normalized['inputMode'] = 0.0;
    } else if ((inputs['area'] ?? 0) > 0) {
      normalized['inputMode'] = 1.0;
    }
  }

  if ((normalized['inputMode'] ?? 0).round() == 1 && (normalized['roomWidth'] ?? 0) <= 0) {
    final area = inputs['area'] ?? 0;
    if (area > 0) {
      normalized['roomWidth'] = math.sqrt(area);
    }
  }

  normalized['rollWidth'] = (inputs['rollWidth'] ?? 3.0).toDouble();
  normalized['hasPattern'] = ((inputs['hasPattern'] ?? 0) > 0 ? 1 : 0).toDouble();
  normalized['patternRepeatCm'] = (inputs['patternRepeatCm'] ?? inputs['patternRepeat'] ?? 30).toDouble();
  normalized['needGlue'] = ((inputs['needGlue'] ?? inputs['withGlue'] ?? 0) > 0 ? 1 : 0).toDouble();
  normalized['needPlinth'] = ((inputs['needPlinth'] ?? inputs['withPlinth'] ?? 1) > 0 ? 1 : 0).toDouble();
  normalized['needTape'] = ((inputs['needTape'] ?? (hasLegacyV2Signals ? 1 : 0)) > 0 ? 1 : 0).toDouble();

  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(LinoleumCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveGeometry(LinoleumCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(1, inputs['length'] ?? _defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(1, inputs['width'] ?? _defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': _roundValue(length * width, 3),
      'roomLength': _roundValue(length, 3),
      'roomWidth': _roundValue(width, 3),
      'perimeter': _roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(1, inputs['area'] ?? _defaultFor(spec, 'area', 20)).toDouble();
  final roomWidth = math.max(1, inputs['roomWidth'] ?? _defaultFor(spec, 'roomWidth', 4)).toDouble();
  final roomLength = area / roomWidth;
  final explicitPerimeter = math.max(0, inputs['perimeter'] ?? 0).toDouble();
  return {
    'inputMode': 1.0,
    'area': _roundValue(area, 3),
    'roomLength': _roundValue(roomLength, 3),
    'roomWidth': _roundValue(roomWidth, 3),
    'perimeter': _roundValue(explicitPerimeter > 0 ? explicitPerimeter : _estimatePerimeter(area), 3),
  };
}

double _scenarioMultiplier(LinoleumCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

Map<String, double> _keyFactors(LinoleumCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _roundLinearMeters(double value, double step) {
  final safeStep = step > 0 ? step : 0.1;
  return (value / safeStep).ceil() * safeStep;
}

CanonicalCalculatorContractResult calculateCanonicalLinoleum(
  Map<String, double> inputs, {
  LinoleumCanonicalSpec spec = linoleumCanonicalSpecV1,
}) {
  final normalized = hasCanonicalLinoleumInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyLinoleumInputs(inputs);
  final geometry = _resolveGeometry(spec, normalized);
  final rollWidth = (normalized['rollWidth'] ?? _defaultFor(spec, 'rollWidth', 3))
      .clamp(1.5, spec.warningRules.maxSingleRollWidthM)
      .toDouble();
  final hasPattern = (normalized['hasPattern'] ?? _defaultFor(spec, 'hasPattern', 0)) > 0;
  final patternRepeatM = math.max(0, normalized['patternRepeatCm'] ?? _defaultFor(spec, 'patternRepeatCm', 30)).toDouble() / 100;
  final needGlue = (normalized['needGlue'] ?? _defaultFor(spec, 'needGlue', 0)) > 0;
  final needPlinth = (normalized['needPlinth'] ?? _defaultFor(spec, 'needPlinth', 1)) > 0;
  final needTape = (normalized['needTape'] ?? _defaultFor(spec, 'needTape', 1)) > 0;

  final longerSide = math.max(geometry['roomLength']!, geometry['roomWidth']!);
  final shorterSide = math.min(geometry['roomLength']!, geometry['roomWidth']!);
  final stripsNeeded = math.max(1, (shorterSide / rollWidth).ceil());
  final stripLengthBase = longerSide + spec.materialRules.trimAllowanceM;
  final totalLinearM = hasPattern && stripsNeeded > 1
      ? stripLengthBase + (stripLengthBase + patternRepeatM) * (stripsNeeded - 1)
      : stripLengthBase * stripsNeeded;
  final linearMetersRounded = _roundLinearMeters(totalLinearM, spec.packagingRules.linearMeterStepM);
  final totalCoverageArea = _roundValue(linearMetersRounded * rollWidth, 6);
  final wastePercent = geometry['area']! > 0
      ? _roundValue(((totalCoverageArea - geometry['area']!) / geometry['area']!) * 100, 3)
      : 0.0;

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(totalLinearM * multiplier, 6);
    final purchaseQuantity = _roundLinearMeters(exactNeed, spec.packagingRules.linearMeterStepM);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: _roundValue(purchaseQuantity, 6),
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'roll_width:$rollWidth',
        'pattern:${hasPattern ? 'rapport' : 'plain'}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'linoleum-linear-${spec.packagingRules.linearMeterStepM}',
        packageSize: spec.packagingRules.linearMeterStepM,
        packagesCount: (purchaseQuantity / spec.packagingRules.linearMeterStepM).round(),
        unit: spec.packagingRules.linearMeterUnit,
      ),
    );
  }

  final seamsLength = stripsNeeded > 1 ? _roundValue((stripsNeeded - 1) * longerSide, 6) : 0.0;
  final coldWeldingTubes = seamsLength > 0
      ? math.max(1, (seamsLength / spec.packagingRules.coldWeldingTubeLinearM).ceil())
      : 0;
  final glueKg = needGlue ? _roundValue(geometry['area']! * spec.materialRules.glueKgPerM2, 6) : 0.0;
  final glueBuckets = needGlue ? math.max(1, (glueKg / spec.packagingRules.glueBucketKg).ceil()) : 0;
  final primerLiters = _roundValue(geometry['area']! * spec.materialRules.primerLitersPerM2, 6);
  final primerCans = math.max(1, (primerLiters / spec.packagingRules.primerCanLiters).ceil());
  final plinthLengthRaw = needPlinth
      ? math.max(0.0, geometry['perimeter']! - spec.materialRules.defaultDoorOpeningWidthM).toDouble()
      : 0.0;
  final plinthLengthWithReserve = needPlinth
      ? _roundValue(plinthLengthRaw * (1 + spec.materialRules.plinthReservePercent / 100), 6)
      : 0.0;
  final plinthPieces = needPlinth
      ? (plinthLengthWithReserve / spec.packagingRules.plinthPieceLengthM).ceil()
      : 0;
  final tapeLength = needTape
      ? _roundValue(geometry['perimeter']! + longerSide * spec.materialRules.tapeExtraPerimeterRun, 6)
      : 0.0;

  final warnings = <String>[];
  if (stripsNeeded > 1) {
    warnings.add('Укладка потребует $stripsNeeded полосы. Попробуйте рулон шире ${_roundValue(shorterSide, 1)} м для укладки без стыка');
  }
  if (wastePercent > spec.warningRules.highWastePercentThreshold) {
    warnings.add('Отходы составят ${_roundValue(wastePercent, 1)}% — попробуйте рулон большей ширины');
  }
  if (hasPattern && patternRepeatM > 0) {
    warnings.add('Раппорт рисунка увеличивает расход на подгонку полотен');
  }

  final recScenario = scenarios['REC']!;
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Линолеум (${_roundValue(rollWidth, 2)} м ширина)',
      quantity: _roundValue(recScenario.exactNeed, 6),
      unit: spec.packagingRules.linearMeterUnit,
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: (recScenario.purchaseQuantity / spec.packagingRules.linearMeterStepM).round(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (${spec.packagingRules.primerCanLiters.toInt()} л)',
      quantity: primerLiters,
      unit: 'л',
      withReserve: primerCans * spec.packagingRules.primerCanLiters,
      purchaseQty: primerCans,
      category: 'Подготовка',
    ),
  ];

  if (needGlue) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для линолеума (${spec.packagingRules.glueBucketKg.toInt()} кг)',
      quantity: glueKg,
      unit: 'кг',
      withReserve: glueBuckets * spec.packagingRules.glueBucketKg,
      purchaseQty: glueBuckets,
      category: 'Клей',
    ));
  }
  if (needPlinth) {
    materials.add(CanonicalMaterialResult(
      name: 'Плинтус ПВХ (${spec.packagingRules.plinthPieceLengthM} м)',
      quantity: _roundValue(plinthLengthWithReserve / spec.packagingRules.plinthPieceLengthM, 6),
      unit: 'шт',
      withReserve: plinthPieces.toDouble(),
      purchaseQty: plinthPieces,
      category: 'Плинтус',
    ));
  }
  if (needTape) {
    materials.add(CanonicalMaterialResult(
      name: 'Двусторонний скотч / клейкая фиксация',
      quantity: tapeLength,
      unit: 'м',
      withReserve: tapeLength,
      purchaseQty: tapeLength.ceil(),
      category: 'Крепление',
    ));
  }
  if (coldWeldingTubes > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Холодная сварка для швов',
      quantity: coldWeldingTubes.toDouble(),
      unit: 'туб',
      withReserve: coldWeldingTubes.toDouble(),
      purchaseQty: coldWeldingTubes,
      category: 'Швы',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': geometry['area']!,
      'inputMode': geometry['inputMode']!,
      'roomWidth': geometry['roomWidth']!,
      'roomLength': geometry['roomLength']!,
      'perimeter': geometry['perimeter']!,
      'rollWidth': _roundValue(rollWidth, 3),
      'hasPattern': hasPattern ? 1.0 : 0.0,
      'patternRepeatCm': _roundValue(patternRepeatM * 100, 3),
      'stripsNeeded': stripsNeeded.toDouble(),
      'stripLengthBase': _roundValue(stripLengthBase, 6),
      'linearMeters': _roundValue(linearMetersRounded, 6),
      'totalCoverageArea': totalCoverageArea,
      'wastePercent': wastePercent,
      'needGlue': needGlue ? 1.0 : 0.0,
      'needPlinth': needPlinth ? 1.0 : 0.0,
      'needTape': needTape ? 1.0 : 0.0,
      'seamsLength': seamsLength,
      'coldWeldingTubes': coldWeldingTubes.toDouble(),
      'glueNeededKg': glueKg,
      'glueBuckets': glueBuckets.toDouble(),
      'primerNeededL': primerLiters,
      'primerCans': primerCans.toDouble(),
      'plinthLengthRaw': _roundValue(plinthLengthRaw, 6),
      'plinthLengthWithReserve': plinthLengthWithReserve,
      'plinthPieces': plinthPieces.toDouble(),
      'tapeLength': tapeLength,
      'minExactNeedLinearM': scenarios['MIN']!.exactNeed,
      'recExactNeedLinearM': recScenario.exactNeed,
      'maxExactNeedLinearM': scenarios['MAX']!.exactNeed,
      'minPurchaseLinearM': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseLinearM': recScenario.purchaseQuantity,
      'maxPurchaseLinearM': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}

