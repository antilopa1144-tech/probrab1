// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор тёплого пола.
///
/// Нормативы:
/// - СП 60.13330.2020 "Отопление, вентиляция и кондиционирование воздуха"
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
///
/// Поля:
/// - area: площадь помещения (м²)
/// - systemType: тип системы (1=электромат, 2=кабель, 3=ИК плёнка, 4=водяной)
/// - roomType: тип помещения (1=ванная, 2=жилая, 3=кухня, 4=балкон)
/// - usefulAreaPercent: процент полезной площади (50-90%), по умолчанию 72%
/// - addInsulation: добавить теплоизоляцию (0 или 1), по умолчанию 0
class CalculateUnderfloorHeating extends BaseCalculator {
  // Константы мощности по типу помещения (Вт/м²)
  static const _roomPower = {
    1: 180.0, // ванная
    2: 120.0, // жилая
    3: 130.0, // кухня
    4: 200.0, // балкон
  };

  // Шаг укладки труб по типу помещения (мм)
  static const _pipeStep = {
    1: 150, // ванная
    2: 150, // жилая
    3: 150, // кухня
    4: 100, // балкон
  };

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (area > 1000) return 'Площадь превышает допустимый максимум';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(
      inputs,
      'area',
      minValue: 0.1,
      maxValue: 1000.0,
    );
    final systemType = getIntInput(inputs, 'systemType', defaultValue: 1, minValue: 1, maxValue: 4);
    final roomType = getIntInput(inputs, 'roomType', defaultValue: 2, minValue: 1, maxValue: 4);
    final usefulAreaPercent = getInput(inputs, 'usefulAreaPercent', defaultValue: 72.0, minValue: 50.0, maxValue: 90.0);
    final addInsulation = getIntInput(inputs, 'addInsulation', defaultValue: 0, minValue: 0, maxValue: 1);

    // Площадь обогрева (минус мебель, сантехника)
    final heatingArea = area * (usefulAreaPercent / 100);

    // Мощность по типу помещения
    final roomPowerValue = _roomPower[roomType] ?? 150.0;
    final totalPower = (heatingArea * roomPowerValue).round();

    // Общие материалы
    final thermostatCount = 1;
    final sensorCount = 1;
    final corrugatedTubeLength = 2.5; // м для датчика

    final values = <String, double>{
      'area': area,
      'heatingArea': heatingArea,
      'totalPower': totalPower.toDouble(),
      'systemType': systemType.toDouble(),
      'roomType': roomType.toDouble(),
      'thermostatCount': thermostatCount.toDouble(),
      'sensorCount': sensorCount.toDouble(),
      'corrugatedTubeLength': corrugatedTubeLength,
    };

    final costs = <double?>[];

    // Расчёт по типу системы
    switch (systemType) {
      case 1: // Электрический мат
        final matArea = heatingArea;
        values['matArea'] = matArea;
        final matPrice = findPrice(priceList, ['heating_mat', 'electric_mat', 'warm_floor_mat']);
        costs.add(calculateCost(matArea, matPrice?.price));
        break;

      case 2: // Электрический кабель
        final cablePowerPerMeter = 18.0; // Вт/м
        final cableLength = totalPower / cablePowerPerMeter;
        final montageTapeLength = heatingArea * 2.0;
        values['cableLength'] = cableLength;
        values['montageTapeLength'] = montageTapeLength;
        final cablePrice = findPrice(priceList, ['heating_cable', 'electric_cable', 'warm_floor_cable']);
        final tapePrice = findPrice(priceList, ['montage_tape', 'mounting_tape']);
        costs.add(calculateCost(cableLength, cablePrice?.price));
        costs.add(calculateCost(montageTapeLength, tapePrice?.price));
        break;

      case 3: // ИК плёнка
        final filmArea = heatingArea;
        final filmStripArea = 2.5; // м² на полосу
        final filmStrips = (filmArea / filmStripArea).ceil();
        final contactClips = filmStrips * 2;
        final reflectiveSubstrate = area;
        values['filmArea'] = filmArea;
        values['filmStrips'] = filmStrips.toDouble();
        values['contactClips'] = contactClips.toDouble();
        values['reflectiveSubstrate'] = reflectiveSubstrate;
        final filmPrice = findPrice(priceList, ['ir_film', 'infrared_film', 'warm_floor_film']);
        final clipsPrice = findPrice(priceList, ['contact_clips', 'connectors']);
        final substratePrice = findPrice(priceList, ['reflective_substrate', 'foil_substrate']);
        costs.add(calculateCost(filmArea, filmPrice?.price));
        costs.add(calculateCost(contactClips.toDouble(), clipsPrice?.price));
        costs.add(calculateCost(reflectiveSubstrate, substratePrice?.price));
        break;

      case 4: // Водяной тёплый пол
        final pipeStepMm = _pipeStep[roomType] ?? 150;
        final stepM = pipeStepMm / 1000;
        final pipePerM2 = 1 / stepM; // метров трубы на м²
        final pipeMargin = 1.15; // 15% запас
        final pipeLength = heatingArea * pipePerM2 * pipeMargin;

        final maxLoopLength = 100.0; // м
        final loopCount = (pipeLength / maxLoopLength).ceil();
        final collectorOutputs = loopCount;

        final insulationArea = area;
        final screedThickness = 0.08; // м
        final screedVolume = area * screedThickness;

        final damperTapePerM2 = 0.4;
        final damperTapeLength = area * damperTapePerM2;

        final bracketsPerM2 = 10.0;
        final bracketsCount = (heatingArea * bracketsPerM2).ceil();

        values['pipeLength'] = pipeLength;
        values['loopCount'] = loopCount.toDouble();
        values['collectorOutputs'] = collectorOutputs.toDouble();
        values['insulationArea'] = insulationArea;
        values['screedVolume'] = screedVolume;
        values['damperTapeLength'] = damperTapeLength;
        values['bracketsCount'] = bracketsCount.toDouble();
        values['pipeStep'] = pipeStepMm.toDouble();

        final pipePrice = findPrice(priceList, ['pipe_pert', 'pert_pipe', 'underfloor_pipe']);
        final collectorPrice = findPrice(priceList, ['collector', 'manifold']);
        final insulationPrice = findPrice(priceList, ['floor_insulation', 'psb_insulation', 'eps_insulation']);
        final damperPrice = findPrice(priceList, ['damper_tape', 'edge_tape']);
        final bracketsPrice = findPrice(priceList, ['pipe_brackets', 'fixing_clips']);

        costs.add(calculateCost(pipeLength, pipePrice?.price));
        costs.add(calculateCost(collectorOutputs.toDouble() * 1000, collectorPrice?.price)); // цена за коллектор зависит от выходов
        costs.add(calculateCost(insulationArea, insulationPrice?.price));
        costs.add(calculateCost(damperTapeLength, damperPrice?.price));
        costs.add(calculateCost(bracketsCount.toDouble(), bracketsPrice?.price));
        break;
    }

    // Теплоизоляция (для электрических систем - опционально, для водяной - обязательно)
    if (addInsulation == 1 && systemType != 4) {
      values['insulationArea'] = area;
      final insulationPrice = findPrice(priceList, ['floor_insulation', 'penofol', 'foam_insulation']);
      costs.add(calculateCost(area, insulationPrice?.price));
    }

    // Общие материалы
    final thermostatPrice = findPrice(priceList, ['thermostat', 'floor_thermostat', 'temperature_controller']);
    final sensorPrice = findPrice(priceList, ['temp_sensor', 'floor_sensor']);
    final tubePrice = findPrice(priceList, ['corrugated_tube', 'flexible_tube']);
    costs.add(calculateCost(thermostatCount.toDouble(), thermostatPrice?.price));
    costs.add(calculateCost(sensorCount.toDouble(), sensorPrice?.price));
    costs.add(calculateCost(corrugatedTubeLength, tubePrice?.price));

    return createResult(
      values: values,
      totalPrice: sumCosts(costs),
      decimals: 1,
    );
  }
}
