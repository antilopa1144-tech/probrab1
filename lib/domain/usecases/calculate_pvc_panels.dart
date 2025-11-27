import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор панелей ПВХ.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - panelWidth: ширина панели (см), по умолчанию 25
/// - panelLength: длина панели (см), по умолчанию 300
/// - perimeter: периметр комнаты (м), опционально
class CalculatePvcPanels extends BaseCalculator {
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
    final panelWidth = getInput(inputs, 'panelWidth', defaultValue: 25.0, minValue: 10.0, maxValue: 50.0);
    final panelLength = getInput(inputs, 'panelLength', defaultValue: 300.0, minValue: 200.0, maxValue: 600.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной панели в м²
    final panelArea = calculateTileArea(panelWidth, panelLength);

    // Количество панелей с запасом 10%
    final panelsNeeded = calculateUnitsNeeded(area, panelArea, marginPercent: 10.0);

    // Профили: стартовый, финишный, универсальный
    final startProfileLength = addMargin(perimeter, 3.0);
    final finishProfileLength = addMargin(perimeter, 3.0);
    
    // Обрешётка (деревянная или металлическая): шаг 40-50 см
    final battensCount = ceilToInt((perimeter / 4) / 0.45);
    final battensLength = battensCount * (perimeter / 4);

    // Угловые профили (внутренние и наружные): по факту
    final cornerLength = getInput(inputs, 'corners', defaultValue: perimeter * 0.2);

    // F-профиль (для стыка с откосами): по факту
    final fProfileLength = getInput(inputs, 'fProfile', defaultValue: 0.0);

    // Крепёж: саморезы/кляймеры ~6 шт на панель
    final fastenersNeeded = ceilToInt(panelsNeeded * 6);

    // Потолочный плинтус/молдинг: по периметру
    final moldingLength = perimeter;

    // Расчёт стоимости
    final panelPrice = findPrice(priceList, ['pvc_panel', 'panel_pvc', 'plastic_panel']);
    final startProfilePrice = findPrice(priceList, ['profile_start_pvc', 'profile_start']);
    final finishProfilePrice = findPrice(priceList, ['profile_finish_pvc', 'profile_finish']);
    final battensPrice = findPrice(priceList, ['battens', 'timber', 'profile_metal']);
    final cornerPrice = findPrice(priceList, ['corner_pvc', 'corner', 'corner_profile']);
    final fProfilePrice = findPrice(priceList, ['profile_f', 'f_profile']);
    final moldingPrice = findPrice(priceList, ['molding', 'ceiling_molding']);

    final costs = [
      calculateCost(panelsNeeded.toDouble(), panelPrice?.price),
      calculateCost(startProfileLength, startProfilePrice?.price),
      calculateCost(finishProfileLength, finishProfilePrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(cornerLength, cornerPrice?.price),
      if (fProfileLength > 0) calculateCost(fProfileLength, fProfilePrice?.price),
      calculateCost(moldingLength, moldingPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'startProfileLength': startProfileLength,
        'finishProfileLength': finishProfileLength,
        'battensLength': battensLength,
        'cornerLength': cornerLength,
        if (fProfileLength > 0) 'fProfileLength': fProfileLength,
        'moldingLength': moldingLength,
        'fastenersNeeded': fastenersNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
