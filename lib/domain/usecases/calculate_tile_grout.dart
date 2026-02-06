// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

/// Калькулятор затирки для кафеля.
///
/// Нормативы:
/// - СП 29.13330.2023 "Полы" (нормы укладки плитки)
/// - Расход затирки зависит от размера плитки, ширины и глубины шва
///
/// Формула расхода (кг/м²) — в единицах СИ (метры, кг/м³):
///   jointsLengthPerM2 = 1/tileWidth_m + 1/tileHeight_m  (м шва на м² поверхности)
///   jointCrossSection = jointWidth_m × jointDepth_m       (м²)
///   jointVolumePerM2  = jointsLengthPerM2 × jointCrossSection  (м³/м²)
///   consumptionPerM2  = jointVolumePerM2 × density        (кг/м²)
///
/// Плотность затирки:
///   цементная — 1600 кг/м³
///   эпоксидная — 1400 кг/м³
///   полиуретановая — 1200 кг/м³
///
/// Поля:
/// - inputMode: 0 = по размерам (length × width), 1 = по площади
/// - length, width: размеры помещения (м)
/// - area: площадь (м²)
/// - tileSize: размер плитки (выбор из стандартных или 0 = пользовательский)
/// - tileWidth, tileHeight: размеры плитки (см) — только при tileSize=0
/// - jointWidth: ширина шва (мм), по умолчанию 3
/// - jointDepth: глубина шва (мм), по умолчанию 2
/// - groutType: тип затирки (0 = цементная, 1 = эпоксидная, 2 = полиуретановая)
class CalculateTileGrout extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode']?.toInt() ?? 1;
    if (inputMode == 0) {
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length <= 0 || width <= 0) return 'Длина и ширина должны быть больше нуля';
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
    // --- Режим ввода ---
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 1);
    double area;
    if (inputMode == 0) {
      final length = getInput(inputs, 'length', minValue: 0.1);
      final width = getInput(inputs, 'width', minValue: 0.1);
      area = length * width;
    } else {
      area = getInput(inputs, 'area', minValue: 0.1);
    }

    // --- Размер плитки ---
    final tileSize = getIntInput(inputs, 'tileSize', defaultValue: 60);
    double tileWidth;
    double tileHeight;

    if (tileSize == 0) {
      // Пользовательский размер
      tileWidth = getInput(inputs, 'tileWidth', defaultValue: 60.0, minValue: 1.0, maxValue: 200.0);
      tileHeight = getInput(inputs, 'tileHeight', defaultValue: 60.0, minValue: 1.0, maxValue: 200.0);
    } else if (tileSize == 120) {
      // Прямоугольная плитка 120×60
      tileWidth = 120.0;
      tileHeight = 60.0;
    } else {
      // Квадратная плитка (20, 30, 40, 60, 80)
      tileWidth = tileSize.toDouble();
      tileHeight = tileSize.toDouble();
    }

    // --- Параметры шва ---
    final jointWidth = getInput(inputs, 'jointWidth', defaultValue: 3.0, minValue: 1.0, maxValue: 12.0); // мм
    final jointDepth = getInput(inputs, 'jointDepth', defaultValue: 2.0, minValue: 1.0, maxValue: 5.0);   // мм

    // --- Тип затирки ---
    final groutType = getIntInput(inputs, 'groutType', defaultValue: 0); // 0=цементная, 1=эпоксидная, 2=полиуретановая

    // --- Плотность затирки (кг/м³) ---
    final density = switch (groutType) {
      1 => 1400.0, // эпоксидная
      2 => 1200.0, // полиуретановая
      _ => 1600.0, // цементная (по умолчанию)
    };

    // --- Перевод размеров плитки в метры ---
    final tileWidthM = tileWidth / 100.0;   // см → м
    final tileHeightM = tileHeight / 100.0; // см → м

    // --- Перевод параметров шва в метры ---
    final jointWidthM = jointWidth / 1000.0;  // мм → м
    final jointDepthM = jointDepth / 1000.0;  // мм → м

    // --- Расход затирки (кг/м²) по формуле из единиц СИ ---
    // Суммарная длина швов на 1 м² поверхности:
    //   горизонтальные: 1/tileHeightM (штук ряда на метр высоты) × 1 м ширины
    //   вертикальные:   1/tileWidthM  (штук столбца на метр ширины) × 1 м высоты
    //   итого: 1/tileWidthM + 1/tileHeightM  (м шва / м² поверхности)
    final jointsLengthPerM2 = safeDivide(1.0, tileWidthM, defaultValue: 0.0)
        + safeDivide(1.0, tileHeightM, defaultValue: 0.0);

    // Сечение шва (м²)
    final jointCrossSection = jointWidthM * jointDepthM;

    // Объём шва на 1 м² поверхности (м³/м²)
    final jointVolumePerM2 = jointsLengthPerM2 * jointCrossSection;

    // Расход затирки в кг/м²
    final consumptionPerM2 = jointVolumePerM2 * density;

    // --- Общий расход с запасом 10% ---
    final groutNeeded = area * consumptionPerM2 * 1.10;

    // --- Количество упаковок ---
    // Цементная: 2 кг (стандартная упаковка затирки)
    // Эпоксидная: 2.5 кг (набор A+B)
    // Полиуретановая: 2 кг (готовая паста, например Mapei Poxiflex)
    final bagWeight = switch (groutType) {
      1 => 2.5, // эпоксидная
      2 => 2.0, // полиуретановая
      _ => 2.0, // цементная
    };
    final bagsNeeded = (groutNeeded / bagWeight).ceil().clamp(1, 10000);

    // --- Сопутствующие материалы ---
    // Резиновый шпатель: 1 шт на 10 м², минимум 1
    final spatulaCount = (area / 10.0).ceil().clamp(1, 10);
    // Губки для затирки: 1 упаковка (10 шт) на 5 м², минимум 1
    final spongePackCount = (area / 5.0).ceil().clamp(1, 10);

    // --- Стоимость ---
    final groutPrice = findPrice(priceList, ['grout', 'grout_tile', 'затирка']);
    final costs = [
      calculateCost(groutNeeded, groutPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'jointWidth': jointWidth,
        'jointDepth': jointDepth,
        'consumptionPerM2': consumptionPerM2,
        'groutNeeded': groutNeeded,
        'bagsNeeded': bagsNeeded.toDouble(),
        'bagWeight': bagWeight,
        'spatulaCount': spatulaCount.toDouble(),
        'spongePackCount': spongePackCount.toDouble(),
        'groutType': groutType.toDouble(),
      },
      totalPrice: sumCosts(costs),
      calculatorId: 'floors_tile_grout',
      norms: const ['СП 29.13330.2023'],
    );
  }
}
