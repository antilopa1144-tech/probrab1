import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор декоративного камня
///
/// Типы камня:
/// - 0: Гипсовый (3 кг клея/м²)
/// - 1: Бетонный (5 кг клея/м²)
/// - 2: Натуральный (7 кг клея/м²)
///
/// Режимы ввода:
/// - 0: Ручной ввод площади
/// - 1: По размерам стены
class CalculateDecorStoneV2 extends BaseCalculator {
  // Расход клея по типам камня (кг/м²)
  static const List<double> gluePerSqm = [3.0, 5.0, 7.0];

  // Константы расчёта
  static const double wastePercent = 10.0;
  static const double bagSize = 25.0; // кг
  static const double primerConsumption = 0.15; // л/м²
  static const double groutBaseFactor = 0.2; // кг/м² на 5 мм шва

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0, minValue: 0, maxValue: 1);
    final stoneType = getIntInput(inputs, 'stoneType', defaultValue: 0, minValue: 0, maxValue: 2);
    final jointWidth = getInput(inputs, 'jointWidth', defaultValue: 10.0, minValue: 0, maxValue: 20);
    final needGrout = getInput(inputs, 'needGrout', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needPrimer = getInput(inputs, 'needPrimer', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Площадь и размеры
    double area;
    double wallWidth;
    double wallHeight;

    if (inputMode == 1) {
      // Режим стены
      wallWidth = getInput(inputs, 'wallWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30);
      wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 0.5, maxValue: 10);
      area = wallWidth * wallHeight;

      // Валидация
      final rawWidth = inputs['wallWidth'] ?? 4.0;
      final rawHeight = inputs['wallHeight'] ?? 2.7;
      if (rawWidth <= 0) {
        throw CalculationException.invalidInput(
          'CalculateDecorStoneV2',
          'Ширина стены должна быть положительной',
        );
      }
      if (rawHeight <= 0) {
        throw CalculationException.invalidInput(
          'CalculateDecorStoneV2',
          'Высота стены должна быть положительной',
        );
      }
    } else {
      // Ручной режим
      area = getInput(inputs, 'area', defaultValue: 15.0, minValue: 1, maxValue: 500);
      wallWidth = (area / 2.7).clamp(0.5, 30.0);
      wallHeight = 2.7;

      // Валидация
      final rawArea = inputs['area'] ?? 15.0;
      if (rawArea <= 0) {
        throw CalculationException.invalidInput(
          'CalculateDecorStoneV2',
          'Площадь должна быть положительной',
        );
      }
    }

    const wasteFactor = 1 + wastePercent / 100;

    // Камень с запасом
    final stoneArea = area * wasteFactor;

    // Расчёт клея
    final glueConsumption = gluePerSqm[stoneType];
    final glueKg = area * glueConsumption * wasteFactor;
    final glueBags = (glueKg / bagSize).ceil();

    // Затирка
    double groutKg = 0.0;
    if (needGrout && jointWidth > 0) {
      // 0.2 кг/м² на каждые 5 мм ширины шва
      groutKg = area * (jointWidth / 5) * groutBaseFactor * wasteFactor;
    }

    // Грунтовка
    final primerLiters = needPrimer ? area * primerConsumption * wasteFactor : 0.0;

    // Формируем результат
    final values = <String, double>{
      'area': area,
      'wallWidth': wallWidth,
      'wallHeight': wallHeight,
      'inputMode': inputMode.toDouble(),
      'stoneType': stoneType.toDouble(),
      'jointWidth': jointWidth,
      'stoneArea': stoneArea,
      'glueKg': glueKg,
      'glueBags': glueBags.toDouble(),
      'groutKg': groutKg,
      'primerLiters': primerLiters,
      'needGrout': needGrout ? 1.0 : 0.0,
      'needPrimer': needPrimer ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

      // Камень
      final stonePrice = priceList
          .where((p) => p.sku == 'decor_stone')
          .firstOrNull
          ?.price;
      if (stonePrice != null) {
        price += stoneArea * stonePrice;
      }

      // Клей
      final gluePrice = priceList
          .where((p) => p.sku == 'stone_glue')
          .firstOrNull
          ?.price;
      if (gluePrice != null) {
        price += glueBags * gluePrice;
      }

      // Затирка
      if (needGrout && groutKg > 0) {
        final groutPrice = priceList
            .where((p) => p.sku == 'grout')
            .firstOrNull
            ?.price;
        if (groutPrice != null) {
          price += groutKg * groutPrice;
        }
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

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
