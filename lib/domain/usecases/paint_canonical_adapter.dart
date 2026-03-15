import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

const PaintCanonicalSpec paintCanonicalSpecV1 = PaintCanonicalSpec(
  calculatorId: 'paint',
  formulaVersion: 'paint-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 40, min: 0, max: 1000),
    CanonicalInputField(key: 'wallArea', unit: 'm2', defaultValue: 40, min: 0, max: 1000),
    CanonicalInputField(key: 'ceilingArea', unit: 'm2', defaultValue: 20, min: 0, max: 1000),
    CanonicalInputField(key: 'doorsWindows', unit: 'm2', defaultValue: 0, min: 0, max: 200),
    CanonicalInputField(key: 'roomWidth', unit: 'm', defaultValue: 4, min: 0.5, max: 20),
    CanonicalInputField(key: 'roomLength', unit: 'm', defaultValue: 5, min: 0.5, max: 20),
    CanonicalInputField(key: 'roomHeight', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 20),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 20),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 0, min: 0, max: 200),
    CanonicalInputField(key: 'paintType', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'surfaceType', defaultValue: 0, min: 0, max: 8),
    CanonicalInputField(key: 'surfacePrep', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'colorIntensity', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'coats', defaultValue: 2, min: 1, max: 5),
    CanonicalInputField(key: 'coverage', unit: 'm2/l', defaultValue: 10, min: 4, max: 15),
    CanonicalInputField(key: 'canSize', unit: 'l', defaultValue: 0, min: 0, max: 15),
  ],
  enabledFactors: [
    'surface_quality',
    'geometry_complexity',
    'installation_method',
    'worker_skill',
    'waste_factor',
    'logistics_buffer',
    'packaging_rounding',
  ],
  paintTypes: [
    PaintScopeSpec(id: 0, key: 'interior', label: 'Интерьерная краска'),
    PaintScopeSpec(id: 1, key: 'facade', label: 'Фасадная краска'),
  ],
  surfaceTypes: [
    PaintSurfaceSpec(id: 0, key: 'smooth_puttied', label: 'Гладкая шпатлёванная', multiplier: 1.0, scopeIds: [0]),
    PaintSurfaceSpec(id: 1, key: 'plaster_concrete', label: 'Бетон, штукатурка', multiplier: 1.15, scopeIds: [0]),
    PaintSurfaceSpec(id: 2, key: 'porous_block', label: 'Пористая (газоблок, кирпич)', multiplier: 1.3, scopeIds: [0]),
    PaintSurfaceSpec(id: 3, key: 'wood', label: 'Дерево', multiplier: 1.1, scopeIds: [0]),
    PaintSurfaceSpec(id: 4, key: 'wallpaper', label: 'Обои под покраску', multiplier: 1.2, scopeIds: [0]),
    PaintSurfaceSpec(id: 5, key: 'relief_texture', label: 'Рельефная фактура', multiplier: 1.4, scopeIds: [0]),
    PaintSurfaceSpec(id: 6, key: 'facade_concrete', label: 'Фасад: бетон', multiplier: 1.0, scopeIds: [1]),
    PaintSurfaceSpec(id: 7, key: 'facade_brick', label: 'Фасад: кирпич', multiplier: 1.15, scopeIds: [1]),
    PaintSurfaceSpec(id: 8, key: 'facade_bark_beetle', label: 'Фасад: короед', multiplier: 1.4, scopeIds: [1]),
  ],
  surfacePreparations: [
    PaintPreparationSpec(id: 0, key: 'primed', label: 'Загрунтованная', multiplier: 1.0),
    PaintPreparationSpec(id: 1, key: 'raw', label: 'Новая необработанная', multiplier: 1.2),
    PaintPreparationSpec(id: 2, key: 'repainted', label: 'Ранее окрашенная', multiplier: 0.95),
  ],
  colorIntensities: [
    PaintColorSpec(id: 0, key: 'light', label: 'Светлый', multiplier: 1.0),
    PaintColorSpec(id: 1, key: 'bright', label: 'Яркий', multiplier: 1.15),
    PaintColorSpec(id: 2, key: 'dark', label: 'Тёмный', multiplier: 1.3),
  ],
  packagingRules: PaintPackagingRules(
    unit: 'л',
    defaultPackageSize: 5,
    allowedPackageSizes: [3, 5, 9, 10, 15],
    optimalPackageSizes: [3, 5, 10, 15],
  ),
  materialRules: PaintMaterialRules(
    primerLitersPerM2: 0.11,
    legacyUniversalPrimerLitersPerM2: 0.15,
    primerPackageSizeLiters: 10,
    rollerAreaM2PerPiece: 50,
    legacyBrushAreaM2PerPiece: 40,
    legacyBrushesMin: 2,
    legacyBrushesMax: 10,
    brushesCount: 1,
    traysCount: 1,
    tapeRollLengthM: 50,
    tapeRunsPerRoom: 2,
    tapeReserveFactor: 1.1,
    ceilingPremiumFactor: 1.15,
    defaultRollerAbsorptionLiters: 0.3,
    legacyFirstCoatMultiplier: 1.2,
  ),
  warningRules: PaintWarningRules(
    primerRequiredSurfaceIds: [2, 4, 5, 7, 8],
    oneCoatWarningThreshold: 1,
    roughSurfaceWarningIds: [5, 8],
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'surface_quality': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.08},
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
  'logistics_buffer': {'MIN': 1.0, 'REC': 1.02, 'MAX': 1.06},
  'packaging_rounding': {'MIN': 1.0, 'REC': 1.01, 'MAX': 1.03},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

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
    'coverage': _roundValue(coverage, 6),
    'canSize': inputs['canSize'] ?? 0,
  };
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(PaintCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _estimatePerimeter(double area) {
  if (area <= 0) return 0;
  return 4 * math.sqrt(area);
}

Map<String, double> _resolveWork(PaintCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 1)).round();
  final openingsArea = (inputs['openingsArea'] ?? inputs['doorsWindows'] ?? _defaultFor(spec, 'openingsArea', 0))
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
    final defaultRoomHeight = _defaultFor(spec, 'roomHeight', 2.7).clamp(2, 5).toDouble();
    final estimatedPerimeter = ceilingArea > 0
        ? _estimatePerimeter(ceilingArea)
        : wallArea > 0
            ? wallArea / defaultRoomHeight
            : 0.0;
    return {
      'area': _roundValue(wallArea + ceilingArea, 3),
      'wallArea': _roundValue(wallArea, 3),
      'ceilingArea': _roundValue(ceilingArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'openingsPerimeter': _roundValue(openingsPerimeter, 3),
      'inputMode': 1.0,
      'estimatedPerimeter': _roundValue(estimatedPerimeter, 3),
    };
  }

  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && hasCanonicalRoomDimensions)) && hasCanonicalRoomDimensions) {
    final roomWidth = (inputs['roomWidth'] ?? _defaultFor(spec, 'roomWidth', 4)).clamp(0.5, 20).toDouble();
    final roomLength = (inputs['roomLength'] ?? _defaultFor(spec, 'roomLength', 5)).clamp(0.5, 20).toDouble();
    final roomHeight = (inputs['roomHeight'] ?? _defaultFor(spec, 'roomHeight', 2.7)).clamp(2, 5).toDouble();
    final perimeter = 2 * (roomWidth + roomLength);
    final wallArea = (perimeter * roomHeight - openingsArea).clamp(0, double.infinity).toDouble();
    final ceilingArea = roomWidth * roomLength;
    return {
      'area': _roundValue(wallArea + ceilingArea, 3),
      'wallArea': _roundValue(wallArea, 3),
      'ceilingArea': _roundValue(ceilingArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'openingsPerimeter': _roundValue(openingsPerimeter, 3),
      'inputMode': 0.0,
      'estimatedPerimeter': _roundValue(perimeter, 3),
    };
  }

  if (hasLegacyRoomDimensions) {
    final length = (inputs['length'] ?? _defaultFor(spec, 'length', 5)).clamp(1, 20).toDouble();
    final width = (inputs['width'] ?? _defaultFor(spec, 'width', 4)).clamp(1, 20).toDouble();
    final height = (inputs['height'] ?? _defaultFor(spec, 'height', 2.7)).clamp(2, 5).toDouble();
    final perimeter = 2 * (length + width);
    final wallArea = (perimeter * height - openingsArea).clamp(0, double.infinity).toDouble();
    final ceilingArea = length * width;
    return {
      'area': _roundValue(wallArea + ceilingArea, 3),
      'wallArea': _roundValue(wallArea, 3),
      'ceilingArea': _roundValue(ceilingArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'openingsPerimeter': _roundValue(openingsPerimeter, 3),
      'inputMode': 0.0,
      'estimatedPerimeter': _roundValue(perimeter, 3),
    };
  }

  final area = (inputs['area'] ?? _defaultFor(spec, 'area', 40)).clamp(0, 1000).toDouble();
  final perimeter = area > 0 ? _estimatePerimeter(area) : 0.0;
  return {
    'area': _roundValue(area, 3),
    'wallArea': _roundValue(area, 3),
    'ceilingArea': 0.0,
    'openingsArea': _roundValue(openingsArea, 3),
    'openingsPerimeter': _roundValue(openingsPerimeter, 3),
    'inputMode': 1.0,
    'estimatedPerimeter': _roundValue(perimeter, 3),
  };
}

PaintScopeSpec _resolvePaintType(PaintCanonicalSpec spec, Map<String, double> inputs) {
  final paintType = (inputs['paintType'] ?? _defaultFor(spec, 'paintType', 0)).round().clamp(0, 1);
  return spec.paintTypes.firstWhere(
    (type) => type.id == paintType,
    orElse: () => spec.paintTypes.first,
  );
}

PaintSurfaceSpec _resolveSurface(PaintCanonicalSpec spec, Map<String, double> inputs, PaintScopeSpec paintType) {
  final surfaceType = (inputs['surfaceType'] ?? _defaultFor(spec, 'surfaceType', 0)).round().clamp(0, 8);
  for (final surface in spec.surfaceTypes) {
    if (surface.id == surfaceType && surface.scopeIds.contains(paintType.id)) {
      return surface;
    }
  }
  return spec.surfaceTypes.firstWhere(
    (surface) => surface.scopeIds.contains(paintType.id),
    orElse: () => spec.surfaceTypes.first,
  );
}

PaintPreparationSpec _resolvePreparation(PaintCanonicalSpec spec, Map<String, double> inputs) {
  final prepId = (inputs['surfacePrep'] ?? _defaultFor(spec, 'surfacePrep', 0)).round().clamp(0, 2);
  return spec.surfacePreparations.firstWhere(
    (prep) => prep.id == prepId,
    orElse: () => spec.surfacePreparations.first,
  );
}

PaintColorSpec _resolveColor(PaintCanonicalSpec spec, Map<String, double> inputs) {
  final colorId = (inputs['colorIntensity'] ?? _defaultFor(spec, 'colorIntensity', 0)).round().clamp(0, 2);
  return spec.colorIntensities.firstWhere(
    (color) => color.id == colorId,
    orElse: () => spec.colorIntensities.first,
  );
}

double _resolveCoverage(PaintCanonicalSpec spec, Map<String, double> inputs, PaintScopeSpec paintType) {
  final fallback = paintType.id == 1 ? 7.0 : 10.0;
  return (inputs['coverage'] ?? _defaultFor(spec, 'coverage', fallback)).clamp(4, 15).toDouble();
}

int _resolveCoats(PaintCanonicalSpec spec, Map<String, double> inputs) {
  return (inputs['coats'] ?? _defaultFor(spec, 'coats', 2)).round().clamp(1, 5);
}

List<double> _resolvePackageSizes(PaintCanonicalSpec spec, Map<String, double> inputs) {
  final requested = (inputs['canSize'] ?? _defaultFor(spec, 'canSize', 0)).toDouble();
  if (requested > 0 && spec.packagingRules.allowedPackageSizes.contains(requested)) {
    return [requested];
  }
  return spec.packagingRules.optimalPackageSizes;
}

Map<String, double> _keyFactors(PaintCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(PaintCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
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
    'purchase': _roundValue(bestPurchase, 6),
    'leftover': _roundValue(bestLeftover, 6),
    'label': 'paint-can-${bestSize.toInt()}$unit',
  };
}

CanonicalCalculatorContractResult calculateCanonicalPaint(
  Map<String, double> inputs, {
  PaintCanonicalSpec spec = paintCanonicalSpecV1,
}) {
  final work = _resolveWork(spec, inputs);
  final rawWallArea = work['wallArea']!;
  final rawCeilingArea = work['ceilingArea']!;
  final openingsArea = work['openingsArea']!;
  final openingsPerimeter = work['openingsPerimeter']!;
  final estimatedPerimeter = work['estimatedPerimeter']!;
  final paintType = _resolvePaintType(spec, inputs);
  final wallArea = rawWallArea;
  final ceilingArea = paintType.id == 1 ? 0.0 : rawCeilingArea;
  final area = wallArea + ceilingArea;
  final surface = _resolveSurface(spec, inputs, paintType);
  final preparation = _resolvePreparation(spec, inputs);
  final color = _resolveColor(spec, inputs);
  final coverage = _resolveCoverage(spec, inputs, paintType);
  final coats = _resolveCoats(spec, inputs);
  final lPerSqm = (coats * surface.multiplier * preparation.multiplier * color.multiplier) / coverage;
  final wallBaseExactNeed = wallArea * lPerSqm;
  final ceilingBaseExactNeed = ceilingArea * lPerSqm * spec.materialRules.ceilingPremiumFactor;
  final baseExactNeed = wallBaseExactNeed + ceilingBaseExactNeed;
  final packageSizes = _resolvePackageSizes(spec, inputs);
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeed * multiplier, 6);
    final package = _pickPackage(exactNeed, packageSizes, spec.packagingRules.unit);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: package['purchase'] as double,
      leftover: package['leftover'] as double,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'paint:${paintType.key}',
        'surface:${surface.key}',
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
  final primerLiters = _roundValue(area * spec.materialRules.primerLitersPerM2, 3);
  final primerCans = primerLiters > 0
      ? (primerLiters / spec.materialRules.primerPackageSizeLiters).ceil()
      : 0;
  final primerPurchase = _roundValue(primerCans * spec.materialRules.primerPackageSizeLiters, 3);
  final tapeMeters = _roundValue(
    estimatedPerimeter * spec.materialRules.tapeRunsPerRoom * spec.materialRules.tapeReserveFactor,
    3,
  );
  final tapeRolls = tapeMeters > 0
      ? (tapeMeters / spec.materialRules.tapeRollLengthM).ceil()
      : 0;
  final rollers = area > 0 ? (area / spec.materialRules.rollerAreaM2PerPiece).ceil() : 0;
  final brushes = area > 0 ? spec.materialRules.brushesCount : 0;
  final trays = area > 0 ? spec.materialRules.traysCount : 0;

  final warnings = <String>[];
  if (area <= 0) {
    warnings.add('Площадь окраски должна быть больше нуля');
  }
  if (spec.warningRules.primerRequiredSurfaceIds.contains(surface.id)) {
    warnings.add('Для выбранной поверхности рекомендуется предварительное грунтование');
  }
  if (coats <= spec.warningRules.oneCoatWarningThreshold) {
    warnings.add('Один слой редко даёт равномерное укрытие. Обычно рекомендуют 2 слоя');
  }
  if (spec.warningRules.roughSurfaceWarningIds.contains(surface.id)) {
    warnings.add('Для рельефных поверхностей и фасадной фактуры расход краски может быть заметно выше среднего');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${paintType.label} (${recScenario.buyPlan.packageSize.toInt()} л)',
        quantity: recScenario.exactNeed,
        unit: 'л',
        withReserve: recScenario.purchaseQuantity,
        purchaseQty: recScenario.buyPlan.packagesCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка под покраску ${surface.label.toLowerCase()} (${spec.materialRules.primerPackageSizeLiters.toInt()} л)',
        quantity: primerLiters,
        unit: 'л',
        withReserve: primerPurchase,
        purchaseQty: primerCans,
        category: 'Подготовка',
      ),
      CanonicalMaterialResult(
        name: 'Валик малярный (микрофибра, 250 мм)',
        quantity: rollers.toDouble(),
        unit: 'шт',
        withReserve: rollers.toDouble(),
        purchaseQty: rollers,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кисть плоская (для углов, 50 мм)',
        quantity: brushes.toDouble(),
        unit: 'шт',
        withReserve: brushes.toDouble(),
        purchaseQty: brushes,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кювета для краски',
        quantity: trays.toDouble(),
        unit: 'шт',
        withReserve: trays.toDouble(),
        purchaseQty: trays,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Малярная лента (${spec.materialRules.tapeRollLengthM.toInt()} м)',
        quantity: _roundValue(tapeMeters / spec.materialRules.tapeRollLengthM, 3),
        unit: 'рулон',
        withReserve: tapeRolls.toDouble(),
        purchaseQty: tapeRolls,
        category: 'Расходники',
      ),
    ],
    totals: {
      'area': _roundValue(area, 3),
      'wallArea': _roundValue(wallArea, 3),
      'ceilingArea': _roundValue(ceilingArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'openingsPerimeter': _roundValue(openingsPerimeter, 3),
      'inputMode': work['inputMode']!,
      'paintType': paintType.id.toDouble(),
      'surfaceType': surface.id.toDouble(),
      'surfacePrep': preparation.id.toDouble(),
      'colorIntensity': color.id.toDouble(),
      'coats': coats.toDouble(),
      'coverage': _roundValue(coverage, 3),
      'canSize': recScenario.buyPlan.packageSize,
      'lPerSqm': _roundValue(lPerSqm, 6),
      'estimatedPerimeter': _roundValue(estimatedPerimeter, 3),
      'wallBaseExactNeedL': _roundValue(wallBaseExactNeed, 6),
      'ceilingBaseExactNeedL': _roundValue(ceilingBaseExactNeed, 6),
      'baseExactNeedL': _roundValue(baseExactNeed, 6),
      'ceilingPremiumFactor': _roundValue(spec.materialRules.ceilingPremiumFactor, 3),
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
