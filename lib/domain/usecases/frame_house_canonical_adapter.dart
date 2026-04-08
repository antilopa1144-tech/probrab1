import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */



const Map<int, String> _insulationTypeLabels = {
  0: 'Минеральная вата 150 мм',
  1: 'Минеральная вата 200 мм',
  2: 'Пенополистирол 150 мм',
};

const Map<int, String> _outerSheathingLabels = {
  0: 'OSB-9 мм',
  1: 'OSB-12 мм',
  2: 'ЦСП-12 мм',
};

const Map<int, String> _innerSheathingLabels = {
  0: 'OSB-9 мм',
  1: 'ГКЛ',
  2: 'Вагонка',
};


bool hasCanonicalFrameHouseInputs(Map<String, double> inputs) {
  return inputs.containsKey('studStep') ||
      inputs.containsKey('insulationType') ||
      inputs.containsKey('wallLength');
}

Map<String, double> normalizeLegacyFrameHouseInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['wallLength'] = (inputs['wallLength'] ?? 30).toDouble();
  normalized['wallHeight'] = (inputs['wallHeight'] ?? 2.7).toDouble();
  normalized['openingsArea'] = (inputs['openingsArea'] ?? 10).toDouble();
  normalized['studStep'] = (inputs['studStep'] ?? 600).toDouble();
  normalized['insulationType'] = (inputs['insulationType'] ?? 0).toDouble();
  normalized['outerSheathing'] = (inputs['outerSheathing'] ?? 0).toDouble();
  normalized['innerSheathing'] = (inputs['innerSheathing'] ?? 0).toDouble();
  return normalized;
}


CanonicalCalculatorContractResult calculateCanonicalFrameHouse(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(frameHouseSpecData);

  final normalized = hasCanonicalFrameHouseInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyFrameHouseInputs(inputs);

  final wallLength = math.max(1.0, math.min(100.0, (normalized['wallLength'] ?? defaultFor(spec, 'wallLength', 30)).toDouble()));
  final wallHeight = math.max(2.0, math.min(4.0, (normalized['wallHeight'] ?? defaultFor(spec, 'wallHeight', 2.7)).toDouble()));
  final openingsArea = math.max(0.0, math.min(50.0, (normalized['openingsArea'] ?? defaultFor(spec, 'openingsArea', 10)).toDouble()));
  final studStep = (normalized['studStep'] ?? defaultFor(spec, 'studStep', 600)).round().clamp(400, 600);
  final insulationType = (normalized['insulationType'] ?? defaultFor(spec, 'insulationType', 0)).round().clamp(0, 2);
  final outerSheathing = (normalized['outerSheathing'] ?? defaultFor(spec, 'outerSheathing', 0)).round().clamp(0, 2);
  final innerSheathing = (normalized['innerSheathing'] ?? defaultFor(spec, 'innerSheathing', 0)).round().clamp(0, 2);

  // Geometry
  final wallArea = math.max(0.0, wallLength * wallHeight - openingsArea);
  final studs = (wallLength / (studStep / 1000)).ceil() + 1;
  final studMeters = studs * wallHeight * spec.materialRule<num>('stud_reserve').toDouble();
  final studBoards = (studMeters / 6).ceil();
  final strappingM = wallLength * 2 * spec.materialRule<num>('strapping_reserve').toDouble();
  final strappingBoards = (strappingM / 6).ceil();

  // Sheathing
  final outerSheetArea = (spec.materialRule<Map>('outer_sheet_area')['$outerSheathing'] as num?)?.toDouble() ?? 3.125;
  final innerSheetArea = (spec.materialRule<Map>('inner_sheet_area')['$innerSheathing'] as num?)?.toDouble() ?? 3.125;
  final outerSheets = (wallArea / outerSheetArea * spec.materialRule<num>('outer_reserve').toDouble()).ceil();
  final innerSheets = (wallArea * spec.materialRule<num>('inner_reserve').toDouble() / innerSheetArea).ceil();

  // Insulation
  final thickness = (spec.materialRule<Map>('insulation_thickness')['$insulationType'] as num?)?.toDouble() ?? 0.15;
  final insulVol = roundValue(wallArea * thickness, 3);
  final layerCount = (thickness / 0.05).ceil();
  final platesPerLayer = (wallArea / spec.materialRule<num>('plate_area').toDouble() * spec.materialRule<num>('plate_reserve').toDouble()).ceil();
  final totalPlates = platesPerLayer * layerCount;
  final packs = (totalPlates / spec.materialRule<num>('pack_size').toDouble()).ceil();

  // Membranes
  final vaporRolls = (wallArea * spec.materialRule<num>('membrane_reserve').toDouble() / spec.materialRule<num>('vapor_roll').toDouble()).ceil();
  final windRolls = (wallArea * spec.materialRule<num>('membrane_reserve').toDouble() / spec.materialRule<num>('wind_roll').toDouble()).ceil();
  final tapeRolls = (vaporRolls + windRolls) * 2;

  // Fasteners
  final screwsKg = ((outerSheets + innerSheets) * spec.materialRule<num>('screws_per_sheet').toDouble() * spec.materialRule<num>('stud_reserve').toDouble() / spec.materialRule<num>('screw_per_kg').toDouble() * 10).ceil() / 10;
  final nailsKg = (studs * spec.materialRule<num>('nails_per_stud').toDouble() * spec.materialRule<num>('stud_reserve').toDouble() / spec.materialRule<num>('nail_per_kg').toDouble() * 10).ceil() / 10;

  // Scenarios
  final basePrimary = totalPlates;
  const packageLabel = 'insulation-pack-8';
  const packageUnit = 'уп';

  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? (exactNeed / spec.materialRule<num>('pack_size').toDouble()).ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: (packageCount * spec.materialRule<num>('pack_size').toDouble()),
      leftover: roundValue(packageCount * spec.materialRule<num>('pack_size').toDouble() - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'insulationType:$insulationType',
        'studStep:$studStep',
        'packaging:$packageLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: packageLabel,
        packageSize: spec.materialRule<num>('pack_size').toDouble(),
        packagesCount: packageCount,
        unit: packageUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  // Warnings
  final warnings = <String>[];
  if (wallArea > spec.warningRule<num>('large_wall_area_threshold_m2').toDouble()) {
    warnings.add('Большая площадь стен — рассмотрите усиление каркаса');
  }
  if (insulationType == 2 && wallHeight > 3) {
    warnings.add('Для высоких стен рекомендуется минеральная вата вместо ПСБ');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Стойки каркаса (шаг $studStep мм)',
      quantity: studs.toDouble(),
      unit: 'шт',
      withReserve: studBoards.toDouble(),
      purchaseQty: (studBoards * 6.0).toDouble(),
      category: 'Каркас',
      packageInfo: {'count': studBoards, 'unitSize': 6.0, 'packageUnit': 'досок'},
    ),
    CanonicalMaterialResult(
      name: 'Обвязка (доски 6 м)',
      quantity: roundValue(strappingM, 2),
      unit: 'м',
      withReserve: strappingBoards.toDouble(),
      purchaseQty: (strappingBoards * 6.0).toDouble(),
      category: 'Каркас',
      packageInfo: {'count': strappingBoards, 'unitSize': 6.0, 'packageUnit': 'досок'},
    ),
    CanonicalMaterialResult(
      name: 'Наружная обшивка — ${_outerSheathingLabels[outerSheathing]}',
      quantity: outerSheets.toDouble(),
      unit: 'листов',
      withReserve: outerSheets.toDouble(),
      purchaseQty: outerSheets.toDouble(),
      category: 'Обшивка',
    ),
    CanonicalMaterialResult(
      name: 'Внутренняя обшивка — ${_innerSheathingLabels[innerSheathing]}',
      quantity: innerSheets.toDouble(),
      unit: innerSheathing == 2 ? 'шт' : 'листов',
      withReserve: innerSheets.toDouble(),
      purchaseQty: innerSheets.toDouble(),
      category: 'Обшивка',
    ),
    CanonicalMaterialResult(
      name: 'Утеплитель — ${_insulationTypeLabels[insulationType]}',
      quantity: recScenario.exactNeed,
      unit: 'плит',
      withReserve: recScenario.exactNeed.ceilToDouble(),
      purchaseQty: (packs * spec.materialRule<num>('pack_size').toDouble()).toDouble(),
      category: 'Утепление',
      packageInfo: {'count': packs, 'unitSize': spec.materialRule<num>('pack_size').toDouble(), 'packageUnit': 'упаковок'},
    ),
    CanonicalMaterialResult(
      name: 'Утеплитель (упаковки по ${spec.materialRule<num>('pack_size').toDouble()} шт)',
      quantity: packs.toDouble(),
      unit: 'уп',
      withReserve: packs.toDouble(),
      purchaseQty: packs.toDouble(),
      category: 'Утепление',
    ),
    CanonicalMaterialResult(
      name: 'Пароизоляция (рулон ${spec.materialRule<num>('vapor_roll').toDouble().round()} м²)',
      quantity: vaporRolls.toDouble(),
      unit: 'рулонов',
      withReserve: vaporRolls.toDouble(),
      purchaseQty: vaporRolls.toDouble(),
      category: 'Мембраны',
    ),
    CanonicalMaterialResult(
      name: 'Ветрозащита (рулон ${spec.materialRule<num>('wind_roll').toDouble().round()} м²)',
      quantity: windRolls.toDouble(),
      unit: 'рулонов',
      withReserve: windRolls.toDouble(),
      purchaseQty: windRolls.toDouble(),
      category: 'Мембраны',
    ),
    CanonicalMaterialResult(
      name: 'Скотч для мембран',
      quantity: tapeRolls.toDouble(),
      unit: 'рулонов',
      withReserve: tapeRolls.toDouble(),
      purchaseQty: tapeRolls.toDouble(),
      category: 'Мембраны',
    ),
    CanonicalMaterialResult(
      name: 'Саморезы',
      quantity: screwsKg,
      unit: 'кг',
      withReserve: screwsKg,
      purchaseQty: screwsKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
    CanonicalMaterialResult(
      name: 'Гвозди',
      quantity: nailsKg,
      unit: 'кг',
      withReserve: nailsKg,
      purchaseQty: nailsKg.ceil().toDouble(),
      category: 'Крепёж',
    ),
  ];

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'wallLength': roundValue(wallLength, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'studStep': studStep.toDouble(),
      'insulationType': insulationType.toDouble(),
      'outerSheathing': outerSheathing.toDouble(),
      'innerSheathing': innerSheathing.toDouble(),
      'wallArea': roundValue(wallArea, 3),
      'studs': studs.toDouble(),
      'studMeters': roundValue(studMeters, 3),
      'studBoards': studBoards.toDouble(),
      'strappingM': roundValue(strappingM, 3),
      'strappingBoards': strappingBoards.toDouble(),
      'outerSheets': outerSheets.toDouble(),
      'innerSheets': innerSheets.toDouble(),
      'insulVol': insulVol,
      'layerCount': layerCount.toDouble(),
      'platesPerLayer': platesPerLayer.toDouble(),
      'totalPlates': totalPlates.toDouble(),
      'packs': packs.toDouble(),
      'vaporRolls': vaporRolls.toDouble(),
      'windRolls': windRolls.toDouble(),
      'tapeRolls': tapeRolls.toDouble(),
      'screwsKg': screwsKg,
      'nailsKg': nailsKg,
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
