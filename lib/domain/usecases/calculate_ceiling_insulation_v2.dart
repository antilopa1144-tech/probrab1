import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор утепления потолка.
///
/// Рассчитывает материалы для теплоизоляции потолка.
///
/// Поля:
/// - area: площадь потолка (м²) - используется если inputMode=0 (manual)
/// - roomWidth: ширина комнаты (м) - используется если inputMode=1 (room)
/// - roomLength: длина комнаты (м) - используется если inputMode=1 (room)
/// - thickness: толщина утеплителя (мм)
/// - insulationType: тип утеплителя (0 - минвата, 1 - пенопласт, 2 - ЭППС)
/// - inputMode: режим ввода (0 - вручную, 1 - по размерам комнаты)
/// - needVaporBarrier: нужна ли пароизоляция (0/1)
/// - needMembrane: нужна ли мембрана (0/1)
class CalculateCeilingInsulationV2 extends BaseCalculator {
  /// Запас на утеплитель (%)
  static const double insulationWastePercent = 10.0;

  /// Запас на пароизоляцию и мембрану (%)
  static const double filmWastePercent = 15.0;

  /// Базовая площадь упаковки при толщине 100 мм (м²)
  static const double basePackArea = 6.0;

  /// Базовая толщина для расчёта упаковок (мм)
  static const double baseThickness = 100.0;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode']?.toInt() ?? 0;

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
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0, minValue: 0, maxValue: 1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 100.0, minValue: 20.0, maxValue: 300.0);
    final insulationType = getIntInput(inputs, 'insulationType', defaultValue: 0, minValue: 0, maxValue: 2);
    final needVaporBarrier = getIntInput(inputs, 'needVaporBarrier', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needMembrane = getIntInput(inputs, 'needMembrane', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Площадь
    double area;
    double roomWidth = 0;
    double roomLength = 0;

    if (inputMode == 0) {
      // Manual mode
      area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 1000.0);
    } else {
      // Room mode
      roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 50.0);
      roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 50.0);
      area = roomWidth * roomLength;
    }

    // Утеплитель +10% запас
    final insulationArea = area * (1 + insulationWastePercent / 100);

    // Расчёт упаковок (площадь упаковки обратно пропорциональна толщине)
    // При 100 мм = 6 м², при 200 мм = 3 м², при 50 мм = 12 м²
    final packArea = basePackArea * (baseThickness / thickness);
    final insulationPacks = (insulationArea / packArea).ceil();

    // Пароизоляция +15% (ЭППС не требует пароизоляции по СП 50.13330.2012)
    final isXps = insulationType == 2;
    final vaporBarrierArea = (needVaporBarrier && !isXps) ? area * (1 + filmWastePercent / 100) : 0.0;

    // Мембрана +15%
    final membraneArea = needMembrane ? area * (1 + filmWastePercent / 100) : 0.0;

    // Расчёт стоимости
    final insulationPrice = findPrice(priceList, ['insulation', 'утеплитель', 'минвата', 'ceiling_insulation']);
    final vaporPrice = findPrice(priceList, ['vapor_barrier', 'пароизоляция', 'vapor']);
    final membranePrice = findPrice(priceList, ['membrane', 'мембрана', 'ceiling_membrane']);

    final costs = [
      calculateCost(insulationPacks.toDouble(), insulationPrice?.price),
      if (needVaporBarrier) calculateCost(vaporBarrierArea, vaporPrice?.price),
      if (needMembrane) calculateCost(membraneArea, membranePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'thickness': thickness,
        'insulationType': insulationType.toDouble(),
        'inputMode': inputMode.toDouble(),
        'needVaporBarrier': needVaporBarrier ? 1.0 : 0.0,
        'needMembrane': needMembrane ? 1.0 : 0.0,
        'insulationArea': insulationArea,
        'packArea': packArea,
        'insulationPacks': insulationPacks.toDouble(),
        'vaporBarrierArea': vaporBarrierArea,
        'membraneArea': membraneArea,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
