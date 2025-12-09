import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор обоев с раппортом.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - rollWidth: ширина рулона (м), по умолчанию 0.53
/// - rollLength: длина рулона (м), по умолчанию 10.05
/// - rapport: раппорт/шаг рисунка (см), по умолчанию 0 (без раппорта)
/// - wallHeight: высота стен (м), по умолчанию 2.5
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateWallpaper extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final wallHeight = inputs['wallHeight'] ?? 2.5;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (wallHeight <= 0 || wallHeight > 5) return 'Высота стен должна быть от 0.1 до 5 м';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final rollWidth = getInput(inputs, 'rollWidth', defaultValue: 0.53, minValue: 0.5, maxValue: 1.2);
    final rollLength = getInput(inputs, 'rollLength', defaultValue: 10.05, minValue: 5.0, maxValue: 50.0);
    final rapport = getInput(inputs, 'rapport', defaultValue: 0.0, minValue: 0.0, maxValue: 100.0); // см
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 5.0);
    final windowsArea = getInput(inputs, 'windowsArea', minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', minValue: 0.0);

    // Полезная площадь
    final usefulArea = calculateUsefulArea(area, windowsArea: windowsArea, doorsArea: doorsArea);

    if (usefulArea <= 0) {
      return createResult(values: {'error': 1.0});
    }

    // Количество полос на стену
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    final stripsNeeded = ceilToInt(perimeter / rollWidth);

    // Учёт раппорта при расчёте длины полосы
    double stripLength = wallHeight;
    if (rapport > 0) {
      // Раппорт в метрах
      final rapportM = rapport / 100;
      // Подгонка под раппорт: округляем вверх до кратного раппорту + один раппорт запас
      final rapportUnits = (wallHeight / rapportM).ceil() + 1;
      stripLength = rapportUnits * rapportM;
    }

    // Количество полос из одного рулона
    final stripsPerRoll = (rollLength / stripLength).floor();
    
    // Количество рулонов с учётом подрезки и брака
    final rollsNeeded = stripsPerRoll > 0 
        ? ceilToInt(stripsNeeded / stripsPerRoll.toDouble() * 1.05) // +5% запас
        : ceilToInt(usefulArea / (rollWidth * rollLength) * 1.15); // резервный расчёт

    // Клей: расход зависит от типа обоев
    // Бумажные: 0.15-0.2 кг/м²
    // Флизелиновые/виниловые: 0.2-0.25 кг/м²
    // Тяжёлые (стеклообои): 0.25-0.3 кг/м²
    const glueConsumption = 0.22; // кг/м² (средний расход)
    final glueNeeded = usefulArea * glueConsumption;

    // Грунтовка (рекомендуется перед поклейкой): ~0.1 л/м²
    final primerNeeded = usefulArea * 0.1;

    // Расчёт стоимости
    final wallpaperPrice = findPrice(priceList, ['wallpaper', 'wallpaper_vinyl', 'wallpaper_fleece', 'wallpaper_paper']);
    final gluePrice = findPrice(priceList, ['glue_wallpaper', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(rollsNeeded.toDouble(), wallpaperPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'usefulArea': usefulArea,
        'rollsNeeded': rollsNeeded.toDouble(),
        'stripsNeeded': stripsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
        'stripLength': stripLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}

