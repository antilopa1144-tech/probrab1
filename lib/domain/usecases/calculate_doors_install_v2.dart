import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор установки дверей V2.
///
/// Входные параметры:
/// - doorsCount: количество дверей, 1-15, по умолчанию 3
/// - doorHeight: высота двери (м), 1.8-2.4, по умолчанию 2.0
/// - doorWidth: ширина двери (м), 0.6-1.2, по умолчанию 0.8
/// - doorType: тип двери (0=межкомнатная, 1=входная, 2=стеклянная), по умолчанию 0
/// - needCasing: наличники (0=нет, 1=да), по умолчанию 1
/// - needThreshold: порог (0=нет, 1=да), по умолчанию 0
///
/// Выходные значения:
/// - doorsCount: количество дверей
/// - framesCount: количество коробок
/// - hingesCount: количество петель
/// - handlesCount: количество ручек (комплектов)
/// - foamCans: баллоны пены
/// - casingMeters: наличники (м.п.)
/// - thresholdCount: количество порогов
class CalculateDoorsInstallV2 extends BaseCalculator {
  // Петли на дверь по типу
  static const List<int> hingesPerDoorByType = [2, 3, 2]; // interior, entrance, glass

  // Пена: дверей на баллон
  static const double doorsPerFoamCan = 2.0;

  // Запас на наличники
  static const double casingWastePercent = 10.0;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final doorsCount = getIntInput(inputs, 'doorsCount',
        defaultValue: 3, minValue: 1, maxValue: 15);
    final doorHeight = getInput(inputs, 'doorHeight',
        defaultValue: 2.0, minValue: 1.8, maxValue: 2.4);
    final doorWidth = getInput(inputs, 'doorWidth',
        defaultValue: 0.8, minValue: 0.6, maxValue: 1.2);
    final doorType = getIntInput(inputs, 'doorType',
        defaultValue: 0, minValue: 0, maxValue: 2);
    final needCasing = getIntInput(inputs, 'needCasing',
        defaultValue: 1, minValue: 0, maxValue: 1);
    final needThreshold = getIntInput(inputs, 'needThreshold',
        defaultValue: 0, minValue: 0, maxValue: 1);

    // Коробки = количество дверей
    final framesCount = doorsCount;

    // Петли зависят от типа двери
    final hingesPerDoor = hingesPerDoorByType[doorType];
    final hingesCount = doorsCount * hingesPerDoor;

    // Ручки: 1 комплект на дверь
    final handlesCount = doorsCount;

    // Пена: 1 баллон на 2 двери (округляем вверх)
    final foamCans = (doorsCount / doorsPerFoamCan).ceil().toDouble();

    // Наличники: периметр двери × 2 стороны × количество дверей
    double casingMeters = 0;
    if (needCasing == 1) {
      final doorPerimeter = 2 * doorHeight + doorWidth;
      casingMeters = doorPerimeter * 2 * doorsCount * (1 + casingWastePercent / 100);
    }

    // Пороги
    final thresholdCount = needThreshold == 1 ? doorsCount : 0;

    // Расчёт стоимости
    double? totalPrice;

    final doorPrice = findPrice(priceList, ['door', 'door_interior', 'door_entrance']);
    final framePrice = findPrice(priceList, ['door_frame', 'frame']);
    final hingePrice = findPrice(priceList, ['hinge', 'door_hinge']);
    final handlePrice = findPrice(priceList, ['handle', 'door_handle']);
    final foamPrice = findPrice(priceList, ['foam', 'mounting_foam']);
    final casingPrice = findPrice(priceList, ['casing', 'door_casing']);
    final thresholdPrice = findPrice(priceList, ['threshold', 'door_threshold']);

    if (doorPrice != null) {
      totalPrice = (totalPrice ?? 0) + doorsCount * doorPrice.price;
    }
    if (framePrice != null) {
      totalPrice = (totalPrice ?? 0) + framesCount * framePrice.price;
    }
    if (hingePrice != null) {
      totalPrice = (totalPrice ?? 0) + hingesCount * hingePrice.price;
    }
    if (handlePrice != null) {
      totalPrice = (totalPrice ?? 0) + handlesCount * handlePrice.price;
    }
    if (foamPrice != null) {
      totalPrice = (totalPrice ?? 0) + foamCans * foamPrice.price;
    }
    if (needCasing == 1 && casingPrice != null) {
      totalPrice = (totalPrice ?? 0) + casingMeters * casingPrice.price;
    }
    if (needThreshold == 1 && thresholdPrice != null) {
      totalPrice = (totalPrice ?? 0) + thresholdCount * thresholdPrice.price;
    }

    return createResult(
      values: {
        'doorsCount': doorsCount.toDouble(),
        'doorHeight': doorHeight,
        'doorWidth': doorWidth,
        'doorType': doorType.toDouble(),
        'needCasing': needCasing.toDouble(),
        'needThreshold': needThreshold.toDouble(),
        'framesCount': framesCount.toDouble(),
        'hingesCount': hingesCount.toDouble(),
        'handlesCount': handlesCount.toDouble(),
        'foamCans': foamCans,
        'casingMeters': casingMeters,
        'thresholdCount': thresholdCount.toDouble(),
      },
      totalPrice: totalPrice,
    );
  }
}
