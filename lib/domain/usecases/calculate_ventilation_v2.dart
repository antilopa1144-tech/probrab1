import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор вентиляции.
///
/// Рассчитывает воздуховоды, решётки, фитинги для системы вентиляции.
///
/// Поля:
/// - roomArea: площадь помещений (м²)
/// - ceilingHeight: высота потолков (м)
/// - roomsCount: количество комнат
/// - ventilationType: тип вентиляции (0 - естественная, 1 - приточная, 2 - вытяжная)
/// - needRecovery: нужен ли рекуператор (0/1)
class CalculateVentilationV2 extends BaseCalculator {
  /// Кратность воздухообмена по типу вентиляции
  static const Map<int, double> exchangeRates = {
    0: 1.0,  // естественная
    1: 2.0,  // приточная
    2: 1.5,  // вытяжная
  };

  /// Длина воздуховода на комнату (м)
  static const double ductPerRoom = 3.0;

  /// Коэффициент магистрали от площади
  static const double mainDuctCoef = 0.1;

  /// Запас на воздуховоды (%)
  static const double ductWastePercent = 15.0;

  /// Решётки на комнату (приток + вытяжка)
  static const int grillsPerRoom = 2;

  /// Фитинги на комнату
  static const int fittingsPerRoom = 3;

  /// Базовые фитинги (магистраль)
  static const int baseFittings = 4;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final roomArea = inputs['roomArea'] ?? 0;
    if (roomArea <= 0) {
      return 'Площадь помещений должна быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final roomArea = getInput(inputs, 'roomArea', defaultValue: 50.0, minValue: 10.0, maxValue: 500.0);
    final ceilingHeight = getInput(inputs, 'ceilingHeight', defaultValue: 2.7, minValue: 2.2, maxValue: 5.0);
    final roomsCount = getIntInput(inputs, 'roomsCount', defaultValue: 4, minValue: 1, maxValue: 20);
    final ventilationType = getIntInput(inputs, 'ventilationType', defaultValue: 1, minValue: 0, maxValue: 2);
    final needRecovery = getIntInput(inputs, 'needRecovery', defaultValue: 0, minValue: 0, maxValue: 1) == 1;

    // Объём помещений
    final roomVolume = roomArea * ceilingHeight;

    // Кратность воздухообмена
    final exchangeRate = exchangeRates[ventilationType] ?? 1.0;

    // Требуемый воздухообмен (м³/ч)
    final airflowRequired = roomVolume * exchangeRate;

    // Воздуховоды: на комнаты + магистраль с запасом
    final ductLength = roomsCount * ductPerRoom + (roomArea * mainDuctCoef) * (1 + ductWastePercent / 100);

    // Решётки: по 2 на комнату
    final grillsCount = roomsCount * grillsPerRoom;

    // Фитинги: на комнаты + базовые
    final fittingsCount = roomsCount * fittingsPerRoom + baseFittings;

    // Рекуператор
    final recuperatorCount = needRecovery ? 1 : 0;

    // Расчёт стоимости
    final ductPrice = findPrice(priceList, ['duct', 'воздуховод', 'ventilation_duct']);
    final grillPrice = findPrice(priceList, ['grill', 'решётка', 'ventilation_grill']);
    final fittingPrice = findPrice(priceList, ['fitting', 'фитинг', 'ventilation_fitting']);
    final recuperatorPrice = needRecovery ? findPrice(priceList, ['recuperator', 'рекуператор']) : null;

    final costs = [
      calculateCost(ductLength, ductPrice?.price),
      calculateCost(grillsCount.toDouble(), grillPrice?.price),
      calculateCost(fittingsCount.toDouble(), fittingPrice?.price),
      if (needRecovery) calculateCost(1.0, recuperatorPrice?.price),
    ];

    return createResult(
      values: {
        'roomArea': roomArea,
        'ceilingHeight': ceilingHeight,
        'roomsCount': roomsCount.toDouble(),
        'ventilationType': ventilationType.toDouble(),
        'needRecovery': needRecovery ? 1.0 : 0.0,
        'roomVolume': roomVolume,
        'exchangeRate': exchangeRate,
        'airflowRequired': airflowRequired,
        'ductLength': ductLength,
        'grillsCount': grillsCount.toDouble(),
        'fittingsCount': fittingsCount.toDouble(),
        'recuperatorCount': recuperatorCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
