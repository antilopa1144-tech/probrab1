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

class _ComponentScenario {
  final Map<String, dynamic> component;
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
  final Map<String, dynamic> component;
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

double _resolveWorkArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  if (inputMode == 0) {
    final length = (inputs['length'] ?? defaultFor(spec, 'length', 5)).clamp(1, 50).toDouble();
    final width = (inputs['width'] ?? defaultFor(spec, 'width', 4)).clamp(1, 50).toDouble();
    final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.7)).clamp(2, 5).toDouble();
    final ceilingArea = length * width;
    final wallsArea = 2 * (length + width) * height;
    final surfaceMode = (inputs['surface'] ?? defaultFor(spec, 'surface', 0)).round();
    if (surfaceMode == 0) return wallsArea;
    if (surfaceMode == 1) return ceilingArea;
    return wallsArea + ceilingArea;
  }
  return (inputs['area'] ?? defaultFor(spec, 'area', 50)).clamp(1, 500).toDouble();
}

double _resolveBagWeight(SpecReader spec, Map<String, double> inputs) {
  final bagWeight = (inputs['bagWeight'] ?? spec.packagingRule<num>('default_package_size').toDouble());
  if ((spec.packagingRule<List>('allowed_package_sizes') ?? []).contains(bagWeight)) {
    return bagWeight;
  }
  return spec.packagingRule<num>('default_package_size').toDouble();
}

Map<String, dynamic> _resolveQualityProfile(SpecReader spec, Map<String, double> inputs) {
  final qualityClass = (inputs['qualityClass'] ?? defaultFor(spec, 'qualityClass', 0)).round().clamp(0, 3);
  for (final profile in spec.normativeList('quality_profiles')) {
    if ((profile['id'] as num).toInt() == qualityClass) return profile;
  }
  return spec.normativeList('quality_profiles').first;
}

int _resolveComponentLayers(
  SpecReader spec,
  Map<String, double> inputs,
  String componentKey,
  int fallbackLayers,
) {
  final legacyLayers = (inputs['layers'] ?? defaultFor(spec, 'layers', 0)).round().clamp(0, 5);
  final overrideKey = componentKey == 'start' ? 'startLayers' : 'finishLayers';
  final explicitLayers = (inputs[overrideKey] ?? defaultFor(spec, overrideKey, 0)).round().clamp(0, 5);
  if (explicitLayers > 0) return explicitLayers;
  if (legacyLayers > 0) return legacyLayers;
  return fallbackLayers;
}

List<_ResolvedPuttyComponent> _resolveComponents(
  SpecReader spec,
  Map<String, double> inputs,
  int puttyType,
  Map<String, dynamic> qualityProfile,
) {
  final components = spec.normativeList('components');
  final profileComponents = (qualityProfile['components'] as Map<String, dynamic>?) ?? {};
  return components
      .where((component) => ((component['enabled_for_putty_types'] as List?) ?? []).contains(puttyType))
      .map((component) {
        final componentKey = component['key'] as String;
        final profileComponent = profileComponents[componentKey] as Map<String, dynamic>?;
        final fallbackLayers = (profileComponent?['default_layers'] as num?)?.toInt() ?? (component['thickness_mm'] as num).round();
        return _ResolvedPuttyComponent(
          component: component,
          consumptionPerLayer: (profileComponent?['consumption_kg_per_m2_layer'] as num?)?.toDouble() ?? (component['consumption_kg_per_m2_mm'] as num).toDouble(),
          layers: _resolveComponentLayers(spec, inputs, componentKey, fallbackLayers),
        );
      })
      .toList(growable: false);
}

double _findResolvedLayers(List<_ResolvedPuttyComponent> components, String key) {
  for (final component in components) {
    if (component.component['key'] == key) return component.layers.toDouble();
  }
  return 0;
}

CanonicalCalculatorContractResult calculateCanonicalPutty(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(puttySpecData);

  final workArea = _resolveWorkArea(spec, inputs);
  final puttyType = (inputs['puttyType'] ?? defaultFor(spec, 'puttyType', 0)).round().clamp(0, 2);
  final bagWeight = _resolveBagWeight(spec, inputs);
  final qualityProfile = _resolveQualityProfile(spec, inputs);
  final resolvedComponents = _resolveComponents(spec, inputs, puttyType, qualityProfile);

  final scenarios = <String, CanonicalScenarioResult>{};
  final recComponentScenarios = <_ComponentScenario>[];

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final keyFactors = buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName);
    final componentScenarios = resolvedComponents.map((resolved) {
      final exactNeed = roundValue(
        workArea * resolved.layers * resolved.consumptionPerLayer * multiplier,
        3,
      );
      final packageCount = (exactNeed / bagWeight).ceil();
      final purchaseQuantity = roundValue(packageCount * bagWeight, 3);
      final leftover = roundValue(purchaseQuantity - exactNeed, 3);
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

    final exactNeed = roundValue(
      componentScenarios.fold(0.0, (sum, component) => sum + component.exactNeed),
      3,
    );
    final purchaseQuantity = roundValue(
      componentScenarios.fold(0.0, (sum, component) => sum + component.purchaseQuantity),
      3,
    );
    final leftover = roundValue(
      componentScenarios.fold(0.0, (sum, component) => sum + component.leftover),
      3,
    );

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: leftover,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'quality_profile:${qualityProfile['key'] as String}',
        for (final component in componentScenarios)
          'component:${component.component['key']}:layers:${component.exactNeed > 0 ? component.component['key'] == "start" ? _findResolvedLayers(resolvedComponents, "start").toInt() : _findResolvedLayers(resolvedComponents, "finish").toInt() : 0}',
      ],
      keyFactors: keyFactors,
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'bag-${bagWeight.toInt()}kg-total',
        packageSize: bagWeight,
        packagesCount: (purchaseQuantity / bagWeight).ceil(),
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final materials = <CanonicalMaterialResult>[
    for (final componentScenario in recComponentScenarios)
      CanonicalMaterialResult(
        name: 'Шпаклёвка ${(componentScenario.component['label'] as String).toLowerCase()} (мешки ${bagWeight.toInt()} кг)',
        quantity: roundValue(componentScenario.exactNeed / bagWeight, 3),
        unit: 'мешков',
        withReserve: (componentScenario.purchaseQuantity / bagWeight).ceilToDouble(),
        purchaseQty: (componentScenario.purchaseQuantity / bagWeight).ceil().toDouble(),
        category: componentScenario.component['category'] as String,
      ),
  ];

  if (puttyType == 1 || puttyType == 2) {
    final serpyankaMeters = workArea * spec.materialRule<num>('serpyanka_linear_m_per_m2').toDouble() * spec.materialRule<num>('serpyanka_reserve_factor').toDouble();
    materials.add(
      CanonicalMaterialResult(
        name: 'Серпянка (лента армировочная 45 мм, рулон ${spec.materialRule<num>('serpyanka_roll_length_m').toInt()} м)',
        quantity: roundValue(workArea * spec.materialRule<num>('serpyanka_linear_m_per_m2').toDouble(), 3),
        unit: 'м.п.',
        withReserve: serpyankaMeters.ceilToDouble(),
        purchaseQty: (serpyankaMeters / spec.materialRule<num>('serpyanka_roll_length_m').toDouble()).ceil().toDouble(),
        category: 'Армирование',
      ),
    );
  }

  final primerCoatsMap = spec.materialRule<Map>('primer_coats');
  final primerCoats = puttyType == 0
      ? (primerCoatsMap['finish_only'] as num).toDouble()
      : puttyType == 1
          ? (primerCoatsMap['with_start'] as num).toDouble()
          : (primerCoatsMap['start_only'] as num).toDouble();
  final primerLiters = workArea * spec.materialRule<num>('primer_l_per_m2_per_coat').toDouble() * primerCoats;
  materials.add(
    CanonicalMaterialResult(
      name: 'Грунтовка глубокого проникновения (10 л)',
      quantity: roundValue(primerLiters / 10, 3),
      unit: 'канистр',
      withReserve: (primerLiters / 10).ceilToDouble(),
      purchaseQty: (primerLiters / 10).ceil().toDouble(),
      category: 'Подготовка',
    ),
  );

  if ((spec.materialRule<List>('sandpaper_enabled_for_putty_types') ?? []).contains(puttyType)) {
    final sandpaperSheets = (workArea / spec.materialRule<num>('sandpaper_m2_per_sheet').toDouble()).ceil();
    final purchaseQty = (sandpaperSheets * spec.materialRule<num>('sandpaper_reserve_factor').toDouble()).ceil();
    materials.add(
      CanonicalMaterialResult(
        name: 'Наждачная бумага P180-P240',
        quantity: sandpaperSheets.toDouble(),
        unit: 'листов',
        withReserve: purchaseQty.toDouble(),
        purchaseQty: purchaseQty.toDouble(),
        category: 'Шлифовка',
      ),
    );
  }

  final warnings = <String>[];
  if (workArea > spec.warningRule<num>('mechanized_area_threshold_m2').toDouble()) {
    warnings.add('Для больших площадей рекомендуется нанесение шпаклёвки механизированным методом');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'wallArea': roundValue(workArea, 3),
      'puttyType': puttyType.toDouble(),
      'bagWeight': bagWeight,
      'qualityClass': (qualityProfile['id'] as num).toInt().toDouble(),
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
