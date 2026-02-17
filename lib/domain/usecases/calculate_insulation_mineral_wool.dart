// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор утепления минеральной ватой.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 9573-2012 "Плиты из минеральной ваты"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь утепления (м²)
/// - thickness: толщина утеплителя (мм), по умолчанию 100
/// - density: плотность (кг/м³), по умолчанию 50
/// - applicationSurface: поверхность утепления (1=стена, 2=пол, 3=потолок, 4=скат крыши)
class CalculateInsulationMineralWool extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 100;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (thickness < 50 || thickness > 300) return 'Толщина должна быть от 50 до 300 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 100.0, minValue: 50.0, maxValue: 300.0);
    final density = getInput(inputs, 'density', defaultValue: 50.0, minValue: 30.0, maxValue: 200.0);
    final applicationSurface = getIntInput(inputs, 'applicationSurface', defaultValue: 1, minValue: 1, maxValue: 4);

    // Объём утеплителя в м³
    final volume = calculateVolume(area, thickness);

    // Площадь одного рулона/плиты (стандарт: 0.6×1.2 м = 0.72 м²)
    final sheetArea = 0.72;

    // Количество плит/рулонов с запасом 5%
    final sheetsNeeded = calculateUnitsNeeded(area, sheetArea, marginPercent: 5.0);

    // Вес утеплителя
    final weight = volume * density;

    // Пароизоляция: площадь + 10% на нахлёсты и загибы
    final vaporBarrierArea = addMargin(area, 10.0);

    // Гидроизоляция/ветрозащита (для наружного утепления): площадь + 10%
    final windBarrierArea = addMargin(area, 10.0);

    // Крепёж: дюбели-грибки по толщине утеплителя (СП 50.13330)
    // Базовое количество по толщине
    int baseFastenersPerSqm;
    if (thickness <= 50) {
      baseFastenersPerSqm = 4;      // Тонкий слой — 4 по углам плиты
    } else if (thickness <= 100) {
      baseFastenersPerSqm = 5;      // Стандарт — 4 по углам + 1 центр
    } else if (thickness <= 150) {
      baseFastenersPerSqm = 6;      // Рекомендация СП 50.13330
    } else if (thickness <= 200) {
      baseFastenersPerSqm = 8;      // Толстый — усиленное крепление
    } else {
      baseFastenersPerSqm = 10;     // Очень толстый (250-300мм)
    }

    // Корректировка по плотности (СП 50.13330):
    // Лёгкая (<50 кг/м³): меньше крепежа — плита легче
    // Тяжёлая (>100 кг/м³): больше крепежа — плита тяжелее, больше нагрузка
    final double densityFactor;
    if (density < 50) {
      densityFactor = 0.8;
    } else if (density > 100) {
      densityFactor = 1.3;
    } else {
      densityFactor = 1.0;
    }

    final int fastenersPerSqm = (baseFastenersPerSqm * densityFactor).ceil();

    // Множитель по типу поверхности
    final double fastenerMultiplier = switch (applicationSurface) {
      2 => 0.0,   // пол — гравитация держит, крепёж не нужен
      3 => 1.5,   // потолок — против гравитации, усиленный крепёж
      4 => 1.2,   // скат крыши — умеренно усиленный крепёж
      _ => 1.0,   // стена — стандарт
    };

    final fastenersNeeded = ceilToInt(area * fastenersPerSqm * fastenerMultiplier);

    // Соединительная лента для пароизоляции: по швам
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);
    final tapeNeeded = perimeter * 1.5; // +50% на стыки

    // Деревянная/металлическая обрешётка (опционально): зависит от конструкции
    final battensLength = getInput(inputs, 'battens', defaultValue: 0.0);

    // Расчёт стоимости
    final woolPrice = findPrice(priceList, [
      'mineral_wool', 
      'wool_insulation', 
      'insulation_wool',
      'rockwool',
      'stone_wool'
    ]);
    final vaporBarrierPrice = findPrice(priceList, [
      'vapor_barrier', 
      'film_vapor', 
      'barrier_membrane'
    ]);
    final windBarrierPrice = findPrice(priceList, [
      'wind_barrier', 
      'membrane_wind', 
      'windproof_membrane'
    ]);
    final fastenerPrice = findPrice(priceList, [
      'fastener_insulation', 
      'dowel_umbrella', 
      'mushroom_dowel'
    ]);
    final tapePrice = findPrice(priceList, ['tape', 'joining_tape', 'sealing_tape']);
    final battensPrice = findPrice(priceList, ['battens', 'timber', 'wood_strips']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), woolPrice?.price),
      calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(windBarrierArea, windBarrierPrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      if (battensLength > 0) calculateCost(battensLength, battensPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'density': density,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'weight': weight,
        'vaporBarrierArea': vaporBarrierArea,
        'windBarrierArea': windBarrierArea,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'tapeNeeded': tapeNeeded,
        if (battensLength > 0) 'battensLength': battensLength,
        'applicationSurface': applicationSurface.toDouble(),
        'fastenersPerSqm': fastenersPerSqm.toDouble(),
        // Предупреждение: тонкий утеплитель (<100мм) на наружной стене
        if (thickness < 100 && applicationSurface == 1) 'warningThinExterior': 1.0,
        // Предупреждение: пол без механического крепежа
        // Для жёстких плит под стяжку может понадобиться фиксация
        if (applicationSurface == 2) 'warningFloorNoFasteners': 1.0,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
