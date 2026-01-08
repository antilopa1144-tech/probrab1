import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор кассетного потолка.
///
/// Рассчитывает материалы для монтажа кассетного потолка.
///
/// Поля:
/// - area: площадь потолка (м²) - используется если inputMode=0 (manual)
/// - roomWidth: ширина комнаты (м) - используется если inputMode=1 (room)
/// - roomLength: длина комнаты (м) - используется если inputMode=1 (room)
/// - ceilingType: тип кассет (0 - металл, 1 - зеркало, 2 - перфорированные)
/// - cassetteSize: размер кассеты (0 - 600x600, 1 - 600x1200, 2 - 300x300)
/// - inputMode: режим ввода (0 - вручную, 1 - по размерам комнаты)
class CalculateCassetteCeilingV2 extends BaseCalculator {
  /// Запас на кассеты (%)
  static const double cassetteWastePercent = 5.0;

  /// Запас на пристенный профиль (%)
  static const double wallProfileWastePercent = 10.0;

  /// Шаг главного профиля (м)
  static const double mainProfileStep = 1.2;

  /// Длина главного профиля (м)
  static const double mainProfileLength = 3.7;

  /// Площадь на один подвес (м²)
  static const double areaPerHanger = 1.2;

  /// Площади кассет (м²): 600x600, 600x1200, 300x300
  static const List<double> cassetteAreas = [0.36, 0.72, 0.09];

  /// Шаг поперечного профиля для 600x600 (м)
  static const double crossProfileStep600 = 0.6;

  /// Шаг поперечного профиля для других размеров (м)
  static const double crossProfileStepOther = 1.2;

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
    final ceilingType = getIntInput(inputs, 'ceilingType', defaultValue: 0, minValue: 0, maxValue: 2);
    final cassetteSize = getIntInput(inputs, 'cassetteSize', defaultValue: 0, minValue: 0, maxValue: 2);

    // Площадь и размеры
    double area;
    double roomWidth;
    double roomLength;

    if (inputMode == 1) {
      // Room mode
      roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30.0);
      roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 30.0);
      area = roomWidth * roomLength;
    } else {
      // Manual mode - вычисляем "квадратные" размеры для расчёта профилей
      area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 500.0);
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    }

    // Периметр
    final perimeter = 2 * (roomWidth + roomLength);

    // Площадь одной кассеты
    final cassetteArea = cassetteAreas[cassetteSize];

    // Количество кассет с запасом
    final cassettesCount = (area * (1 + cassetteWastePercent / 100) / cassetteArea).ceil();

    // Основной профиль (3.7 м на каждые 1.2 м по длине, и по ширине)
    final mainProfileRows = (roomLength / mainProfileStep).ceil();
    final mainProfilesPerRow = (roomWidth / mainProfileLength).ceil();
    final mainProfileTotalLength = mainProfileRows * mainProfileLength * mainProfilesPerRow;

    // Поперечный профиль (зависит от размера кассеты)
    double crossProfileLength;
    if (cassetteSize == 0) {
      // 600x600 - шаг 0.6 м
      crossProfileLength = (roomWidth / crossProfileStep600).ceil() * roomLength;
    } else {
      // 600x1200 или 300x300 - шаг 1.2 м
      crossProfileLength = (roomWidth / crossProfileStepOther).ceil() * roomLength;
    }

    // Пристенный профиль = периметр + 10%
    final wallProfileLength = perimeter * (1 + wallProfileWastePercent / 100);

    // Подвесы: 1 шт на каждые 1.2 м²
    final hangersCount = (area / areaPerHanger).ceil();

    // Расчёт стоимости
    final cassettePrice = findPrice(priceList, ['cassette', 'кассета', 'ceiling_cassette']);
    final mainProfilePrice = findPrice(priceList, ['main_profile', 'основной_профиль', 'cassette_main']);
    final crossProfilePrice = findPrice(priceList, ['cross_profile', 'поперечный_профиль', 'cassette_cross']);
    final wallProfilePrice = findPrice(priceList, ['wall_profile', 'пристенный_профиль', 'cassette_wall']);
    final hangerPrice = findPrice(priceList, ['hanger', 'подвес', 'cassette_hanger']);

    final costs = [
      calculateCost(cassettesCount.toDouble(), cassettePrice?.price),
      calculateCost(mainProfileTotalLength, mainProfilePrice?.price),
      calculateCost(crossProfileLength, crossProfilePrice?.price),
      calculateCost(wallProfileLength, wallProfilePrice?.price),
      calculateCost(hangersCount.toDouble(), hangerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'perimeter': perimeter,
        'ceilingType': ceilingType.toDouble(),
        'cassetteSize': cassetteSize.toDouble(),
        'cassetteArea': cassetteArea,
        'inputMode': inputMode.toDouble(),
        'cassettesCount': cassettesCount.toDouble(),
        'mainProfileLength': mainProfileTotalLength,
        'crossProfileLength': crossProfileLength,
        'wallProfileLength': wallProfileLength,
        'hangersCount': hangersCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
