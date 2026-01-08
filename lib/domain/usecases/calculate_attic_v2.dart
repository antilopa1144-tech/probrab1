import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор мансарды/чердака
///
/// Типы мансарды:
/// - 0: Холодная (cold) - без утепления
/// - 1: Тёплая (warm) - с утеплением
/// - 2: Жилая (living) - с утеплением и отделкой
class CalculateAtticV2 extends BaseCalculator {
  // Константы расчёта
  static const double insulationFrontalMultiplier = 1.2; // +20% для фронтонов
  static const double insulationWastePercent = 10.0;
  static const double vaporBarrierOverlapPercent = 15.0;
  static const double membraneOverlapPercent = 15.0;
  static const double gypsumWastePercent = 10.0;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final floorLength = getInput(inputs, 'floorLength', defaultValue: 8.0, minValue: 3, maxValue: 20);
    final floorWidth = getInput(inputs, 'floorWidth', defaultValue: 6.0, minValue: 3, maxValue: 15);
    final roofHeight = getInput(inputs, 'roofHeight', defaultValue: 2.5, minValue: 1.5, maxValue: 5);
    final insulationThickness = getInput(inputs, 'insulationThickness', defaultValue: 150.0, minValue: 50, maxValue: 300);
    final atticType = getIntInput(inputs, 'atticType', defaultValue: 1, minValue: 0, maxValue: 2);
    final needVaporBarrier = getInput(inputs, 'needVaporBarrier', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needMembrane = getInput(inputs, 'needMembrane', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needGypsum = getInput(inputs, 'needGypsum', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Валидация
    final rawLength = inputs['floorLength'] ?? 8.0;
    if (rawLength <= 0) {
      throw CalculationException.invalidInput(
        'CalculateAtticV2',
        'Длина должна быть положительной',
      );
    }

    final rawWidth = inputs['floorWidth'] ?? 6.0;
    if (rawWidth <= 0) {
      throw CalculationException.invalidInput(
        'CalculateAtticV2',
        'Ширина должна быть положительной',
      );
    }

    final rawHeight = inputs['roofHeight'] ?? 2.5;
    if (rawHeight <= 0) {
      throw CalculationException.invalidInput(
        'CalculateAtticV2',
        'Высота крыши должна быть положительной',
      );
    }

    // Расчёт площадей
    final floorArea = floorLength * floorWidth;

    // Площадь крыши (двускатная) ≈ площадь пола × множитель (зависит от высоты)
    final roofMultiplier = 1.4 + (roofHeight / 10);
    final roofArea = floorArea * roofMultiplier;

    // Утеплитель: крыша + стены фронтонов (примерно +20%)
    const insulationWasteFactor = 1 + insulationWastePercent / 100;
    double insulationArea = 0.0;
    if (atticType != 0) {
      // Не холодная мансарда
      insulationArea = roofArea * insulationFrontalMultiplier * insulationWasteFactor;
    }

    // Пароизоляция (только если есть утепление)
    const vaporBarrierOverlapFactor = 1 + vaporBarrierOverlapPercent / 100;
    final vaporBarrierArea = (needVaporBarrier && insulationArea > 0)
        ? insulationArea * vaporBarrierOverlapFactor
        : 0.0;

    // Мембрана
    const membraneOverlapFactor = 1 + membraneOverlapPercent / 100;
    final membraneArea = needMembrane ? roofArea * membraneOverlapFactor : 0.0;

    // Гипсокартон (только для жилой мансарды)
    const gypsumWasteFactor = 1 + gypsumWastePercent / 100;
    final gypsumArea = (needGypsum && atticType == 2)
        ? roofArea * gypsumWasteFactor
        : 0.0;

    // Формируем результат
    final values = <String, double>{
      'floorLength': floorLength,
      'floorWidth': floorWidth,
      'roofHeight': roofHeight,
      'insulationThickness': insulationThickness,
      'atticType': atticType.toDouble(),
      'floorArea': floorArea,
      'roofArea': roofArea,
      'insulationArea': insulationArea,
      'vaporBarrierArea': vaporBarrierArea,
      'membraneArea': membraneArea,
      'gypsumArea': gypsumArea,
      'needVaporBarrier': needVaporBarrier ? 1.0 : 0.0,
      'needMembrane': needMembrane ? 1.0 : 0.0,
      'needGypsum': needGypsum ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

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

      // Пароизоляция
      if (vaporBarrierArea > 0) {
        final vaporBarrierPrice = priceList
            .where((p) => p.sku == 'vapor_barrier')
            .firstOrNull
            ?.price;
        if (vaporBarrierPrice != null) {
          price += vaporBarrierArea * vaporBarrierPrice;
        }
      }

      // Мембрана
      if (membraneArea > 0) {
        final membranePrice = priceList
            .where((p) => p.sku == 'membrane')
            .firstOrNull
            ?.price;
        if (membranePrice != null) {
          price += membraneArea * membranePrice;
        }
      }

      // Гипсокартон
      if (gypsumArea > 0) {
        final gypsumPrice = priceList
            .where((p) => p.sku == 'gypsum_board')
            .firstOrNull
            ?.price;
        if (gypsumPrice != null) {
          price += gypsumArea * gypsumPrice;
        }
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
