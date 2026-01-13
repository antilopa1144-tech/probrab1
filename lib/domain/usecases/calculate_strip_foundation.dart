// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ленточного фундамента.
///
/// Нормативы:
/// - СП 63.13330.2018 "Бетонные и железобетонные конструкции"
/// - СП 70.13330.2012 "Несущие и ограждающие конструкции"
///
/// Поля:
/// - area: площадь контура (м²), используется для оценки периметра
/// - width: ширина ленты (м)
/// - height: высота ленты (м)
class CalculateStripFoundation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final perimeter = inputs['perimeter'] ?? 0;
    final width = inputs['width'] ?? 0;
    final height = inputs['height'] ?? 0;

    if (area <= 0 && perimeter <= 0) {
      return 'Площадь или периметр должны быть больше нуля';
    }
    if (area > 10000 || perimeter > 10000) {
      return 'Площадь/периметр слишком большие';
    }
    if (width <= 0 || width > 3) return 'Ширина ленты должна быть от 0.1 до 3 м';
    if (height <= 0 || height > 3) return 'Высота ленты должна быть от 0.1 до 3 м';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final inputPerimeter = inputs['perimeter'] ?? 0.0;
    final perimeter = inputPerimeter > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1, maxValue: 10000.0)
        : estimatePerimeter(getInput(inputs, 'area', minValue: 0.1, maxValue: 10000.0));

    // Если площадь не задана, оцениваем её из периметра (квадратная аппроксимация)
    final inputArea = inputs['area'] ?? 0.0;
    final area = inputArea > 0
        ? getInput(inputs, 'area', minValue: 0.1, maxValue: 10000.0)
        : pow(perimeter / 4, 2).toDouble();
    final width = getInput(
      inputs,
      'width',
      defaultValue: 0.1,
      minValue: 0.1,
      maxValue: 3.0,
    );
    final height = getInput(
      inputs,
      'height',
      defaultValue: 0.1,
      minValue: 0.1,
      maxValue: 3.0,
    );

    // Объём бетона для фундамента (с запасом 5% на разлив)
    const concreteWastePercent = 5.0;
    final concreteVolume = perimeter * width * height * (1 + concreteWastePercent / 100);

    // Армирование (СП 63.13330.2018):
    // - Продольная арматура: 4-6 стержней диаметром 12-14 мм
    // - Поперечные хомуты: диаметр 8-10 мм, шаг 30-40 см
    // Общий вес арматуры: ~100 кг на м³ бетона (норма 80-120 кг/м³)
    final rebarWeight = concreteVolume * 100;

    // Количество стержней продольной арматуры (4-6 шт, по 2-3 сверху и снизу)
    const longitudinalBars = 6;
    final longitudinalLength = perimeter * longitudinalBars;

    // Опалубка: площадь боковых поверхностей (с запасом 10% на раскрой)
    const formworkWastePercent = 10.0;
    final formworkArea = perimeter * height * 2 * (1 + formworkWastePercent / 100);

    // Гидроизоляция: площадь дна и боковых стенок (с запасом 15% на перекат и стыки)
    const waterproofingWastePercent = 15.0;
    final waterproofingArea = ((perimeter * width) + (perimeter * height * 2)) * (1 + waterproofingWastePercent / 100);

    // Песчаная подушка (толщина 15-20 см, запас 10%)
    const sandCushionThickness = 0.15; // м
    const sandWastePercent = 10.0;
    final sandVolume = perimeter * width * sandCushionThickness * (1 + sandWastePercent / 100);

    // Щебень для подушки (10-15 см поверх песка, запас 10%)
    const gravelThickness = 0.1; // м
    const gravelWastePercent = 10.0;
    final gravelVolume = perimeter * width * gravelThickness * (1 + gravelWastePercent / 100);

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
        'area': area,
        'perimeter': perimeter,
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
