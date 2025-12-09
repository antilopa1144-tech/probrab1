// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор грунтовки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - layers: количество слоёв, по умолчанию 1
/// - type: тип (1=обычная, 2=глубокого проникновения, 3=адгезионная), по умолчанию 2
class CalculatePrimer extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(inputs, 'layers', defaultValue: 1, minValue: 1, maxValue: 3);
    final type = getIntInput(inputs, 'type', defaultValue: 2, minValue: 1, maxValue: 3);

    // Расход грунтовки зависит от типа и впитываемости поверхности:
    // - Обычная: 0.08-0.12 л/м²
    // - Глубокого проникновения: 0.12-0.18 л/м²
    // - Адгезионная (бетоноконтакт): 0.25-0.35 л/м²
    final consumptionPerLayer = type == 1 ? 0.1 : (type == 2 ? 0.15 : 0.3);

    // Общий расход с учётом слоёв и запаса 10%
    final primerNeeded = area * consumptionPerLayer * layers * 1.1;

    // Валики: 1-2 шт в зависимости от площади
    final rollersNeeded = ceilToInt(area / 30); // 1 валик на ~30-50 м²

    // Кисти для углов: 1-2 шт
    const brushesNeeded = 2;

    // Кювета для валика: 1 шт
    const traysNeeded = 1;

    // Время высыхания (информативно, часов)
    final dryingTime = type == 1 ? 2.0 : (type == 2 ? 4.0 : 3.0);

    // Расчёт стоимости
    final primerPrice = type == 1
        ? findPrice(priceList, ['primer', 'primer_standard', 'primer_universal'])
        : (type == 2 
            ? findPrice(priceList, ['primer_deep', 'primer_penetrating', 'primer'])
            : findPrice(priceList, ['primer_adhesion', 'concrete_contact', 'betokontakt']));

    final costs = [
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'traysNeeded': traysNeeded.toDouble(),
        'dryingTime': dryingTime,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
