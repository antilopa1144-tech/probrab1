// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор 3D панелей.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - panelSize: размер панели (см), по умолчанию 50 (50×50 см)
class Calculate3dPanels extends BaseCalculator {
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
    final panelSize = getInput(inputs, 'panelSize', defaultValue: 50.0, minValue: 25.0, maxValue: 100.0);

    // Площадь одной панели в м²
    final panelArea = (panelSize / 100) * (panelSize / 100);

    // Количество панелей с запасом 10%
    final panelsNeeded = calculateUnitsNeeded(area, panelArea, marginPercent: 10.0);

    // Клей для 3D панелей: 4-6 кг/м² (зависит от материала панели)
    final glueNeeded = area * 5.0;

    // Грунтовка: ~0.15-0.2 л/м²
    final primerNeeded = area * 0.18;

    // Шпаклёвка для выравнивания стены: ~1.0 кг/м²
    final puttyNeeded = area * 1.0;

    // Краска (если панели под покраску): ~0.12 л/м² в 2 слоя
    final isPaintable = getIntInput(inputs, 'paintable', defaultValue: 0, minValue: 0, maxValue: 1);
    final paintNeeded = isPaintable > 0 ? area * 0.12 * 2 : 0.0;

    // Декоративные элементы (молдинги): по периметру
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final moldingLength = getInput(inputs, 'molding', defaultValue: perimeter);

    // Защитное покрытие (лак): ~0.08 л/м²
    final varnishNeeded = area * 0.08;

    // Расчёт стоимости
    final panelPrice = findPrice(priceList, ['panel_3d', '3d_panel', 'decorative_panel_3d']);
    final gluePrice = findPrice(priceList, ['glue_3d', 'glue', 'adhesive_panel']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_adhesion']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish']);
    final paintPrice = isPaintable > 0 ? findPrice(priceList, ['paint', 'paint_white']) : null;
    final moldingPrice = findPrice(priceList, ['molding', 'decorative_molding']);
    final varnishPrice = findPrice(priceList, ['varnish', 'protective_coating']);

    final costs = [
      calculateCost(panelsNeeded.toDouble(), panelPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      if (isPaintable > 0) calculateCost(paintNeeded, paintPrice?.price),
      calculateCost(moldingLength, moldingPrice?.price),
      calculateCost(varnishNeeded, varnishPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
        'puttyNeeded': puttyNeeded,
        if (isPaintable > 0) 'paintNeeded': paintNeeded,
        'moldingLength': moldingLength,
        'varnishNeeded': varnishNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
