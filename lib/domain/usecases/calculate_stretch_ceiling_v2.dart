import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор натяжного потолка.
///
/// Рассчитывает материалы для монтажа натяжного потолка.
///
/// Поля:
/// - area: площадь потолка (м²) - используется если inputMode=0 (manual)
/// - roomWidth: ширина комнаты (м) - используется если inputMode=1 (room)
/// - roomLength: длина комнаты (м) - используется если inputMode=1 (room)
/// - lightsCount: количество светильников
/// - ceilingType: тип полотна (0 - матовый, 1 - глянцевый, 2 - сатин, 3 - тканевый)
/// - inputMode: режим ввода (0 - вручную, 1 - по размерам комнаты)
class CalculateStretchCeilingV2 extends BaseCalculator {
  /// Запас на профиль (%)
  static const double profileWastePercent = 10.0;

  /// Количество углов (стандартно 4)
  static const int standardCornersCount = 4;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    // Default inputMode is 1 (room mode), same as in calculate()
    final inputMode = inputs['inputMode']?.toInt() ?? 1;

    if (inputMode == 0) {
      // Manual mode
      final area = inputs['area'] ?? 0;
      if (area <= 0) {
        return 'Площадь должна быть больше нуля';
      }
    } else {
      // Room mode
      final width = inputs['roomWidth'] ?? 0;
      final length = inputs['roomLength'] ?? 0;
      if (width <= 0 || length <= 0) {
        return 'Размеры комнаты должны быть больше нуля';
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
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 1, minValue: 0, maxValue: 1);
    final ceilingType = getIntInput(inputs, 'ceilingType', defaultValue: 0, minValue: 0, maxValue: 3);
    final lightsCount = getIntInput(inputs, 'lightsCount', defaultValue: 4, minValue: 0, maxValue: 50);

    // Площадь и размеры
    double area;
    double roomWidth;
    double roomLength;

    if (inputMode == 1) {
      // Room mode
      roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30.0);
      roomLength = getInput(inputs, 'roomLength', defaultValue: 4.0, minValue: 0.5, maxValue: 30.0);
      area = roomWidth * roomLength;
    } else {
      // Manual mode - вычисляем "квадратные" размеры для периметра
      area = getInput(inputs, 'area', defaultValue: 16.0, minValue: 1.0, maxValue: 500.0);
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    }

    // Периметр
    final perimeter = 2 * (roomWidth + roomLength);

    // Профиль с запасом
    final profileLength = perimeter * (1 + profileWastePercent / 100);

    // Расчёт стоимости
    final canvasPrice = findPrice(priceList, ['canvas', 'полотно', 'stretch_canvas']);
    final profilePrice = findPrice(priceList, ['profile', 'профиль', 'stretch_profile']);
    final lightPrice = findPrice(priceList, ['light', 'светильник', 'spotlight']);
    final cornerPrice = findPrice(priceList, ['corner', 'угол', 'stretch_corner']);

    final costs = [
      calculateCost(area, canvasPrice?.price),
      calculateCost(profileLength, profilePrice?.price),
      if (lightsCount > 0) calculateCost(lightsCount.toDouble(), lightPrice?.price),
      calculateCost(standardCornersCount.toDouble(), cornerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'ceilingType': ceilingType.toDouble(),
        'inputMode': inputMode.toDouble(),
        'lightsCount': lightsCount.toDouble(),
        'perimeter': perimeter,
        'profileLength': profileLength,
        'cornersCount': standardCornersCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
