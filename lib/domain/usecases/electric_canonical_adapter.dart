import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'installation_method': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.05},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.05},
};

CanonicalCalculatorContractResult calculateCanonicalElectric(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(electricSpecData);

  final apartmentArea = (inputs['apartmentArea'] ?? defaultFor(spec, 'apartmentArea', 60)).clamp(20.0, 500.0);
  final roomsCount = (inputs['roomsCount'] ?? defaultFor(spec, 'roomsCount', 3)).round().clamp(1, 10);
  final ceilingHeight = (inputs['ceilingHeight'] ?? defaultFor(spec, 'ceilingHeight', 2.7)).clamp(2.4, 4.0);
  final wiringType = (inputs['wiringType'] ?? defaultFor(spec, 'wiringType', 0)).round().clamp(0, 1);
  final hasKitchen = (inputs['hasKitchen'] ?? defaultFor(spec, 'hasKitchen', 1)).round().clamp(0, 1);
  final reserve = (inputs['reserve'] ?? defaultFor(spec, 'reserve', 15)).clamp(5.0, 30.0);

  /* ─── groups ─── */
  final lightingGroups = roomsCount + 1;
  final outletGroups = roomsCount + 2;
  final acGroups = (roomsCount / spec.materialRule<num>('ac_groups_divisor').toDouble()).ceil();
  final breakersCount = lightingGroups + outletGroups + acGroups + (hasKitchen == 1 ? 1 : 0);
  final uzoCount = (outletGroups / 2).ceil() + (hasKitchen == 1 ? 1 : 0) + 1;

  /* ─── cable lengths ─── */
  final cable15length = (apartmentArea * spec.materialRule<num>('cable15_rate').toDouble() + lightingGroups * ceilingHeight) * (1 + reserve / 100);
  final cable25length = (apartmentArea * spec.materialRule<num>('cable25_rate').toDouble() + outletGroups * ceilingHeight * 1.5) * (1 + reserve / 100);
  final cable6length = hasKitchen == 1
      ? (math.sqrt(apartmentArea) * spec.materialRule<num>('cable6_kitchen_factor').toDouble() + ceilingHeight) * spec.materialRule<num>('cable6_reserve').toDouble()
      : 0.0;
  final conduitLength = ((cable15length + cable25length + cable6length) * spec.materialRule<num>('conduit_ratio').toDouble()).ceil();

  /* ─── outlets & switches ─── */
  final outletsCount = (apartmentArea * spec.materialRule<num>('outlets_per_m2').toDouble()).ceil() + roomsCount * spec.materialRule<num>('outlets_per_room').toDouble();
  final switchesCount = roomsCount + spec.materialRule<num>('switches_base').toDouble();

  /* ─── packaging ─── */
  final cable15spools = (cable15length / spec.materialRule<num>('cable_spool_m').toDouble()).ceil();
  final cable25spools = (cable25length / spec.materialRule<num>('cable_spool_m').toDouble()).ceil();
  final conduitPacks = (conduitLength / spec.materialRule<num>('cable_spool_m').toDouble()).ceil();
  final socketBoxes = ((outletsCount + switchesCount) * spec.materialRule<num>('socket_box_reserve').toDouble()).ceil();
  final gypsumKg = ((outletsCount + switchesCount) / 5).ceil();

  /* ─── materials ─── */
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: 'Кабель ВВГнг 3\u00d71.5',
      quantity: roundValue(cable15length, 1),
      unit: 'м',
      withReserve: roundValue(cable15length, 1),
      purchaseQty: (cable15spools * spec.materialRule<num>('cable_spool_m').toDouble()).round().toDouble(),
      category: 'Кабель',
    ),
    CanonicalMaterialResult(
      name: 'Кабель ВВГнг 3\u00d72.5',
      quantity: roundValue(cable25length, 1),
      unit: 'м',
      withReserve: roundValue(cable25length, 1),
      purchaseQty: (cable25spools * spec.materialRule<num>('cable_spool_m').toDouble()).round().toDouble(),
      category: 'Кабель',
    ),
  ];

  if (hasKitchen == 1 && cable6length > 0) {
    materials.add(CanonicalMaterialResult(
      name: 'Кабель ВВГнг 3\u00d76',
      quantity: roundValue(cable6length, 1),
      unit: 'м',
      withReserve: roundValue(cable6length, 1),
      purchaseQty: cable6length.ceil().toDouble(),
      category: 'Кабель',
    ));
  }

  materials.addAll([
    CanonicalMaterialResult(
      name: 'Щиток (модулей)',
      quantity: (breakersCount + uzoCount + 2).toDouble(),
      unit: 'шт',
      withReserve: (breakersCount + uzoCount + 2).toDouble(),
      purchaseQty: (breakersCount + uzoCount + 2).toDouble(),
      category: 'Щиток',
      packageInfo: {'count': 1, 'unitSize': (breakersCount + uzoCount + 2).toDouble(), 'packageUnit': 'щитков'},
    ),
    CanonicalMaterialResult(
      name: 'Автоматы',
      quantity: breakersCount.toDouble(),
      unit: 'шт',
      withReserve: breakersCount.toDouble(),
      purchaseQty: breakersCount.toDouble(),
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name: 'УЗО/дифавтоматы',
      quantity: uzoCount.toDouble(),
      unit: 'шт',
      withReserve: uzoCount.toDouble(),
      purchaseQty: uzoCount.toDouble(),
      category: 'Защита',
    ),
    CanonicalMaterialResult(
      name: 'Розетки',
      quantity: outletsCount.toDouble(),
      unit: 'шт',
      withReserve: outletsCount.toDouble(),
      purchaseQty: outletsCount.toDouble(),
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Выключатели',
      quantity: switchesCount.toDouble(),
      unit: 'шт',
      withReserve: switchesCount.toDouble(),
      purchaseQty: switchesCount.toDouble(),
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Подрозетники',
      quantity: socketBoxes.toDouble(),
      unit: 'шт',
      withReserve: socketBoxes.toDouble(),
      purchaseQty: socketBoxes.toDouble(),
      category: 'Установка',
    ),
    CanonicalMaterialResult(
      name: 'Гофра/кабель-канал',
      quantity: conduitLength.toDouble(),
      unit: 'м',
      withReserve: conduitLength.toDouble(),
      purchaseQty: (conduitPacks * spec.materialRule<num>('cable_spool_m').toDouble()).round().toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Гипс/алебастр',
      quantity: gypsumKg.toDouble(),
      unit: 'кг',
      withReserve: gypsumKg.toDouble(),
      purchaseQty: gypsumKg.toDouble(),
      category: 'Монтаж',
    ),
  ]);

  /* ─── scenarios ─── */
  final basePrimary = (cable15spools + cable25spools).toDouble();
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(spec.enabledFactors, _factorTable, scenarioName);
    final exactNeed = roundValue(basePrimary * multiplier, 6);
    final packageCount = exactNeed > 0 ? exactNeed.ceil() : 0;
    final purchaseQuantity = roundValue(packageCount.toDouble(), 6);
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: exactNeed,
      purchaseQuantity: purchaseQuantity,
      leftover: roundValue(purchaseQuantity - exactNeed, 6),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'wiringType:$wiringType',
        'reserve:$reserve',
        'packaging:electric-cable-spool',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
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
  if (apartmentArea > spec.warningRule<num>('three_phase_area_threshold').toDouble()) {
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
      'apartmentArea': roundValue(apartmentArea, 3),
      'roomsCount': roomsCount.toDouble(),
      'ceilingHeight': roundValue(ceilingHeight, 3),
      'wiringType': wiringType.toDouble(),
      'hasKitchen': hasKitchen.toDouble(),
      'reserve': reserve,
      'lightingGroups': lightingGroups.toDouble(),
      'outletGroups': outletGroups.toDouble(),
      'acGroups': acGroups.toDouble(),
      'breakersCount': breakersCount.toDouble(),
      'uzoCount': uzoCount.toDouble(),
      'cable15length': roundValue(cable15length, 1),
      'cable25length': roundValue(cable25length, 1),
      'cable6length': roundValue(cable6length, 1),
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
