import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор подвала
///
/// Типы подвала:
/// - 0: Технический (technical)
/// - 1: Жилой (living)
/// - 2: Гараж (garage)
class CalculateBasementV2 extends BaseCalculator {
  // Константы расчёта
  static const double floorThickness = 0.15; // 15 см
  static const double concreteWastePercent = 5.0;
  static const double waterproofOverlapPercent = 15.0;
  static const double insulationWastePercent = 10.0;
  static const double drainageWastePercent = 10.0;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final length = getInput(inputs, 'length', defaultValue: 10.0, minValue: 3, maxValue: 30);
    final width = getInput(inputs, 'width', defaultValue: 8.0, minValue: 3, maxValue: 20);
    final depth = getInput(inputs, 'depth', defaultValue: 2.5, minValue: 1.5, maxValue: 4);
    final wallThickness = getInput(inputs, 'wallThickness', defaultValue: 0.3, minValue: 0.15, maxValue: 0.6);
    final basementType = getIntInput(inputs, 'basementType', defaultValue: 0, minValue: 0, maxValue: 2);
    final needWaterproof = getInput(inputs, 'needWaterproof', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needInsulation = getInput(inputs, 'needInsulation', defaultValue: 0.0, minValue: 0, maxValue: 1) == 1.0;
    final needDrainage = getInput(inputs, 'needDrainage', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Валидация
    final rawLength = inputs['length'] ?? 10.0;
    if (rawLength <= 0) {
      throw CalculationException.invalidInput(
        'CalculateBasementV2',
        'Длина должна быть положительной',
      );
    }

    final rawWidth = inputs['width'] ?? 8.0;
    if (rawWidth <= 0) {
      throw CalculationException.invalidInput(
        'CalculateBasementV2',
        'Ширина должна быть положительной',
      );
    }

    final rawDepth = inputs['depth'] ?? 2.5;
    if (rawDepth <= 0) {
      throw CalculationException.invalidInput(
        'CalculateBasementV2',
        'Глубина должна быть положительной',
      );
    }

    // Расчёт площадей
    final floorArea = length * width;
    final perimeter = 2 * (length + width);
    final wallArea = perimeter * depth;

    // Бетон: пол + стены
    final floorVolume = floorArea * floorThickness;
    final wallVolume = wallArea * wallThickness;
    const concreteWasteFactor = 1 + concreteWastePercent / 100;
    final concreteVolume = (floorVolume + wallVolume) * concreteWasteFactor;

    // Гидроизоляция: пол + стены снаружи
    const waterproofOverlapFactor = 1 + waterproofOverlapPercent / 100;
    final waterproofArea = needWaterproof
        ? (floorArea + wallArea) * waterproofOverlapFactor
        : 0.0;

    // Утеплитель
    const insulationWasteFactor = 1 + insulationWastePercent / 100;
    final insulationArea = needInsulation
        ? (floorArea + wallArea) * insulationWasteFactor
        : 0.0;

    // Дренаж по периметру
    const drainageWasteFactor = 1 + drainageWastePercent / 100;
    final drainageLength = needDrainage
        ? perimeter * drainageWasteFactor
        : 0.0;

    // Формируем результат
    final values = <String, double>{
      'length': length,
      'width': width,
      'depth': depth,
      'wallThickness': wallThickness,
      'basementType': basementType.toDouble(),
      'floorArea': floorArea,
      'wallArea': wallArea,
      'perimeter': perimeter,
      'concreteVolume': concreteVolume,
      'waterproofArea': waterproofArea,
      'insulationArea': insulationArea,
      'drainageLength': drainageLength,
      'needWaterproof': needWaterproof ? 1.0 : 0.0,
      'needInsulation': needInsulation ? 1.0 : 0.0,
      'needDrainage': needDrainage ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

      // Бетон
      final concretePrice = priceList
          .where((p) => p.sku == 'concrete')
          .firstOrNull
          ?.price;
      if (concretePrice != null) {
        price += concreteVolume * concretePrice;
      }

      // Гидроизоляция
      if (waterproofArea > 0) {
        final waterproofPrice = priceList
            .where((p) => p.sku == 'waterproof')
            .firstOrNull
            ?.price;
        if (waterproofPrice != null) {
          price += waterproofArea * waterproofPrice;
        }
      }

      // Утеплитель
      if (insulationArea > 0) {
        final insulationPrice = priceList
            .where((p) => p.sku == 'insulation')
            .firstOrNull
            ?.price;
        if (insulationPrice != null) {
          price += insulationArea * insulationPrice;
        }
      }

      // Дренаж
      if (drainageLength > 0) {
        final drainagePrice = priceList
            .where((p) => p.sku == 'drainage')
            .firstOrNull
            ?.price;
        if (drainagePrice != null) {
          price += drainageLength * drainagePrice;
        }
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
