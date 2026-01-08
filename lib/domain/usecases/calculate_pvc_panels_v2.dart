import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ПВХ панелей.
///
/// Рассчитывает материалы для отделки ПВХ панелями.
///
/// Поля:
/// - area: площадь (м²) - используется если inputMode=0 (manual)
/// - wallWidth: ширина стены (м) - используется если inputMode=1 (dimensions)
/// - wallHeight: высота стены (м) - используется если inputMode=1 (dimensions)
/// - panelWidth: ширина панели (м)
/// - panelType: тип панели (0 - стеновые, 1 - потолочные, 2 - ванная)
/// - inputMode: режим ввода (0 - вручную, 1 - по размерам)
/// - needProfile: нужна ли обрешётка (0/1)
/// - needCorners: нужны ли угловые профили (0/1)
class CalculatePvcPanelsV2 extends BaseCalculator {
  /// Запас на панели (%)
  static const double panelWastePercent = 10.0;

  /// Запас на профиль (%)
  static const double profileWastePercent = 10.0;

  /// Шаг обрешётки (м)
  static const double profileStep = 0.4;

  /// Длина углового профиля (м)
  static const double cornerProfileLength = 3.0;

  /// Длина плинтуса (м)
  static const double plinthLength = 3.0;

  /// Количество углов
  static const int standardCornersCount = 4;

  /// Длины панелей по типам (м): wall, ceiling, bathroom
  static const List<double> panelLengths = [2.7, 3.0, 2.7];

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    // Default inputMode is 0 (manual mode), same as in calculate()
    final inputMode = inputs['inputMode']?.toInt() ?? 0;

    if (inputMode == 0) {
      // Manual mode
      final area = inputs['area'] ?? 0;
      if (area <= 0) {
        return 'Площадь должна быть больше нуля';
      }
    } else {
      // Dimensions mode
      final width = inputs['wallWidth'] ?? 0;
      final height = inputs['wallHeight'] ?? 0;
      if (width <= 0 || height <= 0) {
        return 'Размеры стены должны быть больше нуля';
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
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0, minValue: 0, maxValue: 1);
    final panelType = getIntInput(inputs, 'panelType', defaultValue: 0, minValue: 0, maxValue: 2);
    final panelWidth = getInput(inputs, 'panelWidth', defaultValue: 0.25, minValue: 0.1, maxValue: 0.5);
    final needProfile = getIntInput(inputs, 'needProfile', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needCorners = getIntInput(inputs, 'needCorners', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Площадь и размеры
    double area;
    double wallWidth;
    double wallHeight;

    if (inputMode == 1) {
      // Dimensions mode
      wallWidth = getInput(inputs, 'wallWidth', defaultValue: 3.0, minValue: 0.5, maxValue: 30.0);
      wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.5, minValue: 0.5, maxValue: 10.0);
      area = wallWidth * wallHeight;
    } else {
      // Manual mode - вычисляем размеры для расчёта профиля
      area = getInput(inputs, 'area', defaultValue: 15.0, minValue: 1.0, maxValue: 500.0);
      final side = math.sqrt(area);
      wallWidth = side * 1.5;
      wallHeight = side / 1.5;
    }

    // Длина панели зависит от типа
    final panelLength = panelLengths[panelType];

    // Площадь одной панели
    final panelArea = panelWidth * panelLength;

    // Количество панелей с запасом
    final panelsCount = (area * (1 + panelWastePercent / 100) / panelArea).ceil();

    // Профиль для обрешётки (через каждые 0.4м)
    double profileLength = 0;
    if (needProfile) {
      final rows = (wallHeight / profileStep).ceil() + 1;
      profileLength = rows * wallWidth * (1 + profileWastePercent / 100);
    }

    // Угловые профили (4 угла по высоте помещения)
    int cornerCount = 0;
    if (needCorners) {
      cornerCount = (wallHeight * standardCornersCount / cornerProfileLength).ceil();
    }

    // Плинтус потолочный (только для потолочных панелей)
    double plinthTotalLength = 0;
    int plinthPieces = 0;
    if (panelType == 1) {
      // ceiling
      plinthTotalLength = 2 * (wallWidth + wallHeight);
      plinthPieces = (plinthTotalLength / plinthLength).ceil();
    }

    // Расчёт стоимости
    final panelPrice = findPrice(priceList, ['pvc_panel', 'пвх_панель', 'panel']);
    final profilePrice = findPrice(priceList, ['profile', 'профиль', 'pvc_profile']);
    final cornerPrice = findPrice(priceList, ['corner', 'угол', 'pvc_corner']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус', 'pvc_plinth']);

    final costs = [
      calculateCost(panelsCount.toDouble(), panelPrice?.price),
      if (needProfile) calculateCost(profileLength, profilePrice?.price),
      if (needCorners) calculateCost(cornerCount.toDouble(), cornerPrice?.price),
      if (plinthPieces > 0) calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'wallWidth': wallWidth,
        'wallHeight': wallHeight,
        'panelType': panelType.toDouble(),
        'panelWidth': panelWidth,
        'panelLength': panelLength,
        'panelArea': panelArea,
        'inputMode': inputMode.toDouble(),
        'needProfile': needProfile ? 1.0 : 0.0,
        'needCorners': needCorners ? 1.0 : 0.0,
        'panelsCount': panelsCount.toDouble(),
        'profileLength': profileLength,
        'cornerCount': cornerCount.toDouble(),
        'plinthLength': plinthTotalLength,
        'plinthPieces': plinthPieces.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
