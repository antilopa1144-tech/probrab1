import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор покраски потолка.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 28196-89 "Краски водно-дисперсионные"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - layers: количество слоёв (обычно 2)
/// - consumption: расход краски (л/м²), по умолчанию 0.12
class CalculateCeilingPaint extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final layers = inputs['layers'] ?? 2;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (layers < 1 || layers > 4) return 'Количество слоёв должно быть от 1 до 4';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 4);
    final consumption = getInput(inputs, 'consumption', defaultValue: 0.12, minValue: 0.08, maxValue: 0.2);

    // Первый слой - больше расход (впитывается)
    final firstLayerConsumption = consumption * 1.15;
    final otherLayersConsumption = consumption;
    
    final paintNeeded = area * (
      firstLayerConsumption + (layers - 1) * otherLayersConsumption
    ) * 1.05; // запас 5%

    // Грунтовка: ~0.1 л/м², один слой
    final primerNeeded = area * 0.1 * 1.05;

    // Шпаклёвка для потолка: ~1.0-1.2 кг/м²
    final puttyNeeded = area * 1.1;

    // Малярная сетка для трещин: площадь с запасом
    final meshArea = area * 0.1; // ~10% площади потолка обычно требует армирования

    // Валики: 1 шт на ~40 м²
    final rollersNeeded = ceilToInt(area / 40);

    // Кисти для углов: 1-2 шт
    final brushesNeeded = 2;

    // Малярная лента для защиты стен: периметр
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final tapeNeeded = perimeter;

    // Расчёт стоимости
    final paintPrice = findPrice(priceList, ['paint_ceiling', 'paint', 'paint_water_disp', 'ceiling_paint']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_ceiling']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish', 'ceiling_putty']);
    final meshPrice = findPrice(priceList, ['mesh', 'fiberglass_mesh', 'reinforcement_mesh']);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape', 'painter_tape']);

    final costs = [
      calculateCost(paintNeeded, paintPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'paintNeeded': paintNeeded,
        'primerNeeded': primerNeeded,
        'puttyNeeded': puttyNeeded,
        'meshArea': meshArea,
        'tapeNeeded': tapeNeeded,
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'layers': layers.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
