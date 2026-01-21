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

  /// Норма расхода главного профиля (м.п./м²) — согласно СНиП
  static const double mainProfilePerM2 = 2.0;

  /// Норма расхода поперечного профиля (м.п./м²) — согласно СНиП
  static const double crossProfilePerM2 = 1.35;

  /// Норма расхода подвесов (шт/м²) — согласно СНиП
  static const double hangersPerM2 = 2.5;

  /// Площади кассет (м²): 600x600, 600x1200, 300x300
  static const List<double> cassetteAreas = [0.36, 0.72, 0.09];

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

    // Главный профиль: 2.0 м.п. на м² (согласно СНиП)
    final mainProfileTotalLength = area * mainProfilePerM2;

    // Поперечный профиль: 1.35 м.п. на м² (согласно СНиП)
    final crossProfileLength = area * crossProfilePerM2;

    // Пристенный профиль = периметр + 10%
    final wallProfileLength = perimeter * (1 + wallProfileWastePercent / 100);

    // Подвесы: 2.5 шт на м² (согласно СНиП)
    final hangersCount = (area * hangersPerM2).ceil();

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
