// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор шпаклёвки (старт/финиш).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - layers: количество слоёв, по умолчанию 2
/// - type: тип (1=старт, 2=финиш), по умолчанию 1
/// - qualityClass: класс качества (1=эконом Q1-Q2, 2=стандарт Q3, 3=премиум Q4), по умолчанию 2
///
/// Классы качества по СНиП 3.04.01-87:
/// - Q1: базовое выравнивание, под плитку/обои (Волма, Основит)
/// - Q2: стандартное выравнивание, под структурные обои
/// - Q3: качественная отделка, под покраску (Knauf, Bergauf)
/// - Q4: высококачественная отделка, под глянцевую покраску (Sheetrock, Danogips)
class CalculatePutty extends BaseCalculator {
  // Расход шпаклёвки по классу качества (кг/м² на слой)
  // Премиум классы имеют меньший расход за счёт более тонкого слоя
  static const _consumptionByQuality = {
    // Эконом (Q1-Q2): больший расход, грубое выравнивание
    1: {'start': 1.8, 'finish': 1.0},
    // Стандарт (Q3): средний расход
    2: {'start': 1.5, 'finish': 0.8},
    // Премиум (Q4): меньший расход, тонкие слои
    3: {'start': 1.2, 'finish': 0.5},
  };

  // Количество слоёв по классу качества
  static const _layersByQuality = {
    1: {'start': 1, 'finish': 1}, // Эконом: минимум слоёв
    2: {'start': 2, 'finish': 1}, // Стандарт: 2 стартовых + 1 финишный
    3: {'start': 2, 'finish': 2}, // Премиум: 2+2 для идеальной поверхности
  };
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
    final type = getIntInput(inputs, 'type', defaultValue: 1, minValue: 1, maxValue: 2);
    final qualityClass = getIntInput(inputs, 'qualityClass', defaultValue: 2, minValue: 1, maxValue: 3);

    // Тип шпаклёвки: start или finish
    final typeKey = type == 1 ? 'start' : 'finish';

    // Расход шпаклёвки по классу качества (кг/м² на слой)
    final consumptionData = _consumptionByQuality[qualityClass]!;
    final consumptionPerLayer = consumptionData[typeKey]!;

    // Количество слоёв: берём из параметра или рекомендуемое по классу качества
    final defaultLayers = _layersByQuality[qualityClass]![typeKey]!;
    final layers = getIntInput(inputs, 'layers', defaultValue: defaultLayers, minValue: 1, maxValue: 5);

    // Общий расход с учётом слоёв и запаса 10%
    final puttyNeeded = area * consumptionPerLayer * layers * 1.1;

    // Грунтовка: между слоями и финальная
    // Для премиум класса больше грунтовки (между каждым слоем)
    final primerCoats = qualityClass == 3 ? layers + 1 : 2;
    final primerNeeded = area * 0.2 * primerCoats;

    // Армирующая сетка (для стартовой): площадь покрытия
    // Для премиум — обязательно, для эконом — опционально
    final meshArea = type == 1 ? area : 0.0;

    // Наждачная бумага (абразивная сетка): комплект на площадь
    // Для премиум — больше шлифовки (мельче зерно, больше проходов)
    final sandpaperMultiplier = qualityClass == 3 ? 2.0 : 1.0;
    final sandpaperSets = ceilToInt(area / 25 * sandpaperMultiplier);

    // Шпатели: набор из 3-4 шт разного размера
    const spatulasNeeded = 3;

    // Вода для замешивания (информативно): ~0.4 л на кг смеси
    final waterNeeded = puttyNeeded * 0.4;

    // Расчёт стоимости — зависит от класса качества
    final puttyPrice = _findPuttyPrice(priceList, type, qualityClass);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_adhesion']);
    final meshPrice = findPrice(priceList, ['mesh', 'fiberglass_mesh', 'serpyanka']);

    final costs = [
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (type == 1) calculateCost(meshArea, meshPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        'qualityClass': qualityClass.toDouble(),
        'consumptionPerLayer': consumptionPerLayer,
        if (type == 1) 'meshArea': meshArea,
        'sandpaperSets': sandpaperSets.toDouble(),
        'spatulasNeeded': spatulasNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }

  /// Находит цену шпаклёвки по типу и классу качества
  PriceItem? _findPuttyPrice(List<PriceItem> priceList, int type, int qualityClass) {
    // SKU по классу качества:
    // Эконом: volma, osnovit
    // Стандарт: knauf, bergauf
    // Премиум: sheetrock, danogips
    final qualitySkus = {
      1: ['volma', 'osnovit', 'economy'],
      2: ['knauf', 'bergauf', 'standard'],
      3: ['sheetrock', 'danogips', 'premium'],
    };

    final typeSkus = type == 1
        ? ['putty_start', 'putty_base', 'putty']
        : ['putty_finish', 'putty_final', 'putty'];

    // Сначала ищем по классу + типу
    final qualitySku = qualitySkus[qualityClass]!;
    for (final qs in qualitySku) {
      for (final ts in typeSkus) {
        final combined = findPrice(priceList, ['${qs}_$ts', '${ts}_$qs']);
        if (combined != null) return combined;
      }
    }

    // Fallback: только по типу
    return findPrice(priceList, typeSkus);
  }
}
