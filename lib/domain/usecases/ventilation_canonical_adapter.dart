import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';
/* ─── spec types ─── */



const Map<int, String> _ductTypeLabels = {
  0: 'Круглый ø100–160',
  1: 'Прямоугольный 200×100',
  2: 'Гибкий ø125',
};


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


CanonicalCalculatorContractResult calculateCanonicalVentilation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(ventilationSpecData);

  final normalized = hasCanonicalVentilationInputs(inputs)
      ? Map<String, double>.from(inputs)
      : normalizeLegacyVentilationInputs(inputs);

  final totalArea = math.max(10.0, math.min(1000.0, (normalized['totalArea'] ?? defaultFor(spec, 'totalArea', 80)).toDouble()));
  final ceilingHeight = math.max(2.5, math.min(3.5, (normalized['ceilingHeight'] ?? defaultFor(spec, 'ceilingHeight', 2.7)).toDouble()));
  final buildingType = (normalized['buildingType'] ?? defaultFor(spec, 'buildingType', 0)).round().clamp(0, 3);
  final peopleCount = (normalized['peopleCount'] ?? defaultFor(spec, 'peopleCount', 3)).round().clamp(1, 50);
  final ductType = (normalized['ductType'] ?? defaultFor(spec, 'ductType', 0)).round().clamp(0, 2);

  // Airflow calculation
  final volume = totalArea * ceilingHeight;
  final airByVolume = volume * ((spec.materialRule<Map>('exchange_rates')['$buildingType'] as num?)?.toDouble() ?? 1.0);
  final airByPeople = peopleCount * spec.materialRule<num>('air_per_person').toDouble();
  final requiredAirflow = math.max(airByVolume, airByPeople);
  final requiredAirflowRounded = (requiredAirflow / spec.materialRule<num>('airflow_rounding').toDouble()).ceil() * spec.materialRule<num>('airflow_rounding').toDouble();

  // Fan
  final fanCapacity = (requiredAirflowRounded * spec.materialRule<num>('fan_reserve').toDouble() / spec.materialRule<num>('airflow_rounding').toDouble()).ceil() * spec.materialRule<num>('airflow_rounding').toDouble();
  final fanDiameter = fanCapacity <= 300 ? 100 : fanCapacity <= 500 ? 125 : fanCapacity <= 800 ? 150 : 200;

  // Duct length
  final mainDuctLength = math.sqrt(totalArea) * spec.materialRule<num>('main_duct_length_coeff').toDouble() * spec.materialRule<num>('main_duct_reserve').toDouble();

  // Duct sections / coils
  var ductSections = 0;
  var ductCoils = 0;

  if (ductType <= 1) {
    ductSections = (mainDuctLength / spec.materialRule<num>('duct_section_m').toDouble()).ceil();
  } else {
    ductCoils = (mainDuctLength / spec.materialRule<num>('flex_duct_coil_m').toDouble()).ceil();
  }

  // Fittings
  final fittingsBase = ductType <= 1 ? ductSections : ductCoils;
  final fittings = (fittingsBase * spec.materialRule<num>('fittings_per_section').toDouble() * spec.materialRule<num>('fittings_reserve').toDouble()).ceil();

  // Grilles
  final grilles = (totalArea / spec.materialRule<num>('grille_area_m2').toDouble()).ceil() + spec.materialRule<num>('grille_base').toDouble();

  // Clamps
  final clampsBase = ductType <= 1 ? ductSections : ductCoils;
  final clamps = (clampsBase * spec.materialRule<num>('clamps_per_section').toDouble() * spec.materialRule<num>('clamps_reserve').toDouble()).ceil();

  // Silencer
  final silencer = buildingType <= 1 ? spec.materialRule<num>('silencer_count').toDouble() : 0;

  // Primary quantity for scenarios
  final primaryQuantity = ductType <= 1 ? ductSections : ductCoils;
  final primaryUnit = ductType <= 1 ? 'секций' : 'бухт';
  final primaryLabel = ductType <= 1
      ? 'duct-section-${spec.materialRule<num>('duct_section_m').toDouble()}m'
      : 'flex-duct-coil-${spec.materialRule<num>('flex_duct_coil_m').toDouble()}m';

  // Scenarios
  final scenarios = <String, CanonicalScenarioResult>{};
final accuracyMode = parseAccuracyMode(inputs);  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, defaultFactorTable, scenarioName);
    final exactNeed = roundValue(primaryQuantity * accuracyMult * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;

    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: packageCount.toDouble(),
      leftover: roundValue(packageCount - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'buildingType:$buildingType',
        'ductType:$ductType',
        'packaging:$primaryLabel',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, defaultFactorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
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
  if (requiredAirflow > spec.warningRule<num>('professional_airflow_threshold').toDouble()) {
    warnings.add('Требуемый воздухообмен превышает 2000 м³/ч — рекомендуется профессиональное проектирование');
  }
  if (buildingType == 0 && peopleCount > spec.warningRule<num>('supply_exhaust_people_threshold').toDouble()) {
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
      name: 'Воздуховод ${_ductTypeLabels[ductType]} (${spec.materialRule<num>('duct_section_m').toDouble()} м)',
      quantity: ductSections.toDouble(),
      unit: 'секций',
      withReserve: ductSections.toDouble(),
      purchaseQty: ductSections.toDouble(),
      category: 'Воздуховоды',
    ));
  } else {
    materials.add(CanonicalMaterialResult(
      name: 'Воздуховод ${_ductTypeLabels[2]} (${spec.materialRule<num>('flex_duct_coil_m').toDouble()} м)',
      quantity: ductCoils.toDouble(),
      unit: 'бухт',
      withReserve: ductCoils.toDouble(),
      purchaseQty: ductCoils.toDouble(),
      category: 'Воздуховоды',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Фасонные элементы (отводы, тройники)',
      quantity: fittings.toDouble(),
      unit: 'шт',
      withReserve: fittings.toDouble(),
      purchaseQty: fittings.toDouble(),
      category: 'Фасонные',
    ),
    CanonicalMaterialResult(
      name: 'Вентиляционные решётки',
      quantity: grilles.toDouble(),
      unit: 'шт',
      withReserve: grilles.toDouble(),
      purchaseQty: grilles.toDouble(),
      category: 'Распределение',
    ),
    CanonicalMaterialResult(
      name: 'Хомуты и кронштейны',
      quantity: clamps.toDouble(),
      unit: 'шт',
      withReserve: clamps.toDouble(),
      purchaseQty: clamps.toDouble(),
      category: 'Крепёж',
    ),
  ]);

  if (silencer > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Шумоглушитель',
      quantity: silencer.toDouble(),
      unit: 'шт',
      withReserve: silencer.toDouble(),
      purchaseQty: silencer.toDouble(),
      category: 'Оборудование',
    ));
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'totalArea': roundValue(totalArea, 3),
      'ceilingHeight': roundValue(ceilingHeight, 3),
      'buildingType': buildingType.toDouble(),
      'peopleCount': peopleCount.toDouble(),
      'ductType': ductType.toDouble(),
      'volume': roundValue(volume, 3),
      'airByVolume': roundValue(airByVolume, 3),
      'airByPeople': roundValue(airByPeople, 3),
      'requiredAirflow': roundValue(requiredAirflow, 3),
      'requiredAirflowRounded': requiredAirflowRounded.toDouble(),
      'fanCapacity': fanCapacity.toDouble(),
      'fanDiameter': fanDiameter.toDouble(),
      'mainDuctLength': roundValue(mainDuctLength, 3),
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
