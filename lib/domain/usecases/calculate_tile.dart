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
/// Учитывает способ укладки, сложность помещения, размер плитки.
class CalculateTile extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = (inputs['inputMode'] ?? 1).toInt();

    if (inputMode == 0) {
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length <= 0) return 'Длина должна быть больше нуля';
      if (width <= 0) return 'Ширина должна быть больше нуля';
    } else {
      final area = inputs['area'] ?? 0;
      if (area <= 0) return 'Площадь должна быть больше нуля';
    }

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
    final tileSize = getInput(inputs, 'tileSize', defaultValue: 60);
    double tileWidth;
    double tileHeight;

    if (tileSize == 0) {
      tileWidth = getInput(inputs, 'tileWidth', defaultValue: 60.0, minValue: 1.0, maxValue: 200.0);
      tileHeight = getInput(inputs, 'tileHeight', defaultValue: 60.0, minValue: 1.0, maxValue: 200.0);
    } else if (tileSize == 120) {
      tileWidth = 120.0;
      tileHeight = 60.0;
    } else {
      tileWidth = tileSize;
      tileHeight = tileSize;
    }

    final jointWidth = getInput(inputs, 'jointWidth', defaultValue: 3.0, minValue: 1.0, maxValue: 10.0);

    // --- Способ укладки (NEW) ---
    // 1 = прямая (10%), 2 = диагональная (15%), 3 = со смещением (10%), 4 = ёлочка (20%)
    final layoutPattern = getIntInput(inputs, 'layoutPattern', defaultValue: 1, minValue: 1, maxValue: 4);

    // Базовый % отходов по паттерну
    final double patternWaste = switch (layoutPattern) {
      2 => 15.0, // диагональная
      4 => 20.0, // ёлочка
      _ => 10.0, // прямая или со смещением
    };

    // --- Сложность помещения (NEW) ---
    // 1 = простая прямоугольная, 2 = Г-образная, 3 = много углов/труб
    final roomComplexity = getIntInput(inputs, 'roomComplexity', defaultValue: 1, minValue: 1, maxValue: 3);

    // Дополнительный % отходов за сложность помещения (аддитивный)
    final double complexityBonus = switch (roomComplexity) {
      2 => 5.0,  // Г-образная: +5% дополнительных подрезок
      3 => 10.0, // сложная: +10% углы, трубы, выступы
      _ => 0.0,  // простая прямоугольная
    };

    // --- Поправка на размер плитки ---
    final avgSize = (tileWidth + tileHeight) / 2;
    double sizeAdjustment = 0.0;
    if (avgSize > 60) {
      sizeAdjustment = 5.0; // крупная плитка → +5% доп. запас (дорогие подрезки)
    } else if (avgSize < 10) {
      sizeAdjustment = -3.0; // мозаика → -3% (обрезки переиспользуются)
    }

    // Итоговый % отходов (все компоненты аддитивные)
    // Пример: диагональ 15% + Г-образная 5% + крупная плитка 5% = 25%
    final totalWaste = patternWaste + complexityBonus + sizeAdjustment;

    // Площадь одной плитки в м²
    final tileArea = calculateTileArea(tileWidth, tileHeight);
    if (tileArea == 0) {
      return createResult(values: {'error': 1.0});
    }

    // Количество плиток с запасом
    final tilesNeeded = calculateUnitsNeeded(area, tileArea, marginPercent: totalWaste);

    // Затирка: формула через длину швов
    final tileWm = tileWidth / 100;
    final tileHm = tileHeight / 100;
    final jointsLength = (1 / tileWm) + (1 / tileHm);
    // Глубина затирки зависит от размера плитки (коррелирует с толщиной)
    // Малая <15 см: ~4 мм, стандартная 15-40 см: ~6 мм,
    // крупная 40-60 см: ~8 мм, крупноформат >60 см: ~10 мм
    final double groutDepthMm;
    if (avgSize < 15) {
      groutDepthMm = 4.0;
    } else if (avgSize < 40) {
      groutDepthMm = 6.0;
    } else if (avgSize <= 60) {
      groutDepthMm = 8.0;
    } else {
      groutDepthMm = 10.0;
    }
    const groutDensity = 1600.0;
    final groutNeeded = area * jointsLength * (jointWidth / 1000) * (groutDepthMm / 1000) * groutDensity * 1.1;

    // Клей: расход зависит от размера плитки
    final glueConsumption = avgSize < 20 ? 3.5 : (avgSize < 40 ? 4.0 : 5.5);
    final glueNeeded = area * glueConsumption;

    // Крестики: ~1 шт на пересечение (≈ кол-во плиток) + 20% на поломки
    // На каждом пересечении 4 плиток стоит 1 крестик, плюс T-стыки по краям
    final crossesNeeded = (tilesNeeded * 1.2).ceil();

    // Грунтовка: 0.15 л/м²
    final primerNeeded = area * 0.15;

    // Стоимость
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
        'wastePercent': totalWaste,
        // Флаги для условных подсказок
        if (avgSize > 60) 'warningLargeTile': 1.0,
        if (layoutPattern == 4 && area > 30) 'warningHerringboneLargeArea': 1.0,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
