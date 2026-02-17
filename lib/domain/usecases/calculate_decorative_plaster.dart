// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор декоративной штукатурки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - thickness: толщина слоя (мм), по умолчанию 2 (для венецианки)
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateDecorativePlaster extends BaseCalculator {
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
    final thickness = getInput(inputs, 'thickness', defaultValue: 2.0, minValue: 0.5, maxValue: 10.0);
    final windowsArea = getInput(inputs, 'windowsArea', defaultValue: 0.0, minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', defaultValue: 0.0, minValue: 0.0);

    // Полезная площадь
    final usefulArea = [area - windowsArea - doorsArea, 0.0].reduce((a, b) => a > b ? a : b).toDouble();

    // Тип декоративной штукатурки (влияет на расход и технологию)
    final plasterType = getIntInput(inputs, 'plasterType', defaultValue: 0, minValue: 0, maxValue: 2);

    // Расход зависит от типа штукатурки:
    // 0 = Фактурная ("шуба", "барашек"): 1.5 кг/м²·мм — наносится слоем
    // 1 = Структурная ("короед"): 2.5 кг/м²·мм — крупное зерно, больший расход
    // 2 = Венецианская: 0.4 кг/м² на слой — тонкие слои, НЕ зависит от толщины
    double plasterNeeded;
    if (plasterType == 2) {
      // Венецианская: 3-5 тонких слоёв по 0.3-0.5 кг/м²
      final layers = getIntInput(inputs, 'layers', defaultValue: 4, minValue: 3, maxValue: 5);
      plasterNeeded = usefulArea * 0.4 * layers * 1.1; // +10%
    } else {
      final consumptionPerMm = plasterType == 1 ? 2.5 : 1.5; // структурная vs фактурная
      plasterNeeded = usefulArea * consumptionPerMm * thickness * 1.1; // +10%
    }

    // Грунтовка глубокого проникновения: 2 слоя по 0.15 л/м²
    final primerNeeded = usefulArea * 0.15 * 1.1;

    // Базовая шпаклёвка (для выравнивания): ~2 кг/м²
    final baseCoatNeeded = usefulArea * 2.0;

    // Воск/лак для защиты: венецианская — обязательно, остальные — не нужен
    final waxNeeded = plasterType == 2 ? usefulArea * 0.08 : 0.0;

    // Малярная сетка (для армирования углов): ~5% площади
    final meshArea = usefulArea * 0.05;

    // Колер (если нужен): ~5% от объёма штукатурки
    final colorantNeeded = plasterNeeded * 0.05;

    // Инструменты: кельмы, шпатели, тёрки (1 комплект на 50 м²)
    final toolSets = ceilToInt(usefulArea / 50);

    // Расчёт стоимости
    final plasterPrice = findPrice(priceList, [
      'plaster_decor', 
      'plaster_venetian', 
      'plaster_texture',
      'decorative_plaster'
    ]);
    final primerPrice = findPrice(priceList, ['primer_deep', 'primer', 'primer_adhesion']);
    final baseCoatPrice = findPrice(priceList, ['putty_base', 'base_coat', 'leveling_compound']);
    final waxPrice = findPrice(priceList, ['wax_decorative', 'wax', 'protective_coating']);
    final meshPrice = findPrice(priceList, ['mesh', 'fiberglass_mesh']);
    final colorantPrice = findPrice(priceList, ['colorant', 'tint', 'pigment']);

    final costs = [
      calculateCost(plasterNeeded, plasterPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(baseCoatNeeded, baseCoatPrice?.price),
      calculateCost(waxNeeded, waxPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(colorantNeeded, colorantPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'plasterNeeded': plasterNeeded,
        'primerNeeded': primerNeeded,
        'baseCoatNeeded': baseCoatNeeded,
        'waxNeeded': waxNeeded,
        'meshArea': meshArea,
        'colorantNeeded': colorantNeeded,
        'thickness': thickness,
        'plasterType': plasterType.toDouble(),
        'toolSets': toolSets.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
