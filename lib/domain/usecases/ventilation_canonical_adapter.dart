import 'dart:math' as math;

import '../models/canonical_calculator_contract.dart';

/* ─── spec types ─── */

class VentilationPackagingRules {
  final String unit;
  final int packageSize;

  const VentilationPackagingRules({required this.unit, required this.packageSize});
}

class VentilationMaterialRules {
  final List<double> exchangeRates;
  final double airPerPerson;
  final double fanReserve;
  final int airflowRounding;
  final double mainDuctLengthCoeff;
  final double mainDuctReserve;
  final int ductSectionM;
  final int flexDuctCoilM;
  final double fittingsPerSection;
  final double fittingsReserve;
  final double grilleAreaM2;
  final int grilleBase;
  final int clampsPerSection;
  final double clampsReserve;
  final int silencerCount;

  const VentilationMaterialRules({
    required this.exchangeRates,
    required this.airPerPerson,
    required this.fanReserve,
    required this.airflowRounding,
    required this.mainDuctLengthCoeff,
    required this.mainDuctReserve,
    required this.ductSectionM,
    required this.flexDuctCoilM,
    required this.fittingsPerSection,
    required this.fittingsReserve,
    required this.grilleAreaM2,
    required this.grilleBase,
    required this.clampsPerSection,
    required this.clampsReserve,
    required this.silencerCount,
  });
}

class VentilationWarningRules {
  final double professionalAirflowThreshold;
  final int supplyExhaustPeopleThreshold;

  const VentilationWarningRules({
    required this.professionalAirflowThreshold,
    required this.supplyExhaustPeopleThreshold,
  });
}

class VentilationCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final VentilationPackagingRules packagingRules;
  final VentilationMaterialRules materialRules;
  final VentilationWarningRules warningRules;

  const VentilationCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── spec instance ─── */

const VentilationCanonicalSpec ventilationCanonicalSpecV1 = VentilationCanonicalSpec(
  calculatorId: 'ventilation',
  formulaVersion: 'ventilation-canonical-v1',
  inputSchema: [
    CanonicalInputField(key: 'totalArea', unit: 'm2', defaultValue: 80, min: 10, max: 1000),
    CanonicalInputField(key: 'ceilingHeight', unit: 'm', defaultValue: 2.7, min: 2.5, max: 3.5),
    CanonicalInputField(key: 'buildingType', defaultValue: 0, min: 0, max: 3),
    CanonicalInputField(key: 'peopleCount', defaultValue: 3, min: 1, max: 50),
    CanonicalInputField(key: 'ductType', defaultValue: 0, min: 0, max: 2),
  ],
  enabledFactors: ['geometry_complexity', 'worker_skill', 'waste_factor'],
  packagingRules: VentilationPackagingRules(unit: 'секций', packageSize: 1),
  materialRules: VentilationMaterialRules(
    exchangeRates: [1.5, 2.0, 3.0, 5.0],
    airPerPerson: 30,
    fanReserve: 1.2,
    airflowRounding: 50,
    mainDuctLengthCoeff: 2.5,
    mainDuctReserve: 1.15,
    ductSectionM: 3,
    flexDuctCoilM: 10,
    fittingsPerSection: 0.5,
    fittingsReserve: 1.1,
    grilleAreaM2: 15,
    grilleBase: 1,
    clampsPerSection: 2,
    clampsReserve: 1.1,
    silencerCount: 1,
  ),
  warningRules: VentilationWarningRules(
    professionalAirflowThreshold: 2000,
    supplyExhaustPeopleThreshold: 6,
  ),
);

/* ─── factor table ─── */

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.12},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.98, 'REC': 1.0, 'MAX': 1.08},
};

const List<String> _scenarioNames = ['MIN', 'REC', 'MAX'];


const Map<int, String> _ductTypeLabels = {
  0: 'Круглый ø100–160',
  1: 'Прямоугольный 200×100',
  2: 'Гибкий ø125',
};

/* ─── helpers ─── */

bool hasCanonicalVentilationInputs(Map<String, double> inputs) {
  return inputs.containsKey('buildingType') ||
      inputs.containsKey('ductType') ||
      inputs.containsKey('ceilingHeight');
}

Map<String, double> normalizeLegacyVentilationInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  normalized['totalArea'] = (inputs['totalArea'] ?? 80).toDouble();
  normalized['ceilingHeight'] = (inputs['ceilingHeight'] ?? 2.7).toDouble();
  normalized['buildingType'] = (inputs['buildingType'] ?? 0).toDouble();
  normalized['peopleCount'] = (inputs['peopleCount'] ?? 3).toDouble();
  normalized['ductType'] = (inputs['ductType'] ?? 0).toDouble();
  return normalized;
}

double _roundValue(double value, int decimals) {
  var scale = 1.0;
  for (var index = 0; index < decimals; index++) {
    scale *= 10;
  }
  return (value * scale).round() / scale;
}

double _defaultFor(VentilationCanonicalSpec spec, String key, double fallback) {
  for (final field in spec.inputSchema) {
    if (field.key == key) return field.defaultValue;
  }
  return fallback;
}

Map<String, double> _keyFactors(VentilationCanonicalSpec spec, String scenario) {
  final keyFactors = <String, double>{};
  for (final factorName in spec.enabledFactors) {
    keyFactors[factorName] = _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return keyFactors;
}

double _scenarioMultiplier(VentilationCanonicalSpec spec, String scenario) {
  var multiplier = 1.0;
  for (final factorName in spec.enabledFactors) {
    multiplier *= _factorTable[factorName]?[scenario] ?? 1.0;
  }
  return multiplier;
}

/* ─── main ─── */

CanonicalCalculatorContractResult calculateCanonicalVentilation(
  Map<String, double> inputs, {
  VentilationCanonicalSpec spec = ventilationCanonicalSpecV1,
}) {
  final normalized = hasCanonicalVentilationInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyVentilationInputs(inputs);

  final totalArea = math.max(10.0, math.min(1000.0, (normalized['totalArea'] ?? _defaultFor(spec, 'totalArea', 80)).toDouble()));
  final ceilingHeight = math.max(2.5, math.min(3.5, (normalized['ceilingHeight'] ?? _defaultFor(spec, 'ceilingHeight', 2.7)).toDouble()));
  final buildingType = (normalized['buildingType'] ?? _defaultFor(spec, 'buildingType', 0)).round().clamp(0, 3);
  final peopleCount = (normalized['peopleCount'] ?? _defaultFor(spec, 'peopleCount', 3)).round().clamp(1, 50);
  final ductType = (normalized['ductType'] ?? _defaultFor(spec, 'ductType', 0)).round().clamp(0, 2);

  // Airflow calculation
  final volume = totalArea * ceilingHeight;
  final airByVolume = volume * spec.materialRules.exchangeRates[buildingType];
  final airByPeople = peopleCount * spec.materialRules.airPerPerson;
  final requiredAirflow = math.max(airByVolume, airByPeople);
  final requiredAirflowRounded = (requiredAirflow / spec.materialRules.airflowRounding).ceil() * spec.materialRules.airflowRounding;

  // Fan
  final fanCapacity = (requiredAirflowRounded * spec.materialRules.fanReserve / spec.materialRules.airflowRounding).ceil() * spec.materialRules.airflowRounding;
  final fanDiameter = fanCapacity <= 300 ? 100 : fanCapacity <= 500 ? 125 : fanCapacity <= 800 ? 150 : 200;

  // Duct length
  final mainDuctLength = math.sqrt(totalArea) * spec.materialRules.mainDuctLengthCoeff * spec.materialRules.mainDuctReserve;

  // Duct sections / coils
  var ductSections = 0;
  var ductCoils = 0;

  if (ductType <= 1) {
    ductSections = (mainDuctLength / spec.materialRules.ductSectionM).ceil();
  } else {
    ductCoils = (mainDuctLength / spec.materialRules.flexDuctCoilM).ceil();
  }

  // Fittings
  final fittingsBase = ductType <= 1 ? ductSections : ductCoils;
  final fittings = (fittingsBase * spec.materialRules.fittingsPerSection * spec.materialRules.fittingsReserve).ceil();

  // Grilles
  final grilles = (totalArea / spec.materialRules.grilleAreaM2).ceil() + spec.materialRules.grilleBase;

  // Clamps
  final clampsBase = ductType <= 1 ? ductSections : ductCoils;
  final clamps = (clampsBase * spec.materialRules.clampsPerSection * spec.materialRules.clampsReserve).ceil();

  // Silencer
  final silencer = buildingType <= 1 ? spec.materialRules.silencerCount : 0;

  // Primary quantity for scenarios
  final primaryQuantity = ductType <= 1 ? ductSections : ductCoils;
  final primaryUnit = ductType <= 1 ? 'секций' : 'бухт';
  final primaryLabel = ductType <= 1
      ? 'duct-section-${spec.materialRules.ductSectionM}m'
      : 'flex-duct-coil-${spec.materialRules.flexDuctCoilM}m';

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in _scenarioNames) {
    final multiplier = _scenarioMultiplier(spec, scenarioName);
    final exactNeed = _roundValue(primaryQuantity * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: _roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'buildingType:$buildingType',
        'ductType:$ductType',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ..._keyFactors(spec, scenarioName),
        'field_multiplier': _roundValue(multiplier, 6),
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: primaryLabel,
        packageSize: 1,
        packagesCount: packageCount,
        unit: primaryUnit,
      ),
    );
  }

  // Warnings
  final warnings = <String>[];
  if (requiredAirflow > spec.warningRules.professionalAirflowThreshold) {
    warnings.add('Требуемый воздухообмен превышает 2000 м³/ч — рекомендуется профессиональное проектирование');
  }
  if (buildingType == 0 && peopleCount > spec.warningRules.supplyExhaustPeopleThreshold) {
    warnings.add('Для квартиры с числом жильцов более 6 рекомендуется приточно-вытяжная установка');
  }

  // Materials
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Вентилятор канальный ($fanCapacity м³/ч, ø$fanDiameter мм)',
      quantity: 1,
      unit: 'шт',
      withReserve: 1,
      purchaseQty: 1,
      category: 'Оборудование',
    ),
  ];

  if (ductType <= 1) {
    materials.add(CanonicalMaterialResult(
      name: 'Воздуховод ${_ductTypeLabels[ductType]} (${spec.materialRules.ductSectionM} м)',
      quantity: ductSections.toDouble(),
      unit: 'секций',
      withReserve: ductSections.toDouble(),
      purchaseQty: ductSections,
      category: 'Воздуховоды',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: 'Воздуховод ${_ductTypeLabels[2]} (${spec.materialRules.flexDuctCoilM} м)',
      quantity: ductCoils.toDouble(),
      unit: 'бухт',
      withReserve: ductCoils.toDouble(),
      purchaseQty: ductCoils,
      category: 'Воздуховоды',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Фасонные элементы (отводы, тройники)',
      quantity: fittings.toDouble(),
      unit: 'шт',
      withReserve: fittings.toDouble(),
      purchaseQty: fittings,
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Вентиляционные решётки',
      quantity: grilles.toDouble(),
      unit: 'шт',
      withReserve: grilles.toDouble(),
      purchaseQty: grilles,
      category: 'Распределение',
    ),
    CanonicalMaterialResult(
      name: 'Хомуты и кронштейны',
      quantity: clamps.toDouble(),
      unit: 'шт',
      withReserve: clamps.toDouble(),
      purchaseQty: clamps,
      category: 'Крепёж',
    ),
  ]);

  if (silencer > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Шумоглушитель',
      quantity: silencer.toDouble(),
      unit: 'шт',
      withReserve: silencer.toDouble(),
      purchaseQty: silencer,
      category: 'Оборудование',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'totalArea': _roundValue(totalArea, 3),
      'ceilingHeight': _roundValue(ceilingHeight, 3),
      'buildingType': buildingType.toDouble(),
      'peopleCount': peopleCount.toDouble(),
      'ductType': ductType.toDouble(),
      'volume': _roundValue(volume, 3),
      'airByVolume': _roundValue(airByVolume, 3),
      'airByPeople': _roundValue(airByPeople, 3),
      'requiredAirflow': _roundValue(requiredAirflow, 3),
      'requiredAirflowRounded': requiredAirflowRounded.toDouble(),
      'fanCapacity': fanCapacity.toDouble(),
      'fanDiameter': fanDiameter.toDouble(),
      'mainDuctLength': _roundValue(mainDuctLength, 3),
      'ductSections': ductSections.toDouble(),
      'ductCoils': ductCoils.toDouble(),
      'fittings': fittings.toDouble(),
      'grilles': grilles.toDouble(),
      'clamps': clamps.toDouble(),
      'silencer': silencer.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
