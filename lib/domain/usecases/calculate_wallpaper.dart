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
class CalculateWallpaper extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode'] ?? 0;
    if (inputMode == 1 && (inputs['area'] ?? 0) <= 0) {
      return 'Площадь должна быть больше нуля';
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
      // Режим "По площади": берём готовые значения
      area = getInput(inputs, 'area', minValue: 0.1);
      perimeter = estimatePerimeter(area);
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
    final reserve = getInput(inputs, 'reserve', defaultValue: 5.0, minValue: 0.0, maxValue: 15.0);
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

    // Клей обойный (СУХАЯ СМЕСЬ, разводится водой):
    // Стандартная упаковка 200-300 г на 5-8 рулонов (25-40 м²)
    // Расход сухого клея: ~7-10 г/м² в зависимости от типа обоев
    // - Бумажные: 5-7 г/м²
    // - Флизелиновые: 7-10 г/м²
    // - Виниловые/тяжёлые: 10-12 г/м²
    // Используем средний расход 8 г/м² = 0.008 кг/м²
    const glueConsumption = 0.008; // кг/м² (8 г/м² сухого клея)
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

