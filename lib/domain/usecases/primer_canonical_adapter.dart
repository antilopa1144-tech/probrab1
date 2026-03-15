import '../models/canonical_calculator_contract.dart';

const PrimerCanonicalSpec primerCanonicalSpecV1 = PrimerCanonicalSpec(
  calculatorId: 'primer',
  formulaVersion: 'primer-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 50, min: 1, max: 500),
    CanonicalInputField(key: 'roomWidth', unit: 'm', defaultValue: 4, min: 0.5, max: 20),
    CanonicalInputField(key: 'roomLength', unit: 'm', defaultValue: 5, min: 0.5, max: 20),
    CanonicalInputField(key: 'roomHeight', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'surfaceType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'primerType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'coats', defaultValue: 1, min: 1, max: 3),
    CanonicalInputField(key: 'canSize', unit: 'l', defaultValue: 5, min: 5, max: 20),
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
  surfaceTypes: [
    PrimerSurfaceSpec(id: 0, key: 'absorbent_mineral', label: 'Бетон, пеноблок (впитывающая)', multiplier: 1.5),
    PrimerSurfaceSpec(id: 1, key: 'plasterboard_and_plaster', label: 'Гипсокартон, штукатурка', multiplier: 1.0),
    PrimerSurfaceSpec(id: 2, key: 'non_porous', label: 'Кафель, стекло (непористая)', multiplier: 1.2),
    PrimerSurfaceSpec(id: 3, key: 'wood_osb', label: 'Дерево, OSB', multiplier: 1.3),
  ],
  primerTypes: [
    PrimerTypeSpec(id: 0, key: 'deep_penetration', label: 'Грунтовка глубокого проникновения', baseLitersPerM2: 0.1),
    PrimerTypeSpec(id: 1, key: 'contact', label: 'Бетон-контакт', baseLitersPerM2: 0.35),
    PrimerTypeSpec(id: 2, key: 'for_gkl', label: 'Грунтовка для ГКЛ', baseLitersPerM2: 0.12),
  ],
  packagingRules: PrimerPackagingRules(
    unit: 'л',
    defaultPackageSize: 5,
    allowedPackageSizes: [5, 10, 15, 20],
  ),
  materialRules: PrimerMaterialRules(
    rollerAreaM2PerPiece: 30,
    brushesCount: 2,
    traysCount: 1,
    dryingTimeHoursByType: {0: 4, 1: 3, 2: 2},
  ),
  warningRules: PrimerWarningRules(
    absorbentSurfaceIds: [0],
    recommendedDoubleCoatSurfaceIds: [0],
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

bool hasCanonicalPrimerInputs(Map<String, double> inputs) {
  const canonicalKeys = ['inputMode', 'surfaceType', 'primerType', 'coats', 'roomWidth', 'roomLength', 'roomHeight'];
  return canonicalKeys.any(inputs.containsKey);
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(PrimerCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _resolveWorkArea(PrimerCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 1)).round();
  final hasRoomDimensions = inputs.containsKey('roomWidth') && inputs.containsKey('roomLength') && inputs.containsKey('roomHeight');
  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && hasRoomDimensions)) && hasRoomDimensions) {
    final roomWidth = (inputs['roomWidth'] ?? _defaultFor(spec, 'roomWidth', 4)).clamp(0.5, 20).toDouble();
    final roomLength = (inputs['roomLength'] ?? _defaultFor(spec, 'roomLength', 5)).clamp(0.5, 20).toDouble();
    final roomHeight = (inputs['roomHeight'] ?? _defaultFor(spec, 'roomHeight', 2.7)).clamp(2, 5).toDouble();
    return 2 * (roomWidth + roomLength) * roomHeight;
  }
  return (inputs['area'] ?? _defaultFor(spec, 'area', 50)).clamp(1, 500).toDouble();
}

double _resolveCanSize(PrimerCanonicalSpec spec, Map<String, double> inputs) {
  final canSize = (inputs['canSize'] ?? spec.packagingRules.defaultPackageSize).toDouble();
  if (spec.packagingRules.allowedPackageSizes.contains(canSize)) {
    return canSize;
  }
  return spec.packagingRules.defaultPackageSize;
}

PrimerSurfaceSpec _resolveSurface(PrimerCanonicalSpec spec, Map<String, double> inputs) {
  final surfaceType = (inputs['surfaceType'] ?? _defaultFor(spec, 'surfaceType', 0)).round().clamp(0, 3);
  for (final surface in spec.surfaceTypes) {
    if (surface.id == surfaceType) return surface;
  }
  return spec.surfaceTypes.first;
}

PrimerTypeSpec _resolvePrimerType(PrimerCanonicalSpec spec, Map<String, double> inputs) {
  final primerType = (inputs['primerType'] ?? _defaultFor(spec, 'primerType', 0)).round().clamp(0, 2);
  for (final type in spec.primerTypes) {
    if (type.id == primerType) return type;
  }
  return spec.primerTypes.first;
}

Map<String, double> _keyFactors(PrimerCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(PrimerCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalPrimer(
  Map<String, double> inputs, {
  PrimerCanonicalSpec spec = primerCanonicalSpecV1,
}) {
  final workArea = _resolveWorkArea(spec, inputs);
  final surface = _resolveSurface(spec, inputs);
  final primerType = _resolvePrimerType(spec, inputs);
  final coats = (inputs['coats'] ?? _defaultFor(spec, 'coats', 1)).round().clamp(1, 3);
  final canSize = _resolveCanSize(spec, inputs);
  final lPerSqm = primerType.baseLitersPerM2 * surface.multiplier;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(workArea * lPerSqm * coats * multiplier, 6);
    final packagesCount = (exactNeed / canSize).ceil();
    final purchaseQuantity = _roundValue(packagesCount * canSize, 6);
    final leftover = _roundValue(purchaseQuantity - exactNeed, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: leftover,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'surface:${surface.key}',
        'primer:${primerType.key}',
      ],
      keyFactors: _keyFactors(spec, scenarioName),
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'primer-can-${canSize.toInt()}l',
        packageSize: canSize,
        packagesCount: packagesCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final warnings = <String>[];
  if (spec.warningRules.absorbentSurfaceIds.contains(surface.id) && primerType.id != 0) {
    warnings.add('Для сильно впитывающих поверхностей рекомендуется грунтовка глубокого проникновения');
  }
  if (spec.warningRules.absorbentSurfaceIds.contains(surface.id) && primerType.id == 1) {
    warnings.add('Бетон-контакт применяют в основном по гладким невпитывающим основаниям');
  }
  if (spec.warningRules.recommendedDoubleCoatSurfaceIds.contains(surface.id) && coats == 1) {
    warnings.add('Для впитывающих оснований обычно рекомендуют 2 слоя грунтовки');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${primerType.label} (${canSize.toInt()} л)',
        quantity: recScenario.exactNeed,
        unit: 'л',
        withReserve: recScenario.purchaseQuantity,
        purchaseQty: recScenario.buyPlan.packagesCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Валик малярный 250 мм',
        quantity: (workArea / spec.materialRules.rollerAreaM2PerPiece).ceilToDouble(),
        unit: 'шт',
        withReserve: (workArea / spec.materialRules.rollerAreaM2PerPiece).ceilToDouble(),
        purchaseQty: (workArea / spec.materialRules.rollerAreaM2PerPiece).ceil(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кисть для углов и примыканий',
        quantity: spec.materialRules.brushesCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.brushesCount.toDouble(),
        purchaseQty: spec.materialRules.brushesCount,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кювета для грунтовки',
        quantity: spec.materialRules.traysCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.traysCount.toDouble(),
        purchaseQty: spec.materialRules.traysCount,
        category: 'Инструмент',
      ),
    ],
    totals: {
      'area': _roundValue(workArea, 3),
      'inputMode': (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 1)).round().toDouble(),
      'surfaceType': surface.id.toDouble(),
      'primerType': primerType.id.toDouble(),
      'coats': coats.toDouble(),
      'canSize': canSize,
      'lPerSqm': _roundValue(lPerSqm, 4),
      'minExactNeedL': scenarios['MIN']!.exactNeed,
      'recExactNeedL': recScenario.exactNeed,
      'maxExactNeedL': scenarios['MAX']!.exactNeed,
      'minPurchaseL': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseL': recScenario.purchaseQuantity,
      'maxPurchaseL': scenarios['MAX']!.purchaseQuantity,
      'dryingTimeHours': spec.materialRules.dryingTimeHoursByType[primerType.id] ?? 4,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
