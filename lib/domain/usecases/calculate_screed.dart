// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор стяжки пола.
///
/// Нормативы:
/// - СНиП 2.03.13-88 "Полы"
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - thickness: толщина стяжки (мм), по умолчанию 50
/// - cementGrade: марка цемента (М400/М500), влияет на пропорции
class CalculateScreed extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 50.0;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (thickness < 30 || thickness > 150) return 'Толщина стяжки должна быть от 30 до 150 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 30.0, maxValue: 150.0);
    final cementGrade = getInput(inputs, 'cementGrade', defaultValue: 400.0);

    // Объём стяжки в м³
    final volume = calculateVolume(area, thickness);

    // Пропорции цементно-песчаной смеси по СНиП 2.03.13-88:
    // М400: 1:3 (цемент:песок), М500: 1:4
    // Для стяжки М150-М200 используется соотношение цемента к песку
    final cementRatio = cementGrade >= 500 ? 0.23 : 0.33; // доля цемента (с учётом потерь)
    final sandRatio = 1.0 - cementRatio;

    // Плотность раствора ~2100 кг/м³ (с учётом уплотнения)
    const solutionDensity = 2100.0; // кг/м³
    final totalWeight = volume * solutionDensity;

    // Количество цемента и песка с учётом потерь (+3%)
    final cementNeeded = totalWeight * cementRatio * 1.03;
    final sandNeeded = totalWeight * sandRatio;

    // Мешки цемента (50 кг стандартный мешок)
    final cementBags = ceilToInt(cementNeeded / 50);

    // Песок в м³ (плотность ~1600 кг/м³)
    final sandVolume = sandNeeded / 1600;

    // Гидроизоляция (пленка под стяжку): площадь + 20% на нахлёсты
    final waterproofingArea = addMargin(area, 20.0);

    // Демпферная лента (по периметру): периметр + 5%
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final damperTapeLength = addMargin(perimeter, 5.0);

    // Армирующая сетка (при толщине > 40 мм): площадь + 10%
    final meshArea = thickness > 40 ? addMargin(area, 10.0) : 0.0;

    // Маяки (профиль): примерно каждые 1-1.5 м
    final beaconsLength = ceilToInt(area / 1.2) * 3.0; // м

    // Пластификатор (для улучшения текучести): ~0.5-1% от массы цемента
    final plasticizerNeeded = cementNeeded * 0.007; // кг

    // Расчёт стоимости
    final cementPrice = findPrice(priceList, ['cement_m${cementGrade.round()}', 'cement_m400', 'cement_m500', 'cement']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction', 'sand_river']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing', 'film_pe']);
    final damperTapePrice = findPrice(priceList, ['damper_tape', 'tape_edge']);
    final meshPrice = findPrice(priceList, ['mesh', 'mesh_reinforcement']);
    final beaconPrice = findPrice(priceList, ['beacon', 'profile_beacon']);
    final plasticizerPrice = findPrice(priceList, ['plasticizer', 'additive_plasticizer']);

    final costs = [
      calculateCost(cementBags.toDouble(), cementPrice?.price),
      calculateCost(sandVolume, sandPrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      calculateCost(damperTapeLength, damperTapePrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(beaconsLength, beaconPrice?.price),
      calculateCost(plasticizerNeeded, plasticizerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'volume': volume,
        'cementBags': cementBags.toDouble(),
        'sandVolume': sandVolume,
        'thickness': thickness,
        'waterproofingArea': waterproofingArea,
        'damperTapeLength': damperTapeLength,
        'meshArea': meshArea,
        'beaconsLength': beaconsLength,
        'plasticizerNeeded': plasticizerNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}

