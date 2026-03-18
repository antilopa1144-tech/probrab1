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

bool hasCanonicalPrimerInputs(Map<String, double> inputs) {
  const canonicalKeys = ['inputMode', 'surfaceType', 'primerType', 'coats', 'roomWidth', 'roomLength', 'roomHeight'];
  return canonicalKeys.any(inputs.containsKey);
}

double _resolveWorkArea(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 1)).round();
  final hasRoomDimensions = inputs.containsKey('roomWidth') && inputs.containsKey('roomLength') && inputs.containsKey('roomHeight');
  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && hasRoomDimensions)) && hasRoomDimensions) {
    final roomWidth = (inputs['roomWidth'] ?? defaultFor(spec, 'roomWidth', 4)).clamp(0.5, 20).toDouble();
    final roomLength = (inputs['roomLength'] ?? defaultFor(spec, 'roomLength', 5)).clamp(0.5, 20).toDouble();
    final roomHeight = (inputs['roomHeight'] ?? defaultFor(spec, 'roomHeight', 2.7)).clamp(2, 5).toDouble();
    return 2 * (roomWidth + roomLength) * roomHeight;
  }
  return (inputs['area'] ?? defaultFor(spec, 'area', 50)).clamp(1, 500).toDouble();
}

double _resolveCanSize(SpecReader spec, Map<String, double> inputs) {
  final canSize = (inputs['canSize'] ?? spec.packagingRule<num>('default_package_size').toDouble());
  if ((spec.packagingRule<List>('allowed_package_sizes') ?? []).contains(canSize)) {
    return canSize;
  }
  return spec.packagingRule<num>('default_package_size').toDouble();
}

Map<String, dynamic> _resolveSurface(SpecReader spec, Map<String, double> inputs) {
  final surfaceType = (inputs['surfaceType'] ?? defaultFor(spec, 'surfaceType', 0)).round().clamp(0, 3);
  for (final surface in spec.normativeList('surface_types')) {
    if ((surface['id'] as num).toInt() == surfaceType) return surface;
  }
  return spec.normativeList('surface_types').first;
}

Map<String, dynamic> _resolvePrimerType(SpecReader spec, Map<String, double> inputs) {
  final primerType = (inputs['primerType'] ?? defaultFor(spec, 'primerType', 0)).round().clamp(0, 2);
  for (final type in spec.normativeList('primer_types')) {
    if ((type['id'] as num).toInt() == primerType) return type;
  }
  return spec.normativeList('primer_types').first;
}

CanonicalCalculatorContractResult calculateCanonicalPrimer(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(primerSpecData);

  final workArea = _resolveWorkArea(spec, inputs);
  final surface = _resolveSurface(spec, inputs);
  final primerType = _resolvePrimerType(spec, inputs);
  final coats = (inputs['coats'] ?? defaultFor(spec, 'coats', 1)).round().clamp(1, 3);
  final canSize = _resolveCanSize(spec, inputs);
  final lPerSqm = (primerType['base_l_per_m2'] as num).toDouble() * (surface['multiplier'] as num).toDouble();
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(workArea * lPerSqm * coats * multiplier, 6);
    final packagesCount = (exactNeed / canSize).ceil();
    final purchaseQuantity = roundValue(packagesCount * canSize, 6);
    final leftover = roundValue(purchaseQuantity - exactNeed, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: leftover,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'surface:${surface['key'] as String}',
        'primer:${primerType['key'] as String}',
      ],
      keyFactors: buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'primer-can-${canSize.toInt()}l',
        packageSize: canSize,
        packagesCount: packagesCount,
        unit: spec.packagingRule<String>('unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final warnings = <String>[];
  if ((spec.warningRule<List>('absorbent_surface_ids') ?? []).contains((surface['id'] as num).toInt()) && (primerType['id'] as num).toInt() != 0) {
    warnings.add('Для сильно впитывающих поверхностей рекомендуется грунтовка глубокого проникновения');
  }
  if ((spec.warningRule<List>('absorbent_surface_ids') ?? []).contains((surface['id'] as num).toInt()) && (primerType['id'] as num).toInt() == 1) {
    warnings.add('Бетон-контакт применяют в основном по гладким невпитывающим основаниям');
  }
  if ((spec.warningRule<List>('recommended_double_coat_surface_ids') ?? []).contains((surface['id'] as num).toInt()) && coats == 1) {
    warnings.add('Для впитывающих оснований обычно рекомендуют 2 слоя грунтовки');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: '${primerType['label'] as String} (${canSize.toInt()} л)',
        quantity: recScenario.exactNeed,
        unit: 'л',
        withReserve: recScenario.purchaseQuantity,
        purchaseQty: (recScenario.buyPlan.packagesCount * canSize).toDouble(),
        category: 'Основное',
        packageInfo: {'count': recScenario.buyPlan.packagesCount, 'unitSize': canSize, 'packageUnit': 'канистр'},
      ),
      CanonicalMaterialResult(
        name: 'Валик малярный 250 мм',
        quantity: (workArea / spec.materialRule<num>('roller_area_m2_per_piece').toDouble()).ceilToDouble(),
        unit: 'шт',
        withReserve: (workArea / spec.materialRule<num>('roller_area_m2_per_piece').toDouble()).ceilToDouble(),
        purchaseQty: (workArea / spec.materialRule<num>('roller_area_m2_per_piece').toDouble()).ceil().toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кисть для углов и примыканий',
        quantity: spec.materialRule<num>('brushes_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('brushes_count').toDouble(),
        purchaseQty: spec.materialRule<num>('brushes_count').toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Кювета для грунтовки',
        quantity: spec.materialRule<num>('trays_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('trays_count').toDouble(),
        purchaseQty: spec.materialRule<num>('trays_count').toDouble(),
        category: 'Инструмент',
      ),
    ],
    totals: {
      'area': roundValue(workArea, 3),
      'inputMode': (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 1)).round().toDouble(),
      'surfaceType': (surface['id'] as num).toInt().toDouble(),
      'primerType': (primerType['id'] as num).toInt().toDouble(),
      'coats': coats.toDouble(),
      'canSize': canSize,
      'lPerSqm': roundValue(lPerSqm, 4),
      'minExactNeedL': scenarios['MIN']!.exactNeed,
      'recExactNeedL': recScenario.exactNeed,
      'maxExactNeedL': scenarios['MAX']!.exactNeed,
      'minPurchaseL': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseL': recScenario.purchaseQuantity,
      'maxPurchaseL': scenarios['MAX']!.purchaseQuantity,
      'dryingTimeHours': (spec.materialRule<Map>('drying_time_hours_by_type')['${(primerType['id'] as num).toInt()}'] as num?)?.toDouble() ?? 4,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
