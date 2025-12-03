import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор ленточного фундамента.
///
/// Нормативы:
/// - СНиП 52-01-2003 "Бетонные и железобетонные конструкции"
/// - СНиП 3.03.01-87 "Несущие и ограждающие конструкции"
///
/// Поля:
/// - perimeter: периметр фундамента (м)
/// - width: ширина ленты (м)
/// - height: высота ленты (м)
class CalculateStripFoundation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final perimeter = inputs['perimeter'] ?? 0;
    final width = inputs['width'] ?? 0;
    final height = inputs['height'] ?? 0;

    if (perimeter < 0) return 'Периметр должен быть неотрицательным';
    if (width < 0 || width > 3) return 'Ширина ленты должна быть от 0.1 до 3 м';
    if (height < 0 || height > 3) return 'Высота ленты должна быть от 0.1 до 3 м';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final perimeter = getInput(inputs, 'perimeter', defaultValue: 0.0, minValue: 0.0);
    final width = getInput(inputs, 'width', defaultValue: 0.0, minValue: 0.0, maxValue: 3.0);
    final height = getInput(inputs, 'height', defaultValue: 0.0, minValue: 0.0, maxValue: 3.0);

    // Объём бетона для фундамента
    final concreteVolume = perimeter * width * height;

    // Армирование (СНиП 52-01-2003):
    // - Продольная арматура: 4-6 стержней диаметром 12-14 мм
    // - Поперечные хомуты: диаметр 8-10 мм, шаг 30-40 см
    // Общий вес арматуры: ~80-120 кг на м³ бетона
    final rebarWeight = concreteVolume * 0.01 * 7850;

    // Количество стержней продольной арматуры (4-6 шт, по 2-3 сверху и снизу)
    final longitudinalBars = 6;
    final longitudinalLength = perimeter * longitudinalBars;

    // Опалубка: площадь боковых поверхностей
    final formworkArea = perimeter * height * 2; // обе стороны

    // Гидроизоляция: площадь дна и боковых стенок
    final waterproofingArea = (perimeter * width) + (perimeter * height * 2);

    // Песчаная подушка (обычно толщина 15-20 см)
    final sandCushionThickness = 0.15; // м
    final sandVolume = perimeter * width * sandCushionThickness;

    // Щебень для подушки (обычно 10-15 см поверх песка)
    final gravelThickness = 0.1; // м
    final gravelVolume = perimeter * width * gravelThickness;

    // Если делать бетон самостоятельно:
    // Для М300: цемент М400 (330 кг/м³), песок (0.6 м³), щебень (0.8 м³)
    final cementBags = concreteVolume * 7; // мешки по 50 кг

    // Расчёт стоимости
    final concretePrice = findPrice(priceList, ['concrete_m300', 'concrete_m250', 'concrete']);
    final rebarPrice = findPrice(priceList, ['rebar', 'rebar_12mm', 'reinforcement']);
    final formworkPrice = findPrice(priceList, ['formwork', 'plywood']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing', 'film_pe', 'bitumen']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone']);

    final costs = [
      calculateCost(concreteVolume, concretePrice?.price),
      calculateCost(rebarWeight, rebarPrice?.price),
      calculateCost(formworkArea, formworkPrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(sandVolume, sandPrice?.price),
      calculateCost(gravelVolume, gravelPrice?.price),
    ];

    return createResult(
      values: {
        'concreteVolume': concreteVolume,
        'rebarWeight': rebarWeight,
        'longitudinalBars': longitudinalBars.toDouble(),
        'longitudinalLength': longitudinalLength,
        'formworkArea': formworkArea,
        'waterproofingArea': waterproofingArea,
        'sandVolume': sandVolume,
        'gravelVolume': gravelVolume,
        'cementBags': cementBags.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
