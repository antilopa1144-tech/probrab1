import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.95, 'REC': 1.0, 'MAX': 1.1},
  'waste_factor': {'MIN': 0.97, 'REC': 1.0, 'MAX': 1.05},
};

CanonicalCalculatorContractResult calculateCanonicalHeating(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(heatingSpecData);

  final totalArea = (inputs['totalArea'] ?? defaultFor(spec, 'totalArea', 80)).clamp(10.0, 500.0);
  final ceilingHeight = (inputs['ceilingHeight'] ?? defaultFor(spec, 'ceilingHeight', 2.7)).clamp(2.5, 3.5);
  final climateZone = (inputs['climateZone'] ?? defaultFor(spec, 'climateZone', 1)).round().clamp(0, 3);
  final buildingType = (inputs['buildingType'] ?? defaultFor(spec, 'buildingType', 1)).round().clamp(0, 3);
  final radiatorType = (inputs['radiatorType'] ?? defaultFor(spec, 'radiatorType', 0)).round().clamp(0, 3);
  final roomCount = (inputs['roomCount'] ?? defaultFor(spec, 'roomCount', 4)).round().clamp(1, 20);

  /* ─── power calculation ─── */
  final heightM = ceilingHeight;
  final heightCoeff = heightM / 2.7;
  final powerPerM2 = (spec.materialRule<Map>('power_per_m2_base')['$climateZone'] as num?)?.toDouble() ?? 100;
  final buildingCoeff = (spec.materialRule<Map>('building_coeff')['$buildingType'] as num?)?.toDouble() ?? 1.0;
  final totalPowerW = totalArea * powerPerM2 * buildingCoeff * heightCoeff;
  final totalPowerKW = (totalPowerW / 100).round() / 10;

  /* ─── radiator calculation ─── */
  final wattPerUnit = (spec.materialRule<Map>('radiator_power')['$radiatorType'] as num?)?.toDouble() ?? 150;
  final totalUnits = (totalPowerW / wattPerUnit).ceil();

  /* ─── piping ─── */
  final pipeSticks = (roomCount * spec.materialRule<num>('pipe_rate').toDouble() * spec.materialRule<num>('pipe_reserve').toDouble() / spec.materialRule<num>('pp_pipe_stick_m').toDouble()).ceil();
  final fittings = (roomCount * spec.materialRule<num>('fittings_per_room').toDouble() * spec.materialRule<num>('fittings_reserve').toDouble()).ceil();
  final brackets = (roomCount * spec.materialRule<num>('brackets_per_room').toDouble() * spec.materialRule<num>('brackets_reserve').toDouble()).ceil();
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
      purchaseQty: totalUnits.toInt(),
      category: 'Отопление',
    ),
    CanonicalMaterialResult(
      name: 'Труба ПП \u00f825 (палки по 4 м)',
      quantity: pipeSticks.toDouble(),
      unit: 'шт',
      withReserve: pipeSticks.toDouble(),
      purchaseQty: pipeSticks.toInt(),
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Фитинги',
      quantity: fittings.toDouble(),
      unit: 'шт',
      withReserve: fittings.toDouble(),
      purchaseQty: fittings.toInt(),
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Кронштейны',
      quantity: brackets.toDouble(),
      unit: 'шт',
      withReserve: brackets.toDouble(),
      purchaseQty: brackets.toInt(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Термоголовки',
      quantity: thermoHeads.toDouble(),
      unit: 'шт',
      withReserve: thermoHeads.toDouble(),
      purchaseQty: thermoHeads.toInt(),
      category: 'Регулировка',
    ),
    CanonicalMaterialResult(
      name: 'Краны Маевского',
      quantity: mayevskyValves.toDouble(),
      unit: 'шт',
      withReserve: mayevskyValves.toDouble(),
      purchaseQty: mayevskyValves.toInt(),
      category: 'Арматура',
    ),
  ];

  /* ─── scenarios ─── */
  final basePrimary = totalUnits.toDouble();
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
        'climateZone:$climateZone',
        'buildingType:$buildingType',
        'radiatorType:$radiatorType',
        'packaging:radiator-unit',
      ],
      keyFactors: {
        ...buildKeyFactors(spec.enabledFactors, _factorTable, scenarioName),
        'field_multiplier': roundValue(multiplier, 6),
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
  if (totalPowerKW > spec.warningRule<num>('gas_boiler_power_threshold_kw').toDouble()) {
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
      'totalArea': roundValue(totalArea, 3),
      'ceilingHeight': roundValue(ceilingHeight, 3),
      'climateZone': climateZone.toDouble(),
      'buildingType': buildingType.toDouble(),
      'radiatorType': radiatorType.toDouble(),
      'roomCount': roomCount.toDouble(),
      'heightCoeff': roundValue(heightCoeff, 4),
      'totalPowerW': roundValue(totalPowerW, 1),
      'totalPowerKW': totalPowerKW,
      'wattPerUnit': wattPerUnit.toDouble(),
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
