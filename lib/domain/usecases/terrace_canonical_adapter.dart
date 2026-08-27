import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */

const Map<int, String> _boardTypeLabels = {
  0: 'Террасная доска из ДПК',
  1: 'Террасная доска из лиственницы',
  2: 'Террасная доска из сосны',
  3: 'Планкен для настила',
};

const Map<int, String> _treatmentLabels = {
  1: 'Масло для дерева',
  2: 'Антисептик для дерева',
};

bool hasCanonicalTerraceInputs(Map<String, double> inputs) {
  final hasCanonicalDimensions =
      inputs.containsKey('length') ||
      inputs.containsKey('width') ||
      inputs.containsKey('boardType') ||
      inputs.containsKey('lagStep') ||
      inputs.containsKey('boardLength');
  final hasLegacyOnlyInputs =
      inputs.containsKey('area') ||
      inputs.containsKey('floorType') ||
      inputs.containsKey('railing') ||
      inputs.containsKey('roof') ||
      inputs.containsKey('roofType');
  return hasCanonicalDimensions || !hasLegacyOnlyInputs;
}

Map<String, double> normalizeLegacyTerraceInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final legacyArea = math.max(1.0, inputs['area'] ?? 15.0);
  final legacySide = math.sqrt(legacyArea);
  normalized['length'] = (inputs['length'] ?? legacySide).toDouble();
  normalized['width'] = (inputs['width'] ?? legacySide).toDouble();
  normalized['boardType'] =
      (inputs['boardType'] ?? ((inputs['floorType'] ?? 1) - 1)).toDouble();
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

  final length = math.max(
    1.0,
    math.min(
      30.0,
      (normalized['length'] ?? defaultFor(spec, 'length', 5)).toDouble(),
    ),
  );
  final width = math.max(
    1.0,
    math.min(
      15.0,
      (normalized['width'] ?? defaultFor(spec, 'width', 3)).toDouble(),
    ),
  );
  final boardType =
      (normalized['boardType'] ?? defaultFor(spec, 'boardType', 0))
          .round()
          .clamp(0, 3);
  final boardLength = math.max(
    1000.0,
    math.min(
      12000.0,
      (normalized['boardLength'] ?? defaultFor(spec, 'boardLength', 3000))
          .toDouble(),
    ),
  );
  final boardWidthMm = math.max(
    70.0,
    math.min(
      300.0,
      (normalized['boardWidthMm'] ?? defaultFor(spec, 'boardWidthMm', 150))
          .toDouble(),
    ),
  );
  final gapMm = math.max(
    0.0,
    math.min(
      20.0,
      (normalized['gapMm'] ?? defaultFor(spec, 'gapMm', 5)).toDouble(),
    ),
  );
  final offcutReuseMode =
      (normalized['offcutReuseMode'] ?? defaultFor(spec, 'offcutReuseMode', 0))
          .round() ==
      1;
  final boardReservePercent = math.max(
    0.0,
    (normalized['boardReservePercent'] ??
            defaultFor(spec, 'boardReservePercent', 10))
        .toDouble(),
  );
  final lagStep = math.max(
    200.0,
    math.min(
      1000.0,
      (normalized['lagStep'] ?? defaultFor(spec, 'lagStep', 400)).toDouble(),
    ),
  );
  final lagLengthM = math.max(
    1.0,
    (normalized['lagLengthM'] ?? defaultFor(spec, 'lagLengthM', 3)).toDouble(),
  );
  final lagReservePercent = math.max(
    0.0,
    (normalized['lagReservePercent'] ??
            defaultFor(spec, 'lagReservePercent', 5))
        .toDouble(),
  );
  final clipsPerIntersection = math.max(
    0.0,
    (normalized['clipsPerIntersection'] ??
            defaultFor(spec, 'clipsPerIntersection', 1))
        .toDouble(),
  );
  final starterClipsPerRow = math.max(
    0.0,
    (normalized['starterClipsPerRow'] ??
            defaultFor(spec, 'starterClipsPerRow', 2))
        .toDouble(),
  );
  final clipPackCount = math.max(
    1,
    (normalized['clipPackCount'] ?? defaultFor(spec, 'clipPackCount', 100))
        .round(),
  );
  final fastenersPerClip = math.max(
    0.0,
    (normalized['fastenersPerClip'] ?? defaultFor(spec, 'fastenersPerClip', 1))
        .toDouble(),
  );
  final fastenerPackCount = math.max(
    1,
    (normalized['fastenerPackCount'] ??
            defaultFor(spec, 'fastenerPackCount', 100))
        .round(),
  );
  final fastenerReservePercent = math.max(
    0.0,
    (normalized['fastenerReservePercent'] ??
            defaultFor(spec, 'fastenerReservePercent', 5))
        .toDouble(),
  );
  final withTreatment =
      (normalized['withTreatment'] ?? defaultFor(spec, 'withTreatment', 0))
          .round()
          .clamp(0, 2);
  final treatmentRate = math.max(
    0.01,
    (normalized['treatmentRateLPerM2PerLayer'] ??
            defaultFor(spec, 'treatmentRateLPerM2PerLayer', 0.1))
        .toDouble(),
  );
  final treatmentLayers = math.max(
    1,
    (normalized['treatmentLayers'] ?? defaultFor(spec, 'treatmentLayers', 2))
        .round(),
  );
  final treatmentCanL = math.max(
    0.5,
    (normalized['treatmentCanL'] ?? defaultFor(spec, 'treatmentCanL', 2.5))
        .toDouble(),
  );
  final treatmentReservePercent = math.max(
    0.0,
    (normalized['treatmentReservePercent'] ??
            defaultFor(spec, 'treatmentReservePercent', 10))
        .toDouble(),
  );
  final withGeotextile =
      (normalized['withGeotextile'] ?? defaultFor(spec, 'withGeotextile', 1))
          .round() ==
      1;
  final geotextileRollM2 = math.max(
    5.0,
    (normalized['geotextileRollM2'] ?? defaultFor(spec, 'geotextileRollM2', 50))
        .toDouble(),
  );
  final geotextileReservePercent = math.max(
    0.0,
    (normalized['geotextileReservePercent'] ??
            defaultFor(spec, 'geotextileReservePercent', 5))
        .toDouble(),
  );

  final area = length * width;
  final boardLengthM = boardLength / 1000.0;
  final boardPitch = (boardWidthMm + gapMm) / 1000.0;
  final rowCount = ((width + gapMm / 1000.0) / boardPitch).ceil();
  final boardsPerRow = (length / boardLengthM).ceil();
  final safeBaseBoards = rowCount * boardsPerRow;
  final sharedCutBaseBoards = rowCount * length / boardLengthM;
  final baseBoardExact = offcutReuseMode
      ? sharedCutBaseBoards
      : safeBaseBoards.toDouble();
  final baseBoardPurchase = baseBoardExact.ceil();
  final totalBoardLinearM = rowCount * length;
  final baseCutWasteM = math.max(
    0.0,
    baseBoardPurchase * boardLengthM - totalBoardLinearM,
  );
  final jointCount = math.max(0, baseBoardPurchase - rowCount);

  const packageLabel = 'terrace-board';
  const packageUnit = 'шт';
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final reservePercent = scenarioName == 'MIN'
        ? 0.0
        : scenarioName == 'MAX'
        ? boardReservePercent +
              spec.materialRule<num>('max_extra_board_percent').toDouble()
        : boardReservePercent;
    final multiplier = 1 + reservePercent / 100.0;
    final exactNeed = roundValue(baseBoardExact * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'board_type:$boardType',
        'offcut_reuse_mode:${offcutReuseMode ? 1 : 0}',
        'scenario_policy:explicit_board_reserve',
      ],
      keyFactors: {
        'field_multiplier': roundValue(multiplier, 6),
        'reserve_percent': roundValue(reservePercent, 3),
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
  final lagRowCount = (length / (lagStep / 1000.0)).ceil() + 1;
  final lagBaseM = lagRowCount * width;
  final lagWithReserveM = lagBaseM * (1 + lagReservePercent / 100.0);
  final lagPcs = (lagWithReserveM / lagLengthM).ceil();
  final clipBaseCount =
      rowCount * lagRowCount * clipsPerIntersection +
      rowCount * starterClipsPerRow;
  final clipWithReserveCount =
      clipBaseCount * (1 + fastenerReservePercent / 100.0);
  final clipPacks = (clipWithReserveCount / clipPackCount).ceil();
  final fastenerBaseCount = clipBaseCount * fastenersPerClip;
  final fastenerWithReserveCount =
      fastenerBaseCount * (1 + fastenerReservePercent / 100.0);
  final fastenerPacks = (fastenerWithReserveCount / fastenerPackCount).ceil();
  final treatmentBaseL = withTreatment > 0
      ? area * treatmentRate * treatmentLayers
      : 0.0;
  final treatmentWithReserveL =
      treatmentBaseL * (1 + treatmentReservePercent / 100.0);
  final treatmentCans = treatmentWithReserveL > 0
      ? (treatmentWithReserveL / treatmentCanL).ceil()
      : 0;
  final geotextileBaseM2 = withGeotextile ? area : 0.0;
  final geotextileWithReserveM2 =
      geotextileBaseM2 * (1 + geotextileReservePercent / 100.0);
  final geotextileRolls = geotextileWithReserveM2 > 0
      ? (geotextileWithReserveM2 / geotextileRollM2).ceil()
      : 0;

  final warnings = <String>[];
  if (jointCount > 0) {
    warnings.add(
      'В базовом раскрое получается $jointCount стыков досок: проверьте разбежку и дополнительные лаги под каждым стыком',
    );
  }
  if (boardType != 0 && withTreatment == 0) {
    warnings.add(
      'Для деревянной доски не выбрана обработка: проверьте заводскую защиту и требования производителя',
    );
  }
  if (area > spec.warningRule<num>('large_area_threshold_m2').toDouble()) {
    warnings.add(
      'Для площади более 50 м² нужна отдельная схема раскладки, стыков и компенсационных зазоров',
    );
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name:
          '${_boardTypeLabels[boardType]} ${boardWidthMm.round()}×${boardLength.round()} мм',
      quantity: roundValue(baseBoardExact, 6),
      unit: 'шт',
      withReserve: recScenario.exactNeed,
      purchaseQty: recScenario.purchaseQuantity,
      category: 'Доска',
      packageInfo: {
        'count': recScenario.buyPlan.packagesCount,
        'size': 1.0,
        'packageUnit': 'досок',
      },
    ),
    CanonicalMaterialResult(
      name: 'Лаги выбранной системы (${roundValue(lagLengthM, 2)} м)',
      quantity: roundValue(lagBaseM / lagLengthM, 6),
      unit: 'шт',
      withReserve: roundValue(lagWithReserveM / lagLengthM, 6),
      purchaseQty: lagPcs.toDouble(),
      category: 'Каркас',
    ),
    CanonicalMaterialResult(
      name: boardType == 0
          ? 'Монтажные клипсы выбранной системы ДПК'
          : 'Скрытый крепёж выбранной системы',
      quantity: roundValue(clipBaseCount, 6),
      unit: 'шт',
      withReserve: roundValue(clipWithReserveCount, 6),
      purchaseQty: (clipPacks * clipPackCount).toDouble(),
      category: 'Крепёж',
      packageInfo: {
        'count': clipPacks,
        'size': clipPackCount.toDouble(),
        'packageUnit': 'упаковок',
      },
    ),
    CanonicalMaterialResult(
      name: 'Саморезы для выбранных клипс и лаг',
      quantity: roundValue(fastenerBaseCount, 6),
      unit: 'шт',
      withReserve: roundValue(fastenerWithReserveCount, 6),
      purchaseQty: (fastenerPacks * fastenerPackCount).toDouble(),
      category: 'Крепёж',
      packageInfo: {
        'count': fastenerPacks,
        'size': fastenerPackCount.toDouble(),
        'packageUnit': 'упаковок',
      },
    ),
  ];

  if (withGeotextile) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Геотекстиль (${roundValue(geotextileRollM2, 2)} м²)',
        quantity: roundValue(geotextileBaseM2, 6),
        unit: 'м²',
        withReserve: roundValue(geotextileWithReserveM2, 6),
        purchaseQty: (geotextileRolls * geotextileRollM2).toDouble(),
        category: 'Подготовка',
        packageInfo: {
          'count': geotextileRolls,
          'size': geotextileRollM2,
          'packageUnit': 'рулонов',
        },
      ),
    );
  }

  if (withTreatment > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: _treatmentLabels[withTreatment]!,
        quantity: roundValue(treatmentBaseL, 6),
        unit: 'л',
        withReserve: roundValue(treatmentWithReserveL, 6),
        purchaseQty: treatmentCans * treatmentCanL,
        category: 'Защита',
        packageInfo: {
          'count': treatmentCans,
          'size': treatmentCanL,
          'packageUnit': 'банок',
        },
      ),
    );
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
      'boardWidth': boardWidthMm,
      'gap': roundValue(gapMm, 3),
      'boardPitch': roundValue(boardPitch, 6),
      'offcutReuseMode': offcutReuseMode ? 1.0 : 0.0,
      'boardReservePercent': roundValue(boardReservePercent, 3),
      'rowCount': rowCount.toDouble(),
      'boardsPerRow': boardsPerRow.toDouble(),
      'safeBaseBoards': safeBaseBoards.toDouble(),
      'baseBoardExact': roundValue(baseBoardExact, 6),
      'baseBoardPurchase': baseBoardPurchase.toDouble(),
      'totalBoards': recScenario.purchaseQuantity,
      'totalBoardLinearM': roundValue(totalBoardLinearM, 6),
      'baseCutWasteM': roundValue(baseCutWasteM, 6),
      'jointCount': jointCount.toDouble(),
      'lagStep': lagStep,
      'lagLengthM': roundValue(lagLengthM, 3),
      'lagRowCount': lagRowCount.toDouble(),
      'lagBaseM': roundValue(lagBaseM, 6),
      'lagTotalLen': roundValue(lagWithReserveM, 6),
      'lagPcs': lagPcs.toDouble(),
      'clipBaseCount': roundValue(clipBaseCount, 6),
      'klaymerCount': (clipPacks * clipPackCount).toDouble(),
      'clipPacks': clipPacks.toDouble(),
      'fastenerBaseCount': roundValue(fastenerBaseCount, 6),
      'screwCount': (fastenerPacks * fastenerPackCount).toDouble(),
      'fastenerPacks': fastenerPacks.toDouble(),
      'treatmentL': roundValue(treatmentWithReserveL, 6),
      'treatmentCans': treatmentCans.toDouble(),
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
