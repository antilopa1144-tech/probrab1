// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор обоев с раппортом и гибридным режимом ввода.
///
/// Поддерживает два режима ввода:
/// 1. **По размерам** (inputMode = 0): длина, ширина, высота → автоматический расчёт площади/периметра
/// 2. **По площади** (inputMode = 1): готовая площадь стен
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - inputMode: режим ввода (0 = по размерам, 1 = по площади)
/// - length, width: размеры помещения (м) - только для режима 0
/// - area: площадь стен (м²) - только для режима 1
/// - wallHeight: высота стен (м), по умолчанию 2.5
/// - rollWidth: ширина рулона (м), по умолчанию 0.53
/// - rollLength: длина рулона (м), по умолчанию 10.05
/// - rapport: раппорт/шаг рисунка (см), по умолчанию 0 (без раппорта)
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
/// - wallpaperType: тип обоев (1 = бумажные, 2 = виниловые, 3 = флизелиновые)
class CalculateWallpaper extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = (inputs['inputMode'] ?? 0).toInt();

    if (inputMode == 0) {
      // Режим "По размерам": проверяем length и width
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length <= 0) return 'Длина должна быть больше нуля';
      if (width <= 0) return 'Ширина должна быть больше нуля';
    } else {
      // Режим "По площади": проверяем area
      final area = inputs['area'] ?? 0;
      if (area <= 0) return 'Площадь должна быть больше нуля';
    }

    final wallHeight = inputs['wallHeight'] ?? 2.5;
    if (wallHeight <= 0 || wallHeight > 5) return 'Высота стен должна быть от 0.1 до 5 м';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // --- Режим ввода: по размерам (0) или по площади (1) ---
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0);

    // Вычисляем площадь и периметр в зависимости от режима
    double area;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам": вычисляем площадь и периметр
      final length = getInput(inputs, 'length', minValue: 0.1);
      final width = getInput(inputs, 'width', minValue: 0.1);
      final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 5.0);

      area = (length + width) * 2 * wallHeight;
      perimeter = (length + width) * 2;
    } else {
      // Режим "По площади": берём площадь стен
      area = getInput(inputs, 'area', minValue: 0.1);
      final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 5.0);
      // Периметр = площадь стен / высота стен (а не sqrt(area)*4, т.к. area — это площадь СТЕН, а не пола)
      perimeter = area / wallHeight;
    }

    // --- Получаем размер рулона ---
    final rollSize = getIntInput(inputs, 'rollSize', defaultValue: 1);
    double rollWidth;
    double rollLength;

    switch (rollSize) {
      case 1: // 0.53×10
        rollWidth = 0.53;
        rollLength = 10.05;
        break;
      case 2: // 1.06×10
        rollWidth = 1.06;
        rollLength = 10.05;
        break;
      case 3: // 1.06×25
        rollWidth = 1.06;
        rollLength = 25.0;
        break;
      default: // Пользовательский
        rollWidth = getInput(inputs, 'rollWidth', defaultValue: 0.53, minValue: 0.5, maxValue: 1.2);
        rollLength = getInput(inputs, 'rollLength', defaultValue: 10.05, minValue: 5.0, maxValue: 50.0);
    }

    // --- Получаем остальные входные данные ---
    final rapport = getInput(inputs, 'rapport', defaultValue: 0.0, minValue: 0.0, maxValue: 100.0); // см
    // Запас убран по запросу пользователя — раскрой обоев уже учтён в формуле полос
    const reserve = 0.0;
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 5.0);
    final windowsArea = getInput(inputs, 'windowsArea', minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', minValue: 0.0);

    // Полезная площадь
    final usefulArea = calculateUsefulArea(area, windowsArea: windowsArea, doorsArea: doorsArea);

    if (usefulArea <= 0) {
      return createResult(values: {'error': 1.0});
    }

    // Количество полос на стену
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
    
    // Количество рулонов с учётом подрезки и запаса (reserve%)
    final reserveMultiplier = 1.0 + (reserve / 100);
    final rollsNeeded = stripsPerRoll > 0
        ? ceilToInt(stripsNeeded / stripsPerRoll.toDouble() * reserveMultiplier)
        : ceilToInt(usefulArea / (rollWidth * rollLength) * (1.0 + reserve / 100 + 0.10)); // резервный расчёт

    // --- Тип обоев: влияет на расход клея ---
    // 1 = бумажные (лёгкие, мало клея)
    // 2 = виниловые (тяжёлые, больше клея)
    // 3 = флизелиновые (средние)
    final wallpaperType = getIntInput(inputs, 'wallpaperType', defaultValue: 1);

    // Клей обойный (СУХАЯ СМЕСЬ, разводится водой):
    // Расход сухого клея зависит от типа обоев:
    // - Бумажные: 5 г/м² (лёгкие, тонкий слой клея)
    // - Флизелиновые: 8 г/м² (средний вес, клей на стену)
    // - Виниловые: 10 г/м² (тяжёлые, густой клей)
    double pasteRate;
    switch (wallpaperType) {
      case 1: pasteRate = 0.005; break;  // бумажные — 5 г/м²
      case 2: pasteRate = 0.010; break;  // виниловые — 10 г/м²
      case 3: pasteRate = 0.008; break;  // флизелиновые — 8 г/м²
      default: pasteRate = 0.008;        // fallback
    }

    // Клей с запасом 10% (потери при замешивании и нанесении)
    final pasteNeeded = usefulArea * pasteRate * 1.1;
    // Стандартная упаковка клея — 250 г (0.25 кг), рассчитана на 7-8 рулонов
    final pastePacks = ceilToInt(pasteNeeded / 0.25);

    // Грунтовка (рекомендуется перед поклейкой): 0.15 л/м² с запасом 10%
    final primerNeeded = usefulArea * 0.15 * 1.1;
    // Стандартная канистра грунтовки — 5 л
    final primerCans = ceilToInt(primerNeeded / 5.0);

    // Расчёт стоимости
    final wallpaperPrice = findPrice(priceList, ['wallpaper', 'wallpaper_vinyl', 'wallpaper_fleece', 'wallpaper_paper']);
    final gluePrice = findPrice(priceList, ['glue_wallpaper', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(rollsNeeded.toDouble(), wallpaperPrice?.price),
      calculateCost(pasteNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'usefulArea': usefulArea,
        'rollsNeeded': rollsNeeded.toDouble(),
        'stripsNeeded': stripsNeeded.toDouble(),
        'glueNeeded': pasteNeeded,       // backward compat key
        'pasteNeeded': pasteNeeded,      // new key (same value)
        'pastePacks': pastePacks.toDouble(),
        'primerNeeded': primerNeeded,
        'primerCans': primerCans.toDouble(),
        'stripLength': stripLength,
        'wallpaperType': wallpaperType.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}

