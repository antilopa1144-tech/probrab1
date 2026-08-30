import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

double _clamp(double value, double min, double max) =>
    math.max(min, math.min(max, value)).toDouble();

int _whole(double value, int min, int max) =>
    _clamp(value, min.toDouble(), max.toDouble()).round();

String _compact(double value, [int decimals = 2]) {
  final rounded = roundValue(value, decimals);
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

Map<String, double> normalizeLegacyVentilationInputs(
  Map<String, double> inputs,
) {
  final normalized = Map<String, double>.from(inputs);
  normalized.putIfAbsent(
    'calculationMode',
    () => inputs.containsKey('projectAirflowM3h') ? 1 : 0,
  );
  normalized.putIfAbsent('totalArea', () => inputs['area'] ?? 80);
  normalized.putIfAbsent('ceilingHeight', () => 2.7);
  normalized.putIfAbsent('peopleCount', () => inputs['rooms'] ?? 3);
  normalized.putIfAbsent('ductShape', () => 0);
  return normalized;
}

void _addPieceMaterial(
  List<CanonicalMaterialResult> materials,
  String name,
  int count,
  String category,
) {
  if (count <= 0) return;
  materials.add(
    CanonicalMaterialResult(
      name: name,
      quantity: count.toDouble(),
      unit: 'шт',
      withReserve: count.toDouble(),
      purchaseQty: count.toDouble(),
      category: category,
    ),
  );
}

CanonicalCalculatorContractResult calculateCanonicalVentilation(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(ventilationSpecData);
  final normalized = normalizeLegacyVentilationInputs(inputs);

  final calculationMode = _whole(
    normalized['calculationMode'] ?? defaultFor(spec, 'calculationMode', 0),
    0,
    1,
  );
  final totalArea = _clamp(
    normalized['totalArea'] ?? defaultFor(spec, 'totalArea', 80),
    10,
    1000,
  );
  final ceilingHeight = _clamp(
    normalized['ceilingHeight'] ?? defaultFor(spec, 'ceilingHeight', 2.7),
    2.2,
    5,
  );
  final peopleCount = _whole(
    normalized['peopleCount'] ?? defaultFor(spec, 'peopleCount', 3),
    1,
    50,
  );
  final projectAirflowM3h = _clamp(
    normalized['projectAirflowM3h'] ??
        defaultFor(spec, 'projectAirflowM3h', 300),
    1,
    100000,
  );
  final ductShape = _whole(
    normalized['ductShape'] ?? defaultFor(spec, 'ductShape', 0),
    0,
    1,
  );
  final roundDiameterMm = _clamp(
    normalized['roundDiameterMm'] ?? defaultFor(spec, 'roundDiameterMm', 200),
    80,
    2000,
  );
  final rectWidthMm = _clamp(
    normalized['rectWidthMm'] ?? defaultFor(spec, 'rectWidthMm', 300),
    100,
    3000,
  );
  final rectHeightMm = _clamp(
    normalized['rectHeightMm'] ?? defaultFor(spec, 'rectHeightMm', 200),
    50,
    3000,
  );
  final targetVelocityMps = _clamp(
    normalized['targetVelocityMps'] ?? defaultFor(spec, 'targetVelocityMps', 3),
    0.5,
    15,
  );
  final selectedFanCapacityM3h = _clamp(
    normalized['selectedFanCapacityM3h'] ??
        defaultFor(spec, 'selectedFanCapacityM3h', 0),
    0,
    100000,
  );
  final ductLengthM = _clamp(
    normalized['ductLengthM'] ?? defaultFor(spec, 'ductLengthM', 0),
    0,
    10000,
  );
  final stockLengthM = _clamp(
    normalized['stockLengthM'] ?? defaultFor(spec, 'stockLengthM', 3),
    0.1,
    50,
  );
  final ductReservePercent = _clamp(
    normalized['ductReservePercent'] ??
        defaultFor(spec, 'ductReservePercent', 10),
    0,
    30,
  );
  final fittingCount = _whole(
    normalized['fittingCount'] ?? defaultFor(spec, 'fittingCount', 0),
    0,
    10000,
  );
  final airTerminalCount = _whole(
    normalized['airTerminalCount'] ?? defaultFor(spec, 'airTerminalCount', 0),
    0,
    10000,
  );
  final clampCount = _whole(
    normalized['clampCount'] ?? defaultFor(spec, 'clampCount', 0),
    0,
    50000,
  );

  final volume = totalArea * ceilingHeight;
  final areaPerPerson = totalArea / peopleCount;
  final airByPeople =
      peopleCount *
      spec.materialRule<num>('residential_air_per_person_m3h').toDouble();
  final airByArea =
      totalArea *
      spec.materialRule<num>('residential_air_per_area_m3h_m2').toDouble();
  final airByVolume =
      volume *
      spec.materialRule<num>('residential_min_air_change_per_h').toDouble();
  final boundary = spec
      .materialRule<num>('area_per_person_boundary_m2')
      .toDouble();
  final residentialAirflow = areaPerPerson > boundary
      ? math.max(airByPeople, airByVolume).toDouble()
      : airByArea;
  final requiredAirflow = calculationMode == 0
      ? residentialAirflow
      : projectAirflowM3h;

  final selectedFreeAreaM2 = ductShape == 0
      ? math.pi * math.pow(roundDiameterMm / 1000, 2) / 4
      : (rectWidthMm / 1000) * (rectHeightMm / 1000);
  final actualVelocityMps = requiredAirflow / 3600 / selectedFreeAreaM2;
  final requiredFreeAreaM2 = requiredAirflow / 3600 / targetVelocityMps;
  final requiredRoundDiameterMm =
      math.sqrt(4 * requiredFreeAreaM2 / math.pi) * 1000;
  final selectedDuctCapacityM3h = selectedFreeAreaM2 * targetVelocityMps * 3600;
  final selectedFanMarginM3h = selectedFanCapacityM3h > 0
      ? selectedFanCapacityM3h - requiredAirflow
      : 0.0;

  final ductWithReserveM = ductLengthM * (1 + ductReservePercent / 100);
  final minStockCount = ductLengthM > 0
      ? (ductLengthM / stockLengthM).ceil()
      : 0;
  final recStockCount = ductWithReserveM > 0
      ? (ductWithReserveM / stockLengthM).ceil()
      : 0;
  final minPurchaseLengthM = minStockCount * stockLengthM;
  final recPurchaseLengthM = recStockCount * stockLengthM;

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final usesReserve = scenarioName != 'MIN';
    final exactNeed = usesReserve ? ductWithReserveM : ductLengthM;
    final packageCount = usesReserve ? recStockCount : minStockCount;
    final purchaseQuantity = usesReserve
        ? recPurchaseLengthM
        : minPurchaseLengthM;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: roundValue(exactNeed, 6),
      purchaseQuantity: roundValue(purchaseQuantity, 6),
      leftover: roundValue(
        math.max(0, purchaseQuantity - exactNeed).toDouble(),
        6,
      ),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'calculation_mode:$calculationMode',
        'duct_shape:$ductShape',
        'no_hidden_reserve',
      ],
      keyFactors: {
        'explicit_reserve_percent': usesReserve
            ? roundValue(ductReservePercent, 3)
            : 0,
        'field_multiplier': 1,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: 'duct-stock-${_compact(stockLengthM, 3)}m',
        packageSize: roundValue(stockLengthM, 6),
        packagesCount: packageCount,
        unit: spec.packagingRule<String>('duct_unit'),
      ),
    );
  }

  final materials = <CanonicalMaterialResult>[];
  if (ductLengthM > 0) {
    final ductDescription = ductShape == 0
        ? 'круглый ø${_compact(roundDiameterMm, 1)} мм'
        : 'прямоугольный ${_compact(rectWidthMm, 1)}×${_compact(rectHeightMm, 1)} мм';
    materials.add(
      CanonicalMaterialResult(
        name: 'Воздуховод $ductDescription',
        quantity: roundValue(ductLengthM, 6),
        unit: 'м',
        withReserve: roundValue(ductWithReserveM, 6),
        purchaseQty: roundValue(recPurchaseLengthM, 6),
        category: 'Воздуховоды',
        packageInfo: {
          'count': recStockCount,
          'size': roundValue(stockLengthM, 6),
          'packageUnit': spec.packagingRule<String>('duct_unit'),
        },
      ),
    );
  }
  _addPieceMaterial(
    materials,
    'Фасонные элементы по проектной ведомости',
    fittingCount,
    'Фасонные элементы',
  );
  _addPieceMaterial(
    materials,
    'Воздухораспределители по проектной ведомости',
    airTerminalCount,
    'Распределение воздуха',
  );
  _addPieceMaterial(
    materials,
    'Хомуты и крепления по проектной ведомости',
    clampCount,
    'Крепёж',
  );

  final warnings = <String>[
    'Это предварительная проверка расхода и средней скорости, а не проект системы вентиляции.',
    'Калькулятор не определяет баланс притока и вытяжки кухни и санузлов, потери давления, местные сопротивления, утечки, шум и рабочую точку вентилятора.',
    'Противопожарные требования, дымоудаление, теплоизоляцию, защиту от конденсата, автоматику и электропитание проверяют отдельно.',
  ];
  if (calculationMode == 0) {
    warnings.add(
      'Жилой режим оценивает минимальный наружный воздух для помещений с естественным проветриванием; вытяжные расходы и перетоки задают по планировке.',
    );
  } else {
    warnings.add(
      'В проектном режиме расход принят как готовое исходное значение и не проверен по назначению помещений.',
    );
  }
  if (actualVelocityMps > targetVelocityMps) {
    warnings.add(
      'В выбранном сечении скорость ${_compact(actualVelocityMps)} м/с выше заданной цели ${_compact(targetVelocityMps)} м/с.',
    );
  }
  if (actualVelocityMps >
      spec.warningRule<num>('velocity_attention_mps').toDouble()) {
    warnings.add(
      'Скорость выше контрольного уровня требует отдельной проверки шума и потерь давления.',
    );
  }
  if (requiredAirflow >
      spec.warningRule<num>('professional_airflow_threshold_m3h').toDouble()) {
    warnings.add(
      'Расход выше 2000 м³/ч требует профессионального аэродинамического расчёта системы.',
    );
  }
  if (selectedFanCapacityM3h > 0) {
    warnings.add(
      'Паспортная производительность вентилятора без характеристики сети не подтверждает фактический расход в рабочей точке.',
    );
    if (selectedFanCapacityM3h < requiredAirflow) {
      warnings.add(
        'Указанная паспортная производительность вентилятора ниже расчётного расхода.',
      );
    }
  }
  if (ductLengthM == 0) {
    warnings.add(
      'Закупка воздуховодов не рассчитана: внесите длину трассы из проекта или замера.',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'requiredAirflow': roundValue(requiredAirflow, 3),
      'actualVelocityMps': roundValue(actualVelocityMps, 3),
      'requiredRoundDiameterMm': roundValue(requiredRoundDiameterMm, 1),
      'calculationMode': calculationMode.toDouble(),
      'totalArea': roundValue(totalArea, 3),
      'ceilingHeight': roundValue(ceilingHeight, 3),
      'peopleCount': peopleCount.toDouble(),
      'roomVolume': roundValue(volume, 3),
      'volume': roundValue(volume, 3),
      'areaPerPerson': roundValue(areaPerPerson, 3),
      'airByPeople': roundValue(airByPeople, 3),
      'airByArea': roundValue(airByArea, 3),
      'airByVolume': roundValue(airByVolume, 3),
      'airflowRequired': roundValue(requiredAirflow, 3),
      'requiredAirflowRounded': roundValue(requiredAirflow, 3),
      'ductShape': ductShape.toDouble(),
      'selectedFreeAreaM2': roundValue(selectedFreeAreaM2, 6),
      'airVelocity': roundValue(actualVelocityMps, 3),
      'targetVelocityMps': roundValue(targetVelocityMps, 3),
      'requiredFreeAreaM2': roundValue(requiredFreeAreaM2, 6),
      'selectedDuctCapacityM3h': roundValue(selectedDuctCapacityM3h, 3),
      'selectedFanCapacityM3h': roundValue(selectedFanCapacityM3h, 3),
      'fanCapacity': roundValue(selectedFanCapacityM3h, 3),
      'selectedFanMarginM3h': roundValue(selectedFanMarginM3h, 3),
      'fanDiameter': ductShape == 0 ? roundValue(roundDiameterMm, 1) : 0,
      'ductLengthM': roundValue(ductLengthM, 3),
      'mainDuctLength': roundValue(ductLengthM, 3),
      'ductWithReserveM': roundValue(ductWithReserveM, 3),
      'ductReservePercent': roundValue(ductReservePercent, 3),
      'stockLengthM': roundValue(stockLengthM, 3),
      'ductSections': recStockCount.toDouble(),
      'ductCoils': 0,
      'fittings': fittingCount.toDouble(),
      'fittingsCount': fittingCount.toDouble(),
      'grilles': airTerminalCount.toDouble(),
      'grillsCount': airTerminalCount.toDouble(),
      'airTerminalCount': airTerminalCount.toDouble(),
      'clamps': clampCount.toDouble(),
      'silencer': 0,
      'recuperatorCount': 0,
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
