import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';


const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};


CanonicalCalculatorContractResult calculateCanonicalWoodWall(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(woodWallSpecData);

  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round().clamp(0, 1);
  final areaInput = (inputs['area'] ?? defaultFor(spec, 'area', 15)).clamp(1.0, 500.0);
  final length = (inputs['length'] ?? defaultFor(spec, 'length', 4)).clamp(1.0, 30.0);
  final height = (inputs['height'] ?? defaultFor(spec, 'height', 2.5)).clamp(2.0, 4.0);
  final boardWidth = (inputs['boardWidth'] ?? defaultFor(spec, 'boardWidth', 10)).clamp(5.0, 20.0);
  final boardLength = (inputs['boardLength'] ?? defaultFor(spec, 'boardLength', 3)).clamp(2.0, 6.0);

  // Area
  final area = inputMode == 1 ? roundValue(length * height, 3) : areaInput;

  // Boards
  final boardArea = (boardWidth / 100) * boardLength;
  final boards = (area / boardArea * spec.materialRule<num>('board_reserve').toDouble()).ceil();

  // Perimeter
  final perimeter = inputMode == 1 ? 2 * (length + length) : 4 * math.sqrt(area);

  // Battens
  final battensCount = ((perimeter / 4) / spec.materialRule<num>('batten_step').toDouble()).ceil();
  final battensLen = battensCount * height;

  // Plinth & corners
  final plinth = perimeter * spec.materialRule<num>('plinth_reserve').toDouble();
  final corners = perimeter * spec.materialRule<num>('corner_ratio').toDouble() * spec.materialRule<num>('corner_reserve').toDouble();
  final ceilingPlinth = perimeter * spec.materialRule<num>('plinth_reserve').toDouble();

  // Coatings
  final antisepticL = area * spec.materialRule<num>('antiseptic_l_per_m2').toDouble();
  final finishL = area * spec.materialRule<num>('finish_l_per_m2').toDouble() * spec.materialRule<num>('finish_layers').toDouble();
  final primerL = area * spec.materialRule<num>('primer_l_per_m2').toDouble();

  // Fasteners
  final fastenersPcs = boards * spec.materialRule<num>('fasteners_per_board').toDouble();
  final fastenersKg = (fastenersPcs / 600 * 10).ceil() / 10; // 3.5×35 мм: 600 шт/кг
  final clamps = boards * spec.materialRule<num>('clamps_per_board').toDouble();

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(boards * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'inputMode:$inputMode',
        'boardWidth:$boardWidth',
        'boardLength:$boardLength',
        'packaging:wood-board',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
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
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь — дайте вагонке акклиматизироваться минимум 48 часов');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Доски (вагонка)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Облицовка',
    ),
    CanonicalMaterialResult(
      name: 'Обрешётка (п.м.)',
      quantity: roundValue(battensLen, 2),
      unit: 'п.м.',
      withReserve: battensLen.ceilToDouble(),
      purchaseQty: battensLen.ceil().toDouble(),
      category: 'Подсистема',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус напольный (п.м.)',
      quantity: roundValue(plinth, 2),
      unit: 'п.м.',
      withReserve: plinth.ceilToDouble(),
      purchaseQty: plinth.ceil().toDouble(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Уголки (п.м.)',
      quantity: roundValue(corners, 2),
      unit: 'п.м.',
      withReserve: corners.ceilToDouble(),
      purchaseQty: corners.ceil().toDouble(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Плинтус потолочный (п.м.)',
      quantity: roundValue(ceilingPlinth, 2),
      unit: 'п.м.',
      withReserve: ceilingPlinth.ceilToDouble(),
      purchaseQty: ceilingPlinth.ceil().toDouble(),
      category: 'Профиль',
    ),
    CanonicalMaterialResult(
      name: 'Антисептик (л)',
      quantity: roundValue(antisepticL, 2),
      unit: 'л',
      withReserve: antisepticL.ceilToDouble(),
      purchaseQty: antisepticL.ceil().toDouble(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Лак / финиш (л)',
      quantity: roundValue(finishL, 2),
      unit: 'л',
      withReserve: finishL.ceilToDouble(),
      purchaseQty: finishL.ceil().toDouble(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Грунтовка (л)',
      quantity: roundValue(primerL, 2),
      unit: 'л',
      withReserve: primerL.ceilToDouble(),
      purchaseQty: primerL.ceil().toDouble(),
      category: 'Покрытие',
    ),
    CanonicalMaterialResult(
      name: 'Крепёж (саморезы/гвозди)',
      quantity: fastenersKg,
      unit: 'кг',
      withReserve: fastenersKg,
      purchaseQty: fastenersKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры',
      quantity: clamps.toDouble(),
      unit: 'шт',
      withReserve: clamps.toDouble(),
      purchaseQty: clamps.toDouble(),
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
      'boardArea': roundValue(boardArea, 4),
      'boards': boards.toDouble(),
      'perimeter': roundValue(perimeter, 3),
      'battensCount': battensCount.toDouble(),
      'battensLen': roundValue(battensLen, 3),
      'plinth': roundValue(plinth, 3),
      'corners': roundValue(corners, 3),
      'ceilingPlinth': roundValue(ceilingPlinth, 3),
      'antisepticL': roundValue(antisepticL, 3),
      'finishL': roundValue(finishL, 3),
      'primerL': roundValue(primerL, 3),
      'fasteners': fastenersKg,
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
