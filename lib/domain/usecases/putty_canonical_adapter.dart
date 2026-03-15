import '../models/canonical_calculator_contract.dart';

const PuttyCanonicalSpec puttyCanonicalSpecV1 = PuttyCanonicalSpec(
  calculatorId: 'putty',
  formulaVersion: 'putty-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 50),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 50),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 50, min: 1, max: 500),
    CanonicalInputField(key: 'surface', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'puttyType', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'bagWeight', unit: 'kg', defaultValue: 20, min: 5, max: 25),
    CanonicalInputField(key: 'qualityClass', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'layers', defaultValue: 0, min: 0, max: 5),
    CanonicalInputField(key: 'startLayers', defaultValue: 0, min: 0, max: 5),
    CanonicalInputField(key: 'finishLayers', defaultValue: 0, min: 0, max: 5),
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
  components: [
    PuttyComponentSpec(
      key: 'finish',
      label: 'Финишная',
      category: 'Финишная',
      enabledForPuttyTypes: [0, 1],
      consumptionKgPerM2Mm: 1.1,
      thicknessMm: 1,
    ),
    PuttyComponentSpec(
      key: 'start',
      label: 'Стартовая',
      category: 'Стартовая',
      enabledForPuttyTypes: [1, 2],
      consumptionKgPerM2Mm: 2.7,
      thicknessMm: 1,
    ),
  ],
  qualityProfiles: [
    PuttyQualityProfile(
      id: 0,
      key: 'legacy_web',
      components: {
        'finish': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 1.1, defaultLayers: 1),
        'start': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 2.7, defaultLayers: 1),
      },
    ),
    PuttyQualityProfile(
      id: 1,
      key: 'economy',
      components: {
        'finish': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 1.0, defaultLayers: 1),
        'start': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 1.8, defaultLayers: 1),
      },
    ),
    PuttyQualityProfile(
      id: 2,
      key: 'standard',
      components: {
        'finish': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 0.8, defaultLayers: 1),
        'start': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 1.5, defaultLayers: 2),
      },
    ),
    PuttyQualityProfile(
      id: 3,
      key: 'premium',
      components: {
        'finish': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 0.5, defaultLayers: 2),
        'start': PuttyQualityComponentProfile(consumptionKgPerM2Layer: 1.2, defaultLayers: 2),
      },
    ),
  ],
  packagingRules: PuttyPackagingRules(
    unit: 'kg',
    defaultPackageSize: 20,
    allowedPackageSizes: [5, 20, 25],
  ),
  materialRules: PuttyAuxiliaryRules(
    primerLitersPerM2PerCoat: 0.15,
    finishOnlyPrimerCoats: 1,
    withStartPrimerCoats: 2,
    startOnlyPrimerCoats: 1,
    serpyankaLinearMPerM2: 1.2,
    serpyankaReserveFactor: 1.1,
    serpyankaRollLengthM: 45,
    sandpaperM2PerSheet: 5,
    sandpaperReserveFactor: 1.1,
    sandpaperEnabledForPuttyTypes: [0, 1],
  ),
  warningRules: PuttyWarningRules(mechanizedAreaThresholdM2: 100),
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

class _ComponentScenario {
  final PuttyComponentSpec component;
  final double exactNeed;
  final double purchaseQuantity;
  final double leftover;
  final Map<String, double> keyFactors;

  const _ComponentScenario({
    required this.component,
    required this.exactNeed,
    required this.purchaseQuantity,
    required this.leftover,
    required this.keyFactors,
  });
}

class _ResolvedPuttyComponent {
  final PuttyComponentSpec component;
  final double consumptionPerLayer;
  final int layers;

  const _ResolvedPuttyComponent({
    required this.component,
    required this.consumptionPerLayer,
    required this.layers,
  });
}

bool hasCanonicalPuttyInputs(Map<String, double> inputs) {
  const canonicalKeys = ['inputMode', 'surface', 'puttyType', 'bagWeight', 'length', 'width', 'height', 'startLayers', 'finishLayers'];
  return canonicalKeys.any(inputs.containsKey);
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(PuttyCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

double _resolveWorkArea(PuttyCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = (inputs['length'] ?? _defaultFor(spec, 'length', 5)).clamp(1, 50).toDouble();
    final width = (inputs['width'] ?? _defaultFor(spec, 'width', 4)).clamp(1, 50).toDouble();
    final height = (inputs['height'] ?? _defaultFor(spec, 'height', 2.7)).clamp(2, 5).toDouble();
    final ceilingArea = length * width;
    final wallsArea = 2 * (length + width) * height;
    final surfaceMode = (inputs['surface'] ?? _defaultFor(spec, 'surface', 0)).round();
    if (surfaceMode == 0) return wallsArea;
    if (surfaceMode == 1) return ceilingArea;
    return wallsArea + ceilingArea;
  }
  return (inputs['area'] ?? _defaultFor(spec, 'area', 50)).clamp(1, 500).toDouble();
}

double _resolveBagWeight(PuttyCanonicalSpec spec, Map<String, double> inputs) {
  final bagWeight = (inputs['bagWeight'] ?? spec.packagingRules.defaultPackageSize).toDouble();
  if (spec.packagingRules.allowedPackageSizes.contains(bagWeight)) {
    return bagWeight;
  }
  return spec.packagingRules.defaultPackageSize;
}

PuttyQualityProfile _resolveQualityProfile(PuttyCanonicalSpec spec, Map<String, double> inputs) {
  final qualityClass = (inputs['qualityClass'] ?? _defaultFor(spec, 'qualityClass', 0)).round().clamp(0, 3);
  for (final profile in spec.qualityProfiles) {
    if (profile.id == qualityClass) return profile;
  }
  return spec.qualityProfiles.first;
}

int _resolveComponentLayers(
  PuttyCanonicalSpec spec,
  Map<String, double> inputs,
  String componentKey,
  int fallbackLayers,
) {
  final legacyLayers = (inputs['layers'] ?? _defaultFor(spec, 'layers', 0)).round().clamp(0, 5);
  final overrideKey = componentKey == 'start' ? 'startLayers' : 'finishLayers';
  final explicitLayers = (inputs[overrideKey] ?? _defaultFor(spec, overrideKey, 0)).round().clamp(0, 5);
  if (explicitLayers > 0) return explicitLayers;
  if (legacyLayers > 0) return legacyLayers;
  return fallbackLayers;
}

List<_ResolvedPuttyComponent> _resolveComponents(
  PuttyCanonicalSpec spec,
  Map<String, double> inputs,
  int puttyType,
  PuttyQualityProfile qualityProfile,
) {
  return spec.components
      .where((component) => component.enabledForPuttyTypes.contains(puttyType))
      .map((component) {
        final profileComponent = qualityProfile.components[component.key];
        final fallbackLayers = profileComponent?.defaultLayers ?? component.thicknessMm.round();
        return _ResolvedPuttyComponent(
          component: component,
          consumptionPerLayer: profileComponent?.consumptionKgPerM2Layer ?? component.consumptionKgPerM2Mm,
          layers: _resolveComponentLayers(spec, inputs, component.key, fallbackLayers),
        );
      })
      .toList(growable: false);
}

Map<String, double> _keyFactors(PuttyCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(PuttyCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

double _findResolvedLayers(List<_ResolvedPuttyComponent> components, String key) {
  for (final component in components) {
    if (component.component.key == key) return component.layers.toDouble();
  }
  return 0;
}

CanonicalCalculatorContractResult calculateCanonicalPutty(
  Map<String, double> inputs, {
  PuttyCanonicalSpec spec = puttyCanonicalSpecV1,
}) {
  final workArea = _resolveWorkArea(spec, inputs);
  final puttyType = (inputs['puttyType'] ?? _defaultFor(spec, 'puttyType', 0)).round().clamp(0, 2);
  final bagWeight = _resolveBagWeight(spec, inputs);
  final qualityProfile = _resolveQualityProfile(spec, inputs);
  final resolvedComponents = _resolveComponents(spec, inputs, puttyType, qualityProfile);

  final scenarios = <String, CanonicalScenarioResult>{};
  final recComponentScenarios = <_ComponentScenario>[];

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final keyFactors = _keyFactors(spec, scenarioName);
    final componentScenarios = resolvedComponents.map((resolved) {
      final exactNeed = _roundValue(
        workArea * resolved.layers * resolved.consumptionPerLayer * multiplier,
        3,
      );
      final packageCount = (exactNeed / bagWeight).ceil();
      final purchaseQuantity = _roundValue(packageCount * bagWeight, 3);
      final leftover = _roundValue(purchaseQuantity - exactNeed, 3);
      return _ComponentScenario(
        component: resolved.component,
        exactNeed: exactNeed,
        purchaseQuantity: purchaseQuantity,
        leftover: leftover,
        keyFactors: keyFactors,
      );
    }).toList(growable: false);

    if (scenarioName == 'REC') {
      recComponentScenarios.addAll(componentScenarios);
    }

    final exactNeed = _roundValue(
      componentScenarios.fold(0.0, (sum, component) => sum + component.exactNeed),
      3,
    );
    final purchaseQuantity = _roundValue(
      componentScenarios.fold(0.0, (sum, component) => sum + component.purchaseQuantity),
      3,
    );
    final leftover = _roundValue(
      componentScenarios.fold(0.0, (sum, component) => sum + component.leftover),
      3,
    );

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: leftover,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'quality_profile:${qualityProfile.key}',
        for (final component in componentScenarios)
          'component:${component.component.key}:layers:${component.exactNeed > 0 ? component.component.key == "start" ? _findResolvedLayers(resolvedComponents, "start").toInt() : _findResolvedLayers(resolvedComponents, "finish").toInt() : 0}',
      ],
      keyFactors: keyFactors,
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'bag-${bagWeight.toInt()}kg-total',
        packageSize: bagWeight,
        packagesCount: (purchaseQuantity / bagWeight).ceil(),
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final materials = <CanonicalMaterialResult>[
    for (final componentScenario in recComponentScenarios)
      CanonicalMaterialResult(
        name: 'Шпаклёвка ${componentScenario.component.label.toLowerCase()} (мешки ${bagWeight.toInt()} кг)',
        quantity: _roundValue(componentScenario.exactNeed / bagWeight, 3),
        unit: 'мешков',
        withReserve: (componentScenario.purchaseQuantity / bagWeight).ceilToDouble(),
        purchaseQty: (componentScenario.purchaseQuantity / bagWeight).ceil(),
        category: componentScenario.component.category,
      ),
  ];

  if (puttyType == 1 || puttyType == 2) {
    final serpyankaMeters = workArea * spec.materialRules.serpyankaLinearMPerM2 * spec.materialRules.serpyankaReserveFactor;
    materials.add(
      CanonicalMaterialResult(
        name: 'Серпянка (лента армировочная 45 мм, рулон ${spec.materialRules.serpyankaRollLengthM.toInt()} м)',
        quantity: _roundValue(workArea * spec.materialRules.serpyankaLinearMPerM2, 3),
        unit: 'м.п.',
        withReserve: serpyankaMeters.ceilToDouble(),
        purchaseQty: (serpyankaMeters / spec.materialRules.serpyankaRollLengthM).ceil(),
        category: 'Армирование',
      ),
    );
  }

  final primerCoats = puttyType == 0
      ? spec.materialRules.finishOnlyPrimerCoats
      : puttyType == 1
          ? spec.materialRules.withStartPrimerCoats
          : spec.materialRules.startOnlyPrimerCoats;
  final primerLiters = workArea * spec.materialRules.primerLitersPerM2PerCoat * primerCoats;
  materials.add(
    CanonicalMaterialResult(
      name: 'Грунтовка глубокого проникновения (10 л)',
      quantity: _roundValue(primerLiters / 10, 3),
      unit: 'канистр',
      withReserve: (primerLiters / 10).ceilToDouble(),
      purchaseQty: (primerLiters / 10).ceil(),
      category: 'Подготовка',
    ),
  );

  if (spec.materialRules.sandpaperEnabledForPuttyTypes.contains(puttyType)) {
    final sandpaperSheets = (workArea / spec.materialRules.sandpaperM2PerSheet).ceil();
    final purchaseQty = (sandpaperSheets * spec.materialRules.sandpaperReserveFactor).ceil();
    materials.add(
      CanonicalMaterialResult(
        name: 'Наждачная бумага P180-P240',
        quantity: sandpaperSheets.toDouble(),
        unit: 'листов',
        withReserve: purchaseQty.toDouble(),
        purchaseQty: purchaseQty,
        category: 'Шлифовка',
      ),
    );
  }

  final warnings = <String>[];
  if (workArea > spec.warningRules.mechanizedAreaThresholdM2) {
    warnings.add('Для больших площадей рекомендуется нанесение шпаклёвки механизированным методом');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'wallArea': _roundValue(workArea, 3),
      'puttyType': puttyType.toDouble(),
      'bagWeight': bagWeight,
      'qualityClass': qualityProfile.id.toDouble(),
      'startLayers': _findResolvedLayers(resolvedComponents, 'start'),
      'finishLayers': _findResolvedLayers(resolvedComponents, 'finish'),
      'minExactNeedKg': scenarios['MIN']!.exactNeed,
      'recExactNeedKg': scenarios['REC']!.exactNeed,
      'maxExactNeedKg': scenarios['MAX']!.exactNeed,
      'minPurchaseKg': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseKg': scenarios['REC']!.purchaseQuantity,
      'maxPurchaseKg': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
