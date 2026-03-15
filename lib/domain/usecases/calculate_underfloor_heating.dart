// ignore_for_file: prefer_const_declarations
import 'dart:math' show max, sqrt;

import '../../data/models/price_item.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';

/// Калькулятор тёплого пола.
///
/// Нормативы:
/// - СП 60.13330.2020 "Отопление, вентиляция и кондиционирование воздуха"
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
///
/// Поля legacy-path:
/// - area: площадь помещения (м²)
/// - systemType: тип системы (1=электромат, 2=кабель, 3=ИК плёнка, 4=водяной)
/// - roomType: тип помещения (1=ванная, 2=жилая, 3=кухня, 4=балкон)
/// - usefulAreaPercent: процент полезной площади (50-90%), по умолчанию 72%
/// - addInsulation: добавить теплоизоляцию (0 или 1), по умолчанию 0
/// - filmWidth: ширина ИК плёнки (0=50см, 1=80см, 2=100см), по умолчанию 1 (80см)
///
/// Screen-path дополнительно поддерживает:
/// - inputMode: 0=по площади, 1=по размерам
/// - length: длина помещения (м)
/// - width: ширина помещения (м)
class CalculateUnderfloorHeating extends BaseCalculator {
  static const _roomPower = {1: 180.0, 2: 150.0, 3: 130.0, 4: 200.0};

  static const _pipeStep = {1: 100, 2: 150, 3: 150, 4: 100};

  static const _filmWidths = {0: 0.5, 1: 0.8, 2: 1.0};

  static const _cablePowerPerMeter = 18.0;
  static const _montageTapeMultiplier = 2.0;
  static const _pipeMargin = 1.15;
  static const _maxLoopLength = 100.0;
  static const _screedThickness = 0.08;
  static const _bracketsPerM2 = 10.0;
  static const _thermostatCount = 1.0;
  static const _sensorCount = 1.0;
  static const _corrugatedTubeLength = 2.5;
  static const _contactsPerStrip = 2;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final hasDimensions =
        (inputs['length'] ?? 0) > 0 && (inputs['width'] ?? 0) > 0;
    if (area <= 0 && !hasDimensions) {
      return areaOrRoomDimensionsRequiredMessage();
    }
    if (area > 1000) return maxValueMessage('area', 1000, unit: 'м²');

    return null;
  }

  bool _hasScreenInputs(Map<String, double> inputs) {
    return inputs.containsKey('inputMode') ||
        inputs.containsKey('length') ||
        inputs.containsKey('width');
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasScreenInputs(inputs)) {
      return _calculateScreenPath(inputs, priceList);
    }
    return _calculateLegacyPath(inputs, priceList);
  }

  CalculatorResult _calculateLegacyPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1, maxValue: 1000.0);
    final systemType = getIntInput(
      inputs,
      'systemType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 4,
    );
    final roomType = getIntInput(
      inputs,
      'roomType',
      defaultValue: 2,
      minValue: 1,
      maxValue: 4,
    );
    final usefulAreaPercent = getInput(
      inputs,
      'usefulAreaPercent',
      defaultValue: 72.0,
      minValue: 50.0,
      maxValue: 90.0,
    );
    final addInsulation = getIntInput(
      inputs,
      'addInsulation',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );

    return _calculateCore(
      area: area,
      perimeter: sqrt(area) * 4,
      systemType: systemType,
      roomType: roomType,
      usefulAreaPercent: usefulAreaPercent,
      addInsulation: addInsulation == 1,
      filmWidthIndex: getIntInput(
        inputs,
        'filmWidth',
        defaultValue: 1,
        minValue: 0,
        maxValue: 2,
      ),
      useScreenFilmPlanning: false,
      inputMode: 0,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateScreenPath(
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
    final area = inputMode == 0
        ? getInput(inputs, 'area', minValue: 0.1, maxValue: 1000.0)
        : getInput(inputs, 'length', minValue: 0.1, maxValue: 100.0) *
              getInput(inputs, 'width', minValue: 0.1, maxValue: 100.0);
    final length = getInput(
      inputs,
      'length',
      defaultValue: sqrt(area),
      minValue: 0.1,
      maxValue: 100.0,
    );
    final width = getInput(
      inputs,
      'width',
      defaultValue: sqrt(area),
      minValue: 0.1,
      maxValue: 100.0,
    );

    return _calculateCore(
      area: area,
      perimeter: inputMode == 1 ? (length + width) * 2 : sqrt(area) * 4,
      systemType: getIntInput(
        inputs,
        'systemType',
        defaultValue: 1,
        minValue: 1,
        maxValue: 4,
      ),
      roomType: getIntInput(
        inputs,
        'roomType',
        defaultValue: 2,
        minValue: 1,
        maxValue: 4,
      ),
      usefulAreaPercent: getInput(
        inputs,
        'usefulAreaPercent',
        defaultValue: 72.0,
        minValue: 50.0,
        maxValue: 90.0,
      ),
      addInsulation:
          getIntInput(
            inputs,
            'addInsulation',
            defaultValue: 0,
            minValue: 0,
            maxValue: 1,
          ) ==
          1,
      filmWidthIndex: getIntInput(
        inputs,
        'filmWidth',
        defaultValue: 1,
        minValue: 0,
        maxValue: 2,
      ),
      useScreenFilmPlanning: true,
      inputMode: inputMode,
      length: length,
      width: width,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateCore({
    required double area,
    required double perimeter,
    required int systemType,
    required int roomType,
    required double usefulAreaPercent,
    required bool addInsulation,
    required int filmWidthIndex,
    required bool useScreenFilmPlanning,
    required int inputMode,
    double? length,
    double? width,
    required List<PriceItem> priceList,
  }) {
    final heatingArea = area * (usefulAreaPercent / 100);
    final roomPowerValue = _roomPower[roomType] ?? 150.0;
    final totalPower = (heatingArea * roomPowerValue).round();

    final values = <String, double>{
      'inputMode': inputMode.toDouble(),
      'area': area,
      'perimeter': perimeter,
      'heatingArea': heatingArea,
      'totalPower': totalPower.toDouble(),
      'systemType': systemType.toDouble(),
      'roomType': roomType.toDouble(),
      'usefulAreaPercent': usefulAreaPercent,
      'addInsulation': addInsulation ? 1.0 : 0.0,
      'thermostatCount': _thermostatCount,
      'sensorCount': _sensorCount,
      'corrugatedTubeLength': _corrugatedTubeLength,
    };

    final costs = <double?>[];

    switch (systemType) {
      case 1:
        values['matArea'] = heatingArea;
        final matPrice = findPrice(priceList, [
          'heating_mat',
          'electric_mat',
          'warm_floor_mat',
        ]);
        costs.add(calculateCost(heatingArea, matPrice?.price));
        break;

      case 2:
        final cableLength = totalPower / _cablePowerPerMeter;
        final montageTapeLength = heatingArea * _montageTapeMultiplier;
        values['cableLength'] = cableLength;
        values['montageTapeLength'] = montageTapeLength;
        final cablePrice = findPrice(priceList, [
          'heating_cable',
          'electric_cable',
          'warm_floor_cable',
        ]);
        final tapePrice = findPrice(priceList, [
          'montage_tape',
          'mounting_tape',
        ]);
        costs.add(calculateCost(cableLength, cablePrice?.price));
        costs.add(calculateCost(montageTapeLength, tapePrice?.price));
        break;

      case 3:
        final filmWidthM = _filmWidths[filmWidthIndex] ?? 0.8;
        final filmWidthCm = (filmWidthM * 100).toInt();

        double filmArea;
        double filmLinearMeters;
        int filmStrips;
        int contactClips;

        if (useScreenFilmPlanning) {
          const wallOffset = 0.30;
          double effectiveLength;
          double effectiveWidth;
          if (inputMode == 1 && length != null && width != null) {
            effectiveLength = max(length - 2 * wallOffset, 0.5);
            effectiveWidth = max(width - 2 * wallOffset, 0.5);
          } else {
            final side = sqrt(area);
            effectiveLength = max(side * 1.15 - 2 * wallOffset, 0.5);
            effectiveWidth = max(side * 0.87 - 2 * wallOffset, 0.5);
          }
          filmStrips = max((effectiveWidth / filmWidthM).floor(), 1);
          final stripLength = effectiveLength;
          filmLinearMeters = filmStrips * stripLength;
          filmArea = filmLinearMeters * filmWidthM;
          contactClips = filmStrips * _contactsPerStrip;
        } else {
          filmArea = heatingArea;
          filmLinearMeters = filmArea / filmWidthM;
          filmStrips = (filmLinearMeters / 5.0).ceil();
          contactClips = filmStrips * _contactsPerStrip;
        }

        values['filmArea'] = filmArea;
        values['filmWidthCm'] = filmWidthCm.toDouble();
        values['filmLinearMeters'] = filmLinearMeters;
        values['filmStrips'] = filmStrips.toDouble();
        values['contactClips'] = contactClips.toDouble();
        values['reflectiveSubstrate'] = area;

        final filmPrice = findPrice(priceList, [
          'ir_film',
          'infrared_film',
          'warm_floor_film',
        ]);
        final clipsPrice = findPrice(priceList, [
          'contact_clips',
          'connectors',
        ]);
        final substratePrice = findPrice(priceList, [
          'reflective_substrate',
          'foil_substrate',
        ]);
        costs.add(calculateCost(filmLinearMeters, filmPrice?.price));
        costs.add(calculateCost(contactClips.toDouble(), clipsPrice?.price));
        costs.add(calculateCost(area, substratePrice?.price));
        break;

      case 4:
        final pipeStepMm = _pipeStep[roomType] ?? 150;
        final stepM = pipeStepMm / 1000;
        final pipePerM2 = 1 / stepM;
        final pipeLength = heatingArea * pipePerM2 * _pipeMargin;
        final loopCount = (pipeLength / _maxLoopLength).ceil();
        final collectorOutputs = loopCount;
        final screedVolume = area * _screedThickness;
        final damperTapeLength = perimeter * 1.1;
        final bracketsCount = (heatingArea * _bracketsPerM2).ceil();

        values['pipeStep'] = pipeStepMm.toDouble();
        values['pipeLength'] = pipeLength;
        values['loopCount'] = loopCount.toDouble();
        values['collectorOutputs'] = collectorOutputs.toDouble();
        values['insulationArea'] = area;
        values['screedVolume'] = screedVolume;
        values['damperTapeLength'] = damperTapeLength;
        values['bracketsCount'] = bracketsCount.toDouble();

        final pipePrice = findPrice(priceList, [
          'pipe_pert',
          'pert_pipe',
          'underfloor_pipe',
        ]);
        final collectorPrice = findPrice(priceList, ['collector', 'manifold']);
        final insulationPrice = findPrice(priceList, [
          'floor_insulation',
          'psb_insulation',
          'eps_insulation',
        ]);
        final damperPrice = findPrice(priceList, ['damper_tape', 'edge_tape']);
        final bracketsPrice = findPrice(priceList, [
          'pipe_brackets',
          'fixing_clips',
        ]);
        costs.add(calculateCost(pipeLength, pipePrice?.price));
        costs.add(
          calculateCost(
            collectorOutputs.toDouble() * 1000,
            collectorPrice?.price,
          ),
        );
        costs.add(calculateCost(area, insulationPrice?.price));
        costs.add(calculateCost(damperTapeLength, damperPrice?.price));
        costs.add(
          calculateCost(bracketsCount.toDouble(), bracketsPrice?.price),
        );
        break;
    }

    if (addInsulation && systemType != 4) {
      values['insulationArea'] = area;
      final insulationPrice = findPrice(priceList, [
        'floor_insulation',
        'penofol',
        'foam_insulation',
      ]);
      costs.add(calculateCost(area, insulationPrice?.price));
    }

    final thermostatPrice = findPrice(priceList, [
      'thermostat',
      'floor_thermostat',
      'temperature_controller',
    ]);
    final sensorPrice = findPrice(priceList, ['temp_sensor', 'floor_sensor']);
    final tubePrice = findPrice(priceList, [
      'corrugated_tube',
      'flexible_tube',
    ]);
    costs.add(calculateCost(_thermostatCount, thermostatPrice?.price));
    costs.add(calculateCost(_sensorCount, sensorPrice?.price));
    costs.add(calculateCost(_corrugatedTubeLength, tubePrice?.price));

    return createResult(
      values: values,
      totalPrice: sumCosts(costs),
      decimals: 1,
    );
  }
}
