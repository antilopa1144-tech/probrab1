import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */



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


CanonicalCalculatorContractResult calculateCanonicalTerrace(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(terraceSpecData);

  final normalized = hasCanonicalTerraceInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyTerraceInputs(inputs);

  final length = math.max(1.0, math.min(30.0, (normalized['length'] ?? defaultFor(spec, 'length', 5)).toDouble()));
  final width = math.max(1.0, math.min(15.0, (normalized['width'] ?? defaultFor(spec, 'width', 3)).toDouble()));
  final boardType = (normalized['boardType'] ?? defaultFor(spec, 'boardType', 0)).round().clamp(0, 3);
  final boardLength = math.max(2000.0, math.min(6000.0, (normalized['boardLength'] ?? defaultFor(spec, 'boardLength', 3000)).toDouble()));
  final lagStep = math.max(300.0, math.min(600.0, (normalized['lagStep'] ?? defaultFor(spec, 'lagStep', 400)).toDouble()));
  final withTreatment = (normalized['withTreatment'] ?? defaultFor(spec, 'withTreatment', 0)).round().clamp(0, 2);

  // Geometry
  final area = length * width;
  final boardWidth = (spec.materialRule<Map>('board_widths')['$boardType'] as num?)?.toDouble() ?? 150;
  final gap = (spec.materialRule<Map>('board_gaps')['$boardType'] as num?)?.toDouble() ?? 5;
  final boardPitch = (boardWidth + gap) / 1000.0;
  final rowCount = (width / boardPitch).ceil();
  final boardsPerRow = (length / (boardLength / 1000.0)).ceil();
  final totalBoards = (rowCount * boardsPerRow * spec.materialRule<num>('board_reserve').toDouble()).ceil();

  // Lags
  final lagRowCount = (length / (lagStep / 1000.0)).ceil() + 1;
  final lagTotalLen = lagRowCount * width * spec.materialRule<num>('lag_reserve').toDouble();
  final lagPcs = (lagTotalLen / spec.materialRule<num>('lag_length').toDouble()).ceil();

  // Fasteners
  final klaymerCount = lagRowCount * rowCount;
  final screwPcs = (lagRowCount * rowCount * (boardType == 3 ? 2.0 : 1.2)).ceil();
  final screwKg = (screwPcs / 600 * 10).ceil() / 10; // 3.5×35 мм: 600 шт/кг

  // Treatment
  final treatmentLayers = (spec.materialRule<Map>('treatment_layers')['$withTreatment'] as num?)?.toDouble() ?? 0;
  final treatmentL = roundValue(area * treatmentLayers * spec.materialRule<num>('treatment_l_per_m2').toDouble() * 1.1, 2);

  // Geotextile
  final geotextileRolls = (area * 1.05 / spec.materialRule<num>('geotextile_roll').toDouble()).ceil();

  // Scenarios
  final basePrimary = totalBoards;
  const packageLabel = 'terrace-board';
  const packageUnit = 'шт';

  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'boardType:$boardType',
        'lagStep:${lagStep.round()}',
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
  if (boardType != 0 && withTreatment == 0) {
    warnings.add('Деревянная доска без обработки подвержена гниению — рекомендуется масло или антисептик');
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add('Для террас большой площади рекомендуется профессиональный монтаж');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: '${_boardTypeLabels[boardType]} (${boardLength.round()} мм)',
      quantity: recScenario.exactNeed,
      unit: 'шт',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: recScenario.exactNeed.ceil().toDouble(),
      category: 'Доска',
    ),
    CanonicalMaterialResult(
      name: 'Лаги 50×50 мм (${spec.materialRule<num>('lag_length').toDouble().round()} м)',
      quantity: lagPcs.toDouble(),
      unit: 'шт',
      withReserve: lagPcs.toDouble(),
      purchaseQty: lagPcs.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: 'Кляймеры',
      quantity: klaymerCount.toDouble(),
      unit: 'шт',
      withReserve: klaymerCount.toDouble(),
      purchaseQty: klaymerCount.toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы',
      quantity: screwKg,
      unit: 'кг',
      withReserve: screwKg,
      purchaseQty: screwKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Геотекстиль (${spec.materialRule<num>('geotextile_roll').toDouble().round()} м²)',
      quantity: geotextileRolls.toDouble(),
      unit: 'рулонов',
      withReserve: geotextileRolls.toDouble(),
      purchaseQty: geotextileRolls.toDouble(),
      category: 'Подготовка',
    ),
  ];

  if (treatmentLayers > 0) {
    materials.add(CanonicalMaterialResult(
      name: '${_treatmentLabels[withTreatment]} для дерева',
      quantity: treatmentL,
      unit: 'л',
      withReserve: treatmentL,
      purchaseQty: treatmentL.ceil().toDouble(),
      category: 'Защита',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'length': roundValue(length, 3),
      'width': roundValue(width, 3),
      'area': roundValue(area, 3),
      'boardType': boardType.toDouble(),
      'boardLength': boardLength,
      'lagStep': lagStep,
      'withTreatment': withTreatment.toDouble(),
      'boardWidth': boardWidth.toDouble(),
      'gap': gap.toDouble(),
      'boardPitch': roundValue(boardPitch, 4),
      'rowCount': rowCount.toDouble(),
      'boardsPerRow': boardsPerRow.toDouble(),
      'totalBoards': totalBoards.toDouble(),
      'lagRowCount': lagRowCount.toDouble(),
      'lagTotalLen': roundValue(lagTotalLen, 3),
      'lagPcs': lagPcs.toDouble(),
      'klaymerCount': klaymerCount.toDouble(),
      'screwCount': screwKg,
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
