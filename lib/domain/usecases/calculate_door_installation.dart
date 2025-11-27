import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор установки дверей.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 475-2016 "Блоки дверные"
///
/// Поля:
/// - doors: количество дверей, по умолчанию 1
/// - doorWidth: ширина двери (м), по умолчанию 0.9
/// - doorHeight: высота двери (м), по умолчанию 2.1
/// - doorType: тип двери (1=межкомнатная, 2=входная), по умолчанию 1
class CalculateDoorInstallation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final doors = inputs['doors'] ?? 1;
    if (doors < 1) return 'Количество дверей должно быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final doors = getIntInput(inputs, 'doors', defaultValue: 1, minValue: 1, maxValue: 30);
    final doorWidth = getInput(inputs, 'doorWidth', defaultValue: 0.9, minValue: 0.6, maxValue: 1.4);
    final doorHeight = getInput(inputs, 'doorHeight', defaultValue: 2.1, minValue: 1.8, maxValue: 2.5);
    final doorType = getIntInput(inputs, 'doorType', defaultValue: 1, minValue: 1, maxValue: 2);

    // Площадь одной двери
    final doorArea = doorWidth * doorHeight;

    // Периметр двери
    final doorPerimeter = (doorWidth + doorHeight) * 2;

    // Монтажная пена: 1-2 баллона на дверь
    final foamPerDoor = doorType == 2 ? 2 : 1; // для входной больше
    final foamNeeded = doors * foamPerDoor;

    // Наличники: периметр двери × 2 (с двух сторон) - для межкомнатных
    // Для входных - только со стороны помещения
    final architraveMultiplier = doorType == 1 ? 2 : 1;
    final architraveLength = doorPerimeter * architraveMultiplier * doors;

    // Коробка (дверная лутка): включена в комплект двери
    final framesNeeded = doors;

    // Петли: 2-3 шт на межкомнатную, 3-4 на входную
    final hingesPerDoor = doorType == 1 ? 2 : 3;
    final hingesNeeded = doors * hingesPerDoor;

    // Замки/ручки: 1 комплект на дверь
    final locksNeeded = doors;

    // Доводчик (для входной): 1 шт
    final closersNeeded = doorType == 2 ? doors : 0;

    // Уплотнитель (для входной): периметр двери
    final sealLength = doorType == 2 ? doorPerimeter * doors : 0.0;

    // Порожек: 1 шт на дверь
    final thresholdsNeeded = doors;

    // Монтажные пластины/анкера: 6-8 шт на дверь
    final anchorsNeeded = doors * 7;

    // Саморезы: ~20 шт на дверь
    final screwsNeeded = doors * 20;

    // Расчёт стоимости
    final doorPrice = doorType == 1
        ? findPrice(priceList, ['door', 'door_interior', 'interior_door'])
        : findPrice(priceList, ['door_entrance', 'door_exterior', 'entrance_door']);
    final foamPrice = findPrice(priceList, ['foam_mounting', 'foam', 'polyurethane_foam']);
    final architravePrice = findPrice(priceList, ['architrave', 'door_architrave', 'trim']);
    final framePrice = findPrice(priceList, ['door_frame', 'frame', 'door_jamb']);
    final hingePrice = findPrice(priceList, ['hinge', 'door_hinge']);
    final lockPrice = findPrice(priceList, ['lock', 'door_lock', 'door_handle']);
    final closerPrice = findPrice(priceList, ['closer', 'door_closer']);
    final sealPrice = findPrice(priceList, ['seal', 'door_seal', 'weather_strip']);
    final thresholdPrice = findPrice(priceList, ['threshold', 'door_threshold']);

    final costs = [
      calculateCost(doors.toDouble(), doorPrice?.price),
      calculateCost(foamNeeded.toDouble(), foamPrice?.price),
      calculateCost(architraveLength, architravePrice?.price),
      calculateCost(hingesNeeded.toDouble(), hingePrice?.price),
      calculateCost(locksNeeded.toDouble(), lockPrice?.price),
      if (closersNeeded > 0) calculateCost(closersNeeded.toDouble(), closerPrice?.price),
      if (sealLength > 0) calculateCost(sealLength, sealPrice?.price),
      calculateCost(thresholdsNeeded.toDouble(), thresholdPrice?.price),
    ];

    return createResult(
      values: {
        'doors': doors.toDouble(),
        'doorArea': doorArea,
        'foamNeeded': foamNeeded.toDouble(),
        'architraveLength': architraveLength,
        'framesNeeded': framesNeeded.toDouble(),
        'hingesNeeded': hingesNeeded.toDouble(),
        'locksNeeded': locksNeeded.toDouble(),
        if (closersNeeded > 0) 'closersNeeded': closersNeeded.toDouble(),
        if (sealLength > 0) 'sealLength': sealLength,
        'thresholdsNeeded': thresholdsNeeded.toDouble(),
        'anchorsNeeded': anchorsNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
