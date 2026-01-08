import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор декоративной штукатурки
///
/// Типы штукатурки:
/// - 0: Венецианская (0.4 кг/м² на слой)
/// - 1: Короед (2.5 кг/м² на слой)
/// - 2: Шёлковая (0.3 кг/м² на слой)
///
/// Режимы ввода:
/// - 0: Ручной ввод площади
/// - 1: По размерам стены
class CalculateDecorPlasterV2 extends BaseCalculator {
  // Расход штукатурки по типам (кг/м² на слой)
  static const List<double> consumptionPerSqm = [0.4, 2.5, 0.3];

  // Константы расчёта
  static const double wastePercent = 10.0;
  static const double bucketSize = 25.0; // кг
  static const double primerConsumption = 0.15; // л/м²
  static const double waxConsumption = 0.05; // кг/м²

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0, minValue: 0, maxValue: 1);
    final plasterType = getIntInput(inputs, 'plasterType', defaultValue: 0, minValue: 0, maxValue: 2);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 5);
    final needPrimer = getInput(inputs, 'needPrimer', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needWax = getInput(inputs, 'needWax', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Площадь и размеры
    double area;
    double wallWidth;
    double wallHeight;

    if (inputMode == 1) {
      // Режим стены
      wallWidth = getInput(inputs, 'wallWidth', defaultValue: 5.0, minValue: 1, maxValue: 30);
      wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 1, maxValue: 10);
      area = wallWidth * wallHeight;

      // Валидация
      final rawWidth = inputs['wallWidth'] ?? 5.0;
      final rawHeight = inputs['wallHeight'] ?? 2.7;
      if (rawWidth <= 0) {
        throw CalculationException.invalidInput(
          'CalculateDecorPlasterV2',
          'Ширина стены должна быть положительной',
        );
      }
      if (rawHeight <= 0) {
        throw CalculationException.invalidInput(
          'CalculateDecorPlasterV2',
          'Высота стены должна быть положительной',
        );
      }
    } else {
      // Ручной режим
      area = getInput(inputs, 'area', defaultValue: 30.0, minValue: 1, maxValue: 500);
      wallWidth = (area / 2.7).clamp(1.0, 30.0);
      wallHeight = 2.7;

      // Валидация
      final rawArea = inputs['area'] ?? 30.0;
      if (rawArea <= 0) {
        throw CalculationException.invalidInput(
          'CalculateDecorPlasterV2',
          'Площадь должна быть положительной',
        );
      }
    }

    // Расход штукатурки
    final consumption = consumptionPerSqm[plasterType];
    const wasteFactor = 1 + wastePercent / 100;

    // Расчёт штукатурки
    final plasterKg = area * consumption * layers * wasteFactor;
    final plasterBuckets = (plasterKg / bucketSize).ceil();

    // Грунтовка
    final primerLiters = needPrimer ? area * primerConsumption * wasteFactor : 0.0;

    // Воск (только для венецианской)
    final waxKg = (needWax && plasterType == 0)
        ? area * waxConsumption * wasteFactor
        : 0.0;

    // Формируем результат
    final values = <String, double>{
      'area': area,
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
      'inputMode': inputMode.toDouble(),
      'plasterType': plasterType.toDouble(),
      'layers': layers.toDouble(),
      'plasterKg': plasterKg,
      'plasterBuckets': plasterBuckets.toDouble(),
      'primerLiters': primerLiters,
      'waxKg': waxKg,
      'needPrimer': needPrimer ? 1.0 : 0.0,
      'needWax': needWax ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

      // Штукатурка
      final plasterPrice = priceList
          .where((p) => p.sku == 'decor_plaster')
          .firstOrNull
          ?.price;
      if (plasterPrice != null) {
        price += plasterBuckets * plasterPrice;
      }

      // Грунтовка
      if (needPrimer) {
        final primerPrice = priceList
            .where((p) => p.sku == 'primer')
            .firstOrNull
            ?.price;
        if (primerPrice != null) {
          price += primerLiters * primerPrice;
        }
      }

      // Воск
      if (needWax && waxKg > 0) {
        final waxPrice = priceList
            .where((p) => p.sku == 'wax')
            .firstOrNull
            ?.price;
        if (waxPrice != null) {
          price += waxKg * waxPrice;
        }
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
