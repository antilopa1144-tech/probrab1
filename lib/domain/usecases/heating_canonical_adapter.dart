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

Map<String, double> normalizeLegacyHeatingInputs(Map<String, double> inputs) {
  final normalized = Map<String, double>.from(inputs);
  if (!inputs.containsKey('loadMode') &&
      !inputs.containsKey('designHeatLoadW') &&
      inputs.containsKey('totalArea')) {
    normalized['loadMode'] = 1;
    normalized['heatedAreaM2'] = inputs['totalArea']!;
    normalized['specificHeatLoadWm2'] = 100;
  }
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

CanonicalCalculatorContractResult calculateCanonicalHeating(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(heatingSpecData);
  final normalized = normalizeLegacyHeatingInputs(inputs);

  final loadMode = _whole(
    normalized['loadMode'] ?? defaultFor(spec, 'loadMode', 0),
    0,
    1,
  );
  final designHeatLoadW = _clamp(
    normalized['designHeatLoadW'] ?? defaultFor(spec, 'designHeatLoadW', 8000),
    100,
    200000,
  );
  final heatedAreaM2 = _clamp(
    normalized['heatedAreaM2'] ?? defaultFor(spec, 'heatedAreaM2', 80),
    1,
    2000,
  );
  final specificHeatLoadWm2 = _clamp(
    normalized['specificHeatLoadWm2'] ??
        defaultFor(spec, 'specificHeatLoadWm2', 100),
    10,
    500,
  );
  final deviceKind = _whole(
    normalized['deviceKind'] ?? defaultFor(spec, 'deviceKind', 0),
    0,
    1,
  );
  final devicePowerMode = _whole(
    normalized['devicePowerMode'] ?? defaultFor(spec, 'devicePowerMode', 0),
    0,
    1,
  );
  final deviceOutputAtDesignW = _clamp(
    normalized['deviceOutputAtDesignW'] ??
        defaultFor(spec, 'deviceOutputAtDesignW', 180),
    10,
    50000,
  );
  final nominalDeviceOutputW = _clamp(
    normalized['nominalDeviceOutputW'] ??
        defaultFor(spec, 'nominalDeviceOutputW', 180),
    10,
    50000,
  );
  final ratedDeltaTK = _clamp(
    normalized['ratedDeltaTK'] ?? defaultFor(spec, 'ratedDeltaTK', 50),
    10,
    100,
  );
  final supplyTempC = _clamp(
    normalized['supplyTempC'] ?? defaultFor(spec, 'supplyTempC', 75),
    20,
    120,
  );
  final returnTempC = _clamp(
    normalized['returnTempC'] ?? defaultFor(spec, 'returnTempC', 65),
    10,
    110,
  );
  final roomTempC = _clamp(
    normalized['roomTempC'] ?? defaultFor(spec, 'roomTempC', 20),
    5,
    35,
  );
  final temperatureExponent = _clamp(
    normalized['temperatureExponent'] ??
        defaultFor(spec, 'temperatureExponent', 1.3),
    1,
    2,
  );
  final designReservePercent = _clamp(
    normalized['designReservePercent'] ??
        defaultFor(spec, 'designReservePercent', 0),
    0,
    30,
  );
  final pipeLengthM = _clamp(
    normalized['pipeLengthM'] ?? defaultFor(spec, 'pipeLengthM', 0),
    0,
    10000,
  );
  final pipeStockLengthM = _clamp(
    normalized['pipeStockLengthM'] ?? defaultFor(spec, 'pipeStockLengthM', 4),
    0.1,
    100,
  );
  final pipeReservePercent = _clamp(
    normalized['pipeReservePercent'] ??
        defaultFor(spec, 'pipeReservePercent', 0),
    0,
    30,
  );
  final fittingCount = _whole(
    normalized['fittingCount'] ?? defaultFor(spec, 'fittingCount', 0),
    0,
    10000,
  );
  final bracketCount = _whole(
    normalized['bracketCount'] ?? defaultFor(spec, 'bracketCount', 0),
    0,
    10000,
  );
  final valveSetCount = _whole(
    normalized['valveSetCount'] ?? defaultFor(spec, 'valveSetCount', 0),
    0,
    10000,
  );
  final airVentCount = _whole(
    normalized['airVentCount'] ?? defaultFor(spec, 'airVentCount', 0),
    0,
    10000,
  );

  final preliminaryHeatLoadW = heatedAreaM2 * specificHeatLoadWm2;
  final heatLoadW = loadMode == 0 ? designHeatLoadW : preliminaryHeatLoadW;
  final meanWaterTempC = (supplyTempC + returnTempC) / 2;
  final rawDesignDeltaTK = meanWaterTempC - roomTempC;
  final designDeltaTK = math.max(1, rawDesignDeltaTK).toDouble();
  final temperatureRatio = designDeltaTK / ratedDeltaTK;
  final correctedDeviceOutputW =
      nominalDeviceOutputW *
      math.pow(temperatureRatio, temperatureExponent).toDouble();
  final effectiveDeviceOutputW = devicePowerMode == 0
      ? deviceOutputAtDesignW
      : correctedDeviceOutputW;

  final heatLoadWithReserveW = heatLoadW * (1 + designReservePercent / 100);
  final minExactUnits = heatLoadW / effectiveDeviceOutputW;
  final recExactUnits = heatLoadWithReserveW / effectiveDeviceOutputW;
  final minPurchaseUnits = minExactUnits.ceil();
  final recPurchaseUnits = recExactUnits.ceil();
  final primaryUnit = deviceKind == 0
      ? spec.packagingRule<String>('section_unit')
      : spec.packagingRule<String>('device_unit');

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    final usesReserve = scenarioName != 'MIN';
    final exactNeed = usesReserve ? recExactUnits : minExactUnits;
    final purchaseQuantity = usesReserve ? recPurchaseUnits : minPurchaseUnits;
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: roundValue(exactNeed, 6),
      purchaseQuantity: purchaseQuantity.toDouble(),
      leftover: roundValue(
        math.max(0, purchaseQuantity - exactNeed).toDouble(),
        6,
      ),
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'load_mode:$loadMode',
        'device_kind:$deviceKind',
        'device_power_mode:$devicePowerMode',
        'room_or_independent_zone',
        'no_hidden_reserve',
      ],
      keyFactors: {
        'explicit_reserve_percent': usesReserve
            ? roundValue(designReservePercent, 3)
            : 0,
        'field_multiplier': 1,
      },
      buyPlan: CanonicalBuyPlan(
        packageLabel: deviceKind == 0 ? 'radiator-section' : 'heating-device',
        packageSize: 1,
        packagesCount: purchaseQuantity,
        unit: primaryUnit,
      ),
    );
  }

  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: deviceKind == 0
          ? 'Секции выбранного радиатора'
          : 'Выбранный отопительный прибор',
      quantity: roundValue(minExactUnits, 6),
      unit: primaryUnit,
      withReserve: roundValue(recExactUnits, 6),
      purchaseQty: recPurchaseUnits.toDouble(),
      category: 'Отопительные приборы',
      packageInfo: {
        'count': recPurchaseUnits,
        'size': 1.0,
        'packageUnit': primaryUnit,
      },
    ),
  ];

  final pipeWithReserveM = pipeLengthM * (1 + pipeReservePercent / 100);
  final pipeStockCount = pipeLengthM > 0
      ? (pipeWithReserveM / pipeStockLengthM).ceil()
      : 0;
  final pipePurchaseLengthM = pipeStockCount * pipeStockLengthM;
  if (pipeLengthM > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Труба отопления по проектной ведомости',
        quantity: roundValue(pipeLengthM, 6),
        unit: 'м',
        withReserve: roundValue(pipeWithReserveM, 6),
        purchaseQty: roundValue(pipePurchaseLengthM, 6),
        category: 'Трубопровод',
        packageInfo: {
          'count': pipeStockCount,
          'size': roundValue(pipeStockLengthM, 6),
          'packageUnit': spec.packagingRule<String>('pipe_unit'),
        },
      ),
    );
  }
  _addPieceMaterial(
    materials,
    'Фитинги по проектной ведомости',
    fittingCount,
    'Трубопровод',
  );
  _addPieceMaterial(
    materials,
    'Кронштейны по паспорту и ведомости',
    bracketCount,
    'Монтаж',
  );
  _addPieceMaterial(
    materials,
    'Комплекты регулирующей и запорной арматуры',
    valveSetCount,
    'Арматура',
  );
  _addPieceMaterial(
    materials,
    'Воздухоотводчики по ведомости',
    airVentCount,
    'Арматура',
  );

  final warnings = <String>[
    'Подбор выполняют для одного помещения или одной независимо рассчитанной зоны: общую мощность здания нельзя равномерно делить между комнатами.',
    'Калькулятор не определяет теплопотери через ограждения, вентиляцию и инфильтрацию, а также не проверяет климатические исходные данные.',
    'Гидравлический расчёт, расход теплоносителя, диаметры труб, потери давления, балансировка, источник тепла, автоматика и схема подключения не рассчитываются.',
  ];
  if (loadMode == 1) {
    warnings.add(
      'Режим Вт/м² — предварительная сметная оценка по явно введённой удельной нагрузке, а не нормативный расчёт теплопотерь.',
    );
  } else {
    warnings.add(
      'Тепловая нагрузка принята как готовое проектное значение и не проверена калькулятором.',
    );
  }
  if (devicePowerMode == 0) {
    warnings.add(
      'Проверьте, что паспортная теплоотдача указана именно для расчётных температур подачи, обратки, помещения, расхода и схемы подключения.',
    );
  } else {
    warnings.add(
      'Показатель степени n и исходный температурный напор берут из протокола испытаний или документации конкретной модели.',
    );
    if (supplyTempC <= returnTempC || rawDesignDeltaTK <= 0) {
      warnings.add(
        'Температуры заданы некорректно: подача должна быть выше обратки, а средняя температура воды — выше температуры помещения.',
      );
    }
    if (temperatureRatio <
        spec.warningRule<num>('low_temperature_ratio').toDouble()) {
      warnings.add(
        'Расчётный температурный напор значительно ниже паспортного; теплоотдача прибора сильно уменьшится.',
      );
    }
    if (temperatureRatio >
        spec.warningRule<num>('high_temperature_ratio').toDouble()) {
      warnings.add(
        'Расчётный температурный напор заметно выше паспортного; проверьте допустимый режим прибора и системы.',
      );
    }
  }
  if (designReservePercent > 0) {
    warnings.add(
      'Применён только явно заданный запас мощности ${_compact(designReservePercent, 1)}%; дополнительного скрытого запаса нет.',
    );
  }
  if (pipeLengthM == 0 &&
      fittingCount == 0 &&
      bracketCount == 0 &&
      valveSetCount == 0 &&
      airVentCount == 0) {
    warnings.add(
      'Сопутствующая закупка не рассчитана: внесите длину труб и штучные позиции из проектной ведомости.',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'heatLoadW': roundValue(heatLoadW, 1),
      'effectiveDeviceOutputW': roundValue(effectiveDeviceOutputW, 3),
      'recPurchase': scenarios['REC']!.purchaseQuantity,
      'loadMode': loadMode.toDouble(),
      'designHeatLoadW': roundValue(designHeatLoadW, 1),
      'heatedAreaM2': roundValue(heatedAreaM2, 3),
      'specificHeatLoadWm2': roundValue(specificHeatLoadWm2, 3),
      'preliminaryHeatLoadW': roundValue(preliminaryHeatLoadW, 1),
      'totalPowerW': roundValue(heatLoadW, 1),
      'totalPowerKW': roundValue(heatLoadW / 1000, 3),
      'heatLoadWithReserveW': roundValue(heatLoadWithReserveW, 1),
      'deviceKind': deviceKind.toDouble(),
      'devicePowerMode': devicePowerMode.toDouble(),
      'deviceOutputAtDesignW': roundValue(deviceOutputAtDesignW, 3),
      'nominalDeviceOutputW': roundValue(nominalDeviceOutputW, 3),
      'ratedDeltaTK': roundValue(ratedDeltaTK, 3),
      'supplyTempC': roundValue(supplyTempC, 3),
      'returnTempC': roundValue(returnTempC, 3),
      'roomTempC': roundValue(roomTempC, 3),
      'meanWaterTempC': roundValue(meanWaterTempC, 3),
      'designDeltaTK': roundValue(designDeltaTK, 3),
      'temperatureRatio': roundValue(temperatureRatio, 6),
      'temperatureExponent': roundValue(temperatureExponent, 3),
      'correctedDeviceOutputW': roundValue(correctedDeviceOutputW, 3),
      'wattPerUnit': roundValue(effectiveDeviceOutputW, 3),
      'designReservePercent': roundValue(designReservePercent, 3),
      'exactUnits': roundValue(recExactUnits, 6),
      'totalUnits': recPurchaseUnits.toDouble(),
      'radiatorCount': recPurchaseUnits.toDouble(),
      'pipeLengthM': roundValue(pipeLengthM, 3),
      'pipeWithReserveM': roundValue(pipeWithReserveM, 3),
      'pipeStockLengthM': roundValue(pipeStockLengthM, 3),
      'pipeSticks': pipeStockCount.toDouble(),
      'pipePurchaseLengthM': roundValue(pipePurchaseLengthM, 3),
      'fittings': fittingCount.toDouble(),
      'brackets': bracketCount.toDouble(),
      'thermoHeads': valveSetCount.toDouble(),
      'mayevskyValves': airVentCount.toDouble(),
      'minExactNeed': scenarios['MIN']!.exactNeed,
      'recExactNeed': scenarios['REC']!.exactNeed,
      'maxExactNeed': scenarios['MAX']!.exactNeed,
      'minPurchase': scenarios['MIN']!.purchaseQuantity,
      'maxPurchase': scenarios['MAX']!.purchaseQuantity,
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
