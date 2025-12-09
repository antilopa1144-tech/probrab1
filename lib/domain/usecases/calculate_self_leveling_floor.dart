// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор наливного пола.
///
/// Нормативы:
/// - СНиП 2.03.13-88 "Полы"
/// - ГОСТ 31356-2007 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь пола (м²)
/// - thickness: толщина слоя (мм), по умолчанию 5
class CalculateSelfLevelingFloor extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 5.0;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (thickness < 1 || thickness > 50) return 'Толщина должна быть от 1 до 50 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 5.0, minValue: 1.0, maxValue: 50.0);

    // Расход наливного пола: ~1.5 кг/м² на 1 мм толщины
    const consumptionPerMm = 1.5; // кг/м²·мм
    final mixNeeded = area * consumptionPerMm * thickness * 1.1; // +10% запас

    // Грунтовка глубокого проникновения: 2 слоя по ~0.15 л/м²
    final primerNeeded = area * 0.2 * 1.1;

    // Демпферная лента по периметру: периметр + 5%
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final damperTapeLength = addMargin(perimeter, 5.0);

    // Игольчатые валики для раскатки: 1-2 шт в зависимости от площади
    final rollersNeeded = ceilToInt(area / 50); // 1 валик на 50 м²

    // Краскоступы (для хождения по свежему полу): 1 пара
    const shoesNeeded = 1;

    // Расход воды (информативно): ~0.15-0.2 л на кг смеси
    final waterNeeded = mixNeeded * 0.175; // л

    // Расчёт стоимости
    final mixPrice = findPrice(priceList, ['self_leveling', 'self_leveling_floor', 'leveling_compound', 'floor_leveler']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_penetrating']);
    final damperTapePrice = findPrice(priceList, ['damper_tape', 'tape_edge', 'expansion_tape']);
    final rollerPrice = findPrice(priceList, ['roller_spiked', 'needle_roller']);
    final shoesPrice = findPrice(priceList, ['shoes_spiked', 'cleats']);

    final costs = [
      calculateCost(mixNeeded, mixPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(damperTapeLength, damperTapePrice?.price),
      calculateCost(rollersNeeded.toDouble(), rollerPrice?.price),
      calculateCost(shoesNeeded.toDouble(), shoesPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'mixNeeded': mixNeeded,
        'primerNeeded': primerNeeded,
        'damperTapeLength': damperTapeLength,
        'rollersNeeded': rollersNeeded.toDouble(),
        'shoesNeeded': shoesNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
