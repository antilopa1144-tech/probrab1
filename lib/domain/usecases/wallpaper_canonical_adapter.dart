import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'surface_quality': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.08},
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

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
  if (!normalized.containsKey('rollWidth') || !normalized.containsKey('rollLength')) {
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
  normalized['wallHeight'] = (inputs['wallHeight'] ?? inputs['height'] ?? 2.5).toDouble();
  normalized['wallpaperType'] = (inputs['wallpaperType'] ?? 1).round().clamp(1, 3).toDouble();
  return normalized;
}

Map<String, double> _resolveGeometry(SpecReader spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? defaultFor(spec, 'inputMode', 0)).round();
  final wallHeight = (inputs['wallHeight'] ?? inputs['height'] ?? inputs['roomHeight'] ?? defaultFor(spec, 'wallHeight', 2.7))
      .clamp(2, 5)
      .toDouble();
  final exactOpeningsArea = math.max(0, inputs['openingsArea'] ?? 0).toDouble();
  final doorsCount = math.max(0, (inputs['doorsCount'] ?? inputs['doors'] ?? 0).round());
  final windowsCount = math.max(0, (inputs['windowsCount'] ?? inputs['windows'] ?? 0).round());
  final defaultOpeningsArea =
      doorsCount * spec.materialRule<num>('door_area_m2').toDouble() +
      windowsCount * spec.materialRule<num>('window_area_m2').toDouble();
  final openingsArea = (exactOpeningsArea > 0 ? exactOpeningsArea : defaultOpeningsArea).toDouble();

  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && inputs.containsKey('perimeter'))) &&
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

  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && inputs.containsKey('roomWidth') && inputs.containsKey('roomLength'))) &&
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

  final wallArea = math.max(0, inputs['area'] ?? defaultFor(spec, 'area', 40)).toDouble();
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

Map<String, dynamic> _resolveWallpaperType(SpecReader spec, Map<String, double> inputs) {
  final wallpaperType = (inputs['wallpaperType'] ?? defaultFor(spec, 'wallpaperType', 1)).round().clamp(1, 3);
  return spec.normativeList('wallpaper_types').firstWhere(
    (type) => (type['id'] as num).toInt() == wallpaperType,
    orElse: () => spec.normativeList('wallpaper_types').first,
  );
}

double _resolveRollWidth(SpecReader spec, Map<String, double> inputs) {
  return (inputs['rollWidth'] ?? defaultFor(spec, 'rollWidth', 0.53)).clamp(0.5, 1.2).toDouble();
}

double _resolveRollLength(SpecReader spec, Map<String, double> inputs) {
  return (inputs['rollLength'] ?? defaultFor(spec, 'rollLength', 10.05)).clamp(5, 50).toDouble();
}

double _resolveRapportMeters(SpecReader spec, Map<String, double> inputs) {
  return math.max(0, inputs['rapport'] ?? defaultFor(spec, 'rapport', 0)).toDouble() / 100;
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
  final reservePercent = math.max(0, inputs['reservePercent'] ?? defaultFor(spec, 'reservePercent', 0)).toDouble();
  final reserveRolls = math.max(0, (inputs['reserveRolls'] ?? defaultFor(spec, 'reserveRolls', 0)).round());
  final wallHeight = geometry['wallHeight']!;
  final stripLength = rapport > 0
      ? (wallHeight / rapport).ceil() * rapport + spec.materialRule<num>('trim_allowance_m').toDouble()
      : wallHeight;
  final stripsPerRoll = stripLength > 0 ? math.max(0, (rollLength / stripLength).floor()) : 0;
  final netArea = geometry['netArea']!;
  final stripsNeeded = wallHeight > 0 && rollWidth > 0
      ? (netArea / (rollWidth * wallHeight)).ceil()
      : 0;
  final baseExactRolls = stripsPerRoll > 0 ? stripsNeeded / stripsPerRoll : 0.0;
  final reserveMultiplier = 1 + reservePercent / 100;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(baseExactRolls * multiplier * reserveMultiplier + reserveRolls, 6);
    final purchaseQuantity = exactNeed > 0 ? exactNeed.ceilToDouble() : 0.0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'wallpaper:${wallpaperType['key'] as String}',
        'packaging:wallpaper-roll-1',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
        'reserve_percent': roundValue(reservePercent, 3),
        'reserve_rolls': reserveRolls.toDouble(),
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
  final pasteNeeded = netArea * (wallpaperType['paste_kg_per_m2'] as num).toDouble() * spec.materialRule<num>('paste_reserve_factor').toDouble();
  final pastePacks = pasteNeeded > 0 ? math.max(1, (pasteNeeded / spec.packagingRule<num>('paste_pack_kg').toDouble()).ceil()) : 0;
  final primerNeeded = netArea * spec.materialRule<num>('primer_liters_per_m2').toDouble() * spec.materialRule<num>('primer_reserve_factor').toDouble();
  final primerCans = primerNeeded > 0 ? math.max(1, (primerNeeded / spec.packagingRule<num>('primer_can_liters').toDouble()).ceil()) : 0;

  final warnings = <String>[];
  if (netArea <= 0) {
    warnings.add('Полезная площадь оклейки должна быть больше нуля');
  }
  if (rapport > spec.warningRule<num>('large_rapport_threshold_m').toDouble()) {
    warnings.add('Большой раппорт узора увеличивает отходы. Проверьте запас по рулонам перед покупкой');
  }
  if (rollWidth > spec.warningRule<num>('wide_roll_threshold_m').toDouble()) {
    warnings.add('Широкие обои сложнее клеить одному. Для метровых рулонов лучше работать вдвоём');
  }
  if (stripsPerRoll <= spec.warningRule<num>('low_strips_per_roll_threshold').toDouble() && netArea > 0) {
    warnings.add('Из одного рулона получается мало полос. Проверьте высоту стены, длину рулона и раппорт');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: 'Обои',
        quantity: recScenario.exactNeed,
        unit: spec.packagingRule<String>('roll_unit'),
        withReserve: recScenario.purchaseQuantity,
        purchaseQty: recScenario.buyPlan.packagesCount.toDouble(),
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Клей обойный (${(wallpaperType['label'] as String).toLowerCase()}, ${spec.packagingRule<num>('paste_pack_kg').toDouble()} кг)',
        quantity: roundValue(pasteNeeded, 6),
        unit: 'кг',
        withReserve: roundValue(pastePacks * spec.packagingRule<num>('paste_pack_kg').toDouble(), 6),
        purchaseQty: (pastePacks * spec.packagingRule<num>('paste_pack_kg').toDouble()).toDouble(),
        category: 'Клей',
        packageInfo: {'count': pastePacks, 'unitSize': spec.packagingRule<num>('paste_pack_kg').toDouble(), 'packageUnit': 'упаковок'},
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка глубокого проникновения (${spec.packagingRule<num>('primer_can_liters').toInt()} л)',
        quantity: roundValue(primerNeeded, 6),
        unit: 'л',
        withReserve: roundValue(primerCans * spec.packagingRule<num>('primer_can_liters').toDouble(), 6),
        purchaseQty: (primerCans * spec.packagingRule<num>('primer_can_liters').toDouble()).toDouble(),
        category: 'Грунтовка',
        packageInfo: {'count': primerCans, 'unitSize': spec.packagingRule<num>('primer_can_liters').toDouble(), 'packageUnit': 'канистр'},
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
        withReserve: spec.materialRule<num>('wallpaper_spatula_count').toDouble(),
        purchaseQty: spec.materialRule<num>('wallpaper_spatula_count').toDouble(),
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
      'wallpaperType': (wallpaperType['id'] as num).toInt().toDouble(),
      'reservePercent': roundValue(reservePercent, 3),
      'reserveRolls': reserveRolls.toDouble(),
      'stripLength': roundValue(stripLength, 3),
      'stripsPerRoll': stripsPerRoll.toDouble(),
      'stripsNeeded': stripsNeeded.toDouble(),
      'baseExactRolls': roundValue(baseExactRolls, 6),
      'rollsNeeded': recScenario.purchaseQuantity,
      'pasteNeededKg': roundValue(pasteNeeded, 6),
      'pastePacks': pastePacks.toDouble(),
      'primerNeededL': roundValue(primerNeeded, 6),
      'primerCans': primerCans.toDouble(),
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
