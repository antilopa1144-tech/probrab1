import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор фасадных панелей V2.
///
/// Входные параметры:
/// - wallLength: периметр дома (м), 10-200, по умолчанию 40
/// - wallHeight: высота стен (м), 2-10, по умолчанию 3
/// - openingsArea: площадь проёмов (м²), 0-50, по умолчанию 10
/// - panelType: тип панелей (0=виниловые, 1=металлические, 2=фиброцементные), по умолчанию 0
/// - needInsulation: утепление (0/1), по умолчанию 1
/// - needProfile: обрешётка (0/1), по умолчанию 1
///
/// Выходные значения:
/// - wallArea: площадь стен (м²)
/// - panelsArea: площадь панелей с запасом (м²)
/// - profileLength: длина профиля (м.п.)
/// - insulationArea: площадь утеплителя (м²)
/// - cornersCount: количество угловых элементов (шт)
/// - startersCount: количество стартовых планок (шт)
class CalculateFacadePanelsV2 extends BaseCalculator {
  // Запас на панели
  static const double panelsWastePercent = 10.0;

  // Шаг обрешётки
  static const double profileStep = 0.6; // м
  static const double profileWastePercent = 10.0;

  // Запас на утеплитель
  static const double insulationWastePercent = 5.0;

  // Длина профилей
  static const double cornerProfileLength = 3.0; // м
  static const double starterProfileLength = 3.0; // м

  // Количество внешних углов дома
  static const int externalCorners = 4;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final wallLength = getInput(inputs, 'wallLength',
        defaultValue: 40.0, minValue: 10.0, maxValue: 200.0);
    final wallHeight = getInput(inputs, 'wallHeight',
        defaultValue: 3.0, minValue: 2.0, maxValue: 10.0);
    final openingsArea = getInput(inputs, 'openingsArea',
        defaultValue: 10.0, minValue: 0.0, maxValue: 50.0);
    final panelType = getIntInput(inputs, 'panelType',
        defaultValue: 0, minValue: 0, maxValue: 2);
    final needInsulation = getIntInput(inputs, 'needInsulation',
        defaultValue: 1, minValue: 0, maxValue: 1);
    final needProfile = getIntInput(inputs, 'needProfile',
        defaultValue: 1, minValue: 0, maxValue: 1);

    // Площадь стен
    final grossArea = wallLength * wallHeight;
    final wallArea = grossArea - openingsArea;

    // Панели с запасом
    final panelsArea = wallArea * (1 + panelsWastePercent / 100);

    // Профиль для обрешётки
    double profileLength = 0;
    if (needProfile == 1) {
      final verticals = (wallLength / profileStep).ceil();
      profileLength = verticals * wallHeight * (1 + profileWastePercent / 100);
    }

    // Утеплитель
    final insulationArea = needInsulation == 1
        ? wallArea * (1 + insulationWastePercent / 100)
        : 0.0;

    // Углы: 4 внешних угла × высота / длина профиля
    final cornersCount =
        (externalCorners * wallHeight / cornerProfileLength).ceil();

    // Стартовые планки: периметр / длина профиля
    final startersCount = (wallLength / starterProfileLength).ceil();

    // Расчёт стоимости
    double? totalPrice;

    final panelPrice = findPrice(priceList, ['facade_panel', 'siding']);
    final profilePrice = findPrice(priceList, ['profile', 'metal_profile']);
    final insulationPrice = findPrice(priceList, ['insulation', 'mineral_wool']);
    final cornerPrice = findPrice(priceList, ['corner', 'corner_profile']);
    final starterPrice = findPrice(priceList, ['starter', 'starter_profile']);

    if (panelPrice != null) {
      totalPrice = (totalPrice ?? 0) + panelsArea * panelPrice.price;
    }
    if (needProfile == 1 && profilePrice != null) {
      totalPrice = (totalPrice ?? 0) + profileLength * profilePrice.price;
    }
    if (needInsulation == 1 && insulationPrice != null) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice.price;
    }
    if (cornerPrice != null) {
      totalPrice = (totalPrice ?? 0) + cornersCount * cornerPrice.price;
    }
    if (starterPrice != null) {
      totalPrice = (totalPrice ?? 0) + startersCount * starterPrice.price;
    }

    return createResult(
      values: {
        'wallLength': wallLength,
        'wallHeight': wallHeight,
        'openingsArea': openingsArea,
        'panelType': panelType.toDouble(),
        'needInsulation': needInsulation.toDouble(),
        'needProfile': needProfile.toDouble(),
        'grossArea': grossArea,
        'wallArea': wallArea,
        'panelsArea': panelsArea,
        'profileLength': profileLength,
        'insulationArea': insulationArea,
        'cornersCount': cornersCount.toDouble(),
        'startersCount': startersCount.toDouble(),
      },
      totalPrice: totalPrice,
    );
  }
}
