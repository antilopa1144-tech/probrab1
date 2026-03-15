import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── Spec model classes ─── */

class ScreedTypeSpec {
  final int id;
  final String key;
  final String label;
  final double densityKgPerM3;

  const ScreedTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.densityKgPerM3,
  });
}

class ScreedPackagingRules {
  final String unit;
  final List<int> bagWeights;

  const ScreedPackagingRules({
    required this.unit,
    required this.bagWeights,
  });
}

class ScreedMaterialRules {
  final double volumeMultiplier;
  final double cementDensity;
  final double cementFraction;
  final double sandFraction;
  final double sandDensity;
  final double waterPerM3;
  final double cpsDensityReady;
  final double cpsDensitySemidry;
  final double fiberKgPerM2;
  final double meshMargin;
  final double filmMargin;
  final double damperTapeReserve;
  final double beaconsAreaPerPiece;
  final double meshThicknessThresholdMm;
  final double minThicknessMm;
  final double maxThicknessMm;

  const ScreedMaterialRules({
    required this.volumeMultiplier,
    required this.cementDensity,
    required this.cementFraction,
    required this.sandFraction,
    required this.sandDensity,
    required this.waterPerM3,
    required this.cpsDensityReady,
    required this.cpsDensitySemidry,
    required this.fiberKgPerM2,
    required this.meshMargin,
    required this.filmMargin,
    required this.damperTapeReserve,
    required this.beaconsAreaPerPiece,
    required this.meshThicknessThresholdMm,
    required this.minThicknessMm,
    required this.maxThicknessMm,
  });
}

class ScreedWarningRules {
  final double thinThresholdMm;
  final double thickThresholdMm;
  final double largeAreaCpsThresholdM2;

  const ScreedWarningRules({
    required this.thinThresholdMm,
    required this.thickThresholdMm,
    required this.largeAreaCpsThresholdM2,
  });
}

class ScreedCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<ScreedTypeSpec> screedTypes;
  final ScreedPackagingRules packagingRules;
  final ScreedMaterialRules materialRules;
  final ScreedWarningRules warningRules;

  const ScreedCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.screedTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── Default spec (mirrors screed-canonical.v1.json) ─── */

const ScreedCanonicalSpec screedCanonicalSpecV1 = ScreedCanonicalSpec(
  calculatorId: 'screed',
  formulaVersion: 'screed-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 0.1, max: 50),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 0.1, max: 50),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 20, min: 0.1, max: 1000),
    CanonicalInputField(key: 'thickness', unit: 'mm', defaultValue: 50, min: 30, max: 200),
    CanonicalInputField(key: 'screedType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  screedTypes: [
    ScreedTypeSpec(id: 0, key: 'cps_1_3', label: 'ЦПС 1:3 (ручной замес)', densityKgPerM3: 0),
    ScreedTypeSpec(id: 1, key: 'ready_cps_m150', label: 'Готовая ЦПС М150', densityKgPerM3: 2000),
    ScreedTypeSpec(id: 2, key: 'semi_dry', label: 'Полусухая стяжка', densityKgPerM3: 1800),
  ],
  packagingRules: ScreedPackagingRules(unit: 'кг', bagWeights: [40, 50]),
  materialRules: ScreedMaterialRules(
    volumeMultiplier: 1.08,
    cementDensity: 1300,
    cementFraction: 0.25,
    sandFraction: 0.75,
    sandDensity: 1.6,
    waterPerM3: 200,
    cpsDensityReady: 2000,
    cpsDensitySemidry: 1800,
    fiberKgPerM2: 0.6,
    meshMargin: 1.15,
    filmMargin: 1.1,
    damperTapeReserve: 1.05,
    beaconsAreaPerPiece: 2,
    meshThicknessThresholdMm: 40,
    minThicknessMm: 30,
    maxThicknessMm: 200,
  ),
  warningRules: ScreedWarningRules(
    thinThresholdMm: 30,
    thickThresholdMm: 100,
    largeAreaCpsThresholdM2: 50,
  ),
);

/* ─── Factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── Constants (must match TS engine exactly) ─── */

const double _volumeMultiplier = 1.08;

// Type 0 — ЦПС 1:3
const double _cementDensity = 1300;    // kg/m³
const double _cementFraction = 0.25;   // 1/4 volume
const double _sandFraction = 0.75;     // 3/4 volume
const double _sandDensity = 1.6;       // t/m³
const double _waterPerM3 = 200;        // L/m³

// Type 1 — Ready CPS M150
const double _cpsDensityReady = 2000;  // kg/m³

// Type 2 — Semi-dry
const double _cpsDensitySemidry = 1800; // kg/m³
const double _fiberKgPerM2 = 0.6;

// Ancillary
const double _meshMargin = 1.15;       // 15%
const double _filmMargin = 1.1;        // 10%
const double _damperTapeReserve = 1.05;
const double _beaconsAreaPerPiece = 2;  // 1 beacon per 2 m²

/* ─── Helpers ─── */

bool hasCanonicalScreedInputs(Map<String, double> inputs) {
  return inputs.containsKey('screedType') && !inputs.containsKey('consumption');
}

Map<String, double> normalizeLegacyScreedInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final hasDimensions = (inputs['length'] ?? 0) > 0 && (inputs['width'] ?? 0) > 0;
  if (!normalized.containsKey('inputMode')) {
    normalized['inputMode'] = hasDimensions ? 0.0 : 1.0;
  }
  normalized['screedType'] = (inputs['screedType'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(ScreedCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveArea(ScreedCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(0.1, inputs['length'] ?? _defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(0.1, inputs['width'] ?? _defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': _roundValue(length * width, 3),
      'perimeter': _roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(0.1, inputs['area'] ?? _defaultFor(spec, 'area', 20)).toDouble();
  return {
    'inputMode': 1.0,
    'area': _roundValue(area, 3),
    'perimeter': _roundValue(_estimatePerimeter(area), 3),
  };
}

ScreedTypeSpec _resolveScreedType(ScreedCanonicalSpec spec, Map<String, double> inputs) {
  final screedType = (inputs['screedType'] ?? _defaultFor(spec, 'screedType', 0)).round().clamp(0, 2);
  return spec.screedTypes.firstWhere(
    (item) => item.id == screedType,
    orElse: () => spec.screedTypes.first,
  );
}

double _scenarioMultiplier(ScreedCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

Map<String, double> _keyFactors(ScreedCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

/* ─── Main calculator ─── */

CanonicalCalculatorContractResult calculateCanonicalScreed(
  Map<String, double> inputs, {
  ScreedCanonicalSpec spec = screedCanonicalSpecV1,
}) {
  final normalized = hasCanonicalScreedInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyScreedInputs(inputs);

  final work = _resolveArea(spec, normalized);
  final thickness = (normalized['thickness'] ?? _defaultFor(spec, 'thickness', 50))
      .clamp(spec.materialRules.minThicknessMm, spec.materialRules.maxThicknessMm)
      .toDouble();
  final screedType = _resolveScreedType(spec, normalized);

  final area = work['area']!;
  final perimeter = work['perimeter']!;
  final volume = _roundValue(area * (thickness / 1000) * _volumeMultiplier, 6);

  // Determine effective consumption for scenarios
  double effectiveConsumptionKgPerM2Mm;

  if (screedType.id == 0) {
    effectiveConsumptionKgPerM2Mm = (_cementFraction * _cementDensity * _volumeMultiplier) / 1000;
  } else if (screedType.id == 1) {
    effectiveConsumptionKgPerM2Mm = (_cpsDensityReady * _volumeMultiplier) / 1000;
  } else {
    effectiveConsumptionKgPerM2Mm = (_cpsDensitySemidry * _volumeMultiplier) / 1000;
  }

  const bagWeight = 50.0;

  // Compute scenarios
  final baseExactNeed = area * thickness * effectiveConsumptionKgPerM2Mm;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeed * multiplier, 6);
    final bags = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = _roundValue(bags * bagWeight, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'screed_type:${screedType.key}',
        'packaging:screed-bag-${bagWeight.toInt()}${spec.packagingRules.unit}',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'screed-bag-${bagWeight.toInt()}${spec.packagingRules.unit}',
        packageSize: bagWeight,
        packagesCount: bags,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Ancillary quantities
  final cementKg = _roundValue(volume * _cementFraction * _cementDensity, 3);
  final bags50Cement = (cementKg / 50).ceil();
  final sandTons = _roundValue((volume * _sandFraction * _sandDensity * 10).ceil() / 10, 3);
  final waterL = _roundValue(volume * _waterPerM3, 3);

  final cpsKgReady = _roundValue(volume * _cpsDensityReady, 3);
  final bags50Ready = (cpsKgReady / 50).ceil();
  final bags40Ready = (cpsKgReady / 40).ceil();

  final cpsKgSemidry = _roundValue(volume * _cpsDensitySemidry, 3);
  final bags50Semidry = (cpsKgSemidry / 50).ceil();
  final fiberKg = _roundValue(area * _fiberKgPerM2, 3);

  final meshArea = thickness >= spec.materialRules.meshThicknessThresholdMm
      ? (area * _meshMargin).ceil()
      : 0;
  final filmArea = (area * _filmMargin).ceil();
  final beacons = (area / _beaconsAreaPerPiece).ceil();
  final damperTapeM = (perimeter * _damperTapeReserve).ceil();

  // Build materials list per type
  final materials = <CanonicalMaterialResult>[];

  if (screedType.id == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Цемент М400 (мешки 50 кг)',
        quantity: cementKg,
        unit: 'кг',
        withReserve: (bags50Cement * 50).toDouble(),
        purchaseQty: bags50Cement,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Песок строительный',
        quantity: sandTons,
        unit: 'т',
        withReserve: sandTons,
        purchaseQty: sandTons.ceil(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Вода',
        quantity: waterL,
        unit: 'л',
        withReserve: waterL,
        purchaseQty: waterL.ceil(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Плёнка ПЭ',
        quantity: filmArea.toDouble(),
        unit: 'м²',
        withReserve: filmArea.toDouble(),
        purchaseQty: filmArea,
        category: 'Подготовка',
      ),
    ]);
    if (meshArea > 0) {
      materials.add(CanonicalMaterialResult(
        name: 'Сетка армирующая',
        quantity: meshArea.toDouble(),
        unit: 'м²',
        withReserve: meshArea.toDouble(),
        purchaseQty: meshArea,
        category: 'Армирование',
      ));
    }
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Маячковый профиль',
        quantity: beacons.toDouble(),
        unit: 'шт',
        withReserve: beacons.toDouble(),
        purchaseQty: beacons,
        category: 'Разметка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента',
        quantity: damperTapeM.toDouble(),
        unit: 'м',
        withReserve: damperTapeM.toDouble(),
        purchaseQty: damperTapeM,
        category: 'Подготовка',
      ),
    ]);
  } else if (screedType.id == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Готовая ЦПС М150 (мешки 50 кг)',
        quantity: cpsKgReady,
        unit: 'кг',
        withReserve: (bags50Ready * 50).toDouble(),
        purchaseQty: bags50Ready,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Плёнка ПЭ',
        quantity: filmArea.toDouble(),
        unit: 'м²',
        withReserve: filmArea.toDouble(),
        purchaseQty: filmArea,
        category: 'Подготовка',
      ),
    ]);
    if (meshArea > 0) {
      materials.add(CanonicalMaterialResult(
        name: 'Сетка армирующая',
        quantity: meshArea.toDouble(),
        unit: 'м²',
        withReserve: meshArea.toDouble(),
        purchaseQty: meshArea,
        category: 'Армирование',
      ));
    }
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Маячковый профиль',
        quantity: beacons.toDouble(),
        unit: 'шт',
        withReserve: beacons.toDouble(),
        purchaseQty: beacons,
        category: 'Разметка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента',
        quantity: damperTapeM.toDouble(),
        unit: 'м',
        withReserve: damperTapeM.toDouble(),
        purchaseQty: damperTapeM,
        category: 'Подготовка',
      ),
    ]);
  } else {
    // Type 2 — Semi-dry
    materials.addAll([
      CanonicalMaterialResult(
        name: 'ЦПС полусухая (мешки 50 кг)',
        quantity: cpsKgSemidry,
        unit: 'кг',
        withReserve: (bags50Semidry * 50).toDouble(),
        purchaseQty: bags50Semidry,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Фиброволокно ПП',
        quantity: fiberKg,
        unit: 'кг',
        withReserve: fiberKg,
        purchaseQty: fiberKg.ceil(),
        category: 'Армирование',
      ),
      CanonicalMaterialResult(
        name: 'Плёнка ПЭ',
        quantity: filmArea.toDouble(),
        unit: 'м²',
        withReserve: filmArea.toDouble(),
        purchaseQty: filmArea,
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента',
        quantity: damperTapeM.toDouble(),
        unit: 'м',
        withReserve: damperTapeM.toDouble(),
        purchaseQty: damperTapeM,
        category: 'Подготовка',
      ),
    ]);
  }

  // Warnings
  final warnings = <String>[];
  if (thickness < spec.warningRules.thinThresholdMm) {
    warnings.add('Толщина менее 30 мм — слишком тонкая для выравнивания пола');
  }
  if (thickness > spec.warningRules.thickThresholdMm) {
    warnings.add('При толщине более 100 мм рекомендуется разделить заливку на слои');
  }
  if (screedType.id == 0 && area > spec.warningRules.largeAreaCpsThresholdM2) {
    warnings.add('При площади более 50 м² рекомендуется использовать готовую ЦПС');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'perimeter': perimeter,
      'inputMode': work['inputMode']!,
      'thickness': _roundValue(thickness, 3),
      'screedType': screedType.id.toDouble(),
      'volume': _roundValue(volume, 6),
      'cementKg': screedType.id == 0 ? cementKg : 0,
      'bags50Cement': screedType.id == 0 ? bags50Cement.toDouble() : 0,
      'sandTons': screedType.id == 0 ? sandTons : 0,
      'waterL': screedType.id == 0 ? waterL : 0,
      'cpsKg': screedType.id == 1 ? cpsKgReady : screedType.id == 2 ? cpsKgSemidry : 0,
      'bags50': screedType.id == 1 ? bags50Ready.toDouble() : screedType.id == 2 ? bags50Semidry.toDouble() : 0,
      'bags40': screedType.id == 1 ? bags40Ready.toDouble() : 0,
      'fiberKg': screedType.id == 2 ? fiberKg : 0,
      'meshArea': meshArea.toDouble(),
      'filmArea': filmArea.toDouble(),
      'beacons': beacons.toDouble(),
      'damperTapeM': damperTapeM.toDouble(),
      'minExactNeedKg': scenarios['MIN']!.exactNeed,
      'recExactNeedKg': recScenario.exactNeed,
      'maxExactNeedKg': scenarios['MAX']!.exactNeed,
      'minPurchaseKg': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseKg': recScenario.purchaseQuantity,
      'maxPurchaseKg': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
