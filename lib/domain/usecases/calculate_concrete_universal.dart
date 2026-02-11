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
/// - manualMix: 1 = замес вручную
/// - reserve: запас (%) по умолчанию 5
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

    final concreteVolume =
        addMargin(getInput(inputs, 'concreteVolume', minValue: 0.01), reservePercent);

    // Типовая пропорция для М200 (упрощённо на 1 м³):
    // цемент ~ 6 мешков по 50 кг, песок ~ 0.5 м³, щебень ~ 0.8 м³, вода ~ 180 л
    final cementBags = manualMix ? ceilToInt(concreteVolume * 6.0) : 0;
    final sandVolume = manualMix ? concreteVolume * 0.5 : 0.0;
    final gravelVolume = manualMix ? concreteVolume * 0.8 : 0.0;
    final waterNeeded = manualMix ? concreteVolume * 180.0 : 0.0;

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
}

