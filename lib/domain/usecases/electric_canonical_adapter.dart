import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

class ElectricWiringTypeSpec {
  final int id;
  final String key;
  final String label;

  const ElectricWiringTypeSpec({
    required this.id,
    required this.key,
    required this.label,
  });
}

class ElectricPackagingRules {
  final double cableSpoolM;
  final String unit;

  const ElectricPackagingRules({
    required this.cableSpoolM,
    required this.unit,
  });
}

class ElectricMaterialRules {
  final double cable15Rate;
  final double cable25Rate;
  final double cable6KitchenFactor;
  final double cable6Reserve;
  final double conduitRatio;
  final double outletsPerM2;
  final int outletsPerRoom;
  final int switchesBase;
  final double cableSpoolM;
  final double socketBoxReserve;
  final int acGroupsDivisor;

  const ElectricMaterialRules({
    required this.cable15Rate,
    required this.cable25Rate,
    required this.cable6KitchenFactor,
    required this.cable6Reserve,
    required this.conduitRatio,
    required this.outletsPerM2,
    required this.outletsPerRoom,
    required this.switchesBase,
    required this.cableSpoolM,
    required this.socketBoxReserve,
    required this.acGroupsDivisor,
  });
}

class ElectricWarningRules {
  final double threePhaseAreaThreshold;

  const ElectricWarningRules({
    required this.threePhaseAreaThreshold,
  });
}

class ElectricCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<ElectricWiringTypeSpec> wiringTypes;
  final ElectricPackagingRules packagingRules;
  final ElectricMaterialRules materialRules;
  final ElectricWarningRules warningRules;

  const ElectricCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.wiringTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const ElectricCanonicalSpec electricCanonicalSpecV1 = ElectricCanonicalSpec(
  calculatorId: 'electric',
  formulaVersion: 'electric-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'apartmentArea', unit: 'm2', defaultValue: 60, min: 20, max: 500),
    CanonicalInputField(key: 'roomsCount', defaultValue: 3, min: 1, max: 10),
    CanonicalInputField(key: 'ceilingHeight', unit: 'm', defaultValue: 2.7, min: 2.4, max: 4.0),
    CanonicalInputField(key: 'wiringType', defaultValue: 0, min: 0, max: 1),
    CanonicalInputField(key: 'hasKitchen', defaultValue: 1, min: 0, max: 1),
    CanonicalInputField(key: 'reserve', unit: '%', defaultValue: 15, min: 5, max: 30),
  ],
  enabledFactors: ['geometry_complexity', 'installation_method', 'worker_skill', 'waste_factor'],
  wiringTypes: [
    ElectricWiringTypeSpec(id: 0, key: 'hidden', label: 'Скрытая проводка'),
    ElectricWiringTypeSpec(id: 1, key: 'open', label: 'Открытая проводка'),
  ],
  packagingRules: ElectricPackagingRules(
    cableSpoolM: 50,
    unit: 'бухт',
  ),
  materialRules: ElectricMaterialRules(
    cable15Rate: 1.1,
    cable25Rate: 1.6,
    cable6KitchenFactor: 1.5,
    cable6Reserve: 1.2,
    conduitRatio: 0.8,
    outletsPerM2: 0.6,
    outletsPerRoom: 2,
    switchesBase: 2,
    cableSpoolM: 50,
    socketBoxReserve: 1.1,
    acGroupsDivisor: 2,
  ),
  warningRules: ElectricWarningRules(
    threePhaseAreaThreshold: 100,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'installation_method': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.05},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.05},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(ElectricCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(ElectricCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(ElectricCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalElectric(
  Map<String, double> inputs, {
  ElectricCanonicalSpec spec = electricCanonicalSpecV1,
}) {
  final apartmentArea = (inputs['apartmentArea'] ?? _defaultFor(spec, 'apartmentArea', 60)).clamp(20.0, 500.0);
  final roomsCount = (inputs['roomsCount'] ?? _defaultFor(spec, 'roomsCount', 3)).round().clamp(1, 10);
  final ceilingHeight = (inputs['ceilingHeight'] ?? _defaultFor(spec, 'ceilingHeight', 2.7)).clamp(2.4, 4.0);
  final wiringType = (inputs['wiringType'] ?? _defaultFor(spec, 'wiringType', 0)).round().clamp(0, 1);
  final hasKitchen = (inputs['hasKitchen'] ?? _defaultFor(spec, 'hasKitchen', 1)).round().clamp(0, 1);
  final reserve = (inputs['reserve'] ?? _defaultFor(spec, 'reserve', 15)).clamp(5.0, 30.0);

  /* ─── groups ─── */
  final lightingGroups = roomsCount + 1;
  final outletGroups = roomsCount + 2;
  final acGroups = (roomsCount / spec.materialRules.acGroupsDivisor).ceil();
  final breakersCount = lightingGroups + outletGroups + acGroups + (hasKitchen == 1 ? 1 : 0);
  final uzoCount = (outletGroups / 2).ceil() + (hasKitchen == 1 ? 1 : 0) + 1;

  /* ─── cable lengths ─── */
  final cable15length = (apartmentArea * spec.materialRules.cable15Rate + lightingGroups * ceilingHeight) * (1 + reserve / 100);
  final cable25length = (apartmentArea * spec.materialRules.cable25Rate + outletGroups * ceilingHeight * 1.5) * (1 + reserve / 100);
  final cable6length = hasKitchen == 1
      ? (math.sqrt(apartmentArea) * spec.materialRules.cable6KitchenFactor + ceilingHeight) * spec.materialRules.cable6Reserve
      : 0.0;
  final conduitLength = ((cable15length + cable25length + cable6length) * spec.materialRules.conduitRatio).ceil();

  /* ─── outlets & switches ─── */
  final outletsCount = (apartmentArea * spec.materialRules.outletsPerM2).ceil() + roomsCount * spec.materialRules.outletsPerRoom;
  final switchesCount = roomsCount + spec.materialRules.switchesBase;

  /* ─── packaging ─── */
  final cable15spools = (cable15length / spec.materialRules.cableSpoolM).ceil();
  final cable25spools = (cable25length / spec.materialRules.cableSpoolM).ceil();
  final conduitPacks = (conduitLength / spec.materialRules.cableSpoolM).ceil();
  final socketBoxes = ((outletsCount + switchesCount) * spec.materialRules.socketBoxReserve).ceil();
  final gypsumKg = ((outletsCount + switchesCount) / 5).ceil();

  /* ─── materials ─── */
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Кабель ВВГнг 3\u00d71.5',
      quantity: _roundValue(cable15length, 1),
      unit: 'м',
      withReserve: _roundValue(cable15length, 1),
      purchaseQty: (cable15spools * spec.materialRules.cableSpoolM).round(),
      category: 'Кабель',
    ),
    CanonicalMaterialResult(
      name: 'Кабель ВВГнг 3\u00d72.5',
      quantity: _roundValue(cable25length, 1),
      unit: 'м',
      withReserve: _roundValue(cable25length, 1),
      purchaseQty: (cable25spools * spec.materialRules.cableSpoolM).round(),
      category: 'Кабель',
    ),
  ];

  if (hasKitchen == 1 && cable6length > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Кабель ВВГнг 3\u00d76',
      quantity: _roundValue(cable6length, 1),
      unit: 'м',
      withReserve: _roundValue(cable6length, 1),
      purchaseQty: cable6length.ceil(),
      category: 'Кабель',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Щиток (модулей)',
      quantity: (breakersCount + uzoCount + 2).toDouble(),
      unit: 'шт',
      withReserve: (breakersCount + uzoCount + 2).toDouble(),
      purchaseQty: 1,
      category: 'Щиток',
    ),
    CanonicalMaterialResult(
      name: 'Автоматы',
      quantity: breakersCount.toDouble(),
      unit: 'шт',
      withReserve: breakersCount.toDouble(),
      purchaseQty: breakersCount,
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name: 'УЗО/дифавтоматы',
      quantity: uzoCount.toDouble(),
      unit: 'шт',
      withReserve: uzoCount.toDouble(),
      purchaseQty: uzoCount,
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name: 'Розетки',
      quantity: outletsCount.toDouble(),
      unit: 'шт',
      withReserve: outletsCount.toDouble(),
      purchaseQty: outletsCount,
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Выключатели',
      quantity: switchesCount.toDouble(),
      unit: 'шт',
      withReserve: switchesCount.toDouble(),
      purchaseQty: switchesCount,
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Подрозетники',
      quantity: socketBoxes.toDouble(),
      unit: 'шт',
      withReserve: socketBoxes.toDouble(),
      purchaseQty: socketBoxes,
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Гофра/кабель-канал',
      quantity: conduitLength.toDouble(),
      unit: 'м',
      withReserve: conduitLength.toDouble(),
      purchaseQty: (conduitPacks * spec.materialRules.cableSpoolM).round(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Гипс/алебастр',
      quantity: gypsumKg.toDouble(),
      unit: 'кг',
      withReserve: gypsumKg.toDouble(),
      purchaseQty: gypsumKg,
      category: 'Монтаж',
    ),
  ]);

  /* ─── scenarios ─── */
  final basePrimary = (cable15spools + cable25spools).toDouble();
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    final purchaseQuantity = _roundValue(packageCount.toDouble(), 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: _roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'wiringType:$wiringType',
        'reserve:$reserve',
        'packaging:electric-cable-spool',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'electric-cable-spool',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'бухт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (apartmentArea > spec.warningRules.threePhaseAreaThreshold) {
    warnings.add('Площадь более 100 м\u00b2 \u2014 рекомендуется ввод 380В (3 фазы)');
  }
  if (hasKitchen == 1) {
    warnings.add('Кухня: кабель 3\u00d76 мм\u00b2, автомат 32А, УЗО 40А/30мА');
  }
  warnings.add('Все розетки в ванной и кухне \u2014 через УЗО 10-30 мА');

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'apartmentArea': _roundValue(apartmentArea, 3),
      'roomsCount': roomsCount.toDouble(),
      'ceilingHeight': _roundValue(ceilingHeight, 3),
      'wiringType': wiringType.toDouble(),
      'hasKitchen': hasKitchen.toDouble(),
      'reserve': reserve,
      'lightingGroups': lightingGroups.toDouble(),
      'outletGroups': outletGroups.toDouble(),
      'acGroups': acGroups.toDouble(),
      'breakersCount': breakersCount.toDouble(),
      'uzoCount': uzoCount.toDouble(),
      'cable15length': _roundValue(cable15length, 1),
      'cable25length': _roundValue(cable25length, 1),
      'cable6length': _roundValue(cable6length, 1),
      'conduitLength': conduitLength.toDouble(),
      'outletsCount': outletsCount.toDouble(),
      'switchesCount': switchesCount.toDouble(),
      'cable15spools': cable15spools.toDouble(),
      'cable25spools': cable25spools.toDouble(),
      'conduitPacks': conduitPacks.toDouble(),
      'socketBoxes': socketBoxes.toDouble(),
      'gypsumKg': gypsumKg.toDouble(),
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
