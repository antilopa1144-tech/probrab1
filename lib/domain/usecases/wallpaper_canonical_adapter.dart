import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

bool hasCanonicalWallpaperInputs(Map<String, double> inputs) {
  const canonicalKeys = [
    'perimeter',
    'roomWidth',
    'roomLength',
    'roomHeight',
    'openingsArea',
    'doorsCount',
    'windowsCount',
    'reserveRolls',
    'reservePercent',
  ];
  return canonicalKeys.any(inputs.containsKey);
}

Map<String, double> normalizeLegacyWallpaperInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  final rollSize = (inputs['rollSize'] ?? 1).round();
  if (!normalized.containsKey('rollWidth') ||
      !normalized.containsKey('rollLength')) {
    switch (rollSize) {
      case 2:
        normalized['rollWidth'] = 1.06;
        normalized['rollLength'] = 10.05;
        break;
      case 3:
        normalized['rollWidth'] = 1.06;
        normalized['rollLength'] = 25.0;
        break;
      default:
        normalized['rollWidth'] = inputs['rollWidth'] ?? 0.53;
        normalized['rollLength'] = inputs['rollLength'] ?? 10.05;
        break;
    }
  }

  normalized['openingsArea'] =
      math.max(0, inputs['windowsArea'] ?? 0).toDouble() +
      math.max(0, inputs['doorsArea'] ?? 0).toDouble();
  normalized['reservePercent'] = math.max(0, inputs['reserve'] ?? 0).toDouble();
  normalized['reserveRolls'] = (inputs['reserveRolls'] ?? 0).toDouble();
  normalized['wallHeight'] = (inputs['wallHeight'] ?? inputs['height'] ?? 2.5)
      .toDouble();
  normalized['wallpaperType'] = (inputs['wallpaperType'] ?? 1)
      .round()
      .clamp(1, 3)
      .toDouble();
  return normalized;
}

Map<String, double> _resolveGeometry(
  SpecReader spec,
  Map<String, double> inputs,
) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0))
      .round();
  final wallHeight =
      (inputs['wallHeight'] ??
              inputs['height'] ??
              inputs['roomHeight'] ??
              defaultFor(spec, 'wallHeight', 2.7))
          .clamp(2, 5)
          .toDouble();
  final exactOpeningsArea = math.max(0, inputs['openingsArea'] ?? 0).toDouble();
  final doorsCount = math.max(
    0,
    (inputs['doorsCount'] ?? inputs['doors'] ?? 0).round(),
  );
  final windowsCount = math.max(
    0,
    (inputs['windowsCount'] ?? inputs['windows'] ?? 0).round(),
  );
  final defaultOpeningsArea =
      doorsCount * spec.materialRule<num>('door_area_m2').toDouble() +
      windowsCount * spec.materialRule<num>('window_area_m2').toDouble();
  final openingsArea =
      (exactOpeningsArea > 0 ? exactOpeningsArea : defaultOpeningsArea)
          .toDouble();

  if ((inputMode == 0 ||
          (!inputs.containsKey('inputMode') &&
              inputs.containsKey('perimeter'))) &&
      inputs.containsKey('perimeter')) {
    final perimeter = math.max(1, inputs['perimeter'] ?? 0).toDouble();
    final wallArea = perimeter * wallHeight;
    return {
      'inputMode': 0.0,
      'perimeter': roundValue(perimeter, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'wallArea': roundValue(wallArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'netArea': roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
    };
  }

  if ((inputMode == 0 ||
          (!inputs.containsKey('inputMode') &&
              inputs.containsKey('roomWidth') &&
              inputs.containsKey('roomLength'))) &&
      inputs.containsKey('roomWidth') &&
      inputs.containsKey('roomLength')) {
    final roomWidth = math.max(1, inputs['roomWidth'] ?? 0).toDouble();
    final roomLength = math.max(1, inputs['roomLength'] ?? 0).toDouble();
    final perimeter = 2 * (roomWidth + roomLength);
    final wallArea = perimeter * wallHeight;
    return {
      'inputMode': 0.0,
      'perimeter': roundValue(perimeter, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'wallArea': roundValue(wallArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'netArea': roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
    };
  }

  if (inputs.containsKey('length') && inputs.containsKey('width')) {
    final length = math.max(1, inputs['length'] ?? 0).toDouble();
    final width = math.max(1, inputs['width'] ?? 0).toDouble();
    final perimeter = 2 * (length + width);
    final wallArea = perimeter * wallHeight;
    return {
      'inputMode': 0.0,
      'perimeter': roundValue(perimeter, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'wallArea': roundValue(wallArea, 3),
      'openingsArea': roundValue(openingsArea, 3),
      'netArea': roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
    };
  }

  final wallArea = math
      .max(0, inputs['area'] ?? defaultFor(spec, 'area', 40))
      .toDouble();
  final perimeter = wallHeight > 0 ? wallArea / wallHeight : 0.0;
  return {
    'inputMode': 1.0,
    'perimeter': roundValue(perimeter, 3),
    'wallHeight': roundValue(wallHeight, 3),
    'wallArea': roundValue(wallArea, 3),
    'openingsArea': roundValue(openingsArea, 3),
    'netArea': roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
  };
}

Map<String, dynamic> _resolveWallpaperType(
  SpecReader spec,
  Map<String, double> inputs,
) {
  final wallpaperType =
      (inputs['wallpaperType'] ?? defaultFor(spec, 'wallpaperType', 1))
          .round()
          .clamp(1, 3);
  return spec
      .normativeList('wallpaper_types')
      .firstWhere(
        (type) => (type['id'] as num).toInt() == wallpaperType,
        orElse: () => spec.normativeList('wallpaper_types').first,
      );
}

double _resolveRollWidth(SpecReader spec, Map<String, double> inputs) {
  return (inputs['rollWidth'] ?? defaultFor(spec, 'rollWidth', 0.53))
      .clamp(0.5, 1.2)
      .toDouble();
}

double _resolveRollLength(SpecReader spec, Map<String, double> inputs) {
  return (inputs['rollLength'] ?? defaultFor(spec, 'rollLength', 10.05))
      .clamp(5, 50)
      .toDouble();
}

double _resolveRapportMeters(SpecReader spec, Map<String, double> inputs) {
  return math
          .max(0, inputs['rapport'] ?? defaultFor(spec, 'rapport', 0))
          .toDouble() /
      100;
}

CanonicalCalculatorContractResult calculateCanonicalWallpaper(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(wallpaperSpecData);

  final geometry = _resolveGeometry(spec, inputs);
  final wallpaperType = _resolveWallpaperType(spec, inputs);
  final rollWidth = _resolveRollWidth(spec, inputs);
  final rollLength = _resolveRollLength(spec, inputs);
  final rapport = _resolveRapportMeters(spec, inputs);
  final patternShift = math.max(0, inputs['patternShift'] ?? defaultFor(spec, 'patternShift', 0)).toDouble() / 100;
  final trimAllowance = math.max(0, inputs['trimAllowanceCm'] ?? defaultFor(spec, 'trimAllowanceCm', 10)).toDouble() / 100;
  final openingDeductionMode = (inputs['openingDeductionMode'] ?? defaultFor(spec, 'openingDeductionMode', 0)).round() == 1 ? 1 : 0;
  final reservePercent = math
      .max(0, inputs['reservePercent'] ?? defaultFor(spec, 'reservePercent', 0))
      .toDouble();
  final reserveRolls = math.max(
    0,
    (inputs['reserveRolls'] ?? defaultFor(spec, 'reserveRolls', 0)).round(),
  );
  final wallHeight = geometry['wallHeight']!;
  final stripLengthWithTrim = wallHeight + trimAllowance + (rapport > 0 ? patternShift : 0);
  final stripLength = rapport > 0
      ? (stripLengthWithTrim / rapport).ceil() * rapport
      : stripLengthWithTrim;
  final stripsPerRoll = stripLength > 0
      ? math.max(0, (rollLength / stripLength).floor())
      : 0;
  final netArea = geometry['netArea']!;
  final stripBasis = openingDeductionMode == 1
      ? netArea / wallHeight
      : geometry['perimeter']!;
  final stripsNeeded = wallHeight > 0 && rollWidth > 0
      ? (stripBasis / rollWidth).ceil()
      : 0;
  final accuracyMode = parseAccuracyMode(inputs);
  final baseExactRolls = stripsPerRoll > 0 ? stripsNeeded / stripsPerRoll : 0.0;
  final scenarioPolicy =
      spec.raw['scenario_policy'] as Map<String, dynamic>? ?? const {};
  final recommendedSpareRolls = math.max(
    0,
    (scenarioPolicy['recommended_spare_rolls'] as num?)?.round() ?? 1,
  );
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final scenarioReservePercent = scenarioName == 'MIN' ? 0.0 : reservePercent;
    final scenarioReserveRolls = scenarioName == 'MIN'
        ? 0
        : scenarioName == 'MAX'
        ? math.max(reserveRolls, recommendedSpareRolls)
        : reserveRolls;
    final reserveMultiplier = 1 + scenarioReservePercent / 100;
    final exactNeed = roundValue(
      baseExactRolls * reserveMultiplier + scenarioReserveRolls,
      6,
    );
    final purchaseQuantity = exactNeed > 0 ? exactNeed.ceilToDouble() : 0.0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'wallpaper:${wallpaperType['key'] as String}',
        'accuracy_mode:${accuracyMode.name}',
        'scenario_policy:explicit_wallpaper_reserve',
        'packaging:wallpaper-roll-1',
      ],
      keyFactors: {
        'field_multiplier': roundValue(reserveMultiplier, 6),
        'reserve_percent': roundValue(scenarioReservePercent, 3),
        'reserve_rolls': scenarioReserveRolls.toDouble(),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'wallpaper-roll-1',
        packageSize: 1,
        packagesCount: purchaseQuantity.toInt(),
        unit: spec.packagingRule<String>('roll_unit'),
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final pasteCoverageM2 = math.max(1, inputs['pasteCoverageM2'] ?? defaultFor(spec, 'pasteCoverageM2', 30)).toDouble();
  final pastePackKg = math.max(0.05, inputs['pastePackKg'] ?? defaultFor(spec, 'pastePackKg', 0.25)).toDouble();
  final pastePacks = netArea > 0 ? (netArea / pasteCoverageM2).ceil() : 0;
  final pasteBaseNeeded = netArea / pasteCoverageM2 * pastePackKg;
  final pasteWithReserve = pasteBaseNeeded;
  final primerRate = math.max(0.01, inputs['primerRate'] ?? defaultFor(spec, 'primerRate', 0.15)).toDouble();
  final primerLayers = math.max(1, (inputs['primerLayers'] ?? defaultFor(spec, 'primerLayers', 1)).round());
  final primerCanL = math.max(0.5, inputs['primerCanL'] ?? defaultFor(spec, 'primerCanL', 5)).toDouble();
  final primerBaseNeeded = netArea * primerRate * primerLayers;
  final primerWithReserve = primerBaseNeeded;
  final primerCans = primerWithReserve > 0 ? (primerWithReserve / primerCanL).ceil() : 0;
  final rollLabel =
      '${roundValue(rollWidth, 3)}×${roundValue(rollLength, 3)} м';
  final rapportLabel = rapport > 0
      ? ', раппорт ${roundValue(rapport * 100, 1)} см'
      : ', без подгонки рисунка';

  final warnings = <String>[];
  if (netArea <= 0) {
    warnings.add('Полезная площадь оклейки должна быть больше нуля');
  }
  if (rapport > spec.warningRule<num>('large_rapport_threshold_m').toDouble()) {
    warnings.add(
      'Большой раппорт узора увеличивает отходы. Проверьте запас по рулонам перед покупкой',
    );
  }
  if (rollWidth > spec.warningRule<num>('wide_roll_threshold_m').toDouble()) {
    warnings.add(
      'Широкие обои сложнее клеить одному. Для метровых рулонов лучше работать вдвоём',
    );
  }
  if (stripsPerRoll <=
          spec.warningRule<num>('low_strips_per_roll_threshold').toDouble() &&
      netArea > 0) {
    warnings.add(
      'Из одного рулона получается мало полос. Проверьте высоту стены, длину рулона и раппорт',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name:
            'Обои — ${(wallpaperType['label'] as String).toLowerCase()}, рулон $rollLabel$rapportLabel',
        quantity: roundValue(baseExactRolls, 6),
        unit: spec.packagingRule<String>('roll_unit'),
        withReserve: recScenario.exactNeed,
        purchaseQty: recScenario.buyPlan.packagesCount.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name:
            'Клей обойный (${(wallpaperType['label'] as String).toLowerCase()}, ${roundValue(pastePackKg, 3)} кг)',
        quantity: roundValue(pasteBaseNeeded, 6),
        unit: 'кг',
        withReserve: roundValue(pasteWithReserve, 6),
        purchaseQty:
            (pastePacks * pastePackKg)
                .toDouble(),
        category: 'Клей',
        packageInfo: {
          'count': pastePacks,
          'size': pastePackKg,
          'packageUnit': 'упаковок',
        },
      ),
      CanonicalMaterialResult(
        name:
            'Грунтовка глубокого проникновения (${roundValue(primerCanL, 3)} л)',
        quantity: roundValue(primerBaseNeeded, 6),
        unit: 'л',
        withReserve: roundValue(primerWithReserve, 6),
        purchaseQty:
            (primerCans * primerCanL)
                .toDouble(),
        category: 'Грунтовка',
        packageInfo: {
          'count': primerCans,
          'size': primerCanL,
          'packageUnit': 'канистр',
        },
      ),
      CanonicalMaterialResult(
        name: 'Валик для клея',
        quantity: spec.materialRule<num>('glue_roller_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('glue_roller_count').toDouble(),
        purchaseQty: spec.materialRule<num>('glue_roller_count').toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Пластиковый шпатель для обоев',
        quantity: spec.materialRule<num>('wallpaper_spatula_count').toDouble(),
        unit: 'шт',
        withReserve: spec
            .materialRule<num>('wallpaper_spatula_count')
            .toDouble(),
        purchaseQty: spec
            .materialRule<num>('wallpaper_spatula_count')
            .toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Нож малярный',
        quantity: spec.materialRule<num>('knife_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('knife_count').toDouble(),
        purchaseQty: spec.materialRule<num>('knife_count').toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Лезвия для ножа (упаковка)',
        quantity: spec.materialRule<num>('blades_pack_count').toDouble(),
        unit: 'уп',
        withReserve: spec.materialRule<num>('blades_pack_count').toDouble(),
        purchaseQty: spec.materialRule<num>('blades_pack_count').toDouble(),
        category: 'Расходники',
      ),
      CanonicalMaterialResult(
        name: 'Ведро для клея',
        quantity: spec.materialRule<num>('bucket_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('bucket_count').toDouble(),
        purchaseQty: spec.materialRule<num>('bucket_count').toDouble(),
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Губка для удаления клея',
        quantity: spec.materialRule<num>('sponge_count').toDouble(),
        unit: 'шт',
        withReserve: spec.materialRule<num>('sponge_count').toDouble(),
        purchaseQty: spec.materialRule<num>('sponge_count').toDouble(),
        category: 'Расходники',
      ),
    ],
    totals: {
      'wallArea': roundValue(geometry['wallArea']!, 3),
      'netArea': roundValue(netArea, 3),
      'openingsArea': roundValue(geometry['openingsArea']!, 3),
      'perimeter': roundValue(geometry['perimeter']!, 3),
      'wallHeight': roundValue(wallHeight, 3),
      'inputMode': geometry['inputMode']!,
      'rollWidth': roundValue(rollWidth, 3),
      'rollLength': roundValue(rollLength, 3),
      'rapport': roundValue(rapport * 100, 3),
      'patternShift': roundValue(patternShift * 100, 3),
      'trimAllowanceCm': roundValue(trimAllowance * 100, 3),
      'openingDeductionMode': openingDeductionMode.toDouble(),
      'wallpaperType': (wallpaperType['id'] as num).toInt().toDouble(),
      'reservePercent': roundValue(reservePercent, 3),
      'reserveRolls': reserveRolls.toDouble(),
      'stripLength': roundValue(stripLength, 3),
      'stripsPerRoll': stripsPerRoll.toDouble(),
      'stripsNeeded': stripsNeeded.toDouble(),
      'baseExactRolls': roundValue(baseExactRolls, 6),
      'rollsNeeded': recScenario.purchaseQuantity,
      'pasteBaseNeededKg': roundValue(pasteBaseNeeded, 6),
      'pasteNeededKg': roundValue(pasteWithReserve, 6),
      'pastePurchaseKg': roundValue(
        pastePacks * pastePackKg,
        6,
      ),
      'pastePacks': pastePacks.toDouble(),
      'pasteCoverageM2': pasteCoverageM2,
      'pastePackKg': pastePackKg,
      'primerBaseNeededL': roundValue(primerBaseNeeded, 6),
      'primerNeededL': roundValue(primerWithReserve, 6),
      'primerPurchaseL': roundValue(
        primerCans * primerCanL,
        6,
      ),
      'primerCans': primerCans.toDouble(),
      'primerRate': primerRate,
      'primerLayers': primerLayers.toDouble(),
      'primerCanL': primerCanL,
      'minExactNeedRolls': scenarios['MIN']!.exactNeed,
      'recExactNeedRolls': recScenario.exactNeed,
      'maxExactNeedRolls': scenarios['MAX']!.exactNeed,
      'minPurchaseRolls': scenarios['MIN']!.purchaseQuantity,
      'recPurchaseRolls': recScenario.purchaseQuantity,
      'maxPurchaseRolls': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
