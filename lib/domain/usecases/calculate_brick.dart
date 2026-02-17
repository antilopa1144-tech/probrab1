import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор кирпичной кладки.
///
/// Рассчитывает количество кирпичей и раствора для стен
/// с учётом типа кирпича и толщины кладки.
///
/// Нормативы:
/// - СНиП 3.03.01-87 "Несущие и ограждающие конструкции"
/// - ГОСТ 530-2012 "Кирпич и камень керамические"
///
/// Поля:
/// - area: площадь кладки (м²)
/// - brickType: тип кирпича (0=одинарный, 1=полуторный, 2=двойной)
/// - wallThickness: толщина стены (0=0.5, 1=1, 2=1.5, 3=2 кирпича)
/// - wallWidth: ширина стены (м), опционально для расчёта площади
/// - wallHeight: высота стены (м), опционально для расчёта площади
class CalculateBrick extends BaseCalculator {
  /// Количество кирпичей на 1 м² кладки (с учётом швов 10 мм).
  ///
  /// Ключ: brickType (0, 1, 2)
  /// Значение: Map wallThickness -> bricksPerSqm
  static const Map<int, Map<int, int>> bricksPerSqm = {
    // Одинарный кирпич 250×120×65 мм
    0: {
      0: 51,   // 0.5 кирпича (120 мм)
      1: 102,  // 1 кирпич (250 мм)
      2: 153,  // 1.5 кирпича (380 мм)
      3: 204,  // 2 кирпича (510 мм)
    },
    // Полуторный кирпич 250×120×88 мм
    1: {
      0: 39,
      1: 78,
      2: 117,
      3: 156,
    },
    // Двойной кирпич 250×120×138 мм
    2: {
      0: 26,
      1: 52,
      2: 78,
      3: 104,
    },
  };

  /// Размеры кирпича в мм (длина, ширина, высота)
  static const Map<int, (int, int, int)> brickSizes = {
    0: (250, 120, 65),   // Одинарный
    1: (250, 120, 88),   // Полуторный
    2: (250, 120, 138),  // Двойной
  };

  /// Толщина стены в мм
  static const Map<int, int> wallThicknessMm = {
    0: 120,  // 0.5 кирпича
    1: 250,  // 1 кирпич
    2: 380,  // 1.5 кирпича
    3: 510,  // 2 кирпича
  };

  /// Расход раствора на 1 м² кладки (м³) по СНиП
  /// Зависит от типа кирпича и толщины стены
  /// Источник: технологические карты кирпичной кладки
  static const Map<int, Map<int, double>> mortarPerSqm = {
    // Одинарный кирпич 250×120×65 мм
    0: {
      0: 0.019,  // 0.5 кирпича — ~0.189 м³ на 1000 шт ≈ 0.019 м³/м²
      1: 0.023,  // 1 кирпич — ~0.221 м³ на 1000 шт ≈ 0.023 м³/м²
      2: 0.034,  // 1.5 кирпича
      3: 0.045,  // 2 кирпича
    },
    // Полуторный кирпич 250×120×88 мм
    1: {
      0: 0.016,
      1: 0.020,
      2: 0.029,
      3: 0.038,
    },
    // Двойной кирпич 250×120×138 мм
    2: {
      0: 0.013,
      1: 0.017,
      2: 0.024,
      3: 0.031,
    },
  };

  /// Объём раствора из 1 мешка 25 кг (м³)
  static const double mortarPerBag = 0.015;

  /// Запас на подрезку и бой (%)
  static const double wastePercent = 5.0;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final wallWidth = inputs['wallWidth'];
    final wallHeight = inputs['wallHeight'];

    // Нужна либо площадь, либо размеры стены
    if (area <= 0 && (wallWidth == null || wallHeight == null)) {
      return 'Необходимо указать площадь или размеры стены';
    }

    if (area <= 0 && wallWidth != null && wallHeight != null) {
      if (wallWidth <= 0 || wallHeight <= 0) {
        return 'Размеры стены должны быть положительными';
      }
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final brickType = getIntInput(inputs, 'brickType', defaultValue: 0, minValue: 0, maxValue: 2);
    final wallThickness = getIntInput(inputs, 'wallThickness', defaultValue: 1, minValue: 0, maxValue: 3);

    // Условия работы: 1=нормальные, 2=ветрено, 3=холод <+5°C, 4=жарко >+30°C
    final workingConditions = getIntInput(inputs, 'workingConditions', defaultValue: 1, minValue: 1, maxValue: 4);

    final double conditionsMultiplier = switch (workingConditions) {
      2 => 1.05,  // Ветрено — больше расход раствора (быстрее сохнет)
      3 => 1.10,  // Холод — раствор густеет, больше потерь
      4 => 1.08,  // Жарко — раствор сохнет быстрее, больше потерь
      _ => 1.0,   // Нормальные условия
    };

    // Площадь: либо напрямую, либо из размеров стены
    double area;
    final inputArea = getInput(inputs, 'area', defaultValue: 0);
    if (inputArea > 0) {
      area = inputArea;
    } else {
      final wallWidth = getInput(inputs, 'wallWidth', defaultValue: 5.0, minValue: 0.1, maxValue: 50);
      final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 0.1, maxValue: 10);
      area = wallWidth * wallHeight;
    }

    // Количество кирпичей на м²
    final bricksPerM2 = bricksPerSqm[brickType]![wallThickness]!;

    // Количество кирпичей с запасом (условия НЕ влияют на кирпич)
    final bricksNeeded = (area * bricksPerM2 * (1 + wastePercent / 100)).ceil();

    // Расход раствора (м³/м² кладки по СНиП) + 8% потери на площадке + условия
    final mortarPerM2 = mortarPerSqm[brickType]![wallThickness]!;
    final mortarVolume = area * mortarPerM2 * 1.08 * conditionsMultiplier;

    // Мешки раствора (25 кг)
    final mortarBags = (mortarVolume / mortarPerBag).ceil();

    // Цемент для раствора (примерно 375 кг/м³)
    final cementNeeded = mortarVolume * 375;

    // Песок для раствора (примерно 1.5 м³/м³ раствора)
    final sandNeeded = mortarVolume * 1.5;

    // --- Кладочная сетка: армирование через каждые N рядов ---
    // Несущие стены (wallThickness >= 1) → каждые 5 рядов
    // Перегородки (wallThickness == 0) → каждые 3 ряда
    final brickSize = brickSizes[brickType]!;
    final brickHeightMm = brickSize.$3; // высота кирпича в мм
    const jointMm = 10; // толщина шва 10мм

    // Высота одного ряда (мм)
    final rowHeight = brickHeightMm + jointMm;

    // Высота стены для расчёта рядов
    final wallHeightM = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 0.1, maxValue: 10);
    final totalRows = (wallHeightM * 1000 / rowHeight).ceil();

    // Интервал армирования
    final meshInterval = wallThickness == 0 ? 3 : 5;
    final meshLayers = (totalRows / meshInterval).ceil();

    // Ширина стены для сетки
    final wallWidthM = inputArea > 0
        ? area / wallHeightM
        : getInput(inputs, 'wallWidth', defaultValue: 5.0, minValue: 0.1, maxValue: 50);
    // Площадь сетки с запасом 10%
    final meshArea = meshLayers * wallWidthM * 1.1;
    // Сетка в картах (стандарт: карта 0.5×2.0 м = 1.0 м²)
    final meshCards = (meshArea / 1.0).ceil();

    // Расчёт стоимости
    final brickPrice = findPrice(priceList, ['brick', 'brick_single', 'brick_red', 'brick_ceramic']);
    final cementPrice = findPrice(priceList, ['cement', 'cement_bag', 'portland_cement']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final meshPrice = findPrice(priceList, ['mesh_masonry', 'mesh_brick', 'reinforcing_mesh']);

    final costs = [
      calculateCost(bricksNeeded.toDouble(), brickPrice?.price),
      calculateCost(cementNeeded / 50, cementPrice?.price), // цемент продаётся мешками по 50 кг
      calculateCost(sandNeeded, sandPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
    ];

    // Размер кирпича для информации
    final wallThickMm = wallThicknessMm[wallThickness]!;

    return createResult(
      values: {
        'area': area,
        'bricksNeeded': bricksNeeded.toDouble(),
        'brickType': brickType.toDouble(),
        'wallThickness': wallThickness.toDouble(),
        'wallThicknessMm': wallThickMm.toDouble(),
        'mortarVolume': mortarVolume,
        'mortarBags': mortarBags.toDouble(),
        'cementNeeded': cementNeeded,
        'sandNeeded': sandNeeded,
        'brickLength': brickSize.$1.toDouble(),
        'brickWidth': brickSize.$2.toDouble(),
        'brickHeight': brickSize.$3.toDouble(),
        'workingConditions': workingConditions.toDouble(),
        'meshLayers': meshLayers.toDouble(),
        'meshArea': meshArea,
        'meshCards': meshCards.toDouble(),
        'wallHeight': wallHeightM,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
