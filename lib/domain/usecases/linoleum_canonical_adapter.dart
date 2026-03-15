import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
};

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

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveGeometry(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(1, inputs['length'] ?? defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(1, inputs['width'] ?? defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': roundValue(length * width, 3),
      'roomLength': roundValue(length, 3),
      'roomWidth': roundValue(width, 3),
      'perimeter': roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 20)).toDouble();
  final roomWidth = math.max(1, inputs['roomWidth'] ?? defaultFor(spec, 'roomWidth', 4)).toDouble();
  final roomLength = area / roomWidth;
  final explicitPerimeter = math.max(0, inputs['perimeter'] ?? 0).toDouble();
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'roomLength': roundValue(roomLength, 3),
    'roomWidth': roundValue(roomWidth, 3),
    'perimeter': roundValue(explicitPerimeter > 0 ? explicitPerimeter : _estimatePerimeter(area), 3),
  };
}

double _roundLinearMeters(double value, double step) {
  final safeStep = step > 0 ? step : 0.1;
  return (value / safeStep).ceil() * safeStep;
}

CanonicalCalculatorContractResult calculateCanonicalLinoleum(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(linoleumSpecData);

  final normalized = hasCanonicalLinoleumInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyLinoleumInputs(inputs);
  final geometry = _resolveGeometry(spec, normalized);
  final rollWidth = (normalized['rollWidth'] ?? defaultFor(spec, 'rollWidth', 3))
      .clamp(1.5, spec.warningRule<num>('max_single_roll_width_m').toDouble())
      .toDouble();
  final hasPattern = (normalized['hasPattern'] ?? defaultFor(spec, 'hasPattern', 0)) > 0;
  final patternRepeatM = math.max(0, normalized['patternRepeatCm'] ?? defaultFor(spec, 'patternRepeatCm', 30)).toDouble() / 100;
  final needGlue = (normalized['needGlue'] ?? defaultFor(spec, 'needGlue', 0)) > 0;
  final needPlinth = (normalized['needPlinth'] ?? defaultFor(spec, 'needPlinth', 1)) > 0;
  final needTape = (normalized['needTape'] ?? defaultFor(spec, 'needTape', 1)) > 0;

  final longerSide = math.max(geometry['roomLength']!, geometry['roomWidth']!);
  final shorterSide = math.min(geometry['roomLength']!, geometry['roomWidth']!);
  final stripsNeeded = math.max(1, (shorterSide / rollWidth).ceil());
  final stripLengthBase = longerSide + spec.materialRule<num>('trim_allowance_m').toDouble();
  final totalLinearM = hasPattern && stripsNeeded > 1
      ? stripLengthBase + (stripLengthBase + patternRepeatM) * (stripsNeeded - 1)
      : stripLengthBase * stripsNeeded;
  final linearMetersRounded = _roundLinearMeters(totalLinearM, spec.packagingRule<num>('linear_meter_step_m').toDouble());
  final totalCoverageArea = roundValue(linearMetersRounded * rollWidth, 6);
  final wastePercent = geometry['area']! > 0
      ? roundValue(((totalCoverageArea - geometry['area']!) / geometry['area']!) * 100, 3)
      : 0.0;

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(totalLinearM * multiplier, 6);
    final purchaseQuantity = _roundLinearMeters(exactNeed, spec.packagingRule<num>('linear_meter_step_m').toDouble());
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: roundValue(purchaseQuantity, 6),
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'roll_width:$rollWidth',
        'pattern:${hasPattern ? 'rapport' : 'plain'}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'linoleum-linear-${spec.packagingRule<num>('linear_meter_step_m').toDouble()}',
        packageSize: spec.packagingRule<num>('linear_meter_step_m').toDouble(),
        packagesCount: (purchaseQuantity / spec.packagingRule<num>('linear_meter_step_m').toDouble()).round(),
        unit: spec.packagingRule<String>('linear_meter_unit'),
      ),
    );
  }

  final seamsLength = stripsNeeded > 1 ? roundValue((stripsNeeded - 1) * longerSide, 6) : 0.0;
  final coldWeldingTubes = seamsLength > 0
      ? math.max(1, (seamsLength / spec.packagingRule<num>('cold_welding_tube_linear_m').toDouble()).ceil())
      : 0;
  final glueKg = needGlue ? roundValue(geometry['area']! * spec.materialRule<num>('glue_kg_per_m2').toDouble(), 6) : 0.0;
  final glueBuckets = needGlue ? math.max(1, (glueKg / spec.packagingRule<num>('glue_bucket_kg').toDouble()).ceil()) : 0;
  final primerLiters = roundValue(geometry['area']! * spec.materialRule<num>('primer_liters_per_m2').toDouble(), 6);
  final primerCans = math.max(1, (primerLiters / spec.packagingRule<num>('primer_can_liters').toDouble()).ceil());
  final plinthLengthRaw = needPlinth
      ? math.max(0.0, geometry['perimeter']! - spec.materialRule<num>('default_door_opening_width_m').toDouble())
      : 0.0;
  final plinthLengthWithReserve = needPlinth
      ? roundValue(plinthLengthRaw * (1 + spec.materialRule<num>('plinth_reserve_percent').toDouble() / 100), 6)
      : 0.0;
  final plinthPieces = needPlinth
      ? (plinthLengthWithReserve / spec.packagingRule<num>('plinth_piece_length_m').toDouble()).ceil()
      : 0;
  final tapeLength = needTape
      ? roundValue(geometry['perimeter']! + longerSide * spec.materialRule<num>('tape_extra_perimeter_run').toDouble(), 6)
      : 0.0;

  final warnings = <String>[];
  if (stripsNeeded > 1) {
    warnings.add('Укладка потребует $stripsNeeded полосы. Попробуйте рулон шире ${roundValue(shorterSide, 1)} м для укладки без стыка');
  }
  if (wastePercent > spec.warningRule<num>('high_waste_percent_threshold').toDouble()) {
    warnings.add('Отходы составят ${roundValue(wastePercent, 1)}% — попробуйте рулон большей ширины');
  }
  if (hasPattern && patternRepeatM > 0) {
    warnings.add('Раппорт рисунка увеличивает расход на подгонку полотен');
  }

  final recScenario = scenarios['REC']!;
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Линолеум (${roundValue(rollWidth, 2)} м ширина)',
      quantity: roundValue(recScenario.exactNeed, 6),
      unit: spec.packagingRule<String>('linear_meter_unit'),
      withReserve: recScenario.purchaseQuantity,
      purchaseQty: (recScenario.purchaseQuantity / spec.packagingRule<num>('linear_meter_step_m').toDouble()).round(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (${spec.packagingRule<num>('primer_can_liters').toInt()} л)',
      quantity: primerLiters,
      unit: 'л',
      withReserve: primerCans * spec.packagingRule<num>('primer_can_liters').toDouble(),
      purchaseQty: primerCans.toInt(),
      category: 'Подготовка',
    ),
  ];

  if (needGlue) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для линолеума (${spec.packagingRule<num>('glue_bucket_kg').toInt()} кг)',
      quantity: glueKg,
      unit: 'кг',
      withReserve: glueBuckets * spec.packagingRule<num>('glue_bucket_kg').toDouble(),
      purchaseQty: glueBuckets.toInt(),
      category: 'Клей',
    ));
  }
  if (needPlinth) {
    materials.add(CanonicalMaterialResult(
      name: 'Плинтус ПВХ (${spec.packagingRule<num>('plinth_piece_length_m').toDouble()} м)',
      quantity: roundValue(plinthLengthWithReserve / spec.packagingRule<num>('plinth_piece_length_m').toDouble(), 6),
      unit: 'шт',
      withReserve: plinthPieces.toDouble(),
      purchaseQty: plinthPieces.toInt(),
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
      purchaseQty: coldWeldingTubes.toInt(),
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
      'rollWidth': roundValue(rollWidth, 3),
      'hasPattern': hasPattern ? 1.0 : 0.0,
      'patternRepeatCm': roundValue(patternRepeatM * 100, 3),
      'stripsNeeded': stripsNeeded.toDouble(),
      'stripLengthBase': roundValue(stripLengthBase, 6),
      'linearMeters': roundValue(linearMetersRounded, 6),
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
      'plinthLengthRaw': roundValue(plinthLengthRaw, 6),
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

