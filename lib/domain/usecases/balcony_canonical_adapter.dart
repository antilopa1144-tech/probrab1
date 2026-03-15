import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

// ─── Balcony spec classes ───

class BalconyPackagingRules {
  final String unit;
  final double packageSize;

  const BalconyPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class BalconyMaterialRules {
  final Map<int, double> panelAreas;
  final double battenPitch;
  final double insulationPlate;
  final double insulationReserve;
  final double finishReserve;
  final int klaymerPerPanel;
  final double klaymerReserve;

  const BalconyMaterialRules({
    required this.panelAreas,
    required this.battenPitch,
    required this.insulationPlate,
    required this.insulationReserve,
    required this.finishReserve,
    required this.klaymerPerPanel,
    required this.klaymerReserve,
  });
}

class BalconyWarningRules {
  final double largeBalconyAreaThresholdM2;
  final int uninsulatedWarningThreshold;

  const BalconyWarningRules({
    required this.largeBalconyAreaThresholdM2,
    required this.uninsulatedWarningThreshold,
  });
}

class BalconyCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final BalconyPackagingRules packagingRules;
  final BalconyMaterialRules materialRules;
  final BalconyWarningRules warningRules;

  const BalconyCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

// ─── Spec constant ───

const BalconyCanonicalSpec balconyCanonicalSpecV1 = BalconyCanonicalSpec(
  calculatorId: 'balcony',
  formulaVersion: 'balcony-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 3, min: 1, max: 10),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 1.2, min: 0.6, max: 3),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.5, min: 2, max: 3),
    CanonicalInputField(key: 'finishType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'insulationType', defaultValue: 0, min: 0, max: 3),
  ],
  enabledFactors: [
    'geometry_complexity',
    'worker_skill',
    'waste_factor',
  ],
  packagingRules: BalconyPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: BalconyMaterialRules(
    panelAreas: {0: 0.288, 1: 0.3, 2: 0.288, 3: 0.576},
    battenPitch: 0.4,
    insulationPlate: 0.72,
    insulationReserve: 1.05,
    finishReserve: 1.1,
    klaymerPerPanel: 3,
    klaymerReserve: 1.1,
  ),
  warningRules: BalconyWarningRules(
    largeBalconyAreaThresholdM2: 15,
    uninsulatedWarningThreshold: 0,
  ),
);

// ─── Factor table ───

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 1.0, 'REC': 1.06, 'MAX': 1.15},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _finishLabels = {
  0: 'Вагонка',
  1: 'ПВХ-панели',
  2: 'Имитация бруса',
  3: 'МДФ-панели',
};

const Map<int, String> _insulationLabels = {
  0: 'Без утепления',
  1: 'ПСБ (пенопласт)',
  2: 'Пенофол',
  3: 'ПСБ + пенофол',
};

// ─── Helpers ───

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(BalconyCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(BalconyCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(BalconyCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

// ─── Main calculation ───

CanonicalCalculatorContractResult calculateCanonicalBalcony(
  Map<String, double> inputs, {
  BalconyCanonicalSpec spec = balconyCanonicalSpecV1,
}) {
  final length = (inputs['length'] ?? _defaultFor(spec, 'length', 3)).clamp(1, 10).toDouble();
  final width = (inputs['width'] ?? _defaultFor(spec, 'width', 1.2)).clamp(0.6, 3).toDouble();
  final height = (inputs['height'] ?? _defaultFor(spec, 'height', 2.5)).clamp(2, 3).toDouble();
  final finishType = (inputs['finishType'] ?? _defaultFor(spec, 'finishType', 0)).round().clamp(0, 3);
  final insulationType = (inputs['insulationType'] ?? _defaultFor(spec, 'insulationType', 0)).round().clamp(0, 3);

  final panelArea = spec.materialRules.panelAreas[finishType] ?? 0.288;
  final floorArea = _roundValue(length * width, 6);
  final wallArea = _roundValue((2 * width + 2 * length) * height, 6);
  final ceilingArea = _roundValue(length * width, 6);
  final totalFinishArea = _roundValue(wallArea + ceilingArea, 6);

  final insPlates = insulationType > 0
      ? (totalFinishArea * spec.materialRules.insulationReserve / spec.materialRules.insulationPlate).ceil()
      : 0;
  final panelCount = (totalFinishArea * spec.materialRules.finishReserve / panelArea).ceil();
  final battenRows = (totalFinishArea / spec.materialRules.battenPitch).ceil();
  final klaymerCount = (panelCount * spec.materialRules.klaymerPerPanel * spec.materialRules.klaymerReserve).ceil();

  // Scenarios
  final baseExactNeed = panelCount;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactNeed * multiplier, 6);
    final packageSize = spec.packagingRules.packageSize;
    final packageCount = exactNeed > 0 ? (exactNeed / packageSize).ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount * packageSize, 6);
    final packageLabel = 'balcony-panel-${packageSize == packageSize.roundToDouble() ? packageSize.toInt() : packageSize}';

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'finish:$finishType',
        'insulation:$insulationType',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: packageSize,
        packagesCount: packageCount,
        unit: spec.packagingRules.unit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (floorArea > spec.warningRules.largeBalconyAreaThresholdM2) {
    warnings.add('Большая площадь балкона — рекомендуется профессиональный расчёт нагрузки на плиту');
  }
  if (insulationType == spec.warningRules.uninsulatedWarningThreshold) {
    warnings.add('Без утепления — на балконе будет значительный перепад температур');
  }

  // Materials
  final finishLabel = _finishLabels[finishType] ?? 'Вагонка';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: finishLabel,
      quantity: panelCount.toDouble(),
      unit: 'шт',
      withReserve: panelCount.toDouble(),
      purchaseQty: panelCount,
      category: 'Основное',
    ),
    CanonicalMaterialResult(
      name: 'Обрешётка (брусок 20×40)',
      quantity: battenRows.toDouble(),
      unit: 'шт',
      withReserve: battenRows.toDouble(),
      purchaseQty: battenRows,
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры',
      quantity: klaymerCount.toDouble(),
      unit: 'шт',
      withReserve: klaymerCount.toDouble(),
      purchaseQty: klaymerCount,
      category: 'Крепёж',
    ),
  ];

  if (insulationType > 0) {
    final insulationLabel = _insulationLabels[insulationType] ?? 'Утеплитель';
    materials.add(CanonicalMaterialResult(
      name: insulationLabel,
      quantity: insPlates.toDouble(),
      unit: 'шт',
      withReserve: insPlates.toDouble(),
      purchaseQty: insPlates,
      category: 'Утепление',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': _roundValue(length, 3),
      'width': _roundValue(width, 3),
      'height': _roundValue(height, 3),
      'finishType': finishType.toDouble(),
      'insulationType': insulationType.toDouble(),
      'floorArea': _roundValue(floorArea, 3),
      'wallArea': _roundValue(wallArea, 3),
      'ceilingArea': _roundValue(ceilingArea, 3),
      'totalFinishArea': _roundValue(totalFinishArea, 3),
      'panelArea': _roundValue(panelArea, 6),
      'panelCount': panelCount.toDouble(),
      'insPlates': insPlates.toDouble(),
      'battenRows': battenRows.toDouble(),
      'klaymerCount': klaymerCount.toDouble(),
      'minExactNeedPanels': scenarios['MIN']!.exactNeed,
      'recExactNeedPanels': recScenario.exactNeed,
      'maxExactNeedPanels': scenarios['MAX']!.exactNeed,
      'minPurchasePanels': scenarios['MIN']!.purchaseQuantity,
      'recPurchasePanels': recScenario.purchaseQuantity,
      'maxPurchasePanels': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
