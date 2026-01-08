import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор шумоизоляции.
///
/// Рассчитывает материалы для звукоизоляции стен, потолков и полов.
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - thickness: толщина изоляции (мм)
/// - insulationType: тип изоляции (0 - минвата, 1 - мембрана, 2 - комбинированная)
/// - surfaceType: тип поверхности (0 - стена, 1 - потолок, 2 - пол)
/// - needGypsum: нужен ли гипсокартон (0/1)
/// - needProfile: нужен ли каркас из профиля (0/1)
class CalculateSoundInsulationV2 extends BaseCalculator {
  /// Запас на утеплитель (%)
  static const double insulationWastePercent = 10.0;

  /// Запас на мембрану (%)
  static const double membraneWastePercent = 15.0;

  /// Запас на гипсокартон (%)
  static const double gypsumWastePercent = 10.0;

  /// Запас на профиль (%)
  static const double profileWastePercent = 10.0;

  /// Длина стандартного профиля (м)
  static const double standardProfileLength = 3.0;

  /// Шаг профиля для стен и пола (м)
  static const double wallProfileSpacing = 0.6;

  /// Шаг профиля для потолка (м)
  static const double ceilingProfileSpacing = 0.4;

  /// Площадь на один подвес (м²)
  static const double areaPerHanger = 1.2;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) {
      return 'Площадь должна быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 500.0);
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 20.0, maxValue: 200.0);
    final insulationType = getIntInput(inputs, 'insulationType', defaultValue: 0, minValue: 0, maxValue: 2);
    final surfaceType = getIntInput(inputs, 'surfaceType', defaultValue: 0, minValue: 0, maxValue: 2);
    final needGypsum = getIntInput(inputs, 'needGypsum', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needProfile = getIntInput(inputs, 'needProfile', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Утеплитель +10% (для минваты и комбинированной)
    // insulationType: 0 = mineralWool, 1 = membrane, 2 = combined
    double insulationArea = 0;
    if (insulationType != 1) {
      // не мембрана
      insulationArea = area * (1 + insulationWastePercent / 100);
    }

    // Мембрана +15% (для мембраны и комбинированной)
    double membraneArea = 0;
    if (insulationType != 0) {
      // не минвата
      membraneArea = area * (1 + membraneWastePercent / 100);
    }

    // Гипсокартон +10%
    final gypsumArea = needGypsum ? area * (1 + gypsumWastePercent / 100) : 0.0;

    // Профиль
    double profileLength = 0;
    if (needProfile) {
      // surfaceType: 0 = wall, 1 = ceiling, 2 = floor
      final isCeiling = surfaceType == 1;
      final spacing = isCeiling ? ceilingProfileSpacing : wallProfileSpacing;
      final rows = (area / spacing).ceil();
      profileLength = rows * standardProfileLength * (1 + profileWastePercent / 100);
    }

    // Подвесы: 1 на каждые 1.2 м² (только для потолка с профилем)
    final isCeiling = surfaceType == 1;
    final hangersCount = needProfile && isCeiling ? (area / areaPerHanger).ceil() : 0;

    // Расчёт стоимости
    final insulationPrice = findPrice(priceList, ['insulation', 'утеплитель', 'минвата', 'sound_insulation']);
    final membranePrice = findPrice(priceList, ['membrane', 'мембрана', 'sound_membrane']);
    final gypsumPrice = findPrice(priceList, ['gypsum', 'гипсокартон', 'gkl']);
    final profilePrice = findPrice(priceList, ['profile', 'профиль', 'cd_profile']);
    final hangerPrice = findPrice(priceList, ['hanger', 'подвес', 'suspension']);

    final costs = [
      if (insulationArea > 0) calculateCost(insulationArea, insulationPrice?.price),
      if (membraneArea > 0) calculateCost(membraneArea, membranePrice?.price),
      if (gypsumArea > 0) calculateCost(gypsumArea, gypsumPrice?.price),
      if (profileLength > 0) calculateCost(profileLength, profilePrice?.price),
      if (hangersCount > 0) calculateCost(hangersCount.toDouble(), hangerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'insulationType': insulationType.toDouble(),
        'surfaceType': surfaceType.toDouble(),
        'needGypsum': needGypsum ? 1.0 : 0.0,
        'needProfile': needProfile ? 1.0 : 0.0,
        'insulationArea': insulationArea,
        'membraneArea': membraneArea,
        'gypsumArea': gypsumArea,
        'profileLength': profileLength,
        'hangersCount': hangersCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
