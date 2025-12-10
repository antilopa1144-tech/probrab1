// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор натяжного потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - corners: количество углов, по умолчанию 4
/// - fixtures: количество светильников/люстр, по умолчанию 1
class CalculateStretchCeiling extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final corners = inputs['corners'] ?? 4;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (corners < 0 || corners > 20) return 'Количество углов должно быть от 0 до 20';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final corners = getIntInput(inputs, 'corners', defaultValue: 4, minValue: 0, maxValue: 20);
    final fixtures = getIntInput(inputs, 'fixtures', defaultValue: 1, minValue: 0, maxValue: 20);

    // Периметр: если указан - используем, иначе оцениваем
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);

    // Полотно: площадь с небольшим запасом (3-5%)
    // Натяжные потолки кроятся по размеру с точностью до см
    final canvasArea = addMargin(area, 3.0);

    // Багет (профиль для крепления): периметр + запас 3% на углы и стыки
    final baguetteLength = addMargin(perimeter, 3.0);

    // Углы профиля: внутренние и внешние углы (если комната не прямоугольная)
    final cornerProfilesNeeded = corners > 0 ? corners : 4;

    // Светильники: отверстия под светильники требуют термоколец
    final thermoRingsNeeded = fixtures;

    // Вентиляционные решётки (если нужны): обычно 1-2 шт
    final ventGrillesNeeded = getIntInput(inputs, 'ventGrilles', defaultValue: 0, minValue: 0, maxValue: 10);

    // Обход труб (если есть): обычно в санузлах
    final pipesNeeded = getIntInput(inputs, 'pipes', defaultValue: 0, minValue: 0, maxValue: 10);

    // Заглушка для багета: периметр (м)
    final insertLength = perimeter;

    // Тип потолка влияет на цену (глянцевый дороже матового на ~20-30%)
    final ceilingType = getIntInput(inputs, 'ceilingType', defaultValue: 1, minValue: 1, maxValue: 3);
    // 1 = матовый, 2 = сатиновый, 3 = глянцевый
    final typeMultiplier = ceilingType == 3 ? 1.3 : (ceilingType == 2 ? 1.15 : 1.0);

    // Расчёт стоимости
    final canvasPrice = findPrice(priceList, ['ceiling_stretch', 'ceiling_canvas', 'stretch_ceiling']);
    final baguettePrice = findPrice(priceList, ['baguette', 'baguette_ceiling', 'ceiling_profile']);
    final cornerPrice = findPrice(priceList, ['corner_profile', 'corner']);
    final thermoRingPrice = findPrice(priceList, ['thermo_ring', 'light_ring']);
    final ventGrillePrice = findPrice(priceList, ['vent_grille', 'ventilation']);
    final pipeBypassPrice = findPrice(priceList, ['pipe_bypass', 'pipe_collar']);
    final insertPrice = findPrice(priceList, ['insert', 'baguette_insert']);

    final costs = [
      calculateCost(canvasArea * typeMultiplier, canvasPrice?.price),
      calculateCost(baguetteLength, baguettePrice?.price),
      calculateCost(cornerProfilesNeeded.toDouble(), cornerPrice?.price),
      calculateCost(thermoRingsNeeded.toDouble(), thermoRingPrice?.price),
      calculateCost(ventGrillesNeeded.toDouble(), ventGrillePrice?.price),
      calculateCost(pipesNeeded.toDouble(), pipeBypassPrice?.price),
      calculateCost(insertLength, insertPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'canvasArea': canvasArea,
        'baguetteLength': baguetteLength,
        'cornersNeeded': cornerProfilesNeeded.toDouble(),
        'fixtures': fixtures.toDouble(),
        'thermoRingsNeeded': thermoRingsNeeded.toDouble(),
        'ventGrillesNeeded': ventGrillesNeeded.toDouble(),
        'pipesNeeded': pipesNeeded.toDouble(),
        'insertLength': insertLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}

