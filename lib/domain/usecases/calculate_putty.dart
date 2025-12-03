import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор шпаклёвки (старт/финиш).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - layers: количество слоёв, по умолчанию 2
/// - type: тип (1=старт, 2=финиш), по умолчанию 1
class CalculatePutty extends BaseCalculator {
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
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 5);
    final type = getIntInput(inputs, 'type', defaultValue: 1, minValue: 1, maxValue: 2);

    // Расход шпаклёвки:
    // - Стартовая: 1.2-1.8 кг/м² на слой (зависит от кривизны)
    // - Финишная: 0.5-0.8 кг/м² на слой
    final consumptionPerLayer = type == 1 ? 1.5 : 0.8; // кг/м²

    // Общий расход с учётом слоёв и запаса 10%
    final puttyNeeded = area * consumptionPerLayer * layers * 1.1;

    // Грунтовка: между слоями и финальная
    // ~0.2 л/м² перед шпаклеванием
    final primerNeeded = area * 0.2 * 1.1;

    // Армирующая сетка (для стартовой): площадь покрытия
    final meshArea = type == 1 ? area : 0.0;

    // Наждачная бумага (абразивная сетка): комплект на площадь
    final sandpaperSets = ceilToInt(area / 25); // 1 комплект на 25 м²

    // Шпатели: набор из 3-4 шт разного размера
    final spatulasNeeded = 3;

    // Вода для замешивания (информативно): ~0.4 л на кг смеси
    final waterNeeded = puttyNeeded * 0.4;

    // Расчёт стоимости
    final puttyPrice = type == 1
        ? findPrice(priceList, ['putty_start', 'putty_base', 'putty'])
        : findPrice(priceList, ['putty_finish', 'putty_final', 'putty']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_adhesion']);
    final meshPrice = findPrice(priceList, ['mesh', 'fiberglass_mesh', 'serpyanka']);

    final costs = [
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (type == 1) calculateCost(meshArea, meshPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        if (type == 1) 'meshArea': meshArea,
        'sandpaperSets': sandpaperSets.toDouble(),
        'spatulasNeeded': spatulasNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
