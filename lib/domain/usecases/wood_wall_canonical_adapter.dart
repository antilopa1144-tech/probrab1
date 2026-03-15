import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec instance ─── */

const WoodWallCanonicalSpec woodWallCanonicalSpecV1 = WoodWallCanonicalSpec(
  calculatorId: 'wood-wall',
  formulaVersion: 'wood-wall-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 15, min: 1, max: 500),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 4, min: 1, max: 30),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.5, min: 2, max: 4),
    CanonicalInputField(key: 'boardWidth', unit: 'cm', defaultValue: 10, min: 5, max: 20),
    CanonicalInputField(key: 'boardLength', unit: 'm', defaultValue: 3, min: 2, max: 6),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: WoodWallPackagingRules(unit: 'шт', packageSize: 1),
  materialRules: WoodWallMaterialRules(
    boardReserve: 1.10,
    antisepticLPerM2: 0.3,
    finishLPerM2: 0.1,
    finishLayers: 2,
    primerLPerM2: 0.1,
    fastenersPerBoard: 9,
    clampsPerBoard: 5,
    battenStep: 0.55,
    plinthReserve: 1.03,
    cornerRatio: 0.25,
    cornerReserve: 1.05,
  ),
  warningRules: WoodWallWarningRules(largeAreaThresholdM2: 50),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

/* ─── helpers ─── */

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WoodWallCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(WoodWallCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WoodWallCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalWoodWall(
  Map<String, double> inputs, {
  WoodWallCanonicalSpec spec = woodWallCanonicalSpecV1,
}) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? _defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final length = (inputs['length'] ?? _defaultFor(spec, 'length', 4)).clamp(1.0, 30.0);
  final height = (inputs['height'] ?? _defaultFor(spec, 'height', 2.5)).clamp(2.0, 4.0);
  final boardWidth = (inputs['boardWidth'] ?? _defaultFor(spec, 'boardWidth', 10)).clamp(5.0, 20.0);
  final boardLength = (inputs['boardLength'] ?? _defaultFor(spec, 'boardLength', 3)).clamp(2.0, 6.0);

  // Area
  final area = inputMode == 1 ? _roundValue(length * height, 3) : areaInput;

  // Boards
  final boardArea = (boardWidth / 100) * boardLength;
  final boards = (area / boardArea * spec.materialRules.boardReserve).ceil();

  // Perimeter
  final perimeter = inputMode == 1 ? 2 * (length + length) : 4 * math.sqrt(area);

  // Battens
  final battensCount = ((perimeter / 4) / spec.materialRules.battenStep).ceil();
  final battensLen = battensCount * height;

  // Plinth & corners
  final plinth = perimeter * spec.materialRules.plinthReserve;
  final corners = perimeter * spec.materialRules.cornerRatio * spec.materialRules.cornerReserve;
  final ceilingPlinth = perimeter * spec.materialRules.plinthReserve;

  // Coatings
  final antisepticL = area * spec.materialRules.antisepticLPerM2;
  final finishL = area * spec.materialRules.finishLPerM2 * spec.materialRules.finishLayers;
  final primerL = area * spec.materialRules.primerLPerM2;

  // Fasteners
  final fasteners = boards * spec.materialRules.fastenersPerBoard;
  final clamps = boards * spec.materialRules.clampsPerBoard;

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(boards * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'boardWidth:$boardWidth',
        'boardLength:$boardLength',
        'packaging:wood-board',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'wood-board',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (area > spec.warningRules.largeAreaThresholdM2) {
    warnings.add('Большая площадь — дайте вагонке акклиматизироваться минимум 48 часов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Доски (вагонка)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Обрешётка (п.м.)',
      quantity: _roundValue(battensLen, 2),
      unit: 'п.м.',
      withReserve: battensLen.ceilToDouble(),
      purchaseQty: battensLen.ceil(),
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус напольный (п.м.)',
      quantity: _roundValue(plinth, 2),
      unit: 'п.м.',
      withReserve: plinth.ceilToDouble(),
      purchaseQty: plinth.ceil(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Уголки (п.м.)',
      quantity: _roundValue(corners, 2),
      unit: 'п.м.',
      withReserve: corners.ceilToDouble(),
      purchaseQty: corners.ceil(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус потолочный (п.м.)',
      quantity: _roundValue(ceilingPlinth, 2),
      unit: 'п.м.',
      withReserve: ceilingPlinth.ceilToDouble(),
      purchaseQty: ceilingPlinth.ceil(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Антисептик (л)',
      quantity: _roundValue(antisepticL, 2),
      unit: 'л',
      withReserve: antisepticL.ceilToDouble(),
      purchaseQty: antisepticL.ceil(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Лак / финиш (л)',
      quantity: _roundValue(finishL, 2),
      unit: 'л',
      withReserve: finishL.ceilToDouble(),
      purchaseQty: finishL.ceil(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (л)',
      quantity: _roundValue(primerL, 2),
      unit: 'л',
      withReserve: primerL.ceilToDouble(),
      purchaseQty: primerL.ceil(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Крепёж (саморезы/гвозди)',
      quantity: fasteners.toDouble(),
      unit: 'шт',
      withReserve: fasteners.toDouble(),
      purchaseQty: fasteners,
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры',
      quantity: clamps.toDouble(),
      unit: 'шт',
      withReserve: clamps.toDouble(),
      purchaseQty: clamps,
      category: 'Крепёж',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'area': area,
      'inputMode': inputMode.toDouble(),
      'boardWidth': boardWidth,
      'boardLength': boardLength,
      'boardArea': _roundValue(boardArea, 4),
      'boards': boards.toDouble(),
      'perimeter': _roundValue(perimeter, 3),
      'battensCount': battensCount.toDouble(),
      'battensLen': _roundValue(battensLen, 3),
      'plinth': _roundValue(plinth, 3),
      'corners': _roundValue(corners, 3),
      'ceilingPlinth': _roundValue(ceilingPlinth, 3),
      'antisepticL': _roundValue(antisepticL, 3),
      'finishL': _roundValue(finishL, 3),
      'primerL': _roundValue(primerL, 3),
      'fasteners': fasteners.toDouble(),
      'clamps': clamps.toDouble(),
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
