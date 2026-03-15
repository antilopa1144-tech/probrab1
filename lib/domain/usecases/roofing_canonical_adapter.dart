import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* --- Default spec (mirrors roofing-canonical.v1.json) --- */

/* --- Constants (must match TS engine exactly) --- */

const List<double> _complexityCoeffs = [1.05, 1.15, 1.25];

const Map<int, String> _roofingTypeLabels = {
  0: 'Металлочерепица',
  1: 'Мягкая кровля',
  2: 'Профнастил',
  3: 'Ондулин',
  4: 'Шифер',
  5: 'Керамическая черепица',
};

/* --- Factor table --- */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

/* --- Helpers --- */

/* --- Main calculator --- */

CanonicalCalculatorContractResult calculateCanonicalRoofing(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(roofingSpecData);

  final roofingType = (inputs['roofingType'] ?? defaultFor(spec, 'roofingType', 0)).round().clamp(0, 5);
  final area = (inputs['area'] ?? defaultFor(spec, 'area', 80)).clamp(10, 500).toDouble();
  final slope = (inputs['slope'] ?? defaultFor(spec, 'slope', 30)).clamp(5, 60).toDouble();
  final ridgeLength = (inputs['ridgeLength'] ?? defaultFor(spec, 'ridgeLength', 8)).clamp(1, 30).toDouble();
  final sheetWidth = (inputs['sheetWidth'] ?? defaultFor(spec, 'sheetWidth', 1.18)).clamp(0.8, 1.5).toDouble();
  final sheetLength = (inputs['sheetLength'] ?? defaultFor(spec, 'sheetLength', 2.5)).clamp(1, 8).toDouble();
  final complexity = (inputs['complexity'] ?? defaultFor(spec, 'complexity', 0)).round().clamp(0, 2);

  final complexityCoeff = _complexityCoeffs[complexity];
  final slopeFactor = 1 / math.cos(slope * math.pi / 180);
  final realArea = area * slopeFactor;
  final perimeterEst = 4 * math.sqrt(area);

  final materials = <CanonicalMaterialResult>[];
  final warnings = <String>[];

  /* primary material quantity -- used for scenario packaging */
  var primaryQuantity = 0;
  var primaryUnit = 'шт';
  var primaryLabel = '';

  if (roofingType == 0) {
    /* -- METAL TILE -- */
    final effectiveWidth = sheetWidth - 0.08;
    final sheetArea = effectiveWidth * (sheetLength - 0.15);
    final sheetsNeeded = (realArea / sheetArea * complexityCoeff).ceil();
    final ridgePieces = (ridgeLength / 2 * 1.05).ceil();
    final snowGuards = (perimeterEst / 3).ceil();
    final screws = (realArea * 9).ceil();
    final waterproofingM2 = (realArea * 1.15).ceil();
    final waterproofingRolls = (waterproofingM2 / 75).ceil();
    final battens = (realArea / 0.35 * 1.1).ceil();
    final counterBattens = (realArea / 1.0 * 1.1).ceil();

    primaryQuantity = sheetsNeeded;
    primaryUnit = 'листов';
    primaryLabel = 'metal-tile-sheet';

    materials.add(CanonicalMaterialResult(
      name: '${_roofingTypeLabels[0]} (${sheetWidth}x$sheetLength м)',
      quantity: sheetsNeeded.toDouble(),
      unit: 'листов',
      withReserve: sheetsNeeded.toDouble(),
      purchaseQty: sheetsNeeded.toInt(),
      category: 'Основное',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Коньковые элементы (2 м)',
      quantity: ridgePieces.toDouble(),
      unit: 'шт',
      withReserve: ridgePieces.toDouble(),
      purchaseQty: ridgePieces.toInt(),
      category: 'Доборные',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Снегозадержатели',
      quantity: snowGuards.toDouble(),
      unit: 'шт',
      withReserve: snowGuards.toDouble(),
      purchaseQty: snowGuards.toInt(),
      category: 'Безопасность',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Кровельные саморезы',
      quantity: screws.toDouble(),
      unit: 'шт',
      withReserve: screws.toDouble(),
      purchaseQty: screws.toInt(),
      category: 'Крепёж',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Гидроизоляция (рулон 75 м²)',
      quantity: waterproofingM2.toDouble(),
      unit: 'м²',
      withReserve: (waterproofingRolls * 75).toDouble(),
      purchaseQty: waterproofingRolls.toInt(),
      category: 'Изоляция',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Обрешётка (доска 25x100, шаг ~350 мм)',
      quantity: battens.toDouble(),
      unit: 'шт',
      withReserve: battens.toDouble(),
      purchaseQty: battens.toInt(),
      category: 'Каркас',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Контробрешётка (брусок 50x50)',
      quantity: counterBattens.toDouble(),
      unit: 'шт',
      withReserve: counterBattens.toDouble(),
      purchaseQty: counterBattens.toInt(),
      category: 'Каркас',
    ));
  } else if (roofingType == 1) {
    /* -- SOFT ROOFING -- */
    final packs = (realArea / 3.0 * complexityCoeff).ceil();

    int underlaymentRolls;
    if (slope < 18) {
      underlaymentRolls = (realArea * 1.15 / 15).ceil();
    } else {
      final criticalLinear = perimeterEst + ridgeLength;
      final criticalArea = criticalLinear * 1.0 * 1.15;
      underlaymentRolls = (criticalArea / 15).ceil();
    }

    final masticKg = (perimeterEst + ridgeLength) * 0.1 + realArea * 0.1;
    final masticBuckets = (masticKg / 3).ceil();
    final nailsKg = (realArea * 80 / 400 * 1.05).ceil();
    final ridgeShingles = (ridgeLength / 0.5 * 1.05).ceil();
    final osbSheets = (realArea / 3.125 * 1.05).ceil();
    final ventOutputs = (realArea / 25).ceil();

    primaryQuantity = packs;
    primaryUnit = 'упаковок';
    primaryLabel = 'soft-roofing-pack-3m2';

    materials.add(CanonicalMaterialResult(
      name: '${_roofingTypeLabels[1]} (упаковка 3 м²)',
      quantity: packs.toDouble(),
      unit: 'упаковок',
      withReserve: packs.toDouble(),
      purchaseQty: packs.toInt(),
      category: 'Основное',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Подкладочный ковёр (рулон 15 м²)',
      quantity: underlaymentRolls.toDouble(),
      unit: 'рулонов',
      withReserve: underlaymentRolls.toDouble(),
      purchaseQty: underlaymentRolls.toInt(),
      category: 'Изоляция',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Мастика битумная (ведро 3 кг)',
      quantity: roundValue(masticKg, 3),
      unit: 'кг',
      withReserve: (masticBuckets * 3).toDouble(),
      purchaseQty: masticBuckets.toInt(),
      category: 'Клей',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Кровельные гвозди',
      quantity: nailsKg.toDouble(),
      unit: 'кг',
      withReserve: nailsKg.toDouble(),
      purchaseQty: nailsKg.toInt(),
      category: 'Крепёж',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Коньково-карнизная черепица',
      quantity: ridgeShingles.toDouble(),
      unit: 'шт',
      withReserve: ridgeShingles.toDouble(),
      purchaseQty: ridgeShingles.toInt(),
      category: 'Доборные',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Плиты OSB (1250x2500=3.125 м²)',
      quantity: osbSheets.toDouble(),
      unit: 'листов',
      withReserve: osbSheets.toDouble(),
      purchaseQty: osbSheets.toInt(),
      category: 'Каркас',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Вентиляционные выходы',
      quantity: ventOutputs.toDouble(),
      unit: 'шт',
      withReserve: ventOutputs.toDouble(),
      purchaseQty: ventOutputs.toInt(),
      category: 'Вентиляция',
    ));
  } else {
    /* -- GENERIC: profnastil (2), ondulin (3), shale (4), ceramic (5) -- */
    final typeIdx = roofingType - 2; // 0..3
    double unitSheetArea;
    String unitLabel;
    String unitName;

    if (roofingType == 2) {
      // profnastil
      final effectiveW = sheetWidth - 0.05;
      unitSheetArea = effectiveW * (sheetLength - 0.1);
      unitLabel = 'profnastil-${sheetWidth}x$sheetLength';
      unitName = '${_roofingTypeLabels[2]} (${sheetWidth}x$sheetLength м)';
    } else if (roofingType == 3) {
      // ondulin: sheet 0.95x2.0, effective 0.83x1.85
      unitSheetArea = 0.83 * 1.85; // 1.5355
      unitLabel = 'ondulin-0.95x2.0';
      unitName = '${_roofingTypeLabels[3]} (лист 0.95x2.0 м)';
    } else if (roofingType == 4) {
      // shale: sheet 1.13x1.75, effective 0.98x1.55
      unitSheetArea = 0.98 * 1.55; // 1.519
      unitLabel = 'shale-1.13x1.75';
      unitName = '${_roofingTypeLabels[4]} (лист 1.13x1.75 м)';
    } else {
      // ceramic: 1 tile = 0.03 m², ~13 tiles/m²
      unitSheetArea = 1 / 13; // ~0.07692
      unitLabel = 'ceramic-tile';
      unitName = '${_roofingTypeLabels[5]} (~13 шт/м²)';
    }

    final sheetsOrTiles = (realArea / unitSheetArea * complexityCoeff).ceil();
    final ridgePieces = (ridgeLength / 0.33 * 1.05).ceil();

    const fastenerRates = [10, 20, 4, 4];
    final fastenersNeeded = (realArea * fastenerRates[typeIdx]).ceil();
    final waterproofingRolls = (realArea * 1.15 / 75).ceil();

    final tileUnit = roofingType == 5 ? 'шт' : 'листов';

    primaryQuantity = sheetsOrTiles;
    primaryUnit = tileUnit;
    primaryLabel = unitLabel;

    materials.add(CanonicalMaterialResult(
      name: unitName,
      quantity: sheetsOrTiles.toDouble(),
      unit: tileUnit,
      withReserve: sheetsOrTiles.toDouble(),
      purchaseQty: sheetsOrTiles.toInt(),
      category: 'Основное',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Коньковые элементы (0.33 м)',
      quantity: ridgePieces.toDouble(),
      unit: 'шт',
      withReserve: ridgePieces.toDouble(),
      purchaseQty: ridgePieces.toInt(),
      category: 'Доборные',
    ));
    materials.add(CanonicalMaterialResult(
      name: roofingType == 3 ? 'Гвозди кровельные' : 'Крепёж кровельный',
      quantity: fastenersNeeded.toDouble(),
      unit: 'шт',
      withReserve: fastenersNeeded.toDouble(),
      purchaseQty: fastenersNeeded.toInt(),
      category: 'Крепёж',
    ));
    materials.add(CanonicalMaterialResult(
      name: 'Гидроизоляция (рулон 75 м²)',
      quantity: (realArea * 1.15).ceilToDouble(),
      unit: 'м²',
      withReserve: (waterproofingRolls * 75).toDouble(),
      purchaseQty: waterproofingRolls.toInt(),
      category: 'Изоляция',
    ));
  }

  /* -- scenarios -- */
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(primaryQuantity * multiplier, 6);
    final packages = exactNeed > 0 ? (exactNeed / 1.0).ceil() : 0;
    final purchaseQuantity = roundValue(packages * 1.0, 6);

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'roofingType:$roofingType',
        'complexity:$complexity',
        'slope:${slope.toInt()}',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: primaryLabel,
        packageSize: 1.0,
        packagesCount: packages,
        unit: primaryUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* -- warnings -- */
  if (slope < spec.warningRule<num>('metal_tile_min_slope').toDouble() && roofingType == 0) {
    warnings.add('Уклон менее 14\u00b0 \u2014 слишком пологий для металлочерепицы');
  }
  if (slope < spec.warningRule<num>('soft_roofing_min_slope').toDouble() && roofingType == 1) {
    warnings.add('Уклон менее 12\u00b0 \u2014 слишком пологий для мягкой кровли');
  }
  if (complexity == 2) {
    warnings.add('Сложная геометрия крыши \u2014 рекомендуется профессиональный монтаж');
  }
  if (realArea > spec.warningRule<num>('large_roof_area_threshold').toDouble()) {
    warnings.add('Большая площадь крыши \u2014 рекомендуется доставка краном');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roofingType': roofingType.toDouble(),
      'area': roundValue(area, 3),
      'slope': roundValue(slope, 3),
      'ridgeLength': roundValue(ridgeLength, 3),
      'sheetWidth': roundValue(sheetWidth, 3),
      'sheetLength': roundValue(sheetLength, 3),
      'complexity': complexity.toDouble(),
      'slopeFactor': roundValue(slopeFactor, 6),
      'realArea': roundValue(realArea, 3),
      'perimeterEst': roundValue(perimeterEst, 3),
      'complexityCoeff': complexityCoeff,
      'primaryQuantity': primaryQuantity.toDouble(),
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
