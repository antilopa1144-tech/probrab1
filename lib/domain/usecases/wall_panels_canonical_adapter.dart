import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */



const Map<int, String> _panelTypeLabels = {
  0: 'ПВХ-панели (0.75 м\u00b2)',
  1: 'МДФ-панели (0.494 м\u00b2)',
  2: '3D-панели (0.25 м\u00b2)',
  3: 'Деревянные панели (0.3 м\u00b2)',
  4: 'Каменный шпон (0.5 м\u00b2)',
};


bool hasCanonicalWallPanelsInputs(Map<String, double> inputs) {
  return inputs.containsKey('panelType') ||
      inputs.containsKey('area') ||
      inputs.containsKey('mountMethod');
}

Map<String, double> normalizeLegacyWallPanelsInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['area'] = (inputs['area'] ?? 20).toDouble();
  normalized['panelType'] = (inputs['panelType'] ?? 0).toDouble();
  normalized['mountMethod'] = (inputs['mountMethod'] ?? 0).toDouble();
  normalized['height'] = (inputs['height'] ?? 2.7).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalWallPanels(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(wallPanelsSpecData);

  final normalized = hasCanonicalWallPanelsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyWallPanelsInputs(inputs);

  final area = (normalized['area'] ?? defaultFor(spec, 'area', 20)).round().clamp(1, 200);
  final panelType = (normalized['panelType'] ?? defaultFor(spec, 'panelType', 0)).round().clamp(0, 4);
  final mountMethod = (normalized['mountMethod'] ?? defaultFor(spec, 'mountMethod', 0)).round().clamp(0, 1);
  final height = (normalized['height'] ?? defaultFor(spec, 'height', 2.7)).clamp(2.0, 4.0);

  // Panel area
  final panelArea = (spec.materialRule<Map>('panel_areas')['$panelType'] as num?)?.toDouble() ?? 0.75;
  final battenSpacing = (spec.materialRule<Map>('batten_spacing')['$panelType'] as num?)?.toDouble() ?? 0.5;

  // Common formulas
  final panels = (area * spec.materialRule<num>('panel_reserve').toDouble() / panelArea).ceil();
  final perim = math.sqrt(area) * 4;

  // Mount-specific
  var glueBottles = 0;
  var primer = 0;
  var battenRows = 0;
  double wallLength = 0;
  double battenM = 0;
  var battenPcs = 0;
  var dubels = 0;
  var klaimers = 0;

  if (mountMethod == 0) {
    // Glue
    glueBottles = (area / spec.materialRule<num>('glue_coverage').toDouble()).ceil();
    primer = (area * spec.materialRule<num>('primer_l_per_m2').toDouble() * spec.materialRule<num>('primer_reserve').toDouble() / spec.materialRule<num>('primer_can').toDouble()).ceil();
  } else {
    // Batten frame
    battenRows = (height / battenSpacing).ceil() + 1;
    wallLength = area / height;
    battenM = battenRows * wallLength * spec.materialRule<num>('batten_reserve').toDouble();
    battenPcs = (battenM / spec.materialRule<num>('batten_length').toDouble()).ceil();
    dubels = (battenM / spec.materialRule<num>('dubel_step').toDouble()).ceil();
    klaimers = (area * spec.materialRule<num>('klaymer_per_m2').toDouble()).ceil();
  }

  // All methods
  final molding = (perim * spec.materialRule<num>('molding_reserve').toDouble() / spec.materialRule<num>('molding_length').toDouble()).ceil();
  final sealant = (perim / spec.materialRule<num>('sealant_per_perim').toDouble()).ceil();

  // Scenarios
  const packageLabel = 'wall-panel';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(panels * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'panelType:$panelType',
        'mountMethod:$mountMethod',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
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
    warnings.add('Большая площадь — рассмотрите оптовую закупку панелей');
  }
  if ((spec.warningRule<List>('flat_surface_warning_panel_types') ?? []).contains(panelType) && mountMethod == 0) {
    warnings.add('3D-панели на клей — убедитесь в ровности основания');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_panelTypeLabels[panelType]}',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Облицовка',
    ),
  ];

  if (mountMethod == 0) {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Монтажный клей (флаконы)',
        quantity: glueBottles.toDouble(),
        unit: 'шт',
        withReserve: glueBottles.toDouble(),
        purchaseQty: glueBottles.toDouble(),
        category: 'Монтаж',
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка (канистра ${spec.materialRule<num>('primer_can').toDouble().round()} л)',
        quantity: primer.toDouble(),
        unit: 'канистр',
        withReserve: primer.toDouble(),
        purchaseQty: primer.toDouble(),
        category: 'Грунтовка',
      ),
    ]);
  } else {
    materials.addAll([
      CanonicalMaterialResult(
        name: 'Обрешётка (бруски ${spec.materialRule<num>('batten_length').toDouble().round()} м)',
        quantity: battenPcs.toDouble(),
        unit: 'шт',
        withReserve: battenPcs.toDouble(),
        purchaseQty: battenPcs.toDouble(),
        category: 'Подсистема',
      ),
      CanonicalMaterialResult(
        name: 'Дюбели для обрешётки',
        quantity: dubels.toDouble(),
        unit: 'шт',
        withReserve: dubels.toDouble(),
        purchaseQty: dubels.toDouble(),
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Кляймеры',
        quantity: klaimers.toDouble(),
        unit: 'шт',
        withReserve: klaimers.toDouble(),
        purchaseQty: klaimers.toDouble(),
        category: 'Крепёж',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Молдинги (${spec.materialRule<num>('molding_length').toDouble().round()} м)',
      quantity: molding.toDouble(),
      unit: 'шт',
      withReserve: molding.toDouble(),
      purchaseQty: molding.toDouble(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealant.toDouble(),
      unit: 'шт',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant.toDouble(),
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
      'mountMethod': mountMethod.toDouble(),
      'height': height,
      'panelArea': panelArea,
      'battenSpacing': battenSpacing,
      'panels': panels.toDouble(),
      'perim': roundValue(perim, 4),
      'glueBottles': glueBottles.toDouble(),
      'primer': primer.toDouble(),
      'battenRows': battenRows.toDouble(),
      'wallLength': roundValue(wallLength, 4),
      'battenM': roundValue(battenM, 4),
      'battenPcs': battenPcs.toDouble(),
      'dubels': dubels.toDouble(),
      'klaimers': klaimers.toDouble(),
      'molding': molding.toDouble(),
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
