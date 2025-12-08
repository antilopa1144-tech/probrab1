import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

/// Калькулятор покраски стен.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 28196-89 "Краски водно-дисперсионные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - layers: количество слоёв (обычно 2)
/// - consumption: расход краски (л/м²), по умолчанию 0.15 (СНиП)
/// - windowsArea: площадь окон (м²) - вычитается из общей площади
/// - doorsArea: площадь дверей (м²) - вычитается из общей площади
class CalculateWallPaint extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final layers = inputs['layers'] ?? 2;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (layers < 1 || layers > 5) return 'Количество слоёв должно быть от 1 до 5';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 5);
    final consumption = getInput(inputs, 'consumption', defaultValue: 0.15, minValue: 0.1, maxValue: 0.3);
    final windowsArea = getInput(inputs, 'windowsArea', minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', minValue: 0.0);

    // Полезная площадь (за вычетом проёмов)
    final usefulArea = calculateUsefulArea(area, windowsArea: windowsArea, doorsArea: doorsArea);

    if (usefulArea <= 0) {
      return createResult(
        values: {
          'error': 1.0,
          'usefulArea': 0.0,
        },
      );
    }

    // Расход краски с учётом слоёв и запаса 5-10% (СНиП 3.04.01-87)
    // Первый слой - больше расход, последующие - меньше
    final firstLayerConsumption = consumption * 1.2; // первый слой впитывается больше
    final otherLayersConsumption = consumption;
    
    final paintNeeded = usefulArea * (
      firstLayerConsumption + (layers - 1) * otherLayersConsumption
    ) * 1.08; // запас 8%

    // Грунтовка: расход ~0.1-0.12 л/м², один слой с запасом
    const primerConsumption = 0.12; // л/м²
    final primerNeeded = usefulArea * primerConsumption * 1.05;

    // Шпаклёвка (если стены требуют выравнивания): ~1.2 кг/м² на 1 мм
    final puttingNeeded = usefulArea * 1.5; // примерно 1.5 кг/м² для финишной шпаклёвки

    // Малярный скотч: периметр проёмов + периметр комнаты
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final tapeNeeded = perimeter * 1.2; // м

    // Расходные материалы
    final rollersNeeded = ceilToInt(usefulArea / 50); // валик на ~50 м²
    final brushesNeeded = ceilToInt(usefulArea / 40); // кисть на ~40 м²

    // Расчёт стоимости
    final paintPrice = findPrice(priceList, ['paint_wall', 'paint', 'paint_water_disp']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish']);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape']);

    final costs = [
      calculateCost(paintNeeded, paintPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(puttingNeeded, puttyPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
    ];

    return createResult(
      values: {
        'usefulArea': usefulArea,
        'paintNeeded': paintNeeded,
        'primerNeeded': primerNeeded,
        'puttyNeeded': puttingNeeded,
        'tapeNeeded': tapeNeeded,
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'layers': layers.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}

