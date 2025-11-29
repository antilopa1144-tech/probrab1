import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор кассетного потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - cassetteSize: размер кассеты (см), по умолчанию 60 (60×60 см)
/// - perimeter: периметр комнаты (м), опционально
class CalculateCassetteCeiling extends BaseCalculator {
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
    final cassetteSize = getInput(inputs, 'cassetteSize', defaultValue: 60.0, minValue: 30.0, maxValue: 100.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной кассеты в м²
    final cassetteArea = (cassetteSize / 100) * (cassetteSize / 100);

    // Количество кассет с запасом 5%
    final cassettesNeeded = calculateUnitsNeeded(area, cassetteArea, marginPercent: 5.0);

    // Несущий профиль T-24: основные направляющие по длине комнаты
    final mainProfileCount = ceilToInt((perimeter / 4) / (cassetteSize / 100));
    final mainProfileLength = mainProfileCount * (perimeter / 4);

    // Поперечный профиль T-24: по ширине комнаты
    final crossProfileCount = ceilToInt((perimeter / 4) / (cassetteSize / 100));
    final crossProfileLength = crossProfileCount * (perimeter / 4);

    // Периметральный уголок: по периметру + 3%
    final angleLength = addMargin(perimeter, 3.0);

    // Подвесы: шаг 120 см вдоль несущего профиля
    final hangersNeeded = ceilToInt(mainProfileLength / 1.2);

    // Светильники встраиваемые (опционально): 1 на 8-10 м²
    final lightsNeeded = getIntInput(inputs, 'lights', defaultValue: 0, minValue: 0, maxValue: 50);

    // Расчёт стоимости
    final cassettePrice = findPrice(priceList, ['cassette_ceiling', 'cassette', 'ceiling_panel']);
    final mainProfilePrice = findPrice(priceList, ['profile_main', 'profile_t24', 'main_runner']);
    final crossProfilePrice = findPrice(priceList, ['profile_cross', 'cross_tee']);
    final anglePrice = findPrice(priceList, ['angle', 'wall_angle', 'trim_angle']);
    final hangerPrice = findPrice(priceList, ['hanger_cassette', 'hanger', 'suspension']);
    final lightPrice = findPrice(priceList, ['light_recessed', 'ceiling_light']);

    final costs = [
      calculateCost(cassettesNeeded.toDouble(), cassettePrice?.price),
      calculateCost(mainProfileLength, mainProfilePrice?.price),
      calculateCost(crossProfileLength, crossProfilePrice?.price),
      calculateCost(angleLength, anglePrice?.price),
      calculateCost(hangersNeeded.toDouble(), hangerPrice?.price),
      if (lightsNeeded > 0) calculateCost(lightsNeeded.toDouble(), lightPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'cassettesNeeded': cassettesNeeded.toDouble(),
        'mainProfileLength': mainProfileLength,
        'crossProfileLength': crossProfileLength,
        'angleLength': angleLength,
        'hangersNeeded': hangersNeeded.toDouble(),
        if (lightsNeeded > 0) 'lightsNeeded': lightsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
