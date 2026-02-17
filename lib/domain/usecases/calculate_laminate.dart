// ignore_for_file: prefer_const_declarations
import 'dart:math';

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ламината.
///
/// Нормативы:
/// - ГОСТ 32304-2013 "Ламинат напольный"
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - packArea: площадь в упаковке (м²), по умолчанию 2.0
/// - underlayThickness: толщина подложки (мм), по умолчанию 3
/// - layoutPattern: способ укладки (1=со смещением 1/4, 2=хаотичная, 3=палубная, 4=диагональная)
///
/// Особенности расчёта:
/// - Процент отходов зависит от способа укладки (layoutPattern)
/// - Для маленьких комнат (<15 м²) добавляется доп. запас +0.5% за каждый м² ниже 15
/// - Плинтус разделён на прямые отрезки, внутренние углы и соединители
/// - Если пользователь явно задал reserve выше расчётного — используется reserve (безопасная оценка)
class CalculateLaminate extends BaseCalculator {
  /// Стандартная длина плинтуса (м)
  static const double _plinthPieceLength = 2.5;

  /// Стандартная ширина дверного проёма (м)
  static const double _doorOpeningWidth = 0.9;

  /// Количество внутренних углов для прямоугольной комнаты
  static const int _rectangleInnerCorners = 4;

  /// Порог площади для масштабирования запаса (м²)
  static const double _smallRoomThreshold = 15.0;

  /// Доп. запас за каждый м² ниже порога (%)
  static const double _smallRoomWastePerSqm = 0.5;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = (inputs['inputMode'] ?? 1).toInt();
    final packArea = inputs['packArea'] ?? 2.0;

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

    if (packArea <= 0 || packArea > 10) return 'Площадь упаковки должна быть от 0.1 до 10 м²';

    return null;
  }

  /// Определяет базовый процент отходов по способу укладки.
  ///
  /// - 1: со смещением 1/4 — 7% (минимум отходов, регулярный паттерн)
  /// - 2: хаотичная — 10% (default, среднее значение)
  /// - 3: палубная — 12% (сдвиг на 1/3, чуть больше подрезки)
  /// - 4: диагональная — 15% (максимум отходов, косой рез)
  double _baseWasteForPattern(int layoutPattern) {
    switch (layoutPattern) {
      case 1:
        return 7.0; // со смещением 1/4
      case 2:
        return 10.0; // хаотичная (default)
      case 3:
        return 12.0; // палубная
      case 4:
        return 15.0; // диагональная
      default:
        return 10.0;
    }
  }

  /// Масштабирование запаса по площади: маленькие комнаты (<15 м²) нуждаются
  /// в дополнительном запасе, т.к. процент подрезки выше из-за геометрии.
  ///
  /// Формула: +0.5% за каждый м² ниже 15.
  /// Пример: 5 м² → (15 - 5) * 0.5 = +5%
  double _areaWasteAdjustment(double area) {
    if (area >= _smallRoomThreshold) return 0.0;
    return (_smallRoomThreshold - area) * _smallRoomWastePerSqm;
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
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам": вычисляем площадь и периметр
      final length = getInput(inputs, 'length', minValue: 0.1);
      final width = getInput(inputs, 'width', minValue: 0.1);
      area = length * width;
      perimeter = (length + width) * 2;
    } else {
      // Режим "По площади": берём готовую площадь
      area = getInput(inputs, 'area', minValue: 0.1);
      // Периметр: если указан - используем, иначе оцениваем
      perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
          ? getInput(inputs, 'perimeter', minValue: 0.1)
          : estimatePerimeter(area);
    }

    // Получаем остальные параметры
    final packArea = getInput(inputs, 'packArea', defaultValue: 2.0, minValue: 0.5, maxValue: 3.0);
    final reserve = getInput(inputs, 'reserve', defaultValue: 10.0, minValue: 5.0, maxValue: 20.0);
    final underlayType = getIntInput(inputs, 'underlayType', defaultValue: 3, minValue: 2, maxValue: 5);
    final laminateClass = getIntInput(inputs, 'laminateClass', defaultValue: 32, minValue: 31, maxValue: 34);
    final laminateThickness = getIntInput(inputs, 'laminateThickness', defaultValue: 8, minValue: 6, maxValue: 14);

    // --- Способ укладки и расчёт отходов ---
    final layoutPattern = getIntInput(inputs, 'layoutPattern', defaultValue: 2);
    final baseWaste = _baseWasteForPattern(layoutPattern);
    final areaAdjustment = _areaWasteAdjustment(area);
    final patternWaste = baseWaste + areaAdjustment;

    // Используем max(patternWaste, reserve) — если пользователь явно задал reserve выше,
    // берём его (безопаснее). При дефолтном reserve=10 и layoutPattern=2 (10%) получаем 10%,
    // что обеспечивает обратную совместимость.
    final totalWaste = max(patternWaste, reserve);

    // Количество упаковок ламината с запасом
    final packsNeeded = calculateUnitsNeeded(area, packArea, marginPercent: totalWaste);

    // Подложка: площадь = площадь пола + 5% на подрезку и нахлёсты
    final underlayArea = addMargin(area, 5.0);

    // --- Плинтус: прямые отрезки + углы + соединители ---
    final doorThresholds = getIntInput(inputs, 'doorThresholds', defaultValue: 1, minValue: 0, maxValue: 10);
    final plinthLengthRaw = perimeter - (doorThresholds * _doorOpeningWidth);
    final plinthPieces = ceilToInt(plinthLengthRaw / _plinthPieceLength);
    // Общая длина плинтуса (из целых отрезков)
    final plinthLength = plinthPieces * _plinthPieceLength;
    // Внутренние углы: 4 для прямоугольной комнаты
    final innerCorners = _rectangleInnerCorners;
    // Соединители: между отрезками на одной стене. Для простоты — (plinthPieces - 4),
    // т.к. минимум 4 стены, на каждой по 1 стартовому отрезку без соединителя.
    // Но если отрезков меньше 4, соединители не нужны.
    final plinthConnectors = max(0, plinthPieces - 4);

    // Компенсационные клинья: ~8-10 шт на комнату (по периметру через каждые 50 см)
    final wedgesNeeded = ceilToInt(perimeter / 0.5);

    // Пароизоляционная плёнка (если нужна): площадь + 10% на нахлёсты
    final vaporBarrierArea = addMargin(area, 10.0);

    // Расчёт стоимости
    final laminatePrice = findPrice(priceList, ['laminate', 'laminate_pack']);
    final underlayPrice = findPrice(priceList, ['underlay', 'underlay_${underlayType}mm', 'underlay']);
    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_laminate']);
    final vaporBarrierPrice = findPrice(priceList, ['vapor_barrier', 'film_pe']);
    final thresholdPrice = findPrice(priceList, ['threshold', 'threshold_laminate']);

    final costs = [
      calculateCost(packsNeeded.toDouble(), laminatePrice?.price),
      calculateCost(underlayArea, underlayPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(doorThresholds.toDouble(), thresholdPrice?.price),
    ];

    return createResult(
      values: {
        // Основные результаты (обратная совместимость)
        'area': area,
        'packsNeeded': packsNeeded.toDouble(),
        'underlayArea': underlayArea,
        'plinthLength': plinthLength,
        'wedgesNeeded': wedgesNeeded.toDouble(),
        'vaporBarrierArea': vaporBarrierArea,
        'doorThresholds': doorThresholds.toDouble(),
        'laminateClass': laminateClass.toDouble(),
        'laminateThickness': laminateThickness.toDouble(),
        // Новые результаты
        'wastePercent': totalWaste,
        'plinthPieces': plinthPieces.toDouble(),
        'innerCorners': innerCorners.toDouble(),
        'plinthConnectors': plinthConnectors.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
