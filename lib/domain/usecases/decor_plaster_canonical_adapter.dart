import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

/* ─── spec types ─── */


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const Map<int, String> _textureLabels = {
  0: 'Короед 2 мм',
  1: 'Короед 3 мм',
  2: 'Камешковая',
  3: 'Шуба',
  4: 'Венецианская',
};


bool hasCanonicalDecorPlasterInputs(Map<String, double> inputs) {
  return inputs.containsKey('texture') ||
      inputs.containsKey('area') ||
      inputs.containsKey('surface');
}

Map<String, double> normalizeLegacyDecorPlasterInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 50).toDouble();
  normalized['texture'] = (inputs['texture'] ?? 0).toDouble();
  normalized['surface'] = (inputs['surface'] ?? 0).toDouble();
  normalized['bagWeight'] = (inputs['bagWeight'] ?? 25).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalDecorPlaster(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(decorPlasterSpecData);

  final normalized = hasCanonicalDecorPlasterInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyDecorPlasterInputs(inputs);

  final area = (normalized['area'] ?? defaultFor(spec, 'area', 50)).round().clamp(1, 1000);
  final texture = (normalized['texture'] ?? defaultFor(spec, 'texture', 0)).round().clamp(0, 4);
  final surface = (normalized['surface'] ?? defaultFor(spec, 'surface', 0)).round().clamp(0, 1);
  final bagWeightRaw = (normalized['bagWeight'] ?? defaultFor(spec, 'bagWeight', 25)).round();
  final bagWeight = bagWeightRaw == 15 ? 15 : 25;

  // Consumption
  final consumption = (spec.materialRule<Map>('consumption_kg_per_m2')['$texture'] as num?)?.toDouble() ?? 2.5;

  // Formulas
  final totalKg = area * consumption * spec.materialRule<num>('plaster_reserve').toDouble();
  final bags = (totalKg / bagWeight).ceil();
  final primerCans = (area * spec.materialRule<num>('primer_deep_l_per_m2').toDouble() * spec.materialRule<num>('primer_deep_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();
  final tintedPrimer = (area * spec.materialRule<num>('tinted_primer_l_per_m2').toDouble() / spec.materialRule<num>('tinted_can').toDouble()).ceil();
  final pigmentBanks = (totalKg / 25).ceil();
  final waxCans = texture == spec.warningRule<num>('venetian_facade_texture_id').toDouble() ? (area * spec.materialRule<num>('wax_l_per_m2').toDouble() / spec.materialRule<num>('wax_can').toDouble()).ceil() : 0;

  // Scenarios
  final packageLabel = 'decor-plaster-bag-${bagWeight}kg';
  const packageUnit = 'мешков';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(bags * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'texture:$texture',
        'surface:$surface',
        'bagWeight:$bagWeight',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку');
  }
  if (texture == spec.warningRule<num>('venetian_facade_texture_id').toDouble() && surface == 0) {
    warnings.add('Венецианская штукатурка на фасаде — требуется защитный лак');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_textureLabels[texture]} (мешки $bagWeight кг)',
      quantity: recScenario.exactNeed,
      unit: 'мешков',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Штукатурка',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка глубокого проникновения (${spec.materialRule<num>('primer_can').toDouble().round()} л)',
      quantity: primerCans.toDouble(),
      unit: 'канистр',
      withReserve: primerCans.toDouble(),
      purchaseQty: primerCans.toDouble(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Тонированная грунтовка (${spec.materialRule<num>('tinted_can').toDouble().round()} л)',
      quantity: tintedPrimer.toDouble(),
      unit: 'канистр',
      withReserve: tintedPrimer.toDouble(),
      purchaseQty: tintedPrimer.toDouble(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Пигмент / колер (банки)',
      quantity: pigmentBanks.toDouble(),
      unit: 'шт',
      withReserve: pigmentBanks.toDouble(),
      purchaseQty: pigmentBanks.toDouble(),
      category: 'Отделка',
    ),
  ];

  if (waxCans > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Воск для венецианской штукатурки (${spec.materialRule<num>('wax_can').toDouble().round()} л)',
      quantity: waxCans.toDouble(),
      unit: 'банок',
      withReserve: waxCans.toDouble(),
      purchaseQty: waxCans.toDouble(),
      category: 'Отделка',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area.toDouble(),
      'texture': texture.toDouble(),
      'surface': surface.toDouble(),
      'bagWeight': bagWeight.toDouble(),
      'consumption': consumption,
      'totalKg': roundValue(totalKg, 4),
      'bags': bags.toDouble(),
      'primerCans': primerCans.toDouble(),
      'tintedPrimer': tintedPrimer.toDouble(),
      'pigmentBanks': pigmentBanks.toDouble(),
      'waxCans': waxCans.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': recScenario.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': recScenario.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
