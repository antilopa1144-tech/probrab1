// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ОСБ плит.
///
/// Нормативы:
/// - ГОСТ Р 56309-2014 "Плиты древесные ОСБ"
/// - СП 31-105-2002 "Проектирование и строительство каркасных домов"
/// - СП 64.13330.2017 "Деревянные конструкции"
///
/// Поля:
/// - inputMode: режим ввода (0=по размерам, 1=по площади)
/// - length, width: размеры помещения (м) - для режима 0
/// - area: площадь покрытия (м²) - для режима 1
/// - sheetSize: размер плиты (1=2500×1250, 2=2500×625, 3=2800×1250, 4=3000×1250, 5=2440×1220, 0=пользовательский)
/// - sheetLength, sheetWidth: размеры плиты (м) - для пользовательского размера
/// - thickness: толщина плиты (6, 9, 10, 12, 15, 18, 22 мм)
/// - osbClass: класс ОСБ (1-4)
/// - constructionType: тип конструкции (1=обшивка стен, 2=пол, 3=крыша, 4=перегородки, 5=СИП-панели, 6=опалубка)
/// - joistStep: шаг лаг (мм) - для пола
/// - rafterStep: шаг стропил/обрешётки (мм) - для кровли
/// - environment: условия эксплуатации (1=сухо, 2=влажно, 3=наружные)
/// - loadLevel: уровень нагрузки (1=обычная, 2=высокая)
/// - reserve: запас (%) по умолчанию 10
class CalculateSheetingOsbPlywood extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode']?.toInt() ?? 1;

    if (inputMode == 0) {
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length <= 0 || width <= 0) {
        final fallbackArea = inputs['area'] ?? 0;
        if (fallbackArea <= 0) {
          return 'Длина и ширина должны быть больше нуля';
        }
      }
    } else {
      final area = inputs['area'] ?? 0;
      if (area <= 0) return 'Площадь должна быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // --- Режим ввода: по размерам (0) или по площади (1) ---
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 1);

    // Вычисляем площадь в зависимости от режима
    double area;
    if (inputMode == 0) {
      // Режим "По размерам"
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length > 0 && width > 0) {
        final normalizedLength = getInput(inputs, 'length', minValue: 0.1);
        final normalizedWidth = getInput(inputs, 'width', minValue: 0.1);
        area = normalizedLength * normalizedWidth;
      } else {
        area = getInput(inputs, 'area', minValue: 0.1);
      }
    } else {
      // Режим "По площади"
      area = getInput(inputs, 'area', minValue: 0.1);
    }

    // --- Размер плиты ---
    final sheetSize = getIntInput(inputs, 'sheetSize', defaultValue: 1, minValue: 0, maxValue: 5);
    double sheetLength;
    double sheetWidth;

    switch (sheetSize) {
      case 1: // 2500×1250 мм (основной стандарт)
        sheetLength = 2.50;
        sheetWidth = 1.25;
        break;
      case 2: // 2500×625 мм (шпунтованный для полов)
        sheetLength = 2.50;
        sheetWidth = 0.625;
        break;
      case 3: // 2800×1250 мм (для высоких стен)
        sheetLength = 2.80;
        sheetWidth = 1.25;
        break;
      case 4: // 3000×1250 мм (для высоких стен)
        sheetLength = 3.00;
        sheetWidth = 1.25;
        break;
      case 5: // 2440×1220 мм (редкий размер)
        sheetLength = 2.44;
        sheetWidth = 1.22;
        break;
      default: // Пользовательский размер
        sheetLength = getInput(inputs, 'sheetLength', defaultValue: 2.5, minValue: 1.0, maxValue: 3.6);
        sheetWidth = getInput(inputs, 'sheetWidth', defaultValue: 1.25, minValue: 0.5, maxValue: 1.5);
    }

    final sheetArea = sheetLength * sheetWidth;

    // --- Толщина плиты ---
    final thickness = getIntInput(inputs, 'thickness', defaultValue: 9, minValue: 6, maxValue: 22);

    // --- Класс ОСБ ---
    final osbClass = getIntInput(inputs, 'osbClass', defaultValue: 3, minValue: 1, maxValue: 4);

    // --- Тип конструкции ---
    final constructionType = getIntInput(inputs, 'constructionType', defaultValue: 1, minValue: 1, maxValue: 6);

    // --- Шаг опор (для пола/кровли) ---
    final joistStep = getIntInput(inputs, 'joistStep', defaultValue: 600, minValue: 300, maxValue: 800);
    final rafterStep = getIntInput(inputs, 'rafterStep', defaultValue: 600, minValue: 300, maxValue: 1200);

    // --- Условия эксплуатации ---
    final environment = getIntInput(inputs, 'environment', defaultValue: 1, minValue: 1, maxValue: 3);
    final loadLevel = getIntInput(inputs, 'loadLevel', defaultValue: 1, minValue: 1, maxValue: 2);

    // --- Множитель площади ОСБ (двусторонняя обшивка) ---
    double osbAreaMultiplier;
    switch (constructionType) {
      case 1: // Обшивка стен
        osbAreaMultiplier = 1.0;
        break;
      case 2: // Пол
        osbAreaMultiplier = 1.0;
        break;
      case 3: // Крыша
        osbAreaMultiplier = 1.0;
        break;
      case 4: // Перегородки
        osbAreaMultiplier = 2.1; // ~2.10 м² ОСБ на 1 м² перегородки
        break;
      case 5: // СИП-панели
        osbAreaMultiplier = 2.05; // ~2.05 м² ОСБ на 1 м² панели
        break;
      case 6: // Опалубка
        osbAreaMultiplier = 1.0;
        break;
      default:
        osbAreaMultiplier = 1.0;
    }

    // --- Проёмы ---
    final windowsArea = getInput(inputs, 'windowsArea', minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', minValue: 0.0);
    final openingsArea = windowsArea + doorsArea;

    double effectiveArea = area;

    if (area > 0 && openingsArea > 0) {
      final ratio = openingsArea / area;
      double deductionFactor;
      if (ratio < 0.10) {
        deductionFactor = 0.5;
      } else if (ratio <= 0.30) {
        deductionFactor = 0.75;
      } else {
        deductionFactor = 1.0;
      }
      effectiveArea = area - openingsArea * deductionFactor;
      if (effectiveArea < 0) effectiveArea = 0;
    }

    // --- Запас материала ---
    // Рекомендуемые значения по справочнику:
    // стены 7-12%, полы 5%, кровля 10-20%, перегородки 10%
    double reserve = getInput(inputs, 'reserve', defaultValue: 10.0, minValue: 5.0, maxValue: 20.0);
    if (area > 0 && openingsArea / area > 0.30 && reserve < 15.0) {
      reserve = 15.0;
    }

    final osbBaseArea = effectiveArea * osbAreaMultiplier;

    // Площадь ОСБ с запасом
    final materialArea = addMargin(osbBaseArea, reserve);

    // Количество листов
    final sheetsNeeded = calculateUnitsNeeded(osbBaseArea, sheetArea, marginPercent: reserve);

    // --- Расчёт крепежа в зависимости от типа конструкции ---
    // Нормы расхода саморезов для ОСБ (СП 31-105-2002):
    // - Обшивка стен: шаг 150-200 мм по краям, 300 мм по полю (20-25 шт/м²)
    // - Пол: шаг 200 мм по краям, 300-400 мм по полю (15-20 шт/м²)
    // - Крыша: шаг 150 мм по краям, 300 мм по полю (15-20 шт/м²)
    // - Перегородки: с двух сторон, шаг 200 мм (25-30 шт/м²)
    // - СИП-панели: специальный крепёж (10-15 шт/м²)
    // - Опалубка: крепёж каждые 300-400 мм (20 шт/м²)
    double screwsPerM2;
    String fastenerType;

    switch (constructionType) {
      case 1: // Обшивка стен
        screwsPerM2 = 23.0;
        fastenerType = 'screws_wall';
        break;
      case 2: // Пол
        screwsPerM2 = 18.0;
        fastenerType = 'screws_floor';
        break;
      case 3: // Крыша
        screwsPerM2 = 18.0;
        fastenerType = 'screws_roof';
        break;
      case 4: // Перегородки
        screwsPerM2 = 27.0; // С двух сторон
        fastenerType = 'screws_wall';
        break;
      case 5: // СИП-панели
        screwsPerM2 = 12.0;
        fastenerType = 'screws_sip';
        break;
      case 6: // Опалубка
        screwsPerM2 = 20.0;
        fastenerType = 'screws_formwork';
        break;
      default:
        screwsPerM2 = 20.0;
        fastenerType = 'screws';
    }

    final screwsNeeded = ceilToInt(effectiveArea * screwsPerM2);

    // --- Рекомендованная толщина и предупреждения ---
    int? recommendedThickness;
    bool warningLowThicknessFloor = false;
    bool warningLowThicknessRoof = false;
    bool warningLowThicknessFormwork = false;

    if (constructionType == 2) {
      int minThickness;
      int recThickness;
      if (joistStep <= 300) {
        minThickness = 12;
        recThickness = 15;
      } else if (joistStep <= 400) {
        minThickness = 15;
        recThickness = 18;
      } else if (joistStep <= 500) {
        minThickness = 18;
        recThickness = 18;
      } else if (joistStep <= 600) {
        minThickness = 18;
        recThickness = 22;
      } else {
        minThickness = 22;
        recThickness = 22;
      }
      recommendedThickness = recThickness;
      if (thickness < minThickness) {
        warningLowThicknessFloor = true;
      }
    } else if (constructionType == 3) {
      int minThickness;
      int recThickness;
      if (rafterStep <= 600) {
        minThickness = 9;
        recThickness = 9;
      } else if (rafterStep <= 900) {
        minThickness = 12;
        recThickness = 12;
      } else {
        minThickness = 15;
        recThickness = 15;
      }
      recommendedThickness = recThickness;
      if (thickness < minThickness) {
        warningLowThicknessRoof = true;
      }
    } else if (constructionType == 6) {
      if (thickness < 18) {
        warningLowThicknessFormwork = true;
      }
    }

    final isLowClass = osbClass < 3;
    final warningClassOutdoor = isLowClass &&
        (environment == 3 || constructionType == 1 || constructionType == 3 || constructionType == 6);
    final warningClassWet = isLowClass && environment == 2;
    final warningClassLoad = isLowClass && loadLevel == 2;

    // --- Дополнительные материалы по типу конструкции ---
    double windBarrierArea = 0.0;
    double vaporBarrierArea = 0.0;
    double underlayArea = 0.0;
    double underlaymentArea = 0.0;
    double counterBattensLength = 0.0;
    double clips = 0.0;
    double studsLength = 0.0;
    double insulationArea = 0.0;
    double battensLength = 0.0;
    double glueNeededKg = 0.0;
    double foamNeeded = 0.0;

    switch (constructionType) {
      case 1: // Обшивка стен
        windBarrierArea = addMargin(effectiveArea, 15.0);
        vaporBarrierArea = addMargin(effectiveArea, 15.0);
        break;
      case 2: // Пол
        underlayArea = addMargin(effectiveArea, 5.0);
        break;
      case 3: // Крыша
        underlaymentArea = addMargin(effectiveArea, 10.0);
        clips = ceilToInt(sheetsNeeded * 2.5).toDouble();
        counterBattensLength = effectiveArea * 3.5;
        break;
      case 4: // Перегородки
        studsLength = effectiveArea * 2.75;
        insulationArea = effectiveArea * 1.02;
        break;
      case 5: // СИП-панели
        insulationArea = effectiveArea;
        glueNeededKg = roundBulk(effectiveArea * 0.15);
        foamNeeded = ceilToInt(effectiveArea * 0.3).toDouble();
        break;
      case 6: // Опалубка
        battensLength = effectiveArea * 3.5;
        break;
    }

    // --- Расчёт стоимости ---
    final sheetPrice = findPrice(
      priceList,
      ['osb_${thickness}mm', 'osb', 'plywood_${thickness}mm', 'plywood', 'sheet_material'],
    );
    final screwPrice = findPrice(priceList, [fastenerType, 'screws', 'screws_wood', 'fasteners']);
    final windBarrierPrice = findPrice(priceList, [
      'wind_barrier',
      'membrane_wind',
      'windproof_membrane',
    ]);
    final vaporBarrierPrice = findPrice(priceList, [
      'vapor_barrier',
      'film_vapor',
      'barrier_membrane',
    ]);
    final underlayPrice = findPrice(priceList, ['underlay', 'underlay_floor']);
    final underlaymentPrice = findPrice(priceList, [
      'underlayment_roof',
      'roof_underlayment',
      'roofing_felt',
    ]);
    final counterBattensPrice = findPrice(priceList, ['counter_battens', 'battens']);
    final foamPrice = findPrice(priceList, ['foam', 'mounting_foam', 'polyurethane_foam']);
    final gluePrice = findPrice(priceList, ['sip_glue', 'glue_polyurethane', 'adhesive']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), sheetPrice?.price),
      calculateCost(screwsNeeded.toDouble(), screwPrice?.price),
      calculateCost(windBarrierArea, windBarrierPrice?.price),
      calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(underlayArea, underlayPrice?.price),
      calculateCost(underlaymentArea, underlaymentPrice?.price),
      calculateCost(counterBattensLength, counterBattensPrice?.price),
      calculateCost(foamNeeded, foamPrice?.price),
      calculateCost(glueNeededKg, gluePrice?.price),
    ];

    return createResult(
      values: {
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
        'materialArea': roundBulk(materialArea),
        if (recommendedThickness != null) 'recommendedThickness': recommendedThickness.toDouble(),
        if (windBarrierArea > 0) 'windBarrierArea': roundBulk(windBarrierArea),
        if (vaporBarrierArea > 0) 'vaporBarrierArea': roundBulk(vaporBarrierArea),
        if (underlayArea > 0) 'underlayArea': roundBulk(underlayArea),
        if (underlaymentArea > 0) 'underlaymentArea': roundBulk(underlaymentArea),
        if (counterBattensLength > 0) 'counterBattensLength': roundBulk(counterBattensLength),
        if (clips > 0) 'clips': clips,
        if (studsLength > 0) 'studsLength': roundBulk(studsLength),
        if (insulationArea > 0) 'insulationArea': roundBulk(insulationArea),
        if (battensLength > 0) 'battensLength': roundBulk(battensLength),
        if (glueNeededKg > 0) 'glueNeededKg': glueNeededKg,
        if (foamNeeded > 0) 'foamNeeded': foamNeeded,
        if (warningLowThicknessFloor) 'warningLowThicknessFloor': 1,
        if (warningLowThicknessRoof) 'warningLowThicknessRoof': 1,
        if (warningLowThicknessFormwork) 'warningLowThicknessFormwork': 1,
        if (warningClassOutdoor) 'warningClassOutdoor': 1,
        if (warningClassWet) 'warningClassWet': 1,
        if (warningClassLoad) 'warningClassLoad': 1,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
