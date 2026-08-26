import '../../data/models/price_item.dart';
import 'base_calculator.dart';
import 'canonical_bridge.dart';
import 'calculator_usecase.dart';
import 'decor_stone_canonical_adapter.dart';

/// Калькулятор декоративного камня
///
/// Legacy-обёртка. Источник истины — canonical adapter v2.
class CalculateDecorStoneV2 extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode']?.toInt() ?? 0;

    if (inputMode == 0) {
      final width = inputs['wallWidth'] ?? 0;
      final height = inputs['wallHeight'] ?? 0;
      if (width <= 0 || height <= 0) {
        return wallAreaOrDimensionsRequiredMessage();
      }
    } else {
      final area = inputs['area'] ?? 0;
      if (area <= 0) {
        return positiveValueMessage('area');
      }
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    return CanonicalBridgeUseCase.convertCanonicalToResult(
      calculateCanonicalDecorStone(inputs),
    );
  }
}
