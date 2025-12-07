import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

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

    final area = inputs['area'] ?? 0;
    final power = inputs['power'] ?? 150;
    final type = inputs['type'] ?? 2;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (power < 80 || power > 200) return 'Мощность должна быть от 80 до 200 Вт/м²';
    if (type < 1 || type > 2) return 'Тип должен быть 1 (кабель) или 2 (мат)';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final power = getInput(inputs, 'power', defaultValue: 150.0, minValue: 80.0, maxValue: 200.0);
    final type = getIntInput(inputs, 'type', defaultValue: 2, minValue: 1, maxValue: 2);
    final thermostats = getIntInput(inputs, 'thermostats', defaultValue: 1, minValue: 1, maxValue: 10);

    // Полезная площадь (не укладывается под мебель и стационарную технику)
    // Обычно 60-70% от общей площади
    const usefulAreaRatio = 0.7; // 70% полезной площади
    final usefulArea = area * usefulAreaRatio;

    // Общая мощность системы (Вт)
    final totalPower = usefulArea * power;

    // Расчёт материалов в зависимости от типа
    double cableLength = 0.0;
    double matArea = 0.0;

    if (type == 1) {
      // Нагревательный кабель: укладывается с шагом 10-15 см
      // Плотность укладки: ~5-6 м кабеля на 1 м² (для мощности 150 Вт/м²)
      cableLength = usefulArea * 4;
    } else {
      // Нагревательный мат: готовая секция с фиксированным шагом
      matArea = usefulArea;
    }

    // Теплоизоляция: фольгированный пенополиэтилен под всей площадью
    // Рекомендуется 3-5 мм толщина
    final insulationArea = area;

    // Монтажная лента (для кабеля): крепление кабеля к полу
    // ~20-25 м на комнату среднего размера
    final montageTapeLength = type == 1 ? (area * 1.5) : 0.0;

    // Гофрированная труба для датчика температуры: ~2-3 м на терморегулятор
    final corrugatedTubeLength = thermostats * 2.5;

    // Демпферная лента по периметру: периметр + 5%
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final damperTapeLength = addMargin(perimeter, 5.0);

    // УЗО (устройство защитного отключения): 1 шт на систему
    const rcdNeeded = 1;

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

