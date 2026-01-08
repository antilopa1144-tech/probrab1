import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор фундаментной плиты
///
/// Типы плиты:
/// - 0: Монолитная (стандартная)
/// - 1: Ребристая (+15% бетона на рёбра)
/// - 2: Плавающая (стандартная)
class CalculateSlabV2 extends BaseCalculator {
  // Константы расчёта
  static const double concreteWastePercent = 2.0;
  static const double ribbedMultiplier = 1.15;
  static const double reinforcementPerCubicMeter = 90.0; // кг/м³
  static const double sandLayerThickness = 0.2; // м
  static const double gravelLayerThickness = 0.15; // м
  static const double materialWastePercent = 10.0;
  static const double waterproofWastePercent = 15.0;
  static const double insulationWastePercent = 5.0;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final slabType = getIntInput(inputs, 'slabType', defaultValue: 0, minValue: 0, maxValue: 2);
    final needWaterproof = getInput(inputs, 'needWaterproof', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needInsulation = getInput(inputs, 'needInsulation', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Размеры плиты
    final length = getInput(inputs, 'length', defaultValue: 10.0, minValue: 3, maxValue: 50);
    final width = getInput(inputs, 'width', defaultValue: 8.0, minValue: 3, maxValue: 30);
    final thickness = getInput(inputs, 'thickness', defaultValue: 0.3, minValue: 0.2, maxValue: 0.5);

    // Валидация
    final rawLength = inputs['length'] ?? 10.0;
    final rawWidth = inputs['width'] ?? 8.0;
    if (rawLength <= 0) {
      throw CalculationException.invalidInput(
        'CalculateSlabV2',
        'Длина плиты должна быть положительной',
      );
    }
    if (rawWidth <= 0) {
      throw CalculationException.invalidInput(
        'CalculateSlabV2',
        'Ширина плиты должна быть положительной',
      );
    }

    // Площадь плиты
    final slabArea = length * width;

    // Объём бетона
    var concreteVolume = slabArea * thickness;
    if (slabType == 1) {
      // Ребристая плита - добавляем объём на рёбра
      concreteVolume *= ribbedMultiplier;
    }
    concreteVolume *= (1 + concreteWastePercent / 100);

    // Арматура
    final reinforcementWeight = concreteVolume * reinforcementPerCubicMeter;

    // Песчаная подушка
    final sandVolume = slabArea * sandLayerThickness * (1 + materialWastePercent / 100);

    // Щебень
    final gravelVolume = slabArea * gravelLayerThickness * (1 + materialWastePercent / 100);

    // Гидроизоляция
    final waterproofArea = needWaterproof
        ? slabArea * (1 + waterproofWastePercent / 100)
        : 0.0;

    // Утеплитель
    final insulationArea = needInsulation
        ? slabArea * (1 + insulationWastePercent / 100)
        : 0.0;

    // Формируем результат
    final values = <String, double>{
      'length': length,
      'width': width,
      'thickness': thickness,
      'slabType': slabType.toDouble(),
      'slabArea': slabArea,
      'concreteVolume': concreteVolume,
      'reinforcementWeight': reinforcementWeight,
      'sandVolume': sandVolume,
      'gravelVolume': gravelVolume,
      'waterproofArea': waterproofArea,
      'insulationArea': insulationArea,
      'needWaterproof': needWaterproof ? 1.0 : 0.0,
      'needInsulation': needInsulation ? 1.0 : 0.0,
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

      // Арматура
      final reinforcementPrice = priceList
          .where((p) => p.sku == 'reinforcement')
          .firstOrNull
          ?.price;
      if (reinforcementPrice != null) {
        price += reinforcementWeight * reinforcementPrice;
      }

      // Песок
      final sandPrice = priceList
          .where((p) => p.sku == 'sand')
          .firstOrNull
          ?.price;
      if (sandPrice != null) {
        price += sandVolume * sandPrice;
      }

      // Щебень
      final gravelPrice = priceList
          .where((p) => p.sku == 'gravel')
          .firstOrNull
          ?.price;
      if (gravelPrice != null) {
        price += gravelVolume * gravelPrice;
      }

      // Гидроизоляция
      if (needWaterproof) {
        final waterproofPrice = priceList
            .where((p) => p.sku == 'waterproof')
            .firstOrNull
            ?.price;
        if (waterproofPrice != null) {
          price += waterproofArea * waterproofPrice;
        }
      }

      // Утеплитель
      if (needInsulation) {
        final insulationPrice = priceList
            .where((p) => p.sku == 'insulation')
            .firstOrNull
            ?.price;
        if (insulationPrice != null) {
          price += insulationArea * insulationPrice;
        }
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
