import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── Default spec (mirrors screed-canonical.v1.json) ─── */

/* ─── Factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

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

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = math.max(0.1, inputs['length'] ?? defaultFor(spec, 'length', 5)).toDouble();
    final width = math.max(0.1, inputs['width'] ?? defaultFor(spec, 'width', 4)).toDouble();
    return {
      'inputMode': 0.0,
      'area': roundValue(length * width, 3),
      'perimeter': roundValue(2 * (length + width), 3),
    };
  }

  final area = math.max(0.1, inputs['area'] ?? defaultFor(spec, 'area', 20)).toDouble();
  return {
    'inputMode': 1.0,
    'area': roundValue(area, 3),
    'perimeter': roundValue(_estimatePerimeter(area), 3),
  };
}

Map<String, dynamic> _resolveScreedType(SpecReader spec, Map<String, double> inputs) {
  final screedType = (inputs['screedType'] ?? defaultFor(spec, 'screedType', 0)).round().clamp(0, 2);
  return spec.normativeList('screed_types').firstWhere(
    (item) => (item['id'] as num).toInt() == screedType,
    orElse: () => spec.normativeList('screed_types').first,
  );
}

/* ─── Main calculator ─── */

CanonicalCalculatorContractResult calculateCanonicalScreed(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(screedSpecData);

  final normalized = hasCanonicalScreedInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyScreedInputs(inputs);

  final work = _resolveArea(spec, normalized);
  final thickness = (normalized['thickness'] ?? defaultFor(spec, 'thickness', 50))
      .clamp(spec.materialRule<num>('min_thickness_mm').toDouble(), spec.materialRule<num>('max_thickness_mm').toDouble())
      .toDouble();
  final screedType = _resolveScreedType(spec, normalized);

  final area = work['area']!;
  final perimeter = work['perimeter']!;
  final volume = roundValue(area * (thickness / 1000) * _volumeMultiplier, 6);

  // Determine effective consumption for scenarios
  double effectiveConsumptionKgPerM2Mm;

  if ((screedType['id'] as num).toInt() == 0) {
    effectiveConsumptionKgPerM2Mm = (_cementFraction * _cementDensity * _volumeMultiplier) / 1000;
  } else if ((screedType['id'] as num).toInt() == 1) {
    effectiveConsumptionKgPerM2Mm = (_cpsDensityReady * _volumeMultiplier) / 1000;
  } else {
    effectiveConsumptionKgPerM2Mm = (_cpsDensitySemidry * _volumeMultiplier) / 1000;
  }

  const bagWeight = 50.0;

  // Compute scenarios
  final baseExactNeed = area * thickness * effectiveConsumptionKgPerM2Mm;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeed * multiplier, 6);
    final bags = exactNeed > 0 ? (exactNeed / bagWeight).ceil() : 0;
    final purchaseQuantity = roundValue(bags * bagWeight, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'screed_type:${screedType['key'] as String}',
        'packaging:screed-bag-${bagWeight.toInt()}${spec.packagingRule<String>('unit')}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'screed-bag-${bagWeight.toInt()}${spec.packagingRule<String>('unit')}',
        packageSize: bagWeight,
        packagesCount: bags,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Ancillary quantities
  final cementKg = roundValue(volume * _cementFraction * _cementDensity, 3);
  final bags50Cement = (cementKg / 50).ceil();
  final sandTons = roundValue((volume * _sandFraction * _sandDensity * 10).ceil() / 10, 3);
  final waterL = roundValue(volume * _waterPerM3, 3);

  final cpsKgReady = roundValue(volume * _cpsDensityReady, 3);
  final bags50Ready = (cpsKgReady / 50).ceil();
  final bags40Ready = (cpsKgReady / 40).ceil();

  final cpsKgSemidry = roundValue(volume * _cpsDensitySemidry, 3);
  final bags50Semidry = (cpsKgSemidry / 50).ceil();
  final fiberKg = roundValue(area * _fiberKgPerM2, 3);

  final meshArea = thickness >= spec.materialRule<num>('mesh_thickness_threshold_mm').toDouble()
      ? (area * _meshMargin).ceil()
      : 0;
  final filmArea = (area * _filmMargin).ceil();
  final beacons = (area / _beaconsAreaPerPiece).ceil();
  final damperTapeM = (perimeter * _damperTapeReserve).ceil();

  // Build materials list per type
  final materials = <CanonicalMaterialResult>[];

  if ((screedType['id'] as num).toInt() == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Цемент М400 (мешки 50 кг)',
        quantity: cementKg,
        unit: 'кг',
        withReserve: (bags50Cement * 50).toDouble(),
        purchaseQty: bags50Cement.toInt(),
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
        purchaseQty: filmArea.toInt(),
        category: 'Подготовка',
      ),
    ]);
    if (meshArea > 0) {
      materials.add(CanonicalMaterialResult(
        name: 'Сетка армирующая',
        quantity: meshArea.toDouble(),
        unit: 'м²',
        withReserve: meshArea.toDouble(),
        purchaseQty: meshArea.toInt(),
        category: 'Армирование',
      ));
    }
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Маячковый профиль',
        quantity: beacons.toDouble(),
        unit: 'шт',
        withReserve: beacons.toDouble(),
        purchaseQty: beacons.toInt(),
        category: 'Разметка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента',
        quantity: damperTapeM.toDouble(),
        unit: 'м',
        withReserve: damperTapeM.toDouble(),
        purchaseQty: damperTapeM.toInt(),
        category: 'Подготовка',
      ),
    ]);
  } else if ((screedType['id'] as num).toInt() == 1) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Готовая ЦПС М150 (мешки 50 кг)',
        quantity: cpsKgReady,
        unit: 'кг',
        withReserve: (bags50Ready * 50).toDouble(),
        purchaseQty: bags50Ready.toInt(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Плёнка ПЭ',
        quantity: filmArea.toDouble(),
        unit: 'м²',
        withReserve: filmArea.toDouble(),
        purchaseQty: filmArea.toInt(),
        category: 'Подготовка',
      ),
    ]);
    if (meshArea > 0) {
      materials.add(CanonicalMaterialResult(
        name: 'Сетка армирующая',
        quantity: meshArea.toDouble(),
        unit: 'м²',
        withReserve: meshArea.toDouble(),
        purchaseQty: meshArea.toInt(),
        category: 'Армирование',
      ));
    }
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Маячковый профиль',
        quantity: beacons.toDouble(),
        unit: 'шт',
        withReserve: beacons.toDouble(),
        purchaseQty: beacons.toInt(),
        category: 'Разметка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента',
        quantity: damperTapeM.toDouble(),
        unit: 'м',
        withReserve: damperTapeM.toDouble(),
        purchaseQty: damperTapeM.toInt(),
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
        purchaseQty: bags50Semidry.toInt(),
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
        purchaseQty: filmArea.toInt(),
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Демпферная лента',
        quantity: damperTapeM.toDouble(),
        unit: 'м',
        withReserve: damperTapeM.toDouble(),
        purchaseQty: damperTapeM.toInt(),
        category: 'Подготовка',
      ),
    ]);
  }

  // Warnings
  final warnings = <String>[];
  if (thickness < spec.warningRule<num>('thin_threshold_mm').toDouble()) {
    warnings.add('Толщина менее 30 мм — слишком тонкая для выравнивания пола');
  }
  if (thickness > spec.warningRule<num>('thick_threshold_mm').toDouble()) {
    warnings.add('При толщине более 100 мм рекомендуется разделить заливку на слои');
  }
  if ((screedType['id'] as num).toInt() == 0 && area > spec.warningRule<num>('large_area_cps_threshold_m2').toDouble()) {
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
      'thickness': roundValue(thickness, 3),
      'screedType': (screedType['id'] as num).toInt().toDouble(),
      'volume': roundValue(volume, 6),
      'cementKg': (screedType['id'] as num).toInt() == 0 ? cementKg : 0,
      'bags50Cement': (screedType['id'] as num).toInt() == 0 ? bags50Cement.toDouble() : 0,
      'sandTons': (screedType['id'] as num).toInt() == 0 ? sandTons : 0,
      'waterL': (screedType['id'] as num).toInt() == 0 ? waterL : 0,
      'cpsKg': (screedType['id'] as num).toInt() == 1 ? cpsKgReady : (screedType['id'] as num).toInt() == 2 ? cpsKgSemidry : 0,
      'bags50': (screedType['id'] as num).toInt() == 1 ? bags50Ready.toDouble() : (screedType['id'] as num).toInt() == 2 ? bags50Semidry.toDouble() : 0,
      'bags40': (screedType['id'] as num).toInt() == 1 ? bags40Ready.toDouble() : 0,
      'fiberKg': (screedType['id'] as num).toInt() == 2 ? fiberKg : 0,
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
