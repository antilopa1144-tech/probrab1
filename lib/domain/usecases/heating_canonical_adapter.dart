import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

const Map<String, Map<String, double>> _factorTable = {
  'geometry_complexity': {'MIN': 1.0, 'REC': 1.0, 'MAX': 1.15},
  'worker_skill': {'MIN': 0.96, 'REC': 1.0, 'MAX': 1.07},
  'waste_factor': {'MIN': 0.97, 'REC': 1.06, 'MAX': 1.12},
};

CanonicalCalculatorContractResult calculateCanonicalHeating(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(heatingSpecData);

  final totalArea = (inputs['totalArea'] ?? defaultFor(spec, 'totalArea', 80))
      .clamp(10.0, 500.0);
  final ceilingHeightInput =
      inputs['ceilingHeight'] ?? defaultFor(spec, 'ceilingHeight', 2.7);
  final ceilingHeight =
      (ceilingHeightInput > 10 ? ceilingHeightInput / 100 : ceilingHeightInput)
          .clamp(2.5, 3.5);
  final climateZone =
      (inputs['climateZone'] ?? defaultFor(spec, 'climateZone', 1))
          .round()
          .clamp(0, 3);
  final buildingType =
      (inputs['buildingType'] ?? defaultFor(spec, 'buildingType', 1))
          .round()
          .clamp(0, 3);
  final radiatorType =
      (inputs['radiatorType'] ?? defaultFor(spec, 'radiatorType', 0))
          .round()
          .clamp(0, 3);
  final roomCount = (inputs['roomCount'] ?? defaultFor(spec, 'roomCount', 4))
      .round()
      .clamp(1, 20);

  /* ─── power calculation ─── */
  final heightM = ceilingHeight;
  final heightCoeff = heightM / 2.7;
  final powerPerM2Base = spec.materialRule('power_per_m2_base');
  final powerPerM2 = powerPerM2Base is List
      ? (powerPerM2Base[climateZone] as num?)?.toDouble() ?? 100
      : powerPerM2Base is Map
      ? (powerPerM2Base['$climateZone'] as num?)?.toDouble() ?? 100
      : 100.0;
  final buildingCoeffBase = spec.materialRule('building_coeff');
  final buildingCoeff = buildingCoeffBase is List
      ? (buildingCoeffBase[buildingType] as num?)?.toDouble() ?? 1.0
      : buildingCoeffBase is Map
      ? (buildingCoeffBase['$buildingType'] as num?)?.toDouble() ?? 1.0
      : 1.0;
  final totalPowerW = totalArea * powerPerM2 * buildingCoeff * heightCoeff;
  final totalPowerKW = (totalPowerW / 100).round() / 10;

  /* ─── radiator calculation ─── */
  final radiatorPowerBase = spec.materialRule('radiator_power');
  final wattPerUnit = radiatorPowerBase is List
      ? (radiatorPowerBase[radiatorType] as num?)?.toDouble() ?? 150
      : radiatorPowerBase is Map
      ? (radiatorPowerBase['$radiatorType'] as num?)?.toDouble() ?? 150
      : 150.0;
  final totalUnits = (totalPowerW / wattPerUnit).ceil();
  final radiatorCount = radiatorType <= 1 ? roomCount : totalUnits;

  /* ─── piping ─── */
  final pipeSticks =
      (radiatorCount *
              spec.materialRule<num>('pipe_rate').toDouble() *
              spec.materialRule<num>('pipe_reserve').toDouble() /
              spec.materialRule<num>('pp_pipe_stick_m').toDouble())
          .ceil();
  final fittings =
      (radiatorCount *
              spec.materialRule<num>('fittings_per_room').toDouble() *
              spec.materialRule<num>('fittings_reserve').toDouble())
          .ceil();
  final brackets =
      (roomCount *
              spec.materialRule<num>('brackets_per_room').toDouble() *
              spec.materialRule<num>('brackets_reserve').toDouble())
          .ceil();
  final thermoHeads = radiatorCount;
  final mayevskyValves = radiatorCount;

  /* ─── materials ─── */
  const radiatorLabels = {
    0: 'Биметаллический радиатор, секция 180 Вт',
    1: 'Алюминиевый радиатор, секция 200 Вт',
    2: 'Чугунный радиатор, 7 секций, 700 Вт',
    3: 'Стальной панельный радиатор тип 22, 700 Вт',
  };
  final radiatorLabel = radiatorLabels[radiatorType] ?? 'Отопительный прибор';
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: radiatorLabel,
      quantity: totalUnits.toDouble(),
      unit: radiatorType <= 1 ? 'секций' : 'шт',
      withReserve: totalUnits.toDouble(),
      purchaseQty: totalUnits.toDouble(),
      category: 'Отопление',
    ),
    CanonicalMaterialResult(
      name: 'Армированная труба PP-R Ø25 мм, отрезок 4 м',
      quantity: pipeSticks.toDouble(),
      unit: 'шт',
      withReserve: pipeSticks.toDouble(),
      purchaseQty: pipeSticks.toDouble(),
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: 'Фитинги PP-R Ø25 мм для обвязки радиаторов',
      quantity: fittings.toDouble(),
      unit: 'шт',
      withReserve: fittings.toDouble(),
      purchaseQty: fittings.toDouble(),
      category: 'Трубопровод',
    ),
    CanonicalMaterialResult(
      name: radiatorType <= 1
          ? 'Кронштейны для секционного радиатора'
          : 'Кронштейны для выбранного отопительного прибора',
      quantity: brackets.toDouble(),
      unit: 'шт',
      withReserve: brackets.toDouble(),
      purchaseQty: brackets.toDouble(),
      category: 'Монтаж',
    ),
    CanonicalMaterialResult(
      name: 'Термостатический радиаторный клапан с термоголовкой',
      quantity: thermoHeads.toDouble(),
      unit: 'шт',
      withReserve: thermoHeads.toDouble(),
      purchaseQty: thermoHeads.toDouble(),
      category: 'Регулировка',
    ),
    CanonicalMaterialResult(
      name: 'Ручной воздухоотводчик (кран Маевского) 1/2″',
      quantity: mayevskyValves.toDouble(),
      unit: 'шт',
      withReserve: mayevskyValves.toDouble(),
      purchaseQty: mayevskyValves.toDouble(),
      category: 'Арматура',
    ),
  ];

  /* ─── scenarios ─── */
  final accuracyMode = parseAccuracyMode(inputs);
  final accuracyMult = accuracyPrimaryMultiplier('generic', accuracyMode);
  final basePrimary = (totalUnits * accuracyMult).ceilToDouble();
  final scenarios = <String, CanonicalScenarioResult>{};

  for (final scenarioName in scenarioNames) {
    final multiplier = scenarioMultiplier(
      spec.enabledFactors,
      _factorTable,
      scenarioName,
    );
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
  if (totalPowerKW >
      spec.warningRule<num>('gas_boiler_power_threshold_kw').toDouble()) {
    warnings.add(
      'Расчётная мощность выше 20 кВт. Тип и мощность источника тепла подбирают по расчёту теплопотерь и нагрузке горячего водоснабжения',
    );
  }
  if (buildingType == 3 && climateZone >= 2) {
    warnings.add(
      'Слабая изоляция + холодная зона \u2014 рекомендуется профессиональный теплотехнический расчёт',
    );
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
      'radiatorCount': radiatorCount.toDouble(),
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
