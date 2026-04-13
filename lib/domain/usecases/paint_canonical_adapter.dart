import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'surface_quality': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.08},
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
  'logistics_buffer': {'MIN': 1.0, 'REC': 1.02, 'MAX': 1.06},
  'packaging_rounding': {'MIN': 1.0, 'REC': 1.01, 'MAX': 1.03},
};

bool hasCanonicalPaintInputs(Map<String, double> inputs) {
  final hasCanonicalAreaShape = inputs.containsKey('area') ||
      inputs.containsKey('roomWidth') ||
      inputs.containsKey('roomLength') ||
      inputs.containsKey('roomHeight') ||
      inputs.containsKey('wallArea') ||
      inputs.containsKey('ceilingArea');
  if (!hasCanonicalAreaShape) return false;

  const canonicalKeys = [
    'surfaceType',
    'coverage',
    'coats',
    'canSize',
    'openingsArea',
  ];
  return canonicalKeys.any(inputs.containsKey);
}

bool hasLegacyUniversalPaintInputs(Map<String, double> inputs) {
  if (inputs.containsKey('consumption') ||
      inputs.containsKey('reserve') ||
      inputs.containsKey('layers') ||
      inputs.containsKey('doorsWindows') ||
      inputs.containsKey('length') ||
      inputs.containsKey('width') ||
      inputs.containsKey('height')) {
    return true;
  }

  final paintMode = (inputs['paintType'] ?? 0).round();
  if (paintMode > 1) return true;

  final surfacePrep = inputs['surfacePrep'];
  final colorIntensity = inputs['colorIntensity'];
  return !inputs.containsKey('coverage') &&
      !inputs.containsKey('coats') &&
      ((surfacePrep != null && surfacePrep >= 1) ||
          (colorIntensity != null && colorIntensity >= 1));
}

Map<String, double> normalizeLegacyUniversalPaintInputs(Map<String, double> inputs) {
  final paintMode = (inputs['paintType'] ?? 0).round().clamp(0, 2);
  final inputMode = (inputs['inputMode'] ?? 0).round().clamp(0, 1);
  final openingsArea = math.max(0, inputs['doorsWindows'] ?? 0);

  double grossWallArea;
  double grossCeilingArea;
  if (inputMode == 1) {
    final length = math.max(1, inputs['length'] ?? 5);
    final width = math.max(1, inputs['width'] ?? 4);
    final height = math.max(2, inputs['height'] ?? 2.7);
    grossWallArea = ((length + width) * 2 * height).toDouble();
    grossCeilingArea = (length * width).toDouble();
  } else {
    grossWallArea = math.max(0, inputs['wallArea'] ?? 0);
    grossCeilingArea = math.max(0, inputs['ceilingArea'] ?? 0);
  }

  final wallArea = paintMode == 1 ? 0.0 : grossWallArea;
  final ceilingArea = paintMode == 0 ? 0.0 : grossCeilingArea;
  final legacySurfacePrep = (inputs['surfacePrep'] ?? 1).round().clamp(1, 3);
  final legacyColorIntensity = (inputs['colorIntensity'] ?? 1).round().clamp(1, 3);
  final legacyConsumption = math.max(0.01, inputs['consumption'] ?? 0.11);
  final coverage = 1 / legacyConsumption;

  return {
    'inputMode': 1.0,
    'wallArea': wallArea,
    'ceilingArea': ceilingArea,
    'doorsWindows': paintMode == 1 ? 0.0 : openingsArea.toDouble(),
    'paintType': 0.0,
    'surfaceType': 0.0,
    'surfacePrep': (legacySurfacePrep - 1).toDouble(),
    'colorIntensity': (legacyColorIntensity - 1).toDouble(),
    'coats': (inputs['layers'] ?? 2).round().clamp(1, 4).toDouble(),
    'coverage': roundValue(coverage, 6),
    'canSize': inputs['canSize'] ?? 0,
  };
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveWork(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 1)).round();
  final openingsArea = (inputs['openingsArea'] ?? inputs['doorsWindows'] ?? defaultFor(spec, 'openingsArea', 0))
      .clamp(0, 200)
      .toDouble();
  final openingsPerimeter = openingsArea > 0 ? _estimatePerimeter(openingsArea) * 2 : 0.0;
  final hasSplitAreas = inputs.containsKey('wallArea') || inputs.containsKey('ceilingArea');
  final hasCanonicalRoomDimensions = inputs.containsKey('roomWidth') &&
      inputs.containsKey('roomLength') &&
      inputs.containsKey('roomHeight');
  final hasLegacyRoomDimensions = inputs.containsKey('length') &&
      inputs.containsKey('width') &&
      inputs.containsKey('height');

  if (hasSplitAreas) {
    final grossWallArea = (inputs['wallArea'] ?? 0).clamp(0, 1000).toDouble();
    final ceilingArea = (inputs['ceilingArea'] ?? 0).clamp(0, 1000).toDouble();
    final wallArea = (grossWallArea - openingsArea).clamp(0, double.infinity).toDouble();
    final defaultRoomHeight = defaultFor(spec, 'roomHeight', 2.7).clamp(2, 5).toDouble();
    final estimatedPerimeter = ceilingArea > 0
        ? _estimatePerimeter(ceilingArea)
        : wallArea > 0
            ? wallArea / defaultRoomHeight
            : 0.0;
    return {
      'area': roundValue(wallArea + ceilingArea, 3),
      'wallArea': roundValue(wallArea, 3),
      'ceilingArea': roundValue(ceilingArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'openingsPerimeter': roundValue(openingsPerimeter, 3),
      'inputMode': 1.0,
      'estimatedPerimeter': roundValue(estimatedPerimeter, 3),
    };
  }

  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && hasCanonicalRoomDimensions)) && hasCanonicalRoomDimensions) {
    final roomWidth = (inputs['roomWidth'] ?? defaultFor(spec, 'roomWidth', 4)).clamp(0.5, 20).toDouble();
    final roomLength = (inputs['roomLength'] ?? defaultFor(spec, 'roomLength', 5)).clamp(0.5, 20).toDouble();
    final roomHeight = (inputs['roomHeight'] ?? defaultFor(spec, 'roomHeight', 2.7)).clamp(2, 5).toDouble();
    final perimeter = 2 * (roomWidth + roomLength);
    final wallArea = (perimeter * roomHeight - openingsArea).clamp(0, double.infinity).toDouble();
    final ceilingArea = roomWidth * roomLength;
    return {
      'area': roundValue(wallArea + ceilingArea, 3),
      'wallArea': roundValue(wallArea, 3),
      'ceilingArea': roundValue(ceilingArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'openingsPerimeter': roundValue(openingsPerimeter, 3),
      'inputMode': 0.0,
      'estimatedPerimeter': roundValue(perimeter, 3),
    };
  }

  if (hasLegacyRoomDimensions) {
    final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(1, 20).toDouble();
    final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(1, 20).toDouble();
    final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.7)).clamp(2, 5).toDouble();
    final perimeter = 2 * (length + width);
    final wallArea = (perimeter * height - openingsArea).clamp(0, double.infinity).toDouble();
    final ceilingArea = length * width;
    return {
      'area': roundValue(wallArea + ceilingArea, 3),
      'wallArea': roundValue(wallArea, 3),
      'ceilingArea': roundValue(ceilingArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'openingsPerimeter': roundValue(openingsPerimeter, 3),
      'inputMode': 0.0,
      'estimatedPerimeter': roundValue(perimeter, 3),
    };
  }

  final area = (inputs['area'] ?? defaultFor(spec, 'area', 40)).clamp(0, 1000).toDouble();
  final perimeter = area > 0 ? _estimatePerimeter(area) : 0.0;
  return {
    'area': roundValue(area, 3),
    'wallArea': roundValue(area, 3),
    'ceilingArea': 0.0,
    'openingsArea': roundValue(openingsArea, 3),
    'openingsPerimeter': roundValue(openingsPerimeter, 3),
    'inputMode': 1.0,
    'estimatedPerimeter': roundValue(perimeter, 3),
  };
}

Map<String, dynamic> _resolvePaintType(SpecReader spec, Map<String, double> inputs) {
  final paintType = (inputs['paintType'] ?? defaultFor(spec, 'paintType', 0)).round().clamp(0, 1);
  return spec.normativeList('paint_types').firstWhere(
    (type) => (type['id'] as num).toInt() == paintType,
    orElse: () => spec.normativeList('paint_types').first,
  );
}

Map<String, dynamic> _resolveSurface(SpecReader spec, Map<String, double> inputs, Map<String, dynamic> paintType) {
  final surfaceType = (inputs['surfaceType'] ?? defaultFor(spec, 'surfaceType', 0)).round().clamp(0, 8);
  for (final surface in spec.normativeList('surface_types')) {
    if ((surface['id'] as num).toInt() == surfaceType && (surface['scope_ids'] as List).contains((paintType['id'] as num).toInt())) {
      return surface;
    }
  }
  return spec.normativeList('surface_types').firstWhere(
    (surface) => (surface['scope_ids'] as List).contains((paintType['id'] as num).toInt()),
    orElse: () => spec.normativeList('surface_types').first,
  );
}

Map<String, dynamic> _resolvePreparation(SpecReader spec, Map<String, double> inputs) {
  final prepId = (inputs['surfacePrep'] ?? defaultFor(spec, 'surfacePrep', 0)).round().clamp(0, 2);
  return spec.normativeList('surface_preparations').firstWhere(
    (prep) => (prep['id'] as num).toInt() == prepId,
    orElse: () => spec.normativeList('surface_preparations').first,
  );
}

Map<String, dynamic> _resolveColor(SpecReader spec, Map<String, double> inputs) {
  final colorId = (inputs['colorIntensity'] ?? defaultFor(spec, 'colorIntensity', 0)).round().clamp(0, 2);
  return spec.normativeList('color_intensities').firstWhere(
    (color) => (color['id'] as num).toInt() == colorId,
    orElse: () => spec.normativeList('color_intensities').first,
  );
}

double _resolveCoverage(SpecReader spec, Map<String, double> inputs, Map<String, dynamic> paintType) {
  final fallback = (paintType['id'] as num).toInt() == 1 ? 7.0 : 10.0;
  return (inputs['coverage'] ?? defaultFor(spec, 'coverage', fallback)).clamp(4, 15).toDouble();
}

int _resolveCoats(SpecReader spec, Map<String, double> inputs) {
  return (inputs['coats'] ?? defaultFor(spec, 'coats', 2)).round().clamp(1, 5);
}

List<double> _resolvePackageSizes(SpecReader spec, Map<String, double> inputs) {
  final requested = (inputs['canSize'] ?? defaultFor(spec, 'canSize', 0)).toDouble();
  if (requested > 0 && spec.packagingRule<List>('allowed_package_sizes').contains(requested)) {
    return [requested];
  }
  return spec.packagingRule<List>('optimal_package_sizes').cast<num>().map((e) => e.toDouble()).toList();
}

Map<String, dynamic> _pickPackage(double exactNeed, List<double> packageSizes, String unit) {
  var bestSize = packageSizes.first;
  var bestCount = exactNeed > 0 ? (exactNeed / bestSize).ceil() : 0;
  var bestPurchase = bestCount * bestSize;
  var bestLeftover = bestPurchase - exactNeed;

  for (final size in packageSizes.skip(1)) {
    final count = exactNeed > 0 ? (exactNeed / size).ceil() : 0;
    final purchase = count * size;
    final leftover = purchase - exactNeed;
    if (leftover < bestLeftover || (leftover == bestLeftover && purchase < bestPurchase)) {
      bestSize = size;
      bestCount = count;
      bestPurchase = purchase;
      bestLeftover = leftover;
    }
  }

  return {
    'size': bestSize,
    'count': bestCount,
    'purchase': roundValue(bestPurchase, 6),
    'leftover': roundValue(bestLeftover, 6),
    'label': 'paint-can-${bestSize.toInt()}$unit',
  };
}

CanonicalCalculatorContractResult calculateCanonicalPaint(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(paintSpecData);

  final work = _resolveWork(spec, inputs);
  final rawWallArea = work['wallArea']!;
  final rawCeilingArea = work['ceilingArea']!;
  final openingsArea = work['openingsArea']!;
  final openingsPerimeter = work['openingsPerimeter']!;
  final estimatedPerimeter = work['estimatedPerimeter']!;
  final paintType = _resolvePaintType(spec, inputs);
  final wallArea = rawWallArea;
  final ceilingArea = (paintType['id'] as num).toInt() == 1 ? 0.0 : rawCeilingArea;
  final area = wallArea + ceilingArea;
  final surface = _resolveSurface(spec, inputs, paintType);
  final preparation = _resolvePreparation(spec, inputs);
  final color = _resolveColor(spec, inputs);
  final coverage = _resolveCoverage(spec, inputs, paintType);
  final coats = _resolveCoats(spec, inputs);
  final lPerSqm = (coats * (surface['multiplier'] as num).toDouble() * (preparation['multiplier'] as num).toDouble() * (color['multiplier'] as num).toDouble()) / coverage;
  final wallBaseExactNeed = wallArea * lPerSqm;
  final ceilingBaseExactNeed = ceilingArea * lPerSqm * spec.materialRule<num>('ceiling_premium_factor').toDouble();
  final baseExactNeed = wallBaseExactNeed + ceilingBaseExactNeed;
  final packageSizes = _resolvePackageSizes(spec, inputs);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactNeed * multiplier, 6);
    final package = _pickPackage(exactNeed, packageSizes, spec.packagingRule<String>('unit'));

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'paint:${paintType['key'] as String}',
        'surface:${surface['key'] as String}',
        'packaging:${package['label']}',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: package['label'] as String,
        packageSize: package['size'] as double,
        packagesCount: package['count'] as int,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final primerLiters = roundValue(area * spec.materialRule<num>('primer_l_per_m2').toDouble(), 3);
  final primerCans = primerLiters > 0
      ? (primerLiters / spec.materialRule<num>('primer_package_size_l').toDouble()).ceil()
      : 0;
  final primerPurchase = roundValue(primerCans * spec.materialRule<num>('primer_package_size_l').toDouble(), 3);
  final tapeMeters = roundValue(
    estimatedPerimeter * spec.materialRule<num>('tape_runs_per_room').toDouble() * spec.materialRule<num>('tape_reserve_factor').toDouble(),
    3,
  );
  final tapeRolls = tapeMeters > 0
      ? (tapeMeters / spec.materialRule<num>('tape_roll_length_m').toDouble()).ceil()
      : 0;
  final rollers = area > 0 ? (area / spec.materialRule<num>('roller_area_m2_per_piece').toDouble()).ceil() : 0;
  final brushes = area > 0 ? spec.materialRule<num>('brushes_count').toDouble() : 0;
  final trays = area > 0 ? spec.materialRule<num>('trays_count').toDouble() : 0;

  final warnings = <String>[];
  if (area <= 0) {
    warnings.add('Площадь окраски должна быть больше нуля');
  }
  if (spec.warningRule<List>('primer_required_surface_ids').contains((surface['id'] as num).toInt())) {
    warnings.add('Для выбранной поверхности рекомендуется предварительное грунтование');
  }
  if (coats <= spec.warningRule<num>('one_coat_warning_threshold').toInt()) {
    warnings.add('Один слой редко даёт равномерное укрытие. Обычно рекомендуют 2 слоя');
  }
  if (spec.warningRule<List>('rough_surface_warning_ids').contains((surface['id'] as num).toInt())) {
    warnings.add('Для рельефных поверхностей и фасадной фактуры расход краски может быть заметно выше среднего');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${paintType['label'] as String} (${recScenario.buyPlan.packageSize.toInt()} л)',
        quantity: recScenario.exactNeed,
        unit: 'л',
        withReserve: recScenario.purchaseQuantity,
        purchaseQty: (recScenario.buyPlan.packagesCount * recScenario.buyPlan.packageSize).toDouble(),
        category: 'Основное',
        packageInfo: {'count': recScenario.buyPlan.packagesCount, 'unitSize': recScenario.buyPlan.packageSize, 'packageUnit': 'банок'},
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка под покраску ${(surface['label'] as String).toLowerCase()} (${spec.materialRule<num>('primer_package_size_l').toInt()} л)',
        quantity: primerLiters,
        unit: 'л',
        withReserve: primerPurchase,
        purchaseQty: (primerCans * spec.materialRule<num>('primer_package_size_l').toDouble()).toDouble(),
        category: 'Подготовка',
        packageInfo: {'count': primerCans, 'unitSize': spec.materialRule<num>('primer_package_size_l').toDouble(), 'packageUnit': 'канистр'},
      ),
      CanonicalMaterialResult(
        name: 'Валик малярный (микрофибра, 250 мм)',
        quantity: rollers.toDouble(),
        unit: 'шт',
        withReserve: rollers.toDouble(),
        purchaseQty: rollers.toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кисть плоская (для углов, 50 мм)',
        quantity: brushes.toDouble(),
        unit: 'шт',
        withReserve: brushes.toDouble(),
        purchaseQty: brushes.toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кювета для краски',
        quantity: trays.toDouble(),
        unit: 'шт',
        withReserve: trays.toDouble(),
        purchaseQty: trays.toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Малярная лента (${spec.materialRule<num>('tape_roll_length_m').toInt()} м)',
        quantity: roundValue(tapeMeters / spec.materialRule<num>('tape_roll_length_m').toDouble(), 3),
        unit: 'рулон',
        withReserve: tapeRolls.toDouble(),
        purchaseQty: tapeRolls.toDouble(),
        category: 'Расходники',
      ),
    ],
    totals: {
      'area': roundValue(area, 3),
      'wallArea': roundValue(wallArea, 3),
      'ceilingArea': roundValue(ceilingArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'openingsPerimeter': roundValue(openingsPerimeter, 3),
      'inputMode': work['inputMode']!,
      'paintType': (paintType['id'] as num).toInt().toDouble(),
      'surfaceType': (surface['id'] as num).toInt().toDouble(),
      'surfacePrep': (preparation['id'] as num).toInt().toDouble(),
      'colorIntensity': (color['id'] as num).toInt().toDouble(),
      'coats': coats.toDouble(),
      'coverage': roundValue(coverage, 3),
      'canSize': recScenario.buyPlan.packageSize,
      'lPerSqm': roundValue(lPerSqm, 6),
      'estimatedPerimeter': roundValue(estimatedPerimeter, 3),
      'wallBaseExactNeedL': roundValue(wallBaseExactNeed, 6),
      'ceilingBaseExactNeedL': roundValue(ceilingBaseExactNeed, 6),
      'baseExactNeedL': roundValue(baseExactNeed, 6),
      'ceilingPremiumFactor': roundValue(spec.materialRule<num>('ceiling_premium_factor').toDouble(), 3),
      'primerLiters': primerLiters,
      'tapeMeters': tapeMeters,
      'tapeRolls': tapeRolls.toDouble(),
      'minExactNeedL': scenarios['MIN']!.exactNeed,
      'recExactNeedL': recScenario.exactNeed,
      'maxExactNeedL': scenarios['MAX']!.exactNeed,
      'minPurchaseL': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseL': recScenario.purchaseQuantity,
      'maxPurchaseL': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
