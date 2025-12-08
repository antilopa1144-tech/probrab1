import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

/// Калькулятор покраски стен.
///
/// Нормативы:
/// - ГЭСН-2001 (Государственные элементные сметные нормы)
/// - ФЕР-2001 (Федеральные единичные расценки)
/// - СП 71.13330.2017 "Изоляционные и отделочные покрытия"
/// - ГОСТ 28196-89 "Краски водно-дисперсионные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - layers: количество слоёв (обычно 2)
/// - consumption: расход краски (л/м²), по умолчанию 0.12 (современные краски 2024)
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
    final consumption = getInput(inputs, 'consumption', defaultValue: 0.12, minValue: 0.08, maxValue: 0.20);
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

    // Расход краски по ГЭСН-2001 (табл. 15-01-027)
    // Простая формула: площадь × слои × расход + 10% запас
    final paintNeeded = usefulArea * layers * consumption * 1.10; // запас 10% по ГЭСН

    // Грунтовка: расход 0.10-0.12 л/м² по ГЭСН, один слой с запасом 5%
    const primerConsumption = 0.11; // л/м² (среднее значение)
    final primerNeeded = usefulArea * primerConsumption * 1.05;

    // Малярный скотч: периметр проёмов + периметр комнаты
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final tapeNeeded = perimeter * 1.2; // м

    // Расходные материалы
    final rollersNeeded = ceilToInt(usefulArea / 50); // валик на ~50 м²
    final brushesNeeded = ceilToInt(usefulArea / 40); // кисть на ~40 м²

    // Расчёт стоимости (без шпаклёвки - это отдельная операция)
    final paintPrice = findPrice(priceList, ['paint_wall', 'paint', 'paint_water_disp']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape']);

    final costs = [
      calculateCost(paintNeeded, paintPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
    ];

    return createResult(
      values: {
        'usefulArea': usefulArea,
        'paintNeeded': paintNeeded,
        'primerNeeded': primerNeeded,
        'tapeNeeded': tapeNeeded,
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'layers': layers.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}

