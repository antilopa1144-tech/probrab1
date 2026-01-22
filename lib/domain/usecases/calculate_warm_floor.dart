// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор тёплого пола (электрический).
///
/// Нормативы:
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
/// - ГОСТ Р 50571.7.701-2013 "Электроустановки зданий"
///
/// Поля:
/// - area: площадь пола (м²)
/// - power: мощность на м² (Вт/м²), по умолчанию 150
/// - type: тип (1=кабель, 2=мат), по умолчанию 2
/// - thermostats: количество терморегуляторов, по умолчанию 1
class CalculateWarmFloor extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = (inputs['inputMode'] ?? 1).toInt();

    if (inputMode == 0) {
      // Режим "По размерам": проверяем length и width
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length <= 0) return 'Длина должна быть больше нуля';
      if (width <= 0) return 'Ширина должна быть больше нуля';
    } else {
      // Режим "По площади": проверяем area
      final area = inputs['area'] ?? 0;
      if (area <= 0) return 'Площадь должна быть больше нуля';
    }

    final power = inputs['power'] ?? 150;
    final type = inputs['type'] ?? 2;

    // Получаем пределы мощности из констант
    final minPower = getConstantDouble('power_limits', 'min_power', defaultValue: 80.0);
    final maxPower = getConstantDouble('power_limits', 'max_power', defaultValue: 200.0);

    if (power < minPower || power > maxPower) {
      return 'Мощность должна быть от ${minPower.toInt()} до ${maxPower.toInt()} Вт/м²';
    }
    if (type < 1 || type > 2) return 'Тип должен быть 1 (кабель) или 2 (мат)';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // --- Режим ввода: по размерам (0) или по площади (1) ---
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 1);

    // Вычисляем площадь и периметр в зависимости от режима
    double area;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам": вычисляем площадь и периметр
      final length = getInput(inputs, 'length', minValue: 0.1);
      final width = getInput(inputs, 'width', minValue: 0.1);
      area = length * width;
      perimeter = (length + width) * 2;
    } else {
      // Режим "По площади": берём готовую площадь
      area = getInput(inputs, 'area', minValue: 0.1);
      // Периметр: если указан - используем, иначе оцениваем
      perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
          ? getInput(inputs, 'perimeter', minValue: 0.1)
          : estimatePerimeter(area);
    }

    // --- Мощность в зависимости от типа помещения ---
    final roomType = getIntInput(inputs, 'roomType', defaultValue: 2, minValue: 0, maxValue: 4);
    double power;

    switch (roomType) {
      case 1: // Ванная
        power = getConstantDouble('room_power', 'bathroom', defaultValue: 180.0);
        break;
      case 2: // Жилая комната
        power = getConstantDouble('room_power', 'living_room', defaultValue: 150.0);
        break;
      case 3: // Кухня
        power = getConstantDouble('room_power', 'kitchen', defaultValue: 130.0);
        break;
      case 4: // Балкон/лоджия
        power = getConstantDouble('room_power', 'balcony', defaultValue: 200.0);
        break;
      default: // Пользовательское значение
        final minPower = getConstantDouble('power_limits', 'min_power', defaultValue: 80.0);
        final maxPower = getConstantDouble('power_limits', 'max_power', defaultValue: 200.0);
        final defaultPower = getConstantDouble('room_power', 'default', defaultValue: 150.0);
        power = getInput(inputs, 'power', defaultValue: defaultPower, minValue: minPower, maxValue: maxPower);
    }

    final type = getIntInput(inputs, 'type', defaultValue: 2, minValue: 1, maxValue: 2);
    final thermostats = getIntInput(inputs, 'thermostats', defaultValue: 1, minValue: 1, maxValue: 10);

    // Полезная площадь (не укладывается под мебель и стационарную технику)
    // Пользователь может настроить процент (50-90%)
    final defaultUsefulPercent = getConstantDouble('useful_area', 'default', defaultValue: 70.0);
    final minUsefulPercent = getConstantDouble('useful_area', 'min', defaultValue: 50.0);
    final maxUsefulPercent = getConstantDouble('useful_area', 'max', defaultValue: 90.0);
    final usefulAreaPercent = getInput(
      inputs,
      'usefulAreaPercent',
      defaultValue: defaultUsefulPercent,
      minValue: minUsefulPercent,
      maxValue: maxUsefulPercent,
    );
    final usefulArea = area * (usefulAreaPercent / 100);

    // Общая мощность системы (Вт)
    final totalPower = usefulArea * power;

    // Расчёт материалов в зависимости от типа
    double cableLength = 0.0;
    double matArea = 0.0;

    if (type == 1) {
      // Нагревательный кабель: длина зависит от общей мощности
      // Стандартный кабель: 17-20 Вт/м, используем 18 Вт/м
      final cablePowerPerMeter = getConstantDouble('cable_power', 'standard_cable', defaultValue: 18.0); // Вт/м
      cableLength = totalPower / cablePowerPerMeter;
    } else {
      // Нагревательный мат: готовая секция с фиксированным шагом
      matArea = usefulArea;
    }

    // Теплоизоляция: фольгированный пенополиэтилен под всей площадью
    // Рекомендуется 3-5 мм толщина
    final insulationArea = area;

    // Монтажная лента (для кабеля): крепление кабеля к полу
    // ~20-25 м на комнату среднего размера
    final montageTapeFactor = getConstantDouble('materials', 'montage_tape_factor', defaultValue: 1.5);
    final montageTapeLength = type == 1 ? (area * montageTapeFactor) : 0.0;

    // Гофрированная труба для датчика температуры: ~2-3 м на терморегулятор
    final corrugatedTubePerThermostat = getConstantDouble(
      'materials',
      'corrugated_tube_per_thermostat',
      defaultValue: 2.5,
    );
    final corrugatedTubeLength = thermostats * corrugatedTubePerThermostat;

    // Демпферная лента по периметру: периметр + 5%
    final damperTapeMargin = getMarginPercent('margins', 'damper_tape_margin', defaultValue: 5.0);
    final damperTapeLength = addMargin(perimeter, damperTapeMargin);

    // УЗО (устройство защитного отключения): 1 шт на систему
    final rcdNeeded = getConstantInt('safety', 'rcd_per_system', defaultValue: 1);

    // Расчёт стоимости
    final cablePrice = findPrice(priceList, ['warm_floor_cable', 'cable_heating', 'heating_cable']);
    final matPrice = findPrice(priceList, ['warm_floor_mat', 'mat_heating', 'heating_mat']);
    final thermostatPrice = findPrice(priceList, ['thermostat', 'thermostat_floor', 'temperature_controller']);
    final insulationPrice = findPrice(priceList, ['insulation_foil', 'foil_insulation', 'foam_insulation']);
    final montTapePrice = findPrice(priceList, ['montage_tape', 'mounting_tape']);
    final corrTubePrice = findPrice(priceList, ['corrugated_tube', 'conduit']);
    final damperTapePrice = findPrice(priceList, ['damper_tape', 'tape_edge']);
    final rcdPrice = findPrice(priceList, ['rcd', 'circuit_breaker', 'gfci']);

    final costs = [
      type == 1 ? calculateCost(cableLength, cablePrice?.price) : null,
      type == 2 ? calculateCost(matArea, matPrice?.price) : null,
      calculateCost(thermostats.toDouble(), thermostatPrice?.price),
      calculateCost(insulationArea, insulationPrice?.price),
      calculateCost(montageTapeLength, montTapePrice?.price),
      calculateCost(corrugatedTubeLength, corrTubePrice?.price),
      calculateCost(damperTapeLength, damperTapePrice?.price),
      calculateCost(rcdNeeded.toDouble(), rcdPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'totalPower': totalPower,
        'cableLength': cableLength,
        'matArea': matArea,
        'thermostats': thermostats.toDouble(),
        'insulationArea': insulationArea,
        'montageTapeLength': montageTapeLength,
        'corrugatedTubeLength': corrugatedTubeLength,
        'damperTapeLength': damperTapeLength,
        'rcdNeeded': rcdNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}

