// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ламината.
///
/// Нормативы:
/// - ГОСТ 32304-2013 "Ламинат напольный"
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - packArea: площадь в упаковке (м²), по умолчанию 2.0
/// - underlayThickness: толщина подложки (мм), по умолчанию 3
/// - perimeter: периметр комнаты (м), опционально
class CalculateLaminate extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final packArea = inputs['packArea'] ?? 2.0;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (packArea <= 0 || packArea > 10) return 'Площадь упаковки должна быть от 0.1 до 10 м²';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final packArea = getInput(inputs, 'packArea', defaultValue: 2.0, minValue: 0.1, maxValue: 10.0);
    final underlayThickness = getInput(inputs, 'underlayThickness', defaultValue: 3.0, minValue: 2.0, maxValue: 5.0);

    // Периметр: если указан - используем, иначе оцениваем
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Количество упаковок ламината с запасом 5-7% (ГОСТ 32304-2013)
    // Для прямой укладки - 5%, для диагональной - 7-10%
    final packsNeeded = calculateUnitsNeeded(area, packArea, marginPercent: 7.0);

    // Подложка: площадь = площадь пола + 5% на подрезку и нахлёсты
    final underlayArea = addMargin(area, 5.0);

    // Плинтус: периметр + 5% на подрезку
    final plinthLength = addMargin(perimeter, 5.0);

    // Компенсационные клинья: ~8-10 шт на комнату (по периметру через каждые 50 см)
    final wedgesNeeded = ceilToInt(perimeter / 0.5);

    // Пароизоляционная плёнка (если нужна): площадь + 10% на нахлёсты
    final vaporBarrierArea = addMargin(area, 10.0);

    // Соединительная фурнитура: переходы, пороги (1 шт на дверной проём)
    final doorThresholds = getIntInput(inputs, 'doorThresholds', defaultValue: 1, minValue: 0, maxValue: 10);

    // Расчёт стоимости
    final laminatePrice = findPrice(priceList, ['laminate', 'laminate_pack']);
    final underlayPrice = findPrice(priceList, ['underlay', 'underlay_${underlayThickness.round()}mm', 'underlay']);
    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_laminate']);
    final vaporBarrierPrice = findPrice(priceList, ['vapor_barrier', 'film_pe']);
    final thresholdPrice = findPrice(priceList, ['threshold', 'threshold_laminate']);

    final costs = [
      calculateCost(packsNeeded.toDouble(), laminatePrice?.price),
      calculateCost(underlayArea, underlayPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(doorThresholds.toDouble(), thresholdPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'packsNeeded': packsNeeded.toDouble(),
        'underlayArea': underlayArea,
        'plinthLength': plinthLength,
        'wedgesNeeded': wedgesNeeded.toDouble(),
        'vaporBarrierArea': vaporBarrierArea,
        'doorThresholds': doorThresholds.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}

