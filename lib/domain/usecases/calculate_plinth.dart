import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор плинтуса (пол).
///
/// Поля:
/// - length, width: размеры комнаты (м) (если perimeter не задан)
/// - perimeter: периметр комнаты (м)
/// - doors: количество дверей (шт)
/// - doorWidth: ширина двери (м)
/// - reserve: запас (%) по умолчанию 5
/// - plinthPieceLength: длина планки (м) по умолчанию 2.5
class CalculatePlinth extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final perimeter = inputs['perimeter'] ?? 0;
    final length = inputs['length'] ?? 0;
    final width = inputs['width'] ?? 0;

    if (perimeter <= 0 && (length <= 0 || width <= 0)) {
      return 'Укажите периметр или размеры комнаты';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final reservePercent =
        getInput(inputs, 'reserve', defaultValue: 5.0, minValue: 0.0, maxValue: 30.0);
    final plinthPieceLength =
        getInput(inputs, 'plinthPieceLength', defaultValue: 2.5, minValue: 1.0, maxValue: 4.0);

    var perimeter = getInput(inputs, 'perimeter', defaultValue: 0.0, minValue: 0.0);
    if (perimeter <= 0) {
      final length = getInput(inputs, 'length', minValue: 0.5);
      final width = getInput(inputs, 'width', minValue: 0.5);
      perimeter = 2 * (length + width);
    }

    final doors = getIntInput(inputs, 'doors', defaultValue: 0, minValue: 0, maxValue: 20);
    final doorWidth =
        getInput(inputs, 'doorWidth', defaultValue: 0.8, minValue: 0.5, maxValue: 1.5);
    final doorsTotalWidth = doors > 0 ? doors * doorWidth : 0.0;

    final netLength = (perimeter - doorsTotalWidth) < 0 ? 0.0 : (perimeter - doorsTotalWidth);
    final withReserve = addMargin(netLength, reservePercent);

    final plinthPieces = ceilToInt(safeDivide(withReserve, plinthPieceLength));

    // Крепёж: ориентировочно 2 точки крепления на 1 метр (дюбель+саморез)
    final fastenersNeeded = ceilToInt(withReserve * 2);

    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_floor', 'baseboard']);
    final fastenerPrice = findPrice(priceList, ['fasteners', 'dowel', 'screw']);

    final costs = [
      calculateCost(withReserve, plinthPrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
    ];

    return createResult(
      values: {
        'plinthLengthMeters': roundBulk(withReserve),
        'plinthPieces': plinthPieces.toDouble(),
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'reserve': reservePercent,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
