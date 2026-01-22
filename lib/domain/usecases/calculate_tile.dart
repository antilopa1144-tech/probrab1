// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор плитки / керамогранита.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 6787-2001 "Плитки керамические для полов"
///
/// Поля:
/// - area: площадь (м²)
/// - tileWidth: ширина плитки (см)
/// - tileHeight: высота плитки (см)
/// - jointWidth: ширина шва (мм), по умолчанию 3
class CalculateTile extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = (inputs['inputMode'] ?? 1).toInt();

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

    // Проверяем размер плитки только для пользовательского размера (tileSize == 0)
    final tileSize = (inputs['tileSize'] ?? 60).toInt();
    if (tileSize == 0) {
      final tileWidth = inputs['tileWidth'] ?? 30.0;
      final tileHeight = inputs['tileHeight'] ?? 30.0;
      if (tileWidth <= 0 || tileWidth > 200) return 'Ширина плитки должна быть от 1 до 200 см';
      if (tileHeight <= 0 || tileHeight > 200) return 'Высота плитки должна быть от 1 до 200 см';
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
      // Режим "По размерам": вычисляем площадь
      final length = getInput(inputs, 'length', minValue: 0.1);
      final width = getInput(inputs, 'width', minValue: 0.1);
      area = length * width;
    } else {
      // Режим "По площади": берём готовую площадь
      area = getInput(inputs, 'area', minValue: 0.1);
    }

    // --- Размер плитки ---
    final tileSize = getInput(inputs, 'tileSize', defaultValue: 60);
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
      // Квадратная плитка (20×20, 30×30, 40×40, 60×60, 80×80)
      tileWidth = tileSize;
      tileHeight = tileSize;
    }

    final jointWidth = getInput(inputs, 'jointWidth', defaultValue: 3.0, minValue: 1.0, maxValue: 10.0);
    final reserve = getInput(inputs, 'reserve', defaultValue: 10.0, minValue: 5.0, maxValue: 20.0);

    // Площадь одной плитки в м²
    final tileArea = calculateTileArea(tileWidth, tileHeight);
    if (tileArea == 0) {
      return createResult(values: {'error': 1.0});
    }

    // Количество плиток с запасом (reserve% по выбору пользователя)
    final tilesNeeded = calculateUnitsNeeded(area, tileArea, marginPercent: reserve);

    // Затирка: расход ~1.5 кг/м² × коэффициент шва
    // Формула: площадь × расход × (ширина_шва_мм / 10)
    const groutConsumption = 1.5; // кг/м² на 1 мм шва
    final groutNeeded = area * groutConsumption * (jointWidth / 10);

    // Клей: расход зависит от размера плитки
    // Мелкая плитка (< 20×20): 3-4 кг/м²
    // Средняя (20-40): 4-5 кг/м²
    // Крупная (> 40): 5-6 кг/м²
    final avgSize = (tileWidth + tileHeight) / 2;
    final glueConsumption = avgSize < 20 ? 3.5 : (avgSize < 40 ? 4.0 : 5.5);
    final glueNeeded = area * glueConsumption;

    // Крестики: ~4 шт на плитку (по углам)
    final crossesNeeded = tilesNeeded * 4;

    // Грунтовка: расход ~0.15 л/м² (рекомендуется перед укладкой)
    final primerNeeded = area * 0.15;

    // Расчёт стоимости
    final tilePrice = findPrice(priceList, ['tile', 'tile_ceramic', 'tile_porcelain']);
    final groutPrice = findPrice(priceList, ['grout', 'grout_tile']);
    final gluePrice = findPrice(priceList, ['glue_tile', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(tilesNeeded.toDouble(), tilePrice?.price),
      calculateCost(groutNeeded, groutPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'tilesNeeded': tilesNeeded.toDouble(),
        'groutNeeded': groutNeeded,
        'glueNeeded': glueNeeded,
        'crossesNeeded': crossesNeeded.toDouble(),
        'primerNeeded': primerNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}

