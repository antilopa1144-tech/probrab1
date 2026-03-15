import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

const WallpaperCanonicalSpec wallpaperCanonicalSpecV1 = WallpaperCanonicalSpec(
  calculatorId: 'wallpaper',
  formulaVersion: 'wallpaper-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'inputMode', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'perimeter', unit: 'm', defaultValue: 14, min: 1, max: 200),
    CanonicalInputField(key: 'area', unit: 'm2', defaultValue: 40, min: 0, max: 1000),
    CanonicalInputField(key: 'roomWidth', unit: 'm', defaultValue: 4, min: 1, max: 50),
    CanonicalInputField(key: 'roomLength', unit: 'm', defaultValue: 5, min: 1, max: 50),
    CanonicalInputField(key: 'roomHeight', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'length', unit: 'm', defaultValue: 5, min: 1, max: 50),
    CanonicalInputField(key: 'width', unit: 'm', defaultValue: 4, min: 1, max: 50),
    CanonicalInputField(key: 'height', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'wallHeight', unit: 'm', defaultValue: 2.7, min: 2, max: 5),
    CanonicalInputField(key: 'openingsArea', unit: 'm2', defaultValue: 0, min: 0, max: 500),
    CanonicalInputField(key: 'doorsCount', defaultValue: 0, min: 0, max: 20),
    CanonicalInputField(key: 'windowsCount', defaultValue: 0, min: 0, max: 20),
    CanonicalInputField(key: 'rollWidth', unit: 'm', defaultValue: 0.53, min: 0.5, max: 1.2),
    CanonicalInputField(key: 'rollLength', unit: 'm', defaultValue: 10.05, min: 5, max: 50),
    CanonicalInputField(key: 'rapport', unit: 'cm', defaultValue: 0, min: 0, max: 100),
    CanonicalInputField(key: 'wallpaperType', defaultValue: 1, min: 1, max: 3),
    CanonicalInputField(key: 'reservePercent', defaultValue: 0, min: 0, max: 100),
    CanonicalInputField(key: 'reserveRolls', defaultValue: 0, min: 0, max: 10),
  ],
  enabledFactors: ['surface_quality', 'geometry_complexity', 'installation_method', 'worker_skill'],
  wallpaperTypes: [
    WallpaperTypeSpec(id: 1, key: 'paper', label: 'Бумажные обои', pasteKgPerM2: 0.005),
    WallpaperTypeSpec(id: 2, key: 'vinyl', label: 'Виниловые обои', pasteKgPerM2: 0.01),
    WallpaperTypeSpec(id: 3, key: 'fleece', label: 'Флизелиновые обои', pasteKgPerM2: 0.008),
  ],
  openingDefaults: WallpaperOpeningDefaultsSpec(doorAreaM2: 1.71, windowAreaM2: 1.68),
  packagingRules: WallpaperPackagingRules(
    rollUnit: 'рулонов',
    rollPackageSize: 1,
    pastePackKg: 0.25,
    primerCanLiters: 5,
  ),
  materialRules: WallpaperMaterialRules(
    trimAllowanceM: 0.05,
    primerLitersPerM2: 0.15,
    primerReserveFactor: 1.1,
    pasteReserveFactor: 1.1,
    glueRollerCount: 1,
    wallpaperSpatulaCount: 1,
    knifeCount: 1,
    bladesPackCount: 1,
    bucketCount: 1,
    spongeCount: 2,
  ),
  warningRules: WallpaperWarningRules(
    largeRapportThresholdM: 0.32,
    wideRollThresholdM: 0.7,
    lowStripsPerRollThreshold: 2,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'surface_quality': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.08},
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

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

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(WallpaperCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _resolveGeometry(WallpaperCanonicalSpec spec, Map<String, double> inputs) {
  final inputMode = (inputs['inputMode'] ?? _defaultFor(spec, 'inputMode', 0)).round();
  final wallHeight = (inputs['wallHeight'] ?? inputs['height'] ?? inputs['roomHeight'] ?? _defaultFor(spec, 'wallHeight', 2.7))
      .clamp(2, 5)
      .toDouble();
  final exactOpeningsArea = math.max(0, inputs['openingsArea'] ?? 0).toDouble();
  final doorsCount = math.max(0, (inputs['doorsCount'] ?? inputs['doors'] ?? 0).round());
  final windowsCount = math.max(0, (inputs['windowsCount'] ?? inputs['windows'] ?? 0).round());
  final defaultOpeningsArea =
      doorsCount * spec.openingDefaults.doorAreaM2 +
      windowsCount * spec.openingDefaults.windowAreaM2;
  final openingsArea = (exactOpeningsArea > 0 ? exactOpeningsArea : defaultOpeningsArea).toDouble();

  if ((inputMode == 0 || (!inputs.containsKey('inputMode') && inputs.containsKey('perimeter'))) &&
      inputs.containsKey('perimeter')) {
    final perimeter = math.max(1, inputs['perimeter'] ?? 0).toDouble();
    final wallArea = perimeter * wallHeight;
    return {
      'inputMode': 0.0,
      'perimeter': _roundValue(perimeter, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'wallArea': _roundValue(wallArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'netArea': _roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
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
      'perimeter': _roundValue(perimeter, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'wallArea': _roundValue(wallArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'netArea': _roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
    };
  }

  if (inputs.containsKey('length') && inputs.containsKey('width')) {
    final length = math.max(1, inputs['length'] ?? 0).toDouble();
    final width = math.max(1, inputs['width'] ?? 0).toDouble();
    final perimeter = 2 * (length + width);
    final wallArea = perimeter * wallHeight;
    return {
      'inputMode': 0.0,
      'perimeter': _roundValue(perimeter, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'wallArea': _roundValue(wallArea, 3),
      'openingsArea': _roundValue(openingsArea, 3),
      'netArea': _roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
    };
  }

  final wallArea = math.max(0, inputs['area'] ?? _defaultFor(spec, 'area', 40)).toDouble();
  final perimeter = wallHeight > 0 ? wallArea / wallHeight : 0.0;
  return {
    'inputMode': 1.0,
    'perimeter': _roundValue(perimeter, 3),
    'wallHeight': _roundValue(wallHeight, 3),
    'wallArea': _roundValue(wallArea, 3),
    'openingsArea': _roundValue(openingsArea, 3),
    'netArea': _roundValue(math.max(0, wallArea - openingsArea).toDouble(), 3),
  };
}

WallpaperTypeSpec _resolveWallpaperType(WallpaperCanonicalSpec spec, Map<String, double> inputs) {
  final wallpaperType = (inputs['wallpaperType'] ?? _defaultFor(spec, 'wallpaperType', 1)).round().clamp(1, 3);
  return spec.wallpaperTypes.firstWhere(
    (type) => type.id == wallpaperType,
    orElse: () => spec.wallpaperTypes.first,
  );
}

double _resolveRollWidth(WallpaperCanonicalSpec spec, Map<String, double> inputs) {
  return (inputs['rollWidth'] ?? _defaultFor(spec, 'rollWidth', 0.53)).clamp(0.5, 1.2).toDouble();
}

double _resolveRollLength(WallpaperCanonicalSpec spec, Map<String, double> inputs) {
  return (inputs['rollLength'] ?? _defaultFor(spec, 'rollLength', 10.05)).clamp(5, 50).toDouble();
}

double _resolveRapportMeters(WallpaperCanonicalSpec spec, Map<String, double> inputs) {
  return math.max(0, inputs['rapport'] ?? _defaultFor(spec, 'rapport', 0)).toDouble() / 100;
}

Map<String, double> _keyFactors(WallpaperCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(WallpaperCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalWallpaper(
  Map<String, double> inputs, {
  WallpaperCanonicalSpec spec = wallpaperCanonicalSpecV1,
}) {
  final geometry = _resolveGeometry(spec, inputs);
  final wallpaperType = _resolveWallpaperType(spec, inputs);
  final rollWidth = _resolveRollWidth(spec, inputs);
  final rollLength = _resolveRollLength(spec, inputs);
  final rapport = _resolveRapportMeters(spec, inputs);
  final reservePercent = math.max(0, inputs['reservePercent'] ?? _defaultFor(spec, 'reservePercent', 0)).toDouble();
  final reserveRolls = math.max(0, (inputs['reserveRolls'] ?? _defaultFor(spec, 'reserveRolls', 0)).round());
  final wallHeight = geometry['wallHeight']!;
  final stripLength = rapport > 0
      ? (wallHeight / rapport).ceil() * rapport + spec.materialRules.trimAllowanceM
      : wallHeight;
  final stripsPerRoll = stripLength > 0 ? math.max(0, (rollLength / stripLength).floor()) : 0;
  final netArea = geometry['netArea']!;
  final stripsNeeded = wallHeight > 0 && rollWidth > 0
      ? (netArea / (rollWidth * wallHeight)).ceil()
      : 0;
  final baseExactRolls = stripsPerRoll > 0 ? stripsNeeded / stripsPerRoll : 0.0;
  final reserveMultiplier = 1 + reservePercent / 100;
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(baseExactRolls * multiplier * reserveMultiplier + reserveRolls, 6);
    final purchaseQuantity = exactNeed > 0 ? exactNeed.ceilToDouble() : 0.0;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'wallpaper:${wallpaperType.key}',
        'packaging:wallpaper-roll-1',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
        'reserve_percent': _roundValue(reservePercent, 3),
        'reserve_rolls': reserveRolls.toDouble(),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'wallpaper-roll-1',
        packageSize: 1,
        packagesCount: purchaseQuantity.toInt(),
        unit: spec.packagingRules.rollUnit,
      ),
    );
  }

  final recScenario = scenarios['REC']!;
  final pasteNeeded = netArea * wallpaperType.pasteKgPerM2 * spec.materialRules.pasteReserveFactor;
  final pastePacks = pasteNeeded > 0 ? math.max(1, (pasteNeeded / spec.packagingRules.pastePackKg).ceil()) : 0;
  final primerNeeded = netArea * spec.materialRules.primerLitersPerM2 * spec.materialRules.primerReserveFactor;
  final primerCans = primerNeeded > 0 ? math.max(1, (primerNeeded / spec.packagingRules.primerCanLiters).ceil()) : 0;

  final warnings = <String>[];
  if (netArea <= 0) {
    warnings.add('Полезная площадь оклейки должна быть больше нуля');
  }
  if (rapport > spec.warningRules.largeRapportThresholdM) {
    warnings.add('Большой раппорт узора увеличивает отходы. Проверьте запас по рулонам перед покупкой');
  }
  if (rollWidth > spec.warningRules.wideRollThresholdM) {
    warnings.add('Широкие обои сложнее клеить одному. Для метровых рулонов лучше работать вдвоём');
  }
  if (stripsPerRoll <= spec.warningRules.lowStripsPerRollThreshold && netArea > 0) {
    warnings.add('Из одного рулона получается мало полос. Проверьте высоту стены, длину рулона и раппорт');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: [
      CanonicalMaterialResult(
        name: 'Обои',
        quantity: recScenario.exactNeed,
        unit: spec.packagingRules.rollUnit,
        withReserve: recScenario.purchaseQuantity,
        purchaseQty: recScenario.buyPlan.packagesCount,
        category: 'Основное',
      ),
      CanonicalMaterialResult(
        name: 'Клей обойный (${wallpaperType.label.toLowerCase()}, ${spec.packagingRules.pastePackKg} кг)',
        quantity: _roundValue(pasteNeeded, 6),
        unit: 'кг',
        withReserve: _roundValue(pastePacks * spec.packagingRules.pastePackKg, 6),
        purchaseQty: pastePacks,
        category: 'Клей',
      ),
      CanonicalMaterialResult(
        name: 'Грунтовка глубокого проникновения (${spec.packagingRules.primerCanLiters.toInt()} л)',
        quantity: _roundValue(primerNeeded, 6),
        unit: 'л',
        withReserve: _roundValue(primerCans * spec.packagingRules.primerCanLiters, 6),
        purchaseQty: primerCans,
        category: 'Грунтовка',
      ),
      CanonicalMaterialResult(
        name: 'Валик для клея',
        quantity: spec.materialRules.glueRollerCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.glueRollerCount.toDouble(),
        purchaseQty: spec.materialRules.glueRollerCount,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Пластиковый шпатель для обоев',
        quantity: spec.materialRules.wallpaperSpatulaCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.wallpaperSpatulaCount.toDouble(),
        purchaseQty: spec.materialRules.wallpaperSpatulaCount,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Нож малярный',
        quantity: spec.materialRules.knifeCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.knifeCount.toDouble(),
        purchaseQty: spec.materialRules.knifeCount,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Лезвия для ножа (упаковка)',
        quantity: spec.materialRules.bladesPackCount.toDouble(),
        unit: 'уп',
        withReserve: spec.materialRules.bladesPackCount.toDouble(),
        purchaseQty: spec.materialRules.bladesPackCount,
        category: 'Расходники',
      ),
      CanonicalMaterialResult(
        name: 'Ведро для клея',
        quantity: spec.materialRules.bucketCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.bucketCount.toDouble(),
        purchaseQty: spec.materialRules.bucketCount,
        category: 'Инструмент',
      ),
      CanonicalMaterialResult(
        name: 'Губка для удаления клея',
        quantity: spec.materialRules.spongeCount.toDouble(),
        unit: 'шт',
        withReserve: spec.materialRules.spongeCount.toDouble(),
        purchaseQty: spec.materialRules.spongeCount,
        category: 'Расходники',
      ),
    ],
    totals: {
      'wallArea': _roundValue(geometry['wallArea']!, 3),
      'netArea': _roundValue(netArea, 3),
      'openingsArea': _roundValue(geometry['openingsArea']!, 3),
      'perimeter': _roundValue(geometry['perimeter']!, 3),
      'wallHeight': _roundValue(wallHeight, 3),
      'inputMode': geometry['inputMode']!,
      'rollWidth': _roundValue(rollWidth, 3),
      'rollLength': _roundValue(rollLength, 3),
      'rapport': _roundValue(rapport * 100, 3),
      'wallpaperType': wallpaperType.id.toDouble(),
      'reservePercent': _roundValue(reservePercent, 3),
      'reserveRolls': reserveRolls.toDouble(),
      'stripLength': _roundValue(stripLength, 3),
      'stripsPerRoll': stripsPerRoll.toDouble(),
      'stripsNeeded': stripsNeeded.toDouble(),
      'baseExactRolls': _roundValue(baseExactRolls, 6),
      'rollsNeeded': recScenario.purchaseQuantity,
      'pasteNeededKg': _roundValue(pasteNeeded, 6),
      'pastePacks': pastePacks.toDouble(),
      'primerNeededL': _roundValue(primerNeeded, 6),
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
