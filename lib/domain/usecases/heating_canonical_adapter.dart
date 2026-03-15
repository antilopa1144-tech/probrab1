import '../models/canonical_calculator_contract.dart';

class HeatingClimateZoneSpec {
  final int id;
  final String key;
  final String label;
  final double powerPerM2;

  const HeatingClimateZoneSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.powerPerM2,
  });
}

class HeatingBuildingTypeSpec {
  final int id;
  final String key;
  final String label;
  final double coefficient;

  const HeatingBuildingTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.coefficient,
  });
}

class HeatingRadiatorTypeSpec {
  final int id;
  final String key;
  final String label;
  final double wattPerUnit;

  const HeatingRadiatorTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.wattPerUnit,
  });
}

class HeatingPackagingRules {
  final String unit;
  final double packageSize;

  const HeatingPackagingRules({
    required this.unit,
    required this.packageSize,
  });
}

class HeatingMaterialRules {
  final List<double> powerPerM2Base;
  final List<double> buildingCoeff;
  final List<double> radiatorPower;
  final double ppPipeStickM;
  final double pipeRate;
  final double pipeReserve;
  final double fittingsPerRoom;
  final double fittingsReserve;
  final double bracketsPerRoom;
  final double bracketsReserve;

  const HeatingMaterialRules({
    required this.powerPerM2Base,
    required this.buildingCoeff,
    required this.radiatorPower,
    required this.ppPipeStickM,
    required this.pipeRate,
    required this.pipeReserve,
    required this.fittingsPerRoom,
    required this.fittingsReserve,
    required this.bracketsPerRoom,
    required this.bracketsReserve,
  });
}

class HeatingWarningRules {
  final double gasBoilerPowerThresholdKw;

  const HeatingWarningRules({
    required this.gasBoilerPowerThresholdKw,
  });
}

class HeatingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<HeatingClimateZoneSpec> climateZones;
  final List<HeatingBuildingTypeSpec> buildingTypes;
  final List<HeatingRadiatorTypeSpec> radiatorTypes;
  final HeatingPackagingRules packagingRules;
  final HeatingMaterialRules materialRules;
  final HeatingWarningRules warningRules;

  const HeatingCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.climateZones,
    required this.buildingTypes,
    required this.radiatorTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

const HeatingCanonicalSpec heatingCanonicalSpecV1 = HeatingCanonicalSpec(
  calculatorId: 'heating',
  formulaVersion: 'heating-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'totalArea', unit: 'm2', defaultValue: 80, min: 10, max: 500),
    CanonicalInputField(key: 'ceilingHeight', unit: 'm', defaultValue: 2.7, min: 2.5, max: 3.5),
    CanonicalInputField(key: 'climateZone', defaultValue: 1, min: 0, max: 3),
    CanonicalInputField(key: 'buildingType', defaultValue: 1, min: 0, max: 3),
    CanonicalInputField(key: 'radiatorType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'roomCount', defaultValue: 4, min: 1, max: 20),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  climateZones: [
    HeatingClimateZoneSpec(id: 0, key: 'south', label: 'Юг (до -15\u00b0C)', powerPerM2: 80),
    HeatingClimateZoneSpec(id: 1, key: 'central', label: 'Центр (до -25\u00b0C)', powerPerM2: 100),
    HeatingClimateZoneSpec(id: 2, key: 'urals', label: 'Урал/Сибирь (до -35\u00b0C)', powerPerM2: 130),
    HeatingClimateZoneSpec(id: 3, key: 'far_north', label: 'Крайний Север (до -45\u00b0C)', powerPerM2: 150),
  ],
  buildingTypes: [
    HeatingBuildingTypeSpec(id: 0, key: 'corner_apt', label: 'Угловая квартира', coefficient: 1.3),
    HeatingBuildingTypeSpec(id: 1, key: 'mid_floor_apt', label: 'Квартира средний этаж', coefficient: 1.0),
    HeatingBuildingTypeSpec(id: 2, key: 'good_insulated', label: 'Хорошее утепление', coefficient: 1.1),
    HeatingBuildingTypeSpec(id: 3, key: 'weak_insulated', label: 'Слабое утепление', coefficient: 1.4),
  ],
  radiatorTypes: [
    HeatingRadiatorTypeSpec(id: 0, key: 'bimetallic', label: 'Биметаллический 180 Вт', wattPerUnit: 180),
    HeatingRadiatorTypeSpec(id: 1, key: 'aluminum', label: 'Алюминиевый 200 Вт', wattPerUnit: 200),
    HeatingRadiatorTypeSpec(id: 2, key: 'cast_iron_7s', label: 'Чугунный 7-секц. 700 Вт', wattPerUnit: 700),
    HeatingRadiatorTypeSpec(id: 3, key: 'panel', label: 'Панельный 700 Вт', wattPerUnit: 700),
  ],
  packagingRules: HeatingPackagingRules(
    unit: 'шт',
    packageSize: 1,
  ),
  materialRules: HeatingMaterialRules(
    powerPerM2Base: [80, 100, 130, 150],
    buildingCoeff: [1.3, 1.0, 1.1, 1.4],
    radiatorPower: [180, 200, 700, 700],
    ppPipeStickM: 4,
    pipeRate: 10,
    pipeReserve: 1.15,
    fittingsPerRoom: 6,
    fittingsReserve: 1.1,
    bracketsPerRoom: 3,
    bracketsReserve: 1.05,
  ),
  warningRules: HeatingWarningRules(
    gasBoilerPowerThresholdKw: 20,
  ),
);

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
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

double _defaultFor(HeatingCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(HeatingCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(HeatingCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

CanonicalCalculatorContractResult calculateCanonicalHeating(
  Map<String, double> inputs, {
  HeatingCanonicalSpec spec = heatingCanonicalSpecV1,
}) {
  final totalArea = (inputs['totalArea'] ?? _defaultFor(spec, 'totalArea', 80)).clamp(10.0, 500.0);
  final ceilingHeight = (inputs['ceilingHeight'] ?? _defaultFor(spec, 'ceilingHeight', 2.7)).clamp(2.5, 3.5);
  final climateZone = (inputs['climateZone'] ?? _defaultFor(spec, 'climateZone', 1)).round().clamp(0, 3);
  final buildingType = (inputs['buildingType'] ?? _defaultFor(spec, 'buildingType', 1)).round().clamp(0, 3);
  final radiatorType = (inputs['radiatorType'] ?? _defaultFor(spec, 'radiatorType', 0)).round().clamp(0, 3);
  final roomCount = (inputs['roomCount'] ?? _defaultFor(spec, 'roomCount', 4)).round().clamp(1, 20);

  /* ─── power calculation ─── */
  final heightM = ceilingHeight;
  final heightCoeff = heightM / 2.7;
  final totalPowerW = totalArea * spec.materialRules.powerPerM2Base[climateZone] * spec.materialRules.buildingCoeff[buildingType] * heightCoeff;
  final totalPowerKW = (totalPowerW / 100).round() / 10;

  /* ─── radiator calculation ─── */
  final wattPerUnit = spec.materialRules.radiatorPower[radiatorType];
  final totalUnits = (totalPowerW / wattPerUnit).ceil();

  /* ─── piping ─── */
  final pipeSticks = (roomCount * spec.materialRules.pipeRate * spec.materialRules.pipeReserve / spec.materialRules.ppPipeStickM).ceil();
  final fittings = (roomCount * spec.materialRules.fittingsPerRoom * spec.materialRules.fittingsReserve).ceil();
  final brackets = (roomCount * spec.materialRules.bracketsPerRoom * spec.materialRules.bracketsReserve).ceil();
  final thermoHeads = (roomCount * 1.05).ceil();
  final mayevskyValves = (roomCount * 1.1).ceil();

  /* ─── materials ─── */
  final radiatorLabel = radiatorType <= 1 ? 'Радиаторы (секции)' : 'Радиаторы (панели/приборы)';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: radiatorLabel,
      quantity: totalUnits.toDouble(),
      unit: 'шт',
      withReserve: totalUnits.toDouble(),
      purchaseQty: totalUnits,
      category: 'Отопление',
    ),
    CanonicalMaterialResult(
      name: 'Труба ПП \u00f825 (палки по 4 м)',
      quantity: pipeSticks.toDouble(),
      unit: 'шт',
      withReserve: pipeSticks.toDouble(),
      purchaseQty: pipeSticks,
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Фитинги',
      quantity: fittings.toDouble(),
      unit: 'шт',
      withReserve: fittings.toDouble(),
      purchaseQty: fittings,
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Кронштейны',
      quantity: brackets.toDouble(),
      unit: 'шт',
      withReserve: brackets.toDouble(),
      purchaseQty: brackets,
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Термоголовки',
      quantity: thermoHeads.toDouble(),
      unit: 'шт',
      withReserve: thermoHeads.toDouble(),
      purchaseQty: thermoHeads,
      category: 'Регулировка',
    ),
    CanonicalMaterialResult(
      name: 'Краны Маевского',
      quantity: mayevskyValves.toDouble(),
      unit: 'шт',
      withReserve: mayevskyValves.toDouble(),
      purchaseQty: mayevskyValves,
      category: 'Арматура',
    ),
  ];

  /* ─── scenarios ─── */
  final basePrimary = totalUnits.toDouble();
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
        'climateZone:$climateZone',
        'buildingType:$buildingType',
        'radiatorType:$radiatorType',
        'packaging:radiator-unit',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'radiator-unit',
        packageSize: 1,
        packagesCount: packageCount,
        unit: 'шт',
      ),
    );
  }

  final recScenario = scenarios['REC']!;

  /* ─── warnings ─── */
  final warnings = <String>[];
  if (totalPowerKW > spec.warningRules.gasBoilerPowerThresholdKw) {
    warnings.add('Мощность более 20 кВт \u2014 газовый котёл с запасом 15-20%');
  }
  if (buildingType >= 2 && climateZone >= 2) {
    warnings.add('Слабая изоляция + холодная зона \u2014 рекомендуется профессиональный теплотехнический расчёт');
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'totalArea': _roundValue(totalArea, 3),
      'ceilingHeight': _roundValue(ceilingHeight, 3),
      'climateZone': climateZone.toDouble(),
      'buildingType': buildingType.toDouble(),
      'radiatorType': radiatorType.toDouble(),
      'roomCount': roomCount.toDouble(),
      'heightCoeff': _roundValue(heightCoeff, 4),
      'totalPowerW': _roundValue(totalPowerW, 1),
      'totalPowerKW': totalPowerKW,
      'wattPerUnit': wattPerUnit,
      'totalUnits': totalUnits.toDouble(),
      'pipeSticks': pipeSticks.toDouble(),
      'fittings': fittings.toDouble(),
      'brackets': brackets.toDouble(),
      'thermoHeads': thermoHeads.toDouble(),
      'mayevskyValves': mayevskyValves.toDouble(),
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
