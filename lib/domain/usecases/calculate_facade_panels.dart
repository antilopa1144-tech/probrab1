// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор фасадных панелей.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 32603-2012 "Панели фасадные"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - panelWidth: ширина панели (см), по умолчанию 50
/// - panelHeight: высота панели (см), по умолчанию 100
/// - perimeter: периметр здания (м), опционально
class CalculateFacadePanels extends BaseCalculator {
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
    final panelWidth = getInput(inputs, 'panelWidth', defaultValue: 50.0, minValue: 20.0, maxValue: 150.0);
    final panelHeight = getInput(inputs, 'panelHeight', defaultValue: 100.0, minValue: 50.0, maxValue: 300.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной панели в м²
    final panelArea = calculateTileArea(panelWidth, panelHeight);

    // Количество панелей с запасом 10%
    final panelsNeeded = calculateUnitsNeeded(area, panelArea, marginPercent: 10.0);

    // Обрешётка (металлический профиль или деревянные бруски)
    final battensCount = ceilToInt((perimeter / 4) / 0.6);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5);
    final battensLength = battensCount * wallHeight;

    // Крепления: ~4-6 шт на панель
    final fastenersNeeded = panelsNeeded * 4;

    // Угловые элементы: внешние и внутренние
    final cornersLength = perimeter;

    // Стартовая планка: по периметру
    final startStripLength = perimeter;

    // J-профиль (для обрамления проёмов): по факту
    final jProfileLength = getInput(inputs, 'jProfile', defaultValue: 0.0);

    // Н-профиль (соединительный): вертикальные стыки
    final hProfileCount = ceilToInt((perimeter / 4) / 3); // каждые 3 м
    final hProfileLength = hProfileCount * wallHeight;

    // Расчёт стоимости
    final panelPrice = findPrice(priceList, ['facade_panel', 'panel_facade', 'siding_panel']);
    final battensPrice = findPrice(priceList, ['battens', 'metal_profile', 'facade_profile']);
    final fastenerPrice = findPrice(priceList, ['fastener_facade', 'fastener', 'panel_fastener']);
    final cornerPrice = findPrice(priceList, ['corner_facade', 'corner', 'corner_panel']);
    final startStripPrice = findPrice(priceList, ['start_strip_facade', 'start_strip', 'base_strip']);
    final jProfilePrice = findPrice(priceList, ['profile_j', 'j_trim']);
    final hProfilePrice = findPrice(priceList, ['profile_h', 'h_trim', 'joiner']);

    final costs = [
      calculateCost(panelsNeeded.toDouble(), panelPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      calculateCost(cornersLength, cornerPrice?.price),
      calculateCost(startStripLength, startStripPrice?.price),
      if (jProfileLength > 0) calculateCost(jProfileLength, jProfilePrice?.price),
      calculateCost(hProfileLength, hProfilePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'battensLength': battensLength,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'cornersLength': cornersLength,
        'startStripLength': startStripLength,
        if (jProfileLength > 0) 'jProfileLength': jProfileLength,
        'hProfileLength': hProfileLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
