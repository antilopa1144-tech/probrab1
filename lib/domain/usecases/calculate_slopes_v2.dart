import '../../data/models/price_item.dart';
import '../../core/exceptions/calculation_exception.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор оконных откосов
///
/// Типы откосов:
/// - 0: Штукатурные (plaster)
/// - 1: Гипсовые (gypsum)
/// - 2: Сэндвич-панели (sandwich)
class CalculateSlopesV2 extends BaseCalculator {
  // Константы расчёта
  static const double materialWastePercent = 15.0;
  static const double cornerWastePercent = 10.0;
  static const double primerConsumption = 0.15; // л/м²
  static const double windowsPerSealantTube = 2.5;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final windowsCount = getIntInput(inputs, 'windowsCount', defaultValue: 3, minValue: 1, maxValue: 30);
    final windowWidth = getInput(inputs, 'windowWidth', defaultValue: 1.4, minValue: 0.4, maxValue: 3.0);
    final windowHeight = getInput(inputs, 'windowHeight', defaultValue: 1.5, minValue: 0.4, maxValue: 2.5);
    final slopeDepth = getInput(inputs, 'slopeDepth', defaultValue: 0.25, minValue: 0.1, maxValue: 0.5);
    final slopesType = getIntInput(inputs, 'slopesType', defaultValue: 1, minValue: 0, maxValue: 2);
    final needCorners = getInput(inputs, 'needCorners', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;
    final needPrimer = getInput(inputs, 'needPrimer', defaultValue: 1.0, minValue: 0, maxValue: 1) == 1.0;

    // Валидация
    final rawWindowsCount = inputs['windowsCount'] ?? 3.0;
    if (rawWindowsCount <= 0) {
      throw CalculationException.invalidInput(
        'CalculateSlopesV2',
        'Количество окон должно быть положительным',
      );
    }

    final rawWidth = inputs['windowWidth'] ?? 1.4;
    if (rawWidth <= 0) {
      throw CalculationException.invalidInput(
        'CalculateSlopesV2',
        'Ширина окна должна быть положительной',
      );
    }

    final rawHeight = inputs['windowHeight'] ?? 1.5;
    if (rawHeight <= 0) {
      throw CalculationException.invalidInput(
        'CalculateSlopesV2',
        'Высота окна должна быть положительной',
      );
    }

    // Расчёт площади откосов
    // Площадь откосов на одно окно: 2 боковых + 1 верхний
    final sideArea = 2 * windowHeight * slopeDepth;
    final topArea = windowWidth * slopeDepth;
    final areaPerWindow = sideArea + topArea;

    final totalArea = areaPerWindow * windowsCount;
    const materialWasteFactor = 1 + materialWastePercent / 100;
    final materialArea = totalArea * materialWasteFactor;

    // Уголки: периметр окна без нижней части
    const cornerWasteFactor = 1 + cornerWastePercent / 100;
    final perimeterPerWindow = 2 * windowHeight + windowWidth;
    final cornerLength = needCorners
        ? perimeterPerWindow * windowsCount * cornerWasteFactor
        : 0.0;

    // Грунтовка
    final primerLiters = needPrimer ? totalArea * primerConsumption : 0.0;

    // Герметик: 1 туба на 2-3 окна
    final sealantTubes = (windowsCount / windowsPerSealantTube).ceil();

    // Формируем результат
    final values = <String, double>{
      'windowsCount': windowsCount.toDouble(),
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'slopeDepth': slopeDepth,
      'slopesType': slopesType.toDouble(),
      'totalArea': totalArea,
      'materialArea': materialArea,
      'cornerLength': cornerLength,
      'primerLiters': primerLiters,
      'sealantTubes': sealantTubes.toDouble(),
      'needCorners': needCorners ? 1.0 : 0.0,
      'needPrimer': needPrimer ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

      // Материал откосов
      final materialPrice = priceList
          .where((p) => p.sku == 'slopes_material')
          .firstOrNull
          ?.price;
      if (materialPrice != null) {
        price += materialArea * materialPrice;
      }

      // Уголки
      if (needCorners && cornerLength > 0) {
        final cornerPrice = priceList
            .where((p) => p.sku == 'corner_profile')
            .firstOrNull
            ?.price;
        if (cornerPrice != null) {
          price += cornerLength * cornerPrice;
        }
      }

      // Грунтовка
      if (needPrimer && primerLiters > 0) {
        final primerPrice = priceList
            .where((p) => p.sku == 'primer')
            .firstOrNull
            ?.price;
        if (primerPrice != null) {
          price += primerLiters * primerPrice;
        }
      }

      // Герметик
      final sealantPrice = priceList
          .where((p) => p.sku == 'sealant')
          .firstOrNull
          ?.price;
      if (sealantPrice != null) {
        price += sealantTubes * sealantPrice;
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
