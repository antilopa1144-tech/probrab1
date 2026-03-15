import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

const ParquetCanonicalSpec parquetCanonicalSpecV1 = ParquetCanonicalSpec(
  calculatorId: 'parquet',
  formulaVersion: 'parquet-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 30),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 1, max: 500),
    CanonicalInputField(key: 'perimeter', unit: 'm', defaultValue: 0, min: 0, max: 200),
    CanonicalInputField(key: 'packArea', unit: 'm2', defaultValue: 1.892, min: 0.5, max: 4),
    CanonicalInputField(key: 'layoutProfileId', defaultValue: 1, min: 1, max: 3),
    CanonicalInputField(key: 'reservePercent', defaultValue: 0, min: 0, max: 20),
    CanonicalInputField(key: 'needUnderlayment', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'needPlinth', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'needGlue', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'underlaymentRollArea', unit: 'm2', defaultValue: 10, min: 5, max: 20),
    CanonicalInputField(key: 'doorThresholds', defaultValue: 1, min: 0, max: 10),
  ],
  enabledFactors: ['geometry_complexity', 'installation_method', 'worker_skill'],
  layoutProfiles: [
    ParquetLayoutProfileSpec(id: 1, key: 'straight', label: 'Прямая', wastePercent: 5),
    ParquetLayoutProfileSpec(id: 2, key: 'diagonal', label: 'Диагональная', wastePercent: 15),
    ParquetLayoutProfileSpec(id: 3, key: 'herringbone', label: 'Ёлочка', wastePercent: 20),
  ],
  packagingRules: ParquetPackagingRules(
    parquetPackAreaUnit: 'м²',
    underlaymentRollAreaM2: 10,
    plinthPieceLengthM: 2.5,
    glueBucketKg: 10,
  ),
  materialRules: ParquetMaterialRules(
    reservePercentDefault: 0,
    underlaymentOverlapPercent: 10,
    wedgeSpacingM: 0.5,
    defaultDoorOpeningWidthM: 0.9,
    glueKgPerM2: 1.5,
    plinthReservePercent: 5,
  ),
  warningRules: ParquetWarningRules(
    smallAreaWarningThresholdM2: 5,
    diagonalWarningProfileIds: [2],
    herringboneWarningProfileIds: [3],
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

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

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(ParquetCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveGeometry(ParquetCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(1, inputs['length'] ?? _defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(1, inputs['width'] ?? _defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': _roundValue(length * width, 3),
      'perimeter': _roundValue(2 * (length + width), 3),
      'length': _roundValue(length, 3),
      'width': _roundValue(width, 3),
    };
  }

  final area = math.max(1, inputs['area'] ?? _defaultFor(spec, 'area', 20)).toDouble();
  final side = math.sqrt(area);
  final explicitPerimeter = math.max(0, inputs['perimeter'] ?? 0).toDouble();
  return {
    'inputMode': 1.0,
    'area': _roundValue(area, 3),
    'perimeter': _roundValue(explicitPerimeter > 0 ? explicitPerimeter : _estimatePerimeter(area), 3),
    'length': _roundValue(side, 3),
    'width': _roundValue(side, 3),
  };
}

ParquetLayoutProfileSpec _resolveLayout(ParquetCanonicalSpec spec, Map<String, double> inputs) {
  final profileId = (inputs['layoutProfileId'] ?? _defaultFor(spec, 'layoutProfileId', 1)).round().clamp(1, 3);
  return spec.layoutProfiles.firstWhere(
    (layout) => layout.id == profileId,
    orElse: () => spec.layoutProfiles.first,
  );
}

Map<String, double> _keyFactors(ParquetCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(ParquetCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalParquet(
  Map<String, double> inputs, {
  ParquetCanonicalSpec spec = parquetCanonicalSpecV1,
}) {
  final normalized = hasCanonicalParquetInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyParquetInputs(inputs);
  final geometry = _resolveGeometry(spec, normalized);
  final packArea = (normalized['packArea'] ?? _defaultFor(spec, 'packArea', 1.892)).clamp(0.5, 4).toDouble();
  final layout = _resolveLayout(spec, normalized);
  final reservePercent = (normalized['reservePercent'] ?? _defaultFor(spec, 'reservePercent', spec.materialRules.reservePercentDefault)).clamp(0, 20).toDouble();
  final wastePercent = math.max(layout.wastePercent, reservePercent);
  final baseExactNeedArea = _roundValue(geometry['area']! * (1 + wastePercent / 100), 6);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeedArea * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / packArea).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packArea, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'layout:${layout.key}',
        'packaging:parquet-pack-${_roundValue(packArea, 3)}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
        'reserve_percent': _roundValue(reservePercent, 3),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'parquet-pack-${_roundValue(packArea, 3)}',
        packageSize: packArea,
        packagesCount: packageCount,
        unit: spec.packagingRules.parquetPackAreaUnit,
      ),
    );
  }

  final needUnderlayment = (normalized['needUnderlayment'] ?? _defaultFor(spec, 'needUnderlayment', 1)) > 0;
  final needPlinth = (normalized['needPlinth'] ?? _defaultFor(spec, 'needPlinth', 1)) > 0;
  final needGlue = (normalized['needGlue'] ?? _defaultFor(spec, 'needGlue', 0)) > 0;
  final underlaymentRollArea = (normalized['underlaymentRollArea'] ?? _defaultFor(spec, 'underlaymentRollArea', 10)).clamp(5, 20).toDouble();
  final underlaymentArea = needUnderlayment ? _roundValue(geometry['area']! * (1 + spec.materialRules.underlaymentOverlapPercent / 100), 6) : 0.0;
  final underlaymentRolls = needUnderlayment ? (underlaymentArea / underlaymentRollArea).ceil() : 0;
  final doorThresholds = math.max(0, (normalized['doorThresholds'] ?? _defaultFor(spec, 'doorThresholds', 1)).round());
  final plinthLengthRaw = needPlinth ? math.max(0.0, geometry['perimeter']! - doorThresholds * spec.materialRules.defaultDoorOpeningWidthM).toDouble() : 0.0;
  final plinthLengthWithReserve = needPlinth ? _roundValue(plinthLengthRaw * (1 + spec.materialRules.plinthReservePercent / 100), 6) : 0.0;
  final plinthPieces = needPlinth ? (plinthLengthWithReserve / spec.packagingRules.plinthPieceLengthM).ceil() : 0;
  final wedges = needPlinth ? (geometry['perimeter']! / spec.materialRules.wedgeSpacingM).ceil() : 0;
  final glueKg = needGlue ? _roundValue(geometry['area']! * spec.materialRules.glueKgPerM2, 6) : 0.0;
  final glueBuckets = needGlue ? (glueKg / spec.packagingRules.glueBucketKg).ceil() : 0;
  final recScenario = scenarios['REC']!;

  final warnings = <String>[];
  if (geometry['area']! < spec.warningRules.smallAreaWarningThresholdM2) {
    warnings.add('Маленькая площадь — отходы будут выше расчётного процента');
  }
  if (spec.warningRules.diagonalWarningProfileIds.contains(layout.id)) {
    warnings.add('Диагональная укладка требует точной раскладки и увеличивает отходы');
  }
  if (spec.warningRules.herringboneWarningProfileIds.contains(layout.id)) {
    warnings.add('Укладка ёлочкой требует профессионального инструмента и опыта');
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Паркетная доска (${_roundValue(packArea, 3)} м² в упаковке)',
      quantity: _roundValue(recScenario.exactNeed / packArea, 6),
      unit: 'упак.',
      withReserve: recScenario.buyPlan.packagesCount.toDouble(),
      purchaseQty: recScenario.buyPlan.packagesCount,
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Порожек стыковочный',
      quantity: doorThresholds.toDouble(),
      unit: 'шт',
      withReserve: doorThresholds.toDouble(),
      purchaseQty: doorThresholds,
      category: 'Доборные',
    ),
  ];

  if (needUnderlayment) {
    materials.add(CanonicalMaterialResult(
      name: 'Подложка (${_roundValue(underlaymentRollArea, 1)} м²)',
      quantity: _roundValue(underlaymentArea / underlaymentRollArea, 6),
      unit: 'рулонов',
      withReserve: underlaymentRolls.toDouble(),
      purchaseQty: underlaymentRolls,
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
      name: 'Плинтус напольный (${spec.packagingRules.plinthPieceLengthM} м)',
      quantity: _roundValue(plinthLengthWithReserve / spec.packagingRules.plinthPieceLengthM, 6),
      unit: 'шт',
      withReserve: plinthPieces.toDouble(),
      purchaseQty: plinthPieces,
      category: 'Плинтус',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Клинья распорные',
      quantity: wedges.toDouble(),
      unit: 'шт',
      withReserve: wedges.toDouble(),
      purchaseQty: ((wedges / 10).ceil()) * 10,
      category: 'Монтаж',
    ));
  }

  if (needGlue) {
    materials.add(CanonicalMaterialResult(
      name: 'Клей для паркета (${spec.packagingRules.glueBucketKg.toInt()} кг)',
      quantity: glueKg,
      unit: 'кг',
      withReserve: (glueBuckets * spec.packagingRules.glueBucketKg).toDouble(),
      purchaseQty: glueBuckets,
      category: 'Клей',
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
      'packArea': _roundValue(packArea, 6),
      'layoutProfileId': layout.id.toDouble(),
      'reservePercent': _roundValue(reservePercent, 3),
      'wastePercent': _roundValue(wastePercent, 3),
      'baseExactNeedArea': baseExactNeedArea,
      'packsNeeded': recScenario.buyPlan.packagesCount.toDouble(),
      'needUnderlayment': needUnderlayment ? 1.0 : 0.0,
      'needPlinth': needPlinth ? 1.0 : 0.0,
      'needGlue': needGlue ? 1.0 : 0.0,
      'underlayArea': underlaymentArea,
      'underlaymentRolls': underlaymentRolls.toDouble(),
      'plinthLengthRaw': _roundValue(plinthLengthRaw, 6),
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

