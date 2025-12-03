import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор вентиляции.
///
/// Нормативы:
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
/// - СП 60.13330.2016 "Отопление, вентиляция и кондиционирование воздуха"
///
/// Поля:
/// - area: площадь помещения (м²)
/// - rooms: количество комнат, по умолчанию 1
/// - ceilingHeight: высота потолков (м), по умолчанию 2.5
class CalculateVentilation extends BaseCalculator {
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
    final rooms = getIntInput(inputs, 'rooms', defaultValue: 1, minValue: 1, maxValue: 20);
    final ceilingHeight = getInput(inputs, 'ceilingHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);

    // Объём помещения
    final volume = area * ceilingHeight;

    // Воздухообмен: 3 м³/ч на м² для жилых помещений (норма 30 м³/ч на человека)
    final airExchange = area * 3.0; // м³/ч

    // Вентиляционные каналы (естественная вентиляция): 1 на комнату
    final naturalDuctsNeeded = rooms;

    // Решётки вентиляционные: приточная и вытяжная на комнату
    final grillesNeeded = rooms * 2;

    // Вентиляторы (для санузлов, кухонь): ~30% комнат
    final fansNeeded = ceilToInt(rooms * 0.35);

    // Воздуховоды (если принудительная вентиляция): ~5-7 м на комнату
    final ductLength = rooms * 5.0;

    // Диффузоры/анемостаты: по количеству помещений
    final diffusersNeeded = rooms;

    // Вент.установка с рекуперацией (опционально): 1 шт
    final recuperatorNeeded = getIntInput(inputs, 'recuperator', defaultValue: 0, minValue: 0, maxValue: 1);

    // Фильтры: комплект
    final filtersNeeded = recuperatorNeeded > 0 ? 2 : fansNeeded;

    // Расчёт стоимости
    final ductPrice = findPrice(priceList, ['ventilation_duct', 'duct', 'air_duct']);
    final grillePrice = findPrice(priceList, ['ventilation_grille', 'grille', 'vent_cover']);
    final fanPrice = findPrice(priceList, ['ventilation_fan', 'fan', 'exhaust_fan']);
    final diffuserPrice = findPrice(priceList, ['diffuser', 'anemostat', 'air_diffuser']);
    final recuperatorPrice = findPrice(priceList, ['recuperator', 'hrv', 'ventilation_unit']);
    final filterPrice = findPrice(priceList, ['filter', 'air_filter']);

    final costs = [
      calculateCost(ductLength, ductPrice?.price),
      calculateCost(grillesNeeded.toDouble(), grillePrice?.price),
      calculateCost(fansNeeded.toDouble(), fanPrice?.price),
      calculateCost(diffusersNeeded.toDouble(), diffuserPrice?.price),
      if (recuperatorNeeded > 0) calculateCost(recuperatorNeeded.toDouble(), recuperatorPrice?.price),
      calculateCost(filtersNeeded.toDouble(), filterPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'volume': volume,
        'airExchange': airExchange,
        'naturalDuctsNeeded': naturalDuctsNeeded.toDouble(),
        'ductsNeeded': naturalDuctsNeeded.toDouble(),
        'grillesNeeded': grillesNeeded.toDouble(),
        'fansNeeded': fansNeeded.toDouble(),
        'ductLength': ductLength,
        'diffusersNeeded': diffusersNeeded.toDouble(),
        if (recuperatorNeeded > 0) 'recuperatorNeeded': recuperatorNeeded.toDouble(),
        'filtersNeeded': filtersNeeded.toDouble(),
        'rooms': rooms.toDouble(),
        'ceilingHeight': ceilingHeight,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
