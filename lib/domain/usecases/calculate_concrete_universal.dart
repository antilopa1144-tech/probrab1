import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Универсальный калькулятор бетона.
///
/// Варианты использования:
/// - Готовый бетон: считает только объём
/// - Замес вручную: дополнительно считает цемент/песок/щебень/воду по типовой пропорции
///
/// Поля:
/// - concreteVolume: объём бетона (м³)
/// - concreteGrade: марка бетона (1=М100..7=М400), по умолч. 3 (М200)
/// - manualMix: 1 = замес вручную
/// - reserve: запас (%) по умолчанию 5
///
/// Пропорции на 1 м³ (цемент М400, по СНиП):
///
/// | Марка | Цемент, кг | Песок, м³ | Щебень, м³ | Вода, л |
/// |-------|-----------|-----------|------------|---------|
/// | М100  | 170       | 0.56      | 0.88       | 210     |
/// | М150  | 215       | 0.54      | 0.86       | 200     |
/// | М200  | 290       | 0.50      | 0.82       | 190     |
/// | М250  | 340       | 0.47      | 0.80       | 185     |
/// | М300  | 380       | 0.44      | 0.78       | 180     |
/// | М350  | 420       | 0.41      | 0.76       | 175     |
/// | М400  | 480       | 0.38      | 0.73       | 170     |
class CalculateConcreteUniversal extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final volume = inputs['concreteVolume'] ?? 0;
    if (volume <= 0) return 'Объём должен быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final reservePercent =
        getInput(inputs, 'reserve', defaultValue: 5.0, minValue: 0.0, maxValue: 30.0);
    final manualMix = getIntInput(inputs, 'manualMix', defaultValue: 0) != 0;

    // Марка бетона: 1=М100, 2=М150, 3=М200(default), 4=М250, 5=М300, 6=М350, 7=М400
    final concreteGrade = getIntInput(inputs, 'concreteGrade',
        defaultValue: 3, minValue: 1, maxValue: 7);

    final concreteVolume =
        addMargin(getInput(inputs, 'concreteVolume', minValue: 0.01), reservePercent);

    // Пропорции на 1 м³ (цемент М400, по СНиП)
    final proportions = _getProportions(concreteGrade);
    final cementPerM3 = proportions[0]; // кг
    final sandPerM3 = proportions[1]; // м³
    final gravelPerM3 = proportions[2]; // м³
    final waterPerM3 = proportions[3]; // л

    final cementBags = manualMix ? ceilToInt(concreteVolume * cementPerM3 / 50) : 0;
    final sandVolume = manualMix ? concreteVolume * sandPerM3 : 0.0;
    final gravelVolume = manualMix ? concreteVolume * gravelPerM3 : 0.0;
    final waterNeeded = manualMix ? concreteVolume * waterPerM3 : 0.0;

    final concretePrice = findPrice(priceList, ['concrete', 'ready_mix', 'beton']);
    final cementPrice = findPrice(priceList, ['cement', 'cement_m400', 'cement_m500']);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone']);
    final waterPrice = findPrice(priceList, ['water']);

    // Стоимость: готовый бетон ИЛИ компоненты (не суммировать оба варианта)
    final costs = manualMix
        ? [
            calculateCost(cementBags.toDouble(), cementPrice?.price),
            calculateCost(sandVolume, sandPrice?.price),
            calculateCost(gravelVolume, gravelPrice?.price),
            calculateCost(waterNeeded, waterPrice?.price),
          ]
        : [
            calculateCost(concreteVolume, concretePrice?.price),
          ];

    return createResult(
      values: {
        'concreteVolume': roundBulk(concreteVolume),
        'concreteGrade': concreteGrade.toDouble(),
        if (manualMix) ...{
          'cementBags': cementBags.toDouble(),
          'sandVolume': roundBulk(sandVolume),
          'gravelVolume': roundBulk(gravelVolume),
          'waterNeeded': roundBulk(waterNeeded),
        },
        'reserve': reservePercent,
      },
      totalPrice: sumCosts(costs),
    );
  }

  /// Пропорции на 1 м³ бетона (цемент М400, по СНиП).
  ///
  /// Возвращает [cementKg, sandM3, gravelM3, waterL].
  static List<double> _getProportions(int grade) {
    switch (grade) {
      case 1:
        return [170, 0.56, 0.88, 210]; // М100
      case 2:
        return [215, 0.54, 0.86, 200]; // М150
      case 3:
        return [290, 0.50, 0.82, 190]; // М200
      case 4:
        return [340, 0.47, 0.80, 185]; // М250
      case 5:
        return [380, 0.44, 0.78, 180]; // М300
      case 6:
        return [420, 0.41, 0.76, 175]; // М350
      case 7:
        return [480, 0.38, 0.73, 170]; // М400
      default:
        return [290, 0.50, 0.82, 190]; // М200 fallback
    }
  }
}
