import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор реечного потолка.
///
/// Рассчитывает материалы для монтажа реечного потолка.
///
/// Поля:
/// - area: площадь потолка (м²) - используется если inputMode=0 (manual)
/// - roomWidth: ширина комнаты (м) - используется если inputMode=1 (room)
/// - roomLength: длина комнаты (м) - используется если inputMode=1 (room)
/// - ceilingType: тип потолка (0 - алюминий, 1 - сталь, 2 - пластик)
/// - railWidth: ширина рейки (0 - 84мм, 1 - 100мм, 2 - 150мм)
/// - inputMode: режим ввода (0 - вручную, 1 - по размерам комнаты)
class CalculateRailCeilingV2 extends BaseCalculator {
  /// Зазор между рейками (м)
  static const double railGap = 0.016;

  /// Запас на рейки (%)
  static const double railWastePercent = 5.0;

  /// Запас на стрингеры (%)
  static const double stringerWastePercent = 10.0;

  /// Запас на пристенный профиль (%)
  static const double wallProfileWastePercent = 10.0;

  /// Шаг стрингеров (м)
  static const double stringerSpacing = 1.2;

  /// Шаг подвесов (м)
  static const double hangerSpacing = 1.2;

  /// Ширины реек (м)
  static const List<double> railWidths = [0.084, 0.100, 0.150];

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    // Default inputMode is 1 (room mode)
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
    final ceilingType = getIntInput(inputs, 'ceilingType', defaultValue: 0, minValue: 0, maxValue: 2);
    final railWidthIndex = getIntInput(inputs, 'railWidth', defaultValue: 1, minValue: 0, maxValue: 2);
    final railWidth = railWidths[railWidthIndex];

    // Площадь и размеры
    double area;
    double roomWidth;
    double roomLength;

    if (inputMode == 1) {
      // Room mode
      roomWidth = getInput(inputs, 'roomWidth', defaultValue: 3.0, minValue: 0.5, maxValue: 30.0);
      roomLength = getInput(inputs, 'roomLength', defaultValue: 4.0, minValue: 0.5, maxValue: 30.0);
      area = roomWidth * roomLength;
    } else {
      // Manual mode - вычисляем "квадратные" размеры
      area = getInput(inputs, 'area', defaultValue: 12.0, minValue: 1.0, maxValue: 500.0);
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    }

    // Периметр
    final perimeter = 2 * (roomWidth + roomLength);

    // Количество реек (ширина комнаты / (ширина рейки + зазор))
    final railStep = railWidth + railGap;
    final railsCount = (roomWidth / railStep).ceil();

    // Длина реек = количество * длина комнаты + 5% запас
    final railLength = railsCount * roomLength * (1 + railWastePercent / 100);

    // Стрингеры (несущие шины): через каждые 1.2 м
    final stringerRows = (roomWidth / stringerSpacing).ceil();
    final stringerLength = stringerRows * roomLength * (1 + stringerWastePercent / 100);

    // Пристенный профиль = периметр + 10%
    final wallProfileLength = perimeter * (1 + wallProfileWastePercent / 100);

    // Подвесы: через каждые 1.2 м по длине стрингера
    final hangersPerRow = (roomLength / hangerSpacing).ceil();
    final hangersCount = stringerRows * hangersPerRow;

    // Расчёт стоимости
    final railPrice = findPrice(priceList, ['rail', 'рейка', 'rail_ceiling_rail']);
    final stringerPrice = findPrice(priceList, ['stringer', 'стрингер', 'rail_stringer']);
    final wallProfilePrice = findPrice(priceList, ['wall_profile', 'пристенный', 'rail_wall_profile']);
    final hangerPrice = findPrice(priceList, ['hanger', 'подвес', 'rail_hanger']);

    final costs = [
      calculateCost(railLength, railPrice?.price),
      calculateCost(stringerLength, stringerPrice?.price),
      calculateCost(wallProfileLength, wallProfilePrice?.price),
      calculateCost(hangersCount.toDouble(), hangerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'ceilingType': ceilingType.toDouble(),
        'railWidth': railWidthIndex.toDouble(),
        'inputMode': inputMode.toDouble(),
        'perimeter': perimeter,
        'railStep': railStep,
        'railsCount': railsCount.toDouble(),
        'railLength': railLength,
        'stringerRows': stringerRows.toDouble(),
        'stringerLength': stringerLength,
        'wallProfileLength': wallProfileLength,
        'hangersCount': hangersCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
