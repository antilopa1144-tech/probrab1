import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор МДФ панелей.
///
/// Рассчитывает материалы для отделки МДФ панелями.
///
/// Поля:
/// - area: площадь (м²) - используется если inputMode=0 (manual)
/// - wallWidth: ширина стены (м) - используется если inputMode=1 (wall)
/// - wallHeight: высота стены (м) - используется если inputMode=1 (wall)
/// - panelWidth: ширина панели (м)
/// - panelType: тип панели (0 - стандартные, 1 - ламинированные, 2 - шпон)
/// - inputMode: режим ввода (0 - вручную, 1 - по размерам стены)
/// - needProfile: нужна ли обрешётка (0/1)
/// - needPlinth: нужен ли плинтус (0/1)
class CalculateMdfPanelsV2 extends BaseCalculator {
  /// Запас на панели (%)
  static const double panelWastePercent = 10.0;

  /// Запас на профиль (%)
  static const double profileWastePercent = 10.0;

  /// Шаг обрешётки (м)
  static const double profileStep = 0.5;

  /// Стандартная длина панели (м)
  static const double standardPanelLength = 2.7;

  /// Количество кляймеров на панель
  static const int clipsPerPanel = 5;

  /// Длина плинтуса (м)
  static const double plinthLength = 2.7;

  /// Дополнительная длина для плинтуса (примерный расчёт периметра)
  static const double plinthExtraLength = 2.0;

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
      // Wall mode
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
    final panelType = getIntInput(inputs, 'panelType', defaultValue: 1, minValue: 0, maxValue: 2);
    final panelWidth = getInput(inputs, 'panelWidth', defaultValue: 0.25, minValue: 0.1, maxValue: 0.4);
    final needProfile = getIntInput(inputs, 'needProfile', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needPlinth = getIntInput(inputs, 'needPlinth', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Площадь и размеры
    double area;
    double wallWidth;
    double wallHeight;

    if (inputMode == 1) {
      // Wall mode
      wallWidth = getInput(inputs, 'wallWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30.0);
      wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 0.5, maxValue: 10.0);
      area = wallWidth * wallHeight;
    } else {
      // Manual mode - вычисляем размеры для расчёта профиля
      area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 500.0);
      final side = math.sqrt(area);
      wallWidth = side * 1.5;
      wallHeight = side / 1.5;
    }

    // Площадь одной панели
    final panelArea = panelWidth * standardPanelLength;

    // Количество панелей с запасом
    final panelsCount = (area * (1 + panelWastePercent / 100) / panelArea).ceil();

    // Кляймеры: 5 шт на панель
    final clipsCount = panelsCount * clipsPerPanel;

    // Профиль для обрешётки (через каждые 0.5м)
    double profileTotalLength = 0;
    if (needProfile) {
      final horizontalProfiles = (wallHeight / profileStep).ceil() + 1;
      profileTotalLength = horizontalProfiles * wallWidth * (1 + profileWastePercent / 100);
    }

    // Плинтус
    double plinthTotalLength = 0;
    int plinthPieces = 0;
    if (needPlinth) {
      plinthTotalLength = wallWidth * 2 + plinthExtraLength;
      plinthPieces = (plinthTotalLength / plinthLength).ceil();
    }

    // Расчёт стоимости
    final panelPrice = findPrice(priceList, ['mdf_panel', 'мдф_панель', 'panel']);
    final clipsPrice = findPrice(priceList, ['clips', 'кляймер', 'mdf_clips']);
    final profilePrice = findPrice(priceList, ['profile', 'профиль', 'mdf_profile']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус', 'mdf_plinth']);

    final costs = [
      calculateCost(panelsCount.toDouble(), panelPrice?.price),
      calculateCost(clipsCount.toDouble(), clipsPrice?.price),
      if (needProfile) calculateCost(profileTotalLength, profilePrice?.price),
      if (needPlinth) calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'wallWidth': wallWidth,
        'wallHeight': wallHeight,
        'panelType': panelType.toDouble(),
        'panelWidth': panelWidth,
        'panelArea': panelArea,
        'inputMode': inputMode.toDouble(),
        'needProfile': needProfile ? 1.0 : 0.0,
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'panelsCount': panelsCount.toDouble(),
        'clipsCount': clipsCount.toDouble(),
        'profileLength': profileTotalLength,
        'plinthLength': plinthTotalLength,
        'plinthPieces': plinthPieces.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
