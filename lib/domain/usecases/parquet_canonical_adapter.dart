import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

bool hasCanonicalParquetInputs(Map<String, double> inputs) {
  return inputs.containsKey('layoutProfileId') ||
      inputs.containsKey('needUnderlayment') ||
      inputs.containsKey('needPlinth') ||
      inputs.containsKey('needGlue');
}

int _mapLegacyLayoutProfile(Map<String, double> inputs) {
  if (inputs.containsKey('layoutProfileId')) {
    return (inputs['layoutProfileId'] ?? 1).round().clamp(1, 3);
  }
  if (inputs.containsKey('layingMethod')) {
    return ((inputs['layingMethod'] ?? 0).round() + 1).clamp(1, 3);
  }
  if (inputs.containsKey('pattern')) {
    return ((inputs['pattern'] ?? 0).round() + 1).clamp(1, 3);
  }
  return 1;
}

Map<String, double> normalizeLegacyParquetInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final isV2 = inputs.containsKey('pattern') || inputs.containsKey('needUnderlay') || inputs.containsKey('needPlinth') || inputs.containsKey('needGlue') || inputs.containsKey('roomWidth') || inputs.containsKey('roomLength') || inputs.containsKey('packArea');

  if (!normalized.containsKey('length') && inputs.containsKey('roomLength')) {
    normalized['length'] = (inputs['roomLength'] ?? 0).toDouble();
  }
  if (!normalized.containsKey('width') && inputs.containsKey('roomWidth')) {
    normalized['width'] = (inputs['roomWidth'] ?? 0).toDouble();
  }
  normalized['layoutProfileId'] = _mapLegacyLayoutProfile(inputs).toDouble();
  normalized['reservePercent'] = ((inputs['reservePercent'] ?? inputs['reserve'] ?? (isV2 ? 0 : 7)).toDouble()).clamp(0, 20).toDouble();
  normalized['needUnderlayment'] = ((inputs['needUnderlayment'] ?? inputs['needUnderlay'] ?? 1) > 0 ? 1 : 0).toDouble();
  normalized['needPlinth'] = ((inputs['needPlinth'] ?? 1) > 0 ? 1 : 0).toDouble();
  normalized['needGlue'] = ((inputs['needGlue'] ?? (isV2 ? 0 : 1)) > 0 ? 1 : 0).toDouble();
  normalized['underlaymentRollArea'] = (inputs['underlaymentRollArea'] ?? 10).toDouble();
  normalized['doorThresholds'] = (inputs['doorThresholds'] ?? 1).toDouble();
  normalized['packArea'] = (inputs['packArea'] ?? 2.0).toDouble();
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
      'perimeter': roundValue(2 * (length + width), 3),
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
    };
  }

  final area = math.max(1, inputs['area'] ?? defaultFor(spec, 'area', 20)).toDouble();
  final side = math.sqrt(area);
  final explicitPerimeter = math.max(0, inputs['perimeter'] ?? 0).toDouble();
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'perimeter': roundValue(explicitPerimeter > 0 ? explicitPerimeter : _estimatePerimeter(area), 3),
    'length': roundValue(side, 3),
    'width': roundValue(side, 3),
  };
}

Map<String, dynamic> _resolveLayout(SpecReader spec, Map<String, double> inputs) {
  final profileId = (inputs['layoutProfileId'] ?? defaultFor(spec, 'layoutProfileId', 1)).round().clamp(1, 3);
  return spec.normativeList('layout_profiles').firstWhere(
    (layout) => (layout['id'] as num).toInt() == profileId,
    orElse: () => spec.normativeList('layout_profiles').first,
  );
}

CanonicalCalculatorContractResult calculateCanonicalParquet(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(parquetSpecData);

  final normalized = hasCanonicalParquetInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyParquetInputs(inputs);
  final geometry = _resolveGeometry(spec, normalized);
  final packArea = (normalized['packArea'] ?? defaultFor(spec, 'packArea', 1.892)).clamp(0.5, 4).toDouble();
  final layout = _resolveLayout(spec, normalized);
  final reservePercent = (normalized['reservePercent'] ?? defaultFor(spec, 'reservePercent', spec.materialRule<num>('reserve_percent_default').toDouble())).clamp(0, 20).toDouble();
  final wastePercent = math.max((layout['waste_percent'] as num).toDouble(), reservePercent);
  final baseExactNeedArea = roundValue(geometry['area']! * (1 + wastePercent / 100), 6);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeedArea * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / packArea).ceil() : 0;
    final purchaseQuantity = roundValue(packageCount * packArea, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'layout:${layout['key'] as String}',
        'packaging:parquet-pack-${roundValue(packArea, 3)}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
        'reserve_percent': roundValue(reservePercent, 3),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'parquet-pack-${roundValue(packArea, 3)}',
        packageSize: packArea,
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('parquet_pack_area_unit'),
      ),
    );
  }

  final needUnderlayment = (normalized['needUnderlayment'] ?? defaultFor(spec, 'needUnderlayment', 1)) > 0;
  final needPlinth = (normalized['needPlinth'] ?? defaultFor(spec, 'needPlinth', 1)) > 0;
  final needGlue = (normalized['needGlue'] ?? defaultFor(spec, 'needGlue', 0)) > 0;
  final underlaymentRollArea = (normalized['underlaymentRollArea'] ?? defaultFor(spec, 'underlaymentRollArea', 10)).clamp(5, 20).toDouble();
  final underlaymentArea = needUnderlayment ? roundValue(geometry['area']! * (1 + spec.materialRule<num>('underlayment_overlap_percent').toDouble() / 100), 6) : 0.0;
  final underlaymentRolls = needUnderlayment ? (underlaymentArea / underlaymentRollArea).ceil() : 0;
  final doorThresholds = math.max(0, (normalized['doorThresholds'] ?? defaultFor(spec, 'doorThresholds', 1)).round());
  final plinthLengthRaw = needPlinth ? math.max(0.0, geometry['perimeter']! - doorThresholds * spec.materialRule<num>('default_door_opening_width_m').toDouble()) : 0.0;
  final plinthLengthWithReserve = needPlinth ? roundValue(plinthLengthRaw * (1 + spec.materialRule<num>('plinth_reserve_percent').toDouble() / 100), 6) : 0.0;
  final plinthPieces = needPlinth ? (plinthLengthWithReserve / spec.packagingRule<num>('plinth_piece_length_m').toDouble()).ceil() : 0;
  final wedges = needPlinth ? (geometry['perimeter']! / spec.materialRule<num>('wedge_spacing_m').toDouble()).ceil() : 0;
  final glueKg = needGlue ? roundValue(geometry['area']! * spec.materialRule<num>('glue_kg_per_m2').toDouble(), 6) : 0.0;
  final glueBuckets = needGlue ? (glueKg / spec.packagingRule<num>('glue_bucket_kg').toDouble()).ceil() : 0;
  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (geometry['area']! < spec.warningRule<num>('small_area_warning_threshold_m2').toDouble()) {
    warnings.add('Маленькая площадь — отходы будут выше расчётного процента');
  }
  if (spec.warningRule<List>('diagonal_warning_profile_ids').contains((layout['id'] as num).toInt())) {
    warnings.add('Диагональная укладка требует точной раскладки и увеличивает отходы');
  }
  if (spec.warningRule<List>('herringbone_warning_profile_ids').contains((layout['id'] as num).toInt())) {
    warnings.add('Укладка ёлочкой требует профессионального инструмента и опыта');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Паркетная доска (${roundValue(packArea, 3)} м² в упаковке)',
      quantity: roundValue(recScenario.exactNeed / packArea, 6),
      unit: 'упак.',
      withReserve: recScenario.buyPlan.packagesCount.toDouble(),
      purchaseQty: recScenario.buyPlan.packagesCount.toDouble(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Порожек стыковочный',
      quantity: doorThresholds.toDouble(),
      unit: 'шт',
      withReserve: doorThresholds.toDouble(),
      purchaseQty: doorThresholds.toDouble(),
      category: 'Доборные',
    ),
  ];

  if (needUnderlayment) {
    materials.add(CanonicalMaterialResult(
      name: 'Подложка (${roundValue(underlaymentRollArea, 1)} м²)',
      quantity: roundValue(underlaymentArea / underlaymentRollArea, 6),
      unit: 'рулонов',
      withReserve: underlaymentRolls.toDouble(),
      purchaseQty: underlaymentRolls.toDouble(),
      category: 'Подложка',
    ));
    materials.add(const CanonicalMaterialResult(
      name: 'Скотч для подложки',
      quantity: 1,
      unit: 'рулон',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Подложка',
    ));
  }

  if (needPlinth) {
    materials.add(CanonicalMaterialResult(
      name: 'Плинтус напольный (${spec.packagingRule<num>('plinth_piece_length_m').toDouble()} м)',
      quantity: roundValue(plinthLengthWithReserve / spec.packagingRule<num>('plinth_piece_length_m').toDouble(), 6),
      unit: 'шт',
      withReserve: plinthPieces.toDouble(),
      purchaseQty: plinthPieces.toDouble(),
      category: 'Плинтус',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Клинья распорные',
      quantity: wedges.toDouble(),
      unit: 'шт',
      withReserve: wedges.toDouble(),
      purchaseQty: (((wedges / 10).ceil()) * 10).toDouble(),
      category: 'Монтаж',
    ));
  }

  if (needGlue) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для паркета (${spec.packagingRule<num>('glue_bucket_kg').toInt()} кг)',
      quantity: glueKg,
      unit: 'кг',
      withReserve: (glueBuckets * spec.packagingRule<num>('glue_bucket_kg').toDouble()),
      purchaseQty: (glueBuckets * spec.packagingRule<num>('glue_bucket_kg').toDouble()).toDouble(),
      category: 'Клей',
      packageInfo: {'count': glueBuckets, 'unitSize': spec.packagingRule<num>('glue_bucket_kg').toDouble(), 'packageUnit': 'вёдер'},
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': geometry['area']!,
      'perimeter': geometry['perimeter']!,
      'inputMode': geometry['inputMode']!,
      'roomWidth': geometry['width']!,
      'roomLength': geometry['length']!,
      'packArea': roundValue(packArea, 6),
      'layoutProfileId': (layout['id'] as num).toInt().toDouble(),
      'reservePercent': roundValue(reservePercent, 3),
      'wastePercent': roundValue(wastePercent, 3),
      'baseExactNeedArea': baseExactNeedArea,
      'packsNeeded': recScenario.buyPlan.packagesCount.toDouble(),
      'needUnderlayment': needUnderlayment ? 1.0 : 0.0,
      'needPlinth': needPlinth ? 1.0 : 0.0,
      'needGlue': needGlue ? 1.0 : 0.0,
      'underlayArea': underlaymentArea,
      'underlaymentRolls': underlaymentRolls.toDouble(),
      'plinthLengthRaw': roundValue(plinthLengthRaw, 6),
      'plinthLengthWithReserve': plinthLengthWithReserve,
      'plinthPieces': plinthPieces.toDouble(),
      'wedgesNeeded': wedges.toDouble(),
      'glueNeededKg': glueKg,
      'glueBuckets': glueBuckets.toDouble(),
      'doorThresholds': doorThresholds.toDouble(),
      'minExactNeedArea': scenarios['MIN']!.exactNeed,
      'recExactNeedArea': recScenario.exactNeed,
      'maxExactNeedArea': scenarios['MAX']!.exactNeed,
      'minPurchaseArea': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseArea': recScenario.purchaseQuantity,
      'maxPurchaseArea': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}

