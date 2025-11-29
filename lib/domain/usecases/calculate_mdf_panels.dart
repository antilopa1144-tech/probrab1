import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор панелей МДФ.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 32289-2013 "Плиты древесноволокнистые"
///
/// Поля:
/// - area: площадь стен (м²)
/// - panelWidth: ширина панели (см), по умолчанию 20
/// - panelLength: длина панели (см), по умолчанию 260
/// - perimeter: периметр комнаты (м), опционально
class CalculateMdfPanels extends BaseCalculator {
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
    final panelWidth = getInput(inputs, 'panelWidth', defaultValue: 20.0, minValue: 10.0, maxValue: 50.0);
    final panelLength = getInput(inputs, 'panelLength', defaultValue: 260.0, minValue: 200.0, maxValue: 300.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной панели в м²
    final panelArea = calculateTileArea(panelWidth, panelLength);

    // Количество панелей с запасом 10%
    final panelsNeeded = calculateUnitsNeeded(area, panelArea, marginPercent: 10.0);

    // Обрешётка (бруски): шаг 40-50 см по вертикали
    final battensCount = ceilToInt((perimeter / 4) / 0.45);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);
    final battensLength = battensCount * wallHeight;

    // Кляймеры (крепёж для МДФ): ~4-5 шт на панель
    final clampsNeeded = ceilToInt(panelsNeeded * 4.5);

    // Уголки (декоративные): внутренние и наружные
    final cornersLength = addMargin(perimeter * 0.3, 5.0);

    // Плинтус напольный: по периметру
    final plinthLength = addMargin(perimeter, 3.0);

    // Потолочный плинтус: по периметру
    final ceilingPlinthLength = addMargin(perimeter, 3.0);

    // Соединительные планки (при наборной панели): по факту
    final connectorsLength = getInput(inputs, 'connectors', defaultValue: 0.0);

    // Гвозди/саморезы: для обрешётки
    final screwsNeeded = ceilToInt(battensLength * 3); // ~3 шт на м.п.

    // Расчёт стоимости
    final panelPrice = findPrice(priceList, ['mdf_panel', 'panel_mdf', 'mdf_board']);
    final battensPrice = findPrice(priceList, ['battens', 'timber', 'wood_strips']);
    final clampPrice = findPrice(priceList, ['clamp_mdf', 'clamp', 'kleimer']);
    final cornerPrice = findPrice(priceList, ['corner_mdf', 'corner', 'decorative_corner']);
    final plinthPrice = findPrice(priceList, ['plinth_mdf', 'plinth', 'baseboard']);
    final ceilingPlinthPrice = findPrice(priceList, ['plinth_ceiling', 'ceiling_molding']);
    final connectorPrice = findPrice(priceList, ['connector', 'joining_strip']);

    final costs = [
      calculateCost(panelsNeeded.toDouble(), panelPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(clampsNeeded.toDouble(), clampPrice?.price),
      calculateCost(cornersLength, cornerPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(ceilingPlinthLength, ceilingPlinthPrice?.price),
      if (connectorsLength > 0) calculateCost(connectorsLength, connectorPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'battensLength': battensLength,
        'clampsNeeded': clampsNeeded.toDouble(),
        'cornersLength': cornersLength,
        'plinthLength': plinthLength,
        'ceilingPlinthLength': ceilingPlinthLength,
        if (connectorsLength > 0) 'connectorsLength': connectorsLength,
        'screwsNeeded': screwsNeeded.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
