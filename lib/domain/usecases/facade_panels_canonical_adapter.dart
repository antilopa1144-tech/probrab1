import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class FacadePanelsPackagingRules {
  final String unit;
  final int packageSize;

  const FacadePanelsPackagingRules({required this.unit, required this.packageSize});
}

class FacadePanelsMaterialRules {
  final Map<int, double> panelAreas;
  final double panelReserve;
  final double bracketSpacingM2;
  final double bracketReserve;
  final double guideSpacing;
  final double guideLength;
  final double guideReserve;
  final int fastenersPerPanel;
  final double fastenerReserve;
  final int anchorPerBracket;
  final double anchorReserve;
  final double insulationPlate;
  final double insulationReserve;
  final int insulationDowelsPerM2;
  final double windMembraneRoll;
  final double membraneReserve;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final double sealantPerPerim;

  const FacadePanelsMaterialRules({
    required this.panelAreas,
    required this.panelReserve,
    required this.bracketSpacingM2,
    required this.bracketReserve,
    required this.guideSpacing,
    required this.guideLength,
    required this.guideReserve,
    required this.fastenersPerPanel,
    required this.fastenerReserve,
    required this.anchorPerBracket,
    required this.anchorReserve,
    required this.insulationPlate,
    required this.insulationReserve,
    required this.insulationDowelsPerM2,
    required this.windMembraneRoll,
    required this.membraneReserve,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.sealantPerPerim,
  });
}

class FacadePanelsWarningRules {
  final double largeAreaThresholdM2;
  final int thickInsulationThresholdMm;

  const FacadePanelsWarningRules({required this.largeAreaThresholdM2, required this.thickInsulationThresholdMm});
}

class FacadePanelsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final FacadePanelsPackagingRules packagingRules;
  final FacadePanelsMaterialRules materialRules;
  final FacadePanelsWarningRules warningRules;

  const FacadePanelsCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── spec instance ─── */

const FacadePanelsCanonicalSpec facadePanelsCanonicalSpecV1 = FacadePanelsCanonicalSpec(
  calculatorId: 'facade-panels',
  formulaVersion: 'facade-panels-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 100, min: 10, max: 2000),
    CanonicalInputField(key: 'panelType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'substructure', defaultValue: 0, min: 0, max: 2),
    CanonicalInputField(key: 'insulationThickness', unit: 'mm', defaultValue: 0, min: 0, max: 100),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: FacadePanelsPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: FacadePanelsMaterialRules(
    panelAreas: {0: 3.6, 1: 0.72, 2: 2.928, 3: 0.23},
    panelReserve: 1.10,
    bracketSpacingM2: 0.36,
    bracketReserve: 1.1,
    guideSpacing: 0.6,
    guideLength: 3,
    guideReserve: 1.1,
    fastenersPerPanel: 8,
    fastenerReserve: 1.05,
    anchorPerBracket: 2,
    anchorReserve: 1.05,
    insulationPlate: 0.72,
    insulationReserve: 1.05,
    insulationDowelsPerM2: 6,
    windMembraneRoll: 50,
    membraneReserve: 1.15,
    primerLPerM2: 0.15,
    primerReserve: 1.15,
    primerCan: 10,
    sealantPerPerim: 10,
  ),
  warningRules: FacadePanelsWarningRules(largeAreaThresholdM2: 500, thickInsulationThresholdMm: 100),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

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

/* ─── helpers ─── */

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

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(FacadePanelsCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(FacadePanelsCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(FacadePanelsCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalFacadePanels(
  Map<String, double> inputs, {
  FacadePanelsCanonicalSpec spec = facadePanelsCanonicalSpecV1,
}) {
  final normalized = hasCanonicalFacadePanelsInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFacadePanelsInputs(inputs);

  final area = (normalized['area'] ?? _defaultFor(spec, 'area', 100)).round().clamp(10, 2000);
  final panelType = (normalized['panelType'] ?? _defaultFor(spec, 'panelType', 0)).round().clamp(0, 3);
  final substructure = (normalized['substructure'] ?? _defaultFor(spec, 'substructure', 0)).round().clamp(0, 2);
  final insulationThickness = (normalized['insulationThickness'] ?? _defaultFor(spec, 'insulationThickness', 0)).round().clamp(0, 100);

  // Panel area
  final panelArea = spec.materialRules.panelAreas[panelType] ?? 3.6;

  // Formulas
  final panels = (area * spec.materialRules.panelReserve / panelArea).ceil();
  final brackets = (area / spec.materialRules.bracketSpacingM2 * spec.materialRules.bracketReserve).ceil();
  final guides = (area / spec.materialRules.guideSpacing * spec.materialRules.guideReserve / spec.materialRules.guideLength).ceil();
  final fasteners = (panels * spec.materialRules.fastenersPerPanel * spec.materialRules.fastenerReserve).ceil();
  final anchors = (brackets * spec.materialRules.anchorPerBracket * spec.materialRules.anchorReserve).ceil();
  final insPlates = insulationThickness > 0 ? (area * spec.materialRules.insulationReserve / spec.materialRules.insulationPlate).ceil() : 0;
  final insDowels = insPlates > 0 ? (area * spec.materialRules.insulationDowelsPerM2 * spec.materialRules.insulationReserve).ceil() : 0;
  final membrane = insPlates > 0 ? (area * spec.materialRules.membraneReserve / spec.materialRules.windMembraneRoll).ceil() : 0;
  final primer = (area * spec.materialRules.primerLPerM2 * spec.materialRules.primerReserve / spec.materialRules.primerCan).ceil();
  final sealant = (math.sqrt(area) * 4 / spec.materialRules.sealantPerPerim).ceil();

  // Scenarios
  const packageLabel = 'facade-panel';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(panels * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'panelType:$panelType',
        'substructure:$substructure',
        'insulationThickness:$insulationThickness',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
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
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь фасада — рассмотрите оптовую закупку');
  }
  if (insulationThickness >= spec.warningRules.thickInsulationThresholdMm) {
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
      purchaseQty: brackets,
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Направляющие (${spec.materialRules.guideLength.round()} м)',
      quantity: guides.toDouble(),
      unit: 'шт',
      withReserve: guides.toDouble(),
      purchaseQty: guides,
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Крепёж панелей',
      quantity: fasteners.toDouble(),
      unit: 'шт',
      withReserve: fasteners.toDouble(),
      purchaseQty: fasteners,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Анкеры для кронштейнов',
      quantity: anchors.toDouble(),
      unit: 'шт',
      withReserve: anchors.toDouble(),
      purchaseQty: anchors,
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
        purchaseQty: insPlates,
        category: 'Утепление',
      ),
      CanonicalMaterialResult(
        name: 'Дюбели для утеплителя',
        quantity: insDowels.toDouble(),
        unit: 'шт',
        withReserve: insDowels.toDouble(),
        purchaseQty: insDowels,
        category: 'Крепёж',
      ),
      CanonicalMaterialResult(
        name: 'Ветрозащитная мембрана (${spec.materialRules.windMembraneRoll.round()} м\u00b2)',
        quantity: membrane.toDouble(),
        unit: 'рулонов',
        withReserve: membrane.toDouble(),
        purchaseQty: membrane,
        category: 'Утепление',
      ),
    ]);
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Грунтовка (канистра ${spec.materialRules.primerCan.round()} л)',
      quantity: primer.toDouble(),
      unit: 'канистр',
      withReserve: primer.toDouble(),
      purchaseQty: primer,
      category: 'Грунтовка',
    ),
    CanonicalMaterialResult(
      name: 'Герметик (тубы)',
      quantity: sealant.toDouble(),
      unit: 'шт',
      withReserve: sealant.toDouble(),
      purchaseQty: sealant,
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
