import 'dart:math' as math;

import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import 'canonical_adapter_utils.dart';

double _clamp(double value, double min, double max) =>
    math.max(min, math.min(max, value)).toDouble();

int _whole(double value, int min, int max) =>
    _clamp(value, min.toDouble(), max.toDouble()).round();

Map<String, double> normalizeLegacyElectricWarmFloorInputs(
  Map<String, double> inputs,
) {
  final normalized = Map<String, double>.from(inputs);
  final hasV3Fields = inputs.containsKey('roomAreaM2') ||
      inputs.containsKey('kitRatedPowerW') ||
      inputs.containsKey('kitCoverageAreaM2');
  if (hasV3Fields) return normalized;

  final roomArea = inputs['roomArea'] ??
      inputs['area'] ??
      ((inputs['length'] ?? 0) > 0 && (inputs['width'] ?? 0) > 0
          ? inputs['length']! * inputs['width']!
          : 10);
  normalized['roomAreaM2'] = roomArea;

  final excludedArea = inputs['furnitureArea'] ??
      (inputs.containsKey('usefulAreaPercent')
          ? roomArea * (1 - inputs['usefulAreaPercent']! / 100)
          : 2);
  normalized['excludedAreaM2'] = excludedArea;
  normalized['layoutAreaM2'] = math.max(0.1, roomArea - excludedArea).toDouble();

  if (inputs.containsKey('type')) {
    final type = inputs['type']!.round();
    normalized['systemType'] = type == 1 ? 1 : 0;
  } else if (inputs.containsKey('heatingType')) {
    final type = inputs['heatingType']!.round();
    normalized['systemType'] = type == 1 ? 1 : type.toDouble();
  } else if (inputs.containsKey('systemType')) {
    final legacyType = inputs['systemType']!.round();
    normalized['systemType'] = switch (legacyType) {
      1 => 0,
      2 => 1,
      _ => legacyType.toDouble(),
    };
  }
  normalized['legacyInputMode'] = 1;
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

CanonicalCalculatorContractResult _movedWaterResult(
  SpecReader spec,
  double roomArea,
) {
  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: 0,
      purchaseQuantity: 0,
      leftover: 0,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'legacy_water_mode:moved_to_warm-floor-pipes',
      ],
      keyFactors: const {'field_multiplier': 1},
      buyPlan: const CanonicalBuyPlan(
        packageLabel: 'water-floor-moved',
        packageSize: 1,
        packagesCount: 0,
        unit: 'шт',
      ),
    );
  }
  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: const [],
    totals: {
      'roomArea': roundValue(roomArea, 3),
      'heatingArea': 0,
      'systemType': 2,
      'kitCount': 0,
      'totalPowerW': 0,
      'totalPowerKW': 0,
      'circuitCurrentA': 0,
      'legacyWaterMode': 1,
    },
    warnings: const [
      'Водяной тёплый пол перенесён в отдельный калькулятор: здесь рассчитываются только электрические заводские комплекты.',
    ],
    scenarios: scenarios,
  );
}

CanonicalCalculatorContractResult calculateCanonicalWarmFloor(
  Map<String, double> inputs, {
  SpecReader? specOverride,
}) {
  final spec = specOverride ?? const SpecReader(warmFloorSpecData);
  final normalized = normalizeLegacyElectricWarmFloorInputs(inputs);
  final rawRoomArea = normalized['roomAreaM2'] ??
      normalized['roomArea'] ??
      defaultFor(spec, 'roomAreaM2', 10);
  final roomArea = _clamp(rawRoomArea, 1, 500);

  final legacyWater = !inputs.containsKey('roomAreaM2') &&
      ((inputs.containsKey('heatingType') &&
              inputs['heatingType']!.round() == 2) ||
          (inputs.containsKey('systemType') &&
              inputs['systemType']!.round() == 4));
  if (legacyWater) return _movedWaterResult(spec, roomArea);

  final rawExcludedArea = normalized['excludedAreaM2'] ??
      normalized['furnitureArea'] ??
      defaultFor(spec, 'excludedAreaM2', 2);
  final excludedArea = _clamp(rawExcludedArea, 0, roomArea);
  final availableArea = math.max(0, roomArea - excludedArea).toDouble();
  final rawLayoutArea = normalized['layoutAreaM2'] ??
      defaultFor(spec, 'layoutAreaM2', 8);
  final layoutArea = math.min(_clamp(rawLayoutArea, 0.1, 500), availableArea);
  final systemType = _whole(
    normalized['systemType'] ?? defaultFor(spec, 'systemType', 0),
    0,
    1,
  );
  final kitCount = _whole(
    normalized['kitCount'] ?? defaultFor(spec, 'kitCount', 1),
    1,
    100,
  );
  final kitCoverageAreaM2 = _clamp(
    normalized['kitCoverageAreaM2'] ??
        defaultFor(spec, 'kitCoverageAreaM2', 8),
    0.1,
    500,
  );
  final kitRatedPowerW = _clamp(
    normalized['kitRatedPowerW'] ??
        defaultFor(spec, 'kitRatedPowerW', 1200),
    10,
    50000,
  );
  final cableLengthPerKitM = _clamp(
    normalized['cableLengthPerKitM'] ??
        defaultFor(spec, 'cableLengthPerKitM', 60),
    0.1,
    5000,
  );
  final designHeatLoadW = _clamp(
    normalized['designHeatLoadW'] ??
        defaultFor(spec, 'designHeatLoadW', 0),
    0,
    500000,
  );
  final supplyVoltageV = _clamp(
    normalized['supplyVoltageV'] ??
        defaultFor(spec, 'supplyVoltageV', 230),
    100,
    500,
  );
  final thermostatRatedCurrentA = _clamp(
    normalized['thermostatRatedCurrentA'] ??
        defaultFor(spec, 'thermostatRatedCurrentA', 0),
    0,
    100,
  );
  final thermostatCount = _whole(
    normalized['thermostatCount'] ??
        defaultFor(spec, 'thermostatCount', 0),
    0,
    100,
  );
  final floorSensorCount = _whole(
    normalized['floorSensorCount'] ??
        defaultFor(spec, 'floorSensorCount', 0),
    0,
    100,
  );
  final sensorConduitLengthM = _clamp(
    normalized['sensorConduitLengthM'] ??
        defaultFor(spec, 'sensorConduitLengthM', 0),
    0,
    1000,
  );
  final sensorConduitStockLengthM = _clamp(
    normalized['sensorConduitStockLengthM'] ??
        defaultFor(spec, 'sensorConduitStockLengthM', 1),
    0.1,
    100,
  );

  final selectedCoverageAreaM2 = kitCount * kitCoverageAreaM2;
  final totalPowerW = kitCount * kitRatedPowerW;
  final totalCableLengthM = systemType == 1
      ? kitCount * cableLengthPerKitM
      : 0.0;
  final installedPowerDensityWm2 = layoutArea > 0
      ? totalPowerW / layoutArea
      : 0.0;
  final circuitCurrentA = totalPowerW / supplyVoltageV;
  final thermostatLoadPercent = thermostatRatedCurrentA > 0
      ? circuitCurrentA / thermostatRatedCurrentA * 100
      : 0.0;
  final cableStepMm = totalCableLengthM > 0
      ? layoutArea / totalCableLengthM * 1000
      : 0.0;
  final designPowerMarginW = designHeatLoadW > 0
      ? totalPowerW - designHeatLoadW
      : 0.0;

  final kitUnit = spec.packagingRule<String>('kit_unit');
  final materials = <CanonicalMaterialResult>[
    CanonicalMaterialResult(
      name: systemType == 0
          ? 'Выбранный заводской комплект нагревательного мата'
          : 'Выбранный заводской комплект нагревательного кабеля',
      quantity: kitCount.toDouble(),
      unit: kitUnit,
      withReserve: kitCount.toDouble(),
      purchaseQty: kitCount.toDouble(),
      packageInfo: {
        'count': kitCount,
        'size': 1.0,
        'packageUnit': kitUnit,
      },
      category: 'Основное',
    ),
  ];
  _addPieceMaterial(
    materials,
    'Терморегулятор по проектной ведомости',
    thermostatCount,
    'Управление',
  );
  _addPieceMaterial(
    materials,
    'Датчик температуры пола по проектной ведомости',
    floorSensorCount,
    'Управление',
  );

  final conduitStockCount = sensorConduitLengthM > 0
      ? (sensorConduitLengthM / sensorConduitStockLengthM).ceil()
      : 0;
  final conduitPurchaseLengthM =
      conduitStockCount * sensorConduitStockLengthM;
  if (sensorConduitLengthM > 0) {
    materials.add(
      CanonicalMaterialResult(
        name: 'Защитная трубка датчика по проектной ведомости',
        quantity: roundValue(sensorConduitLengthM, 6),
        unit: 'м',
        withReserve: roundValue(sensorConduitLengthM, 6),
        purchaseQty: roundValue(conduitPurchaseLengthM, 6),
        packageInfo: {
          'count': conduitStockCount,
          'size': roundValue(sensorConduitStockLengthM, 6),
          'packageUnit': spec.packagingRule<String>('conduit_unit'),
        },
        category: 'Монтаж',
      ),
    );
  }

  final scenarios = <String, CanonicalScenarioResult>{};
  for (final scenarioName in scenarioNames) {
    scenarios[scenarioName] = CanonicalScenarioResult(
      exactNeed: kitCount.toDouble(),
      purchaseQuantity: kitCount.toDouble(),
      leftover: 0,
      assumptions: [
        'formula_version:${spec.formulaVersion}',
        'systemType:$systemType',
        'factory_kit_passport',
        'no_hidden_reserve',
      ],
      keyFactors: const {'field_multiplier': 1},
      buyPlan: CanonicalBuyPlan(
        packageLabel: systemType == 0
            ? 'electric-floor-mat-kit'
            : 'electric-floor-cable-kit',
        packageSize: 1,
        packagesCount: kitCount,
        unit: kitUnit,
      ),
    );
  }

  final warnings = <String>[
    'Калькулятор проверяет выбранные заводские комплекты и раскладку, но не назначает мощность, кабель питания, автомат, коммутацию или способ управления.',
    'Для цепи электрообогрева требуется защита УДТ с номинальным током срабатывания не более 30 мА; схему, заземление и уравнивание потенциалов проверяет проектировщик или электрик.',
    'Сохраните план зон нагрева, свободных зон, соединений и номинальных мощностей рядом с документацией электроустановки.',
  ];
  if ((normalized['legacyInputMode'] ?? 0) == 1) {
    warnings.add(
      'Старые настройки не содержали паспортных данных комплекта: проверьте площадь, мощность, напряжение и ток заново.',
    );
  }
  if (rawExcludedArea > roomArea) {
    warnings.add(
      'Площадь зон без нагрева больше площади помещения: проверьте планировку и исходные размеры.',
    );
  }
  if (rawLayoutArea > availableArea) {
    warnings.add(
      'Площадь раскладки ограничена доступной площадью без мебели и оборудования; пересмотрите план зон нагрева.',
    );
  }
  final coverageTolerance =
      spec.warningRule<num>('coverage_tolerance_m2').toDouble();
  if (selectedCoverageAreaM2 > layoutArea + coverageTolerance) {
    warnings.add(
      'Паспортная площадь выбранных комплектов больше площади раскладки: нельзя перекрывать маты или произвольно уменьшать длину нагревательного кабеля.',
    );
  } else if (selectedCoverageAreaM2 < layoutArea - coverageTolerance) {
    warnings.add(
      'Выбранные комплекты покрывают не всю площадь раскладки; оставшуюся зону и требуемую мощность проверьте по плану и каталогу производителя.',
    );
  }
  if (designHeatLoadW <= 0) {
    warnings.add(
      'Проектная тепловая нагрузка не введена: калькулятор не подтверждает, что система может быть основным отоплением.',
    );
  } else if (totalPowerW <
      designHeatLoadW *
          spec.warningRule<num>('design_power_low_ratio').toDouble()) {
    warnings.add(
      'Паспортная мощность выбранных комплектов ниже введённой проектной тепловой нагрузки.',
    );
  } else if (totalPowerW >
      designHeatLoadW *
          spec.warningRule<num>('design_power_high_ratio').toDouble()) {
    warnings.add(
      'Паспортная мощность заметно выше введённой проектной нагрузки: проверьте допустимую удельную мощность, покрытие и управление.',
    );
  }
  if (thermostatRatedCurrentA <= 0) {
    warnings.add(
      'Допустимый ток терморегулятора не введён — прямое подключение нагрузки не проверено.',
    );
  } else if (circuitCurrentA > thermostatRatedCurrentA) {
    warnings.add(
      'Расчётный ток выбранных комплектов выше паспортного тока терморегулятора: нужна проектная схема коммутации, например через подходящий контактор.',
    );
  }

  return CanonicalCalculatorContractResult(
    canonicalSpecId: spec.calculatorId,
    formulaVersion: spec.formulaVersion,
    materials: materials,
    totals: {
      'roomArea': roundValue(roomArea, 3),
      'excludedAreaM2': roundValue(excludedArea, 3),
      'availableAreaM2': roundValue(availableArea, 3),
      'heatingArea': roundValue(layoutArea, 3),
      'systemType': systemType.toDouble(),
      'kitCount': kitCount.toDouble(),
      'kitCoverageAreaM2': roundValue(kitCoverageAreaM2, 3),
      'selectedCoverageAreaM2': roundValue(selectedCoverageAreaM2, 3),
      'kitRatedPowerW': roundValue(kitRatedPowerW, 3),
      'totalPowerW': roundValue(totalPowerW, 3),
      'totalPowerKW': roundValue(totalPowerW / 1000, 3),
      'installedPowerDensityWm2': roundValue(
        installedPowerDensityWm2,
        3,
      ),
      'supplyVoltageV': roundValue(supplyVoltageV, 3),
      'circuitCurrentA': roundValue(circuitCurrentA, 3),
      'thermostatRatedCurrentA': roundValue(thermostatRatedCurrentA, 3),
      'thermostatLoadPercent': roundValue(thermostatLoadPercent, 3),
      'thermostatCount': thermostatCount.toDouble(),
      'floorSensorCount': floorSensorCount.toDouble(),
      'cableLengthPerKitM': systemType == 1
          ? roundValue(cableLengthPerKitM, 3)
          : 0,
      'cableLength': roundValue(totalCableLengthM, 3),
      'cableStepMm': roundValue(cableStepMm, 3),
      'designHeatLoadW': roundValue(designHeatLoadW, 3),
      'designPowerMarginW': roundValue(designPowerMarginW, 3),
      'sensorConduitLengthM': roundValue(sensorConduitLengthM, 3),
      'sensorConduitStockLengthM': roundValue(
        sensorConduitStockLengthM,
        3,
      ),
      'conduitStockCount': conduitStockCount.toDouble(),
      'conduitPurchaseLengthM': roundValue(conduitPurchaseLengthM, 3),
      'minExactNeed': kitCount.toDouble(),
      'recExactNeed': kitCount.toDouble(),
      'maxExactNeed': kitCount.toDouble(),
      'minPurchase': kitCount.toDouble(),
      'recPurchase': kitCount.toDouble(),
      'maxPurchase': kitCount.toDouble(),
    },
    warnings: warnings,
    scenarios: scenarios,
  );
}
