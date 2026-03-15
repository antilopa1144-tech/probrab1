import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class TerracePackagingRules {
  final String unit;
  final int packageSize;

  const TerracePackagingRules({required this.unit, required this.packageSize});
}

class TerraceMaterialRules {
  final Map<int, int> boardWidths;
  final Map<int, int> boardGaps;
  final double lagLength;
  final double treatmentLPerM2;
  final Map<int, int> treatmentLayers;
  final double geotextileRoll;
  final double boardReserve;
  final double lagReserve;
  final int klaymerCountPerLagRow;

  const TerraceMaterialRules({
    required this.boardWidths,
    required this.boardGaps,
    required this.lagLength,
    required this.treatmentLPerM2,
    required this.treatmentLayers,
    required this.geotextileRoll,
    required this.boardReserve,
    required this.lagReserve,
    required this.klaymerCountPerLagRow,
  });
}

class TerraceWarningRules {
  final double largeAreaThresholdM2;

  const TerraceWarningRules({required this.largeAreaThresholdM2});
}

class TerraceCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final TerracePackagingRules packagingRules;
  final TerraceMaterialRules materialRules;
  final TerraceWarningRules warningRules;

  const TerraceCanonicalSpec({
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

const TerraceCanonicalSpec terraceCanonicalSpecV1 = TerraceCanonicalSpec(
  calculatorId: 'terrace',
  formulaVersion: 'terrace-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 30),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 3, min: 1, max: 15),
    CanonicalInputField(key: 'boardType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'boardLength', unit: 'mm', defaultValue: 3000, min: 2000, max: 6000),
    CanonicalInputField(key: 'lagStep', unit: 'mm', defaultValue: 400, min: 300, max: 600),
    CanonicalInputField(key: 'withTreatment', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: TerracePackagingRules(unit: 'шт', packageSize: 1),
  materialRules: TerraceMaterialRules(
    boardWidths: {0: 150, 1: 120, 2: 90, 3: 120},
    boardGaps: {0: 5, 1: 5, 2: 5, 3: 0},
    lagLength: 3,
    treatmentLPerM2: 0.15,
    treatmentLayers: {0: 0, 1: 2, 2: 2},
    geotextileRoll: 50,
    boardReserve: 1.1,
    lagReserve: 1.05,
    klaymerCountPerLagRow: 1,
  ),
  warningRules: TerraceWarningRules(largeAreaThresholdM2: 50),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

const Map<int, String> _boardTypeLabels = {
  0: 'ДПК 150 мм',
  1: 'Лиственница 120 мм',
  2: 'Сосна 90 мм',
  3: 'Планкен 120 мм',
};

const Map<int, String> _treatmentLabels = {
  0: 'Без обработки',
  1: 'Масло',
  2: 'Антисептик',
};

/* ─── helpers ─── */

bool hasCanonicalTerraceInputs(Map<String, double> inputs) {
  return inputs.containsKey('boardType') ||
      inputs.containsKey('lagStep') ||
      inputs.containsKey('boardLength');
}

Map<String, double> normalizeLegacyTerraceInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['length'] = (inputs['length'] ?? 5).toDouble();
  normalized['width'] = (inputs['width'] ?? 3).toDouble();
  normalized['boardType'] = (inputs['boardType'] ?? 0).toDouble();
  normalized['boardLength'] = (inputs['boardLength'] ?? 3000).toDouble();
  normalized['lagStep'] = (inputs['lagStep'] ?? 400).toDouble();
  normalized['withTreatment'] = (inputs['withTreatment'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(TerraceCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(TerraceCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(TerraceCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalTerrace(
  Map<String, double> inputs, {
  TerraceCanonicalSpec spec = terraceCanonicalSpecV1,
}) {
  final normalized = hasCanonicalTerraceInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyTerraceInputs(inputs);

  final length = math.max(1.0, math.min(30.0, (normalized['length'] ?? _defaultFor(spec, 'length', 5)).toDouble()));
  final width = math.max(1.0, math.min(15.0, (normalized['width'] ?? _defaultFor(spec, 'width', 3)).toDouble()));
  final boardType = (normalized['boardType'] ?? _defaultFor(spec, 'boardType', 0)).round().clamp(0, 3);
  final boardLength = math.max(2000.0, math.min(6000.0, (normalized['boardLength'] ?? _defaultFor(spec, 'boardLength', 3000)).toDouble()));
  final lagStep = math.max(300.0, math.min(600.0, (normalized['lagStep'] ?? _defaultFor(spec, 'lagStep', 400)).toDouble()));
  final withTreatment = (normalized['withTreatment'] ?? _defaultFor(spec, 'withTreatment', 0)).round().clamp(0, 2);

  // Geometry
  final area = length * width;
  final boardWidth = spec.materialRules.boardWidths[boardType] ?? 150;
  final gap = spec.materialRules.boardGaps[boardType] ?? 5;
  final boardPitch = (boardWidth + gap) / 1000.0;
  final rowCount = (width / boardPitch).ceil();
  final boardsPerRow = (length / (boardLength / 1000.0)).ceil();
  final totalBoards = (rowCount * boardsPerRow * spec.materialRules.boardReserve).ceil();

  // Lags
  final lagRowCount = (length / (lagStep / 1000.0)).ceil() + 1;
  final lagTotalLen = lagRowCount * width * spec.materialRules.lagReserve;
  final lagPcs = (lagTotalLen / spec.materialRules.lagLength).ceil();

  // Fasteners
  final klaymerCount = lagRowCount * rowCount;
  final screwCount = (lagRowCount * rowCount * (boardType == 3 ? 2.0 : 1.2)).ceil();

  // Treatment
  final treatmentLayers = spec.materialRules.treatmentLayers[withTreatment] ?? 0;
  final treatmentL = _roundValue(area * treatmentLayers * spec.materialRules.treatmentLPerM2 * 1.1, 2);

  // Geotextile
  final geotextileRolls = (area * 1.05 / spec.materialRules.geotextileRoll).ceil();

  // Scenarios
  final basePrimary = totalBoards;
  const packageLabel = 'terrace-board';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'boardType:$boardType',
        'lagStep:${lagStep.round()}',
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
  if (boardType != 0 && withTreatment == 0) {
    warnings.add('Деревянная доска без обработки подвержена гниению — рекомендуется масло или антисептик');
  }
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Для террас большой площади рекомендуется профессиональный монтаж');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_boardTypeLabels[boardType]} (${boardLength.round()} мм)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Доска',
    ),
    CanonicalMaterialResult(
      name: 'Лаги 50×50 мм (${spec.materialRules.lagLength.round()} м)',
      quantity: lagPcs.toDouble(),
      unit: 'шт',
      withReserve: lagPcs.toDouble(),
      purchaseQty: lagPcs,
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
    CanonicalMaterialResult(
      name: 'Саморезы',
      quantity: screwCount.toDouble(),
      unit: 'шт',
      withReserve: screwCount.toDouble(),
      purchaseQty: screwCount,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Геотекстиль (${spec.materialRules.geotextileRoll.round()} м²)',
      quantity: geotextileRolls.toDouble(),
      unit: 'рулонов',
      withReserve: geotextileRolls.toDouble(),
      purchaseQty: geotextileRolls,
      category: 'Подготовка',
    ),
  ];

  if (treatmentLayers > 0) {
    materials.add(CanonicalMaterialResult(
      name: '${_treatmentLabels[withTreatment]} для дерева',
      quantity: treatmentL,
      unit: 'л',
      withReserve: treatmentL,
      purchaseQty: treatmentL.ceil(),
      category: 'Защита',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': _roundValue(length, 3),
      'width': _roundValue(width, 3),
      'area': _roundValue(area, 3),
      'boardType': boardType.toDouble(),
      'boardLength': boardLength,
      'lagStep': lagStep,
      'withTreatment': withTreatment.toDouble(),
      'boardWidth': boardWidth.toDouble(),
      'gap': gap.toDouble(),
      'boardPitch': _roundValue(boardPitch, 4),
      'rowCount': rowCount.toDouble(),
      'boardsPerRow': boardsPerRow.toDouble(),
      'totalBoards': totalBoards.toDouble(),
      'lagRowCount': lagRowCount.toDouble(),
      'lagTotalLen': _roundValue(lagTotalLen, 3),
      'lagPcs': lagPcs.toDouble(),
      'klaymerCount': klaymerCount.toDouble(),
      'screwCount': screwCount.toDouble(),
      'treatmentL': treatmentL,
      'geotextileRolls': geotextileRolls.toDouble(),
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
