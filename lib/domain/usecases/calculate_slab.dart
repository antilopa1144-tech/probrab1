import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор монолитной плиты (фундамент или перекрытие).
///
/// Нормативы:
/// - СНиП 52-01-2003 "Бетонные и железобетонные конструкции"
/// - ГОСТ 26633-2015 "Бетоны тяжелые и мелкозернистые"
///
/// Поля:
/// - area: площадь плиты (м²)
/// - thickness: толщина плиты (м), по умолчанию 0.2
class CalculateSlab extends BaseCalculator {
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
    final thickness = getInput(inputs, 'thickness', defaultValue: 0.2, minValue: 0.1, maxValue: 0.5);

    // Объём бетона (thickness уже в метрах, не нужно конвертировать)
    final concreteVolume = area * thickness;

    // Арматура: обычно 1-1.5% от объёма бетона (две сетки)
    // Арматура Ø12 с шагом 200×200 мм в двух направлениях, в 2 слоя
    final rebarVolumePercent = 0.012; // 1.2%
    final rebarVolume = concreteVolume * rebarVolumePercent;
    final rebarDensity = 7850.0; // кг/м³
    final rebarWeight = rebarVolume * rebarDensity;

    // Песчаная подушка: ~0.1-0.15 м толщиной
    final sandBedThickness = 0.12;
    final sandVolume = area * sandBedThickness;

    // Щебень: ~0.15-0.2 м толщиной
    final gravelBedThickness = 0.17;
    final gravelVolume = area * gravelBedThickness;

    // Гидроизоляция: площадь + 10% на нахлёсты и загибы
    final waterproofingArea = addMargin(area, 10.0);

    // Утеплитель (ЭППС): опционально, под плитой (толщина в метрах)
    final insulationThickness = getInput(inputs, 'insulation', defaultValue: 0.0);
    final insulationVolume = insulationThickness > 0 ? area * insulationThickness : 0.0;

    // Опалубка: по периметру плиты
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final formworkArea = perimeter * thickness;

    // Вязальная проволока: ~30 кг на тонну арматуры
    final wireNeeded = rebarWeight / 1000 * 0.03;

    // Пластификатор для бетона: ~0.5 л/м³
    final plasticizerNeeded = concreteVolume * 0.5;

    // Расчёт стоимости
    final concretePrice = findPrice(priceList, ['concrete', 'concrete_m300', 'ready_mix_concrete']);
    final rebarPrice = findPrice(priceList, ['rebar', 'rebar12', 'reinforcement']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone']);
    final waterproofingPrice = findPrice(priceList, ['waterproofing', 'waterproofing_membrane']);
    final insulationPrice = findPrice(priceList, ['xps', 'extruded_polystyrene']);
    final formworkPrice = findPrice(priceList, ['formwork', 'plywood']);

    final costs = [
      calculateCost(concreteVolume, concretePrice?.price),
      calculateCost(rebarWeight, rebarPrice?.price),
      calculateCost(sandVolume, sandPrice?.price),
      calculateCost(gravelVolume, gravelPrice?.price),
      calculateCost(waterproofingArea, waterproofingPrice?.price),
      if (insulationVolume > 0) calculateCost(insulationVolume, insulationPrice?.price),
      calculateCost(formworkArea, formworkPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'concreteVolume': concreteVolume,
        'rebarWeight': rebarWeight,
        'sandVolume': sandVolume,
        'gravelVolume': gravelVolume,
        'waterproofingArea': waterproofingArea,
        if (insulationVolume > 0) 'insulationVolume': insulationVolume,
        'formworkArea': formworkArea,
        'wireNeeded': wireNeeded,
        'plasticizerNeeded': plasticizerNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
