import 'dart:math' as math;

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

const Map<int, String> _panelTypeLabels = {
  0: 'Фиброцементные панели (3.6 м\u00b2)',
  1: 'Металлокассеты (0.72 м\u00b2)',
  2: 'HPL-панели (2.928 м\u00b2)',
  3: 'Металлический сайдинг (0.23 м\u00b2)',
};

const Map<int, String> _substructureLabels = {
  0: 'Алюминиевая',
  1: 'Оцинкованная',
  2: 'Деревянная',
};


bool hasCanonicalFacadePanelsInputs(Map<String, double> inputs) {
  return inputs.containsKey('panelType') ||
      inputs.containsKey('area') ||
      inputs.containsKey('substructure');
}

Map<String, double> normalizeLegacyFacadePanelsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 100).toDouble();
  normalized['panelType'] = (inputs['panelType'] ?? 0).toDouble();
  normalized['substructure'] = (inputs['substructure'] ?? 0).toDouble();
  normalized['insulationThickness'] = (inputs['insulationThickness'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalFacadePanels(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(facadePanelsSpecData);

  final normalized = hasCanonicalFacadePanelsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFacadePanelsInputs(inputs);

  final area = (normalized['area'] ?? defaultFor(spec, 'area', 100)).round().clamp(10, 2000);
  final panelType = (normalized['panelType'] ?? defaultFor(spec, 'panelType', 0)).round().clamp(0, 3);
  final substructure = (normalized['substructure'] ?? defaultFor(spec, 'substructure', 0)).round().clamp(0, 2);
  final insulationThickness = (normalized['insulationThickness'] ?? defaultFor(spec, 'insulationThickness', 0)).round().clamp(0, 100);

  // Panel area
  final panelArea = (spec.materialRule<Map>('panel_areas')['$panelType'] as num?)?.toDouble() ?? 3.6;

  // Formulas
  final panels = (area * spec.materialRule<num>('panel_reserve').toDouble() / panelArea).ceil();
  final brackets = (area / spec.materialRule<num>('bracket_spacing_m2').toDouble() * spec.materialRule<num>('bracket_reserve').toDouble()).ceil();
  final guides = (area / spec.materialRule<num>('guide_spacing').toDouble() * spec.materialRule<num>('guide_reserve').toDouble() / spec.materialRule<num>('guide_length').toDouble()).ceil();
  final fasteners = (panels * spec.materialRule<num>('fasteners_per_panel').toDouble() * spec.materialRule<num>('fastener_reserve').toDouble()).ceil();
  final anchors = (brackets * spec.materialRule<num>('anchor_per_bracket').toDouble() * spec.materialRule<num>('anchor_reserve').toDouble()).ceil();
  final insPlates = insulationThickness > 0 ? (area * spec.materialRule<num>('insulation_reserve').toDouble() / spec.materialRule<num>('insulation_plate').toDouble()).ceil() : 0;
  final insDowels = insPlates > 0 ? (area * spec.materialRule<num>('insulation_dowels_per_m2').toDouble() * spec.materialRule<num>('insulation_reserve').toDouble()).ceil() : 0;
  final membrane = insPlates > 0 ? (area * spec.materialRule<num>('membrane_reserve').toDouble() / spec.materialRule<num>('wind_membrane_roll').toDouble()).ceil() : 0;
  final primer = (area * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();
  final sealant = (math.sqrt(area) * 4 / spec.materialRule<num>('sealant_per_perim').toDouble()).ceil();

  // Scenarios
  const packageLabel = 'facade-panel';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(panels * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'panelType:$panelType',
        'substructure:$substructure',
        'insulationThickness:$insulationThickness',
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
    warnings.add('Большая площадь фасада — рассмотрите оптовую закупку');
  }
  if (insulationThickness >= spec.warningRule<num>('thick_insulation_threshold_mm').toDouble()) {
    warnings.add('Толстый утеплитель — проверьте длину кронштейнов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_panelTypeLabels[panelType]}',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Кронштейны (${_substructureLabels[substructure]})',
      quantity: brackets.toDouble(),
      unit: 'шт',
      withReserve: brackets.toDouble(),
      purchaseQty: brackets.toInt(),
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Направляющие (${spec.materialRule<num>('guide_length').toDouble().round()} м)',
      quantity: guides.toDouble(),
      unit: 'шт',
      withReserve: guides.toDouble(),
      purchaseQty: guides.toInt(),
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Крепёж панелей',
      quantity: fasteners.toDouble(),
      unit: 'шт',
      withReserve: fasteners.toDouble(),
      purchaseQty: fasteners.toInt(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Анкеры для кронштейнов',
      quantity: anchors.toDouble(),
      unit: 'шт',
      withReserve: anchors.toDouble(),
      purchaseQty: anchors.toInt(),
      category: 'Крепёж',
    ),
  ];

  if (insPlates > 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Утеплитель (плиты)',
        quantity: insPlates.toDouble(),
        unit: 'шт',
        withReserve: insPlates.toDouble(),
        purchaseQty: insPlates.toInt(),
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name: 'Дюбели для утеплителя',
        quantity: insDowels.toDouble(),
        unit: 'шт',
        withReserve: insDowels.toDouble(),
        purchaseQty: insDowels.toInt(),
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Ветрозащитная мембрана (${spec.materialRule<num>('wind_membrane_roll').toDouble().round()} м\u00b2)',
        quantity: membrane.toDouble(),
        unit: 'рулонов',
        withReserve: membrane.toDouble(),
        purchaseQty: membrane.toInt(),
        category: 'Утепление',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRule<num>('primer_can').toDouble().round()} л)',
      quantity: primer.toDouble(),
      unit: 'канистр',
      withReserve: primer.toDouble(),
      purchaseQty: primer.toInt(),
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealant.toDouble(),
      unit: 'шт',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant.toInt(),
      category: 'Монтаж',
    ),
  ]);

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area.toDouble(),
      'panelType': panelType.toDouble(),
      'substructure': substructure.toDouble(),
      'insulationThickness': insulationThickness.toDouble(),
      'panelArea': panelArea,
      'panels': panels.toDouble(),
      'brackets': brackets.toDouble(),
      'guides': guides.toDouble(),
      'fasteners': fasteners.toDouble(),
      'anchors': anchors.toDouble(),
      'insPlates': insPlates.toDouble(),
      'insDowels': insDowels.toDouble(),
      'membrane': membrane.toDouble(),
      'primer': primer.toDouble(),
      'sealant': sealant.toDouble(),
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
