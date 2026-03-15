import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Универсальный калькулятор бетона.
///
/// Варианты использования:
/// - Готовый бетон: считает только объём
/// - Замес вручную: дополнительно считает цемент/песок/щебень/воду по типовой пропорции
///
/// Поля:
/// - inputMode: 0 = по объёму, 1 = по площади/толщине
/// - concreteVolume: объём бетона (м³)
/// - area: площадь (м²) для screen-path
/// - thickness: толщина (мм) для screen-path
/// - concreteGrade: марка бетона (1=М100..7=М400), по умолч. 3 (М200)
/// - manualMix: 1 = замес вручную
/// - reserve: запас (%) по умолчанию 5
/// - mixerVolume: объём бетономешалки (л), по умолчанию 150
///
/// Legacy output сохраняется:
/// - concreteVolume: округлённый закупочный объём
/// - cementBags / sandVolume / gravelVolume / waterNeeded
///
/// Дополнительный screen-oriented output:
/// - baseConcreteVolume: точный объём до запаса
/// - concreteVolumeExact: точный объём с запасом
/// - mixerCount / totalWeight / batchCount
/// - sandVolumeExact / gravelVolumeExact / waterNeededExact
class CalculateConcreteUniversal extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = getIntInput(
      inputs,
      'inputMode',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    if (inputMode == 1) {
      final area = inputs['area'] ?? 0;
      final thickness = inputs['thickness'] ?? 0;
      if (area <= 0) return positiveValueMessage('area');
      if (thickness <= 0) return positiveValueMessage('thickness');
      return null;
    }

    final volume = inputs['concreteVolume'] ?? 0;
    if (volume <= 0) return positiveValueMessage('volume');

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final inputMode = getIntInput(
      inputs,
      'inputMode',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final area = getInput(
      inputs,
      'area',
      defaultValue: 10.0,
      minValue: 0.1,
      maxValue: 1000.0,
    );
    final thickness = getInput(
      inputs,
      'thickness',
      defaultValue: 100.0,
      minValue: 50.0,
      maxValue: 500.0,
    );
    final reservePercent = getInput(
      inputs,
      'reserve',
      defaultValue: 5.0,
      minValue: 0.0,
      maxValue: 30.0,
    );
    final manualMix = getIntInput(inputs, 'manualMix', defaultValue: 0) != 0;
    final mixerVolume = getInput(
      inputs,
      'mixerVolume',
      defaultValue: 150.0,
      minValue: 100.0,
      maxValue: 500.0,
    );

    // Марка бетона: 1=М100, 2=М150, 3=М200(default), 4=М250, 5=М300, 6=М350, 7=М400
    final concreteGrade = getIntInput(
      inputs,
      'concreteGrade',
      defaultValue: 3,
      minValue: 1,
      maxValue: 7,
    );

    final sourceVolume = inputMode == 1
        ? area * (thickness / 1000)
        : getInput(
            inputs,
            'concreteVolume',
            defaultValue: 1.0,
            minValue: 0.01,
            maxValue: 1000.0,
          );
    final concreteVolumeExact = sourceVolume * (1 + reservePercent / 100);
    final concreteVolumeRounded = roundBulk(concreteVolumeExact);

    // Пропорции на 1 м³ (цемент М400, по СНиП)
    final proportions = _getProportions(concreteGrade);
    final cementPerM3 = proportions[0];
    final sandPerM3 = proportions[1];
    final gravelPerM3 = proportions[2];
    final waterPerM3 = proportions[3];

    final cementBags = manualMix
        ? ceilToInt(concreteVolumeExact * cementPerM3 / 50)
        : 0;
    final sandVolumeExact = manualMix ? concreteVolumeExact * sandPerM3 : 0.0;
    final gravelVolumeExact = manualMix
        ? concreteVolumeExact * gravelPerM3
        : 0.0;
    final waterNeededExact = manualMix ? concreteVolumeExact * waterPerM3 : 0.0;

    final concretePrice = findPrice(priceList, [
      'concrete',
      'ready_mix',
      'beton',
    ]);
    final cementPrice = findPrice(priceList, [
      'cement',
      'cement_m400',
      'cement_m500',
    ]);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone']);
    final waterPrice = findPrice(priceList, ['water']);

    final mixerCount = ceilToInt(concreteVolumeExact / 7.0);
    final totalWeight = concreteVolumeExact * 2400;
    final mixerOutputVolume = (mixerVolume / 1000) * 0.65;
    final batchCount = manualMix
        ? ceilToInt(concreteVolumeExact / mixerOutputVolume)
        : 0;

    // Стоимость: готовый бетон ИЛИ компоненты (не суммировать оба варианта)
    final costs = manualMix
        ? [
            calculateCost(cementBags.toDouble(), cementPrice?.price),
            calculateCost(sandVolumeExact, sandPrice?.price),
            calculateCost(gravelVolumeExact, gravelPrice?.price),
            calculateCost(waterNeededExact, waterPrice?.price),
          ]
        : [calculateCost(concreteVolumeExact, concretePrice?.price)];

    return createResult(
      values: {
        'inputMode': inputMode.toDouble(),
        'concreteVolume': concreteVolumeRounded,
        'concreteVolumeExact': concreteVolumeExact,
        'baseConcreteVolume': sourceVolume,
        'concreteGrade': concreteGrade.toDouble(),
        'reserve': reservePercent,
        'mixerVolume': mixerVolume,
        'mixerCount': mixerCount.toDouble(),
        'totalWeight': totalWeight,
        'batchCount': batchCount.toDouble(),
        if (inputMode == 1) ...{'area': area, 'thickness': thickness},
        if (manualMix) ...{
          'cementBags': cementBags.toDouble(),
          'sandVolume': roundBulk(sandVolumeExact),
          'gravelVolume': roundBulk(gravelVolumeExact),
          'waterNeeded': roundBulk(waterNeededExact),
          'sandVolumeExact': sandVolumeExact,
          'gravelVolumeExact': gravelVolumeExact,
          'waterNeededExact': waterNeededExact,
        },
      },
      totalPrice: sumCosts(costs),
    );
  }

  /// Пропорции на 1 м³ бетона (цемент М400, по СНиП).
  ///
  /// Возвращает [cementKg, sandM3, gravelM3, waterL].
  static List<double> _getProportions(int grade) {
    switch (grade) {
      case 1:
        return [170, 0.56, 0.88, 210]; // М100
      case 2:
        return [215, 0.54, 0.86, 200]; // М150
      case 3:
        return [290, 0.50, 0.82, 190]; // М200
      case 4:
        return [340, 0.47, 0.80, 185]; // М250
      case 5:
        return [380, 0.44, 0.78, 180]; // М300
      case 6:
        return [420, 0.41, 0.76, 175]; // М350
      case 7:
        return [480, 0.38, 0.73, 170]; // М400
      default:
        return [290, 0.50, 0.82, 190]; // М200 fallback
    }
  }
}
