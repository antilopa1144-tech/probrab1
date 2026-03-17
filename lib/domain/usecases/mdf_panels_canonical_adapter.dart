import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};


CanonicalCalculatorContractResult calculateCanonicalMdfPanels(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(mdfPanelsSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 20)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 4)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).clamp(0.5, 10.0);
  final panelWidth = (inputs['panelWidth'] ?? defaultFor(spec, 'panelWidth', 0.25)).clamp(0.1, 0.4);
  final panelType = (inputs['panelType'] ?? defaultFor(spec, 'panelType', 0)).round().clamp(0, 2);
  final needProfile = (inputs['needProfile'] ?? defaultFor(spec, 'needProfile', 1)).round() == 1 ? 1 : 0;
  final needPlinth = (inputs['needPlinth'] ?? defaultFor(spec, 'needPlinth', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? roundValue(wallWidth * wallHeight, 3) : areaInput;

  // Panels
  final panelArea = panelWidth * spec.materialRule<num>('standard_panel_length').toDouble();
  final panels = (area * spec.materialRule<num>('panel_reserve').toDouble() / panelArea).ceil();

  // Clips
  final clips = panels * spec.materialRule<num>('clips_per_panel').toDouble();

  // Profile (conditional)
  final profileRows = needProfile == 1 ? (wallHeight / spec.materialRule<num>('profile_step').toDouble()).ceil() + 1 : 0;
  final profileLen = profileRows * wallWidth * spec.materialRule<num>('profile_reserve').toDouble();

  // Plinth (conditional)
  final plinthLen = needPlinth == 1 ? wallWidth * 2 + spec.materialRule<num>('plinth_extra').toDouble() : 0.0;
  final plinthPcs = (plinthLen / spec.materialRule<num>('plinth_length').toDouble()).ceil();

  // Scenarios
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
        'inputMode:$inputMode',
        'panelType:$panelType',
        'needProfile:$needProfile',
        'needPlinth:$needPlinth',
        'packaging:mdf-panel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'mdf-panel',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — рассмотрите оптовую закупку панелей');
  }
  if (panelType == 0) {
    warnings.add('Стандартные МДФ-панели не рекомендуются для влажных помещений');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'МДФ-панели',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры (клипсы)',
      quantity: clips.toDouble(),
      unit: 'шт',
      withReserve: clips.toDouble(),
      purchaseQty: clips.toDouble(),
      category: 'Крепёж',
    ),
  ];

  if (needProfile == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Профиль обрешётки (п.м.)',
      quantity: roundValue(profileLen, 2),
      unit: 'п.м.',
      withReserve: profileLen.ceilToDouble(),
      purchaseQty: profileLen.ceil().toDouble(),
      category: 'Подсистема',
    ));
  }

  if (needPlinth == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Плинтус',
      quantity: plinthPcs.toDouble(),
      unit: 'шт',
      withReserve: plinthPcs.toDouble(),
      purchaseQty: plinthPcs.toDouble(),
      category: 'Профиль',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'wallWidth': roundValue(wallWidth, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'panelWidth': roundValue(panelWidth, 3),
      'panelType': panelType.toDouble(),
      'needProfile': needProfile.toDouble(),
      'needPlinth': needPlinth.toDouble(),
      'panelArea': roundValue(panelArea, 4),
      'panels': panels.toDouble(),
      'clips': clips.toDouble(),
      'profileRows': profileRows.toDouble(),
      'profileLen': roundValue(profileLen, 3),
      'plinthLen': roundValue(plinthLen, 3),
      'plinthPcs': plinthPcs.toDouble(),
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
