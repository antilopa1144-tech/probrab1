import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор гидроизоляции ванной
///
/// Типы гидроизоляции:
/// - 0: Жидкая (liquid) - 1.5 кг/м² на слой
/// - 1: Рулонная (roll) - 1.0 м²/м²
/// - 2: Цементная (cement) - 3.0 кг/м² на слой
class CalculateBathroomWaterproofV2 extends BaseCalculator {
  // Расход гидроизоляции по типам (кг/м² на слой)
  static const List<double> consumptionPerSqm = [1.5, 1.0, 3.0];

  // Константы расчёта
  static const double areaWastePercent = 10.0;
  static const double primerConsumption = 0.2; // л/м²
  static const double tapeExtraPercent = 30.0; // +30% на углы и стыки

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final length = getInput(inputs, 'length', defaultValue: 2.5, minValue: 1, maxValue: 10);
    final width = getInput(inputs, 'width', defaultValue: 1.8, minValue: 1, maxValue: 10);
    // Высота обработки стен: минимум 1.5 м для мокрых зон по СНиП 3.04.01-87
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 1.5, minValue: 0.2, maxValue: 3.0);
    final waterproofType = getIntInput(inputs, 'waterproofType', defaultValue: 0, minValue: 0, maxValue: 2);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 3);
    final needPrimer = getInput(inputs, 'needPrimer', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needTape = getInput(inputs, 'needTape', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Валидация
    final rawLength = inputs['length'] ?? 2.5;
    if (rawLength <= 0) {
      throw CalculationException.invalidInput(
        'CalculateBathroomWaterproofV2',
        'Длина должна быть положительной',
      );
    }

    final rawWidth = inputs['width'] ?? 1.8;
    if (rawWidth <= 0) {
      throw CalculationException.invalidInput(
        'CalculateBathroomWaterproofV2',
        'Ширина должна быть положительной',
      );
    }

    // Расчёт площадей
    final floorArea = length * width;
    final perimeter = 2 * (length + width);
    final wallArea = perimeter * wallHeight;
    const areaWasteFactor = 1 + areaWastePercent / 100;
    final totalArea = (floorArea + wallArea) * areaWasteFactor;

    // Расход гидроизоляции
    final consumption = consumptionPerSqm[waterproofType];
    final waterproofKg = totalArea * consumption * layers;

    // Грунтовка
    final primerLiters = needPrimer ? totalArea * primerConsumption : 0.0;

    // Лента: периметр + углы + стыки
    const tapeExtraFactor = 1 + tapeExtraPercent / 100;
    final tapeMeters = needTape ? perimeter * tapeExtraFactor : 0.0;

    // Формируем результат
    final values = <String, double>{
      'length': length,
      'width': width,
      'wallHeight': wallHeight,
      'waterproofType': waterproofType.toDouble(),
      'layers': layers.toDouble(),
      'floorArea': floorArea,
      'wallArea': wallArea,
      'perimeter': perimeter,
      'totalArea': totalArea,
      'waterproofKg': waterproofKg,
      'primerLiters': primerLiters,
      'tapeMeters': tapeMeters,
      'needPrimer': needPrimer ? 1.0 : 0.0,
      'needTape': needTape ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

      // Гидроизоляция
      final waterproofPrice = priceList
          .where((p) => p.sku == 'waterproof')
          .firstOrNull
          ?.price;
      if (waterproofPrice != null) {
        price += waterproofKg * waterproofPrice;
      }

      // Грунтовка
      if (primerLiters > 0) {
        final primerPrice = priceList
            .where((p) => p.sku == 'primer')
            .firstOrNull
            ?.price;
        if (primerPrice != null) {
          price += primerLiters * primerPrice;
        }
      }

      // Лента
      if (tapeMeters > 0) {
        final tapePrice = priceList
            .where((p) => p.sku == 'waterproof_tape')
            .firstOrNull
            ?.price;
        if (tapePrice != null) {
          price += tapeMeters * tapePrice;
        }
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
