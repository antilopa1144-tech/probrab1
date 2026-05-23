import 'calculate_underfloor_heating.dart';
import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';

/// Единый движок расчёта тёплого пола для V2/ProCalculator.
///
/// Кастомный экран [UnderfloorHeatingCalculatorScreen] использует тот же
/// [CalculateUnderfloorHeating]; здесь только нормализация полей каталога V2.
class WarmFloorUnifiedUseCase implements CalculatorUseCase {
  const WarmFloorUnifiedUseCase();

  static final CalculateUnderfloorHeating _calculator =
      CalculateUnderfloorHeating();

  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    return _calculator(mapToLegacyInputs(inputs), priceList);
  }

  /// Преобразует поля V2-каталога в формат кастомного экрана.
  static Map<String, double> mapToLegacyInputs(Map<String, double> inputs) {
    if (inputs.containsKey('systemType')) {
      return Map<String, double>.from(inputs);
    }

    final mapped = Map<String, double>.from(inputs);

    if (mapped.containsKey('type')) {
      final type = mapped['type']!.round();
      // V2: 1=кабель, 2=мат → экран: 1=мат, 2=кабель
      mapped['systemType'] = (type == 1 ? 2.0 : 1.0);
    }

    if (mapped.containsKey('inputMode')) {
      final v2Mode = mapped['inputMode']!.round();
      // V2: 0=размеры, 1=площадь → экран: 0=площадь, 1=размеры
      mapped['inputMode'] = (v2Mode == 0 ? 1.0 : 0.0);
    }

    if (!mapped.containsKey('usefulAreaPercent')) {
      mapped['usefulAreaPercent'] = 70.0;
    }

    return mapped;
  }
}
