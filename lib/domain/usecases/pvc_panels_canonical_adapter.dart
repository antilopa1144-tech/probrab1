import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};


CanonicalCalculatorContractResult calculateCanonicalPvcPanels(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(pvcPanelsSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final wallWidth = (inputs['wallWidth'] ?? defaultFor(spec, 'wallWidth', 3)).clamp(0.5, 30.0);
  final wallHeight = (inputs['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.5)).clamp(0.5, 10.0);
  final panelWidth = (inputs['panelWidth'] ?? defaultFor(spec, 'panelWidth', 0.25)).clamp(0.1, 0.5);
  final panelType = (inputs['panelType'] ?? defaultFor(spec, 'panelType', 0)).round().clamp(0, 2);
  final needProfile = (inputs['needProfile'] ?? defaultFor(spec, 'needProfile', 1)).round() == 1 ? 1 : 0;
  final needCorners = (inputs['needCorners'] ?? defaultFor(spec, 'needCorners', 1)).round() == 1 ? 1 : 0;

  // Area
  final area = inputMode == 1 ? roundValue(wallWidth * wallHeight, 3) : areaInput;

  // Panels
  final panelLengthsMap = spec.materialRule<Map>('panel_lengths');
  final panelLength = (panelLengthsMap['$panelType'] as num?)?.toDouble() ?? (panelLengthsMap['0'] as num?)?.toDouble() ?? 2.7;
  final panelArea = panelWidth * panelLength;
  final panels = (area * spec.materialRule<num>('panel_reserve').toDouble() / panelArea).ceil();

  // Profile (conditional)
  final profileRows = needProfile == 1 ? (wallHeight / spec.materialRule<num>('profile_step').toDouble()).ceil() + 1 : 0;
  final profileLen = profileRows * wallWidth * spec.materialRule<num>('profile_reserve').toDouble();

  // Corner profile (conditional)
  final cornerPcs = needCorners == 1
      ? (wallHeight * spec.materialRule<num>('standard_corners').toDouble() / spec.materialRule<num>('corner_profile_length').toDouble()).ceil()
      : 0;

  // Start profile
  final startProfile = wallWidth * 1.05;

  // Plinth
  final plinthLen = wallWidth * 2;

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
        'needCorners:$needCorners',
        'packaging:pvc-panel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'pvc-panel',
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
  if (panelType == 2) {
    warnings.add('Для ванной комнаты используйте влагостойкие ПВХ-панели');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'ПВХ-панели',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Облицовка',
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

  if (needCorners == 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Угловой профиль',
      quantity: cornerPcs.toDouble(),
      unit: 'шт',
      withReserve: cornerPcs.toDouble(),
      purchaseQty: cornerPcs.toDouble(),
      category: 'Профиль',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Стартовый профиль (п.м.)',
      quantity: roundValue(startProfile, 2),
      unit: 'п.м.',
      withReserve: startProfile.ceilToDouble(),
      purchaseQty: startProfile.ceil().toDouble(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус (п.м.)',
      quantity: roundValue(plinthLen, 2),
      unit: 'п.м.',
      withReserve: plinthLen.ceilToDouble(),
      purchaseQty: plinthLen.ceil().toDouble(),
      category: 'Профиль',
    ),
  ]);

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
      'needCorners': needCorners.toDouble(),
      'panelLength': panelLength,
      'panelArea': roundValue(panelArea, 4),
      'panels': panels.toDouble(),
      'profileRows': profileRows.toDouble(),
      'profileLen': roundValue(profileLen, 3),
      'cornerPcs': cornerPcs.toDouble(),
      'startProfile': roundValue(startProfile, 3),
      'plinthLen': roundValue(plinthLen, 3),
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
