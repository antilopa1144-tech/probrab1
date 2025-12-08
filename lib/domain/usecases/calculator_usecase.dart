
import 'package:probrab_ai/data/models/price_item.dart';


/// Единый результат расчёта.
class CalculatorResult {
  /// Любые числовые результаты: объем, площадь, количество мешков и т.п.
  final Map<String, double> values;

  /// Итоговая стоимость, если считаем деньги.
  final double? totalPrice;

  /// Нормативные источники (например, ГЭСН, ФЕР), использованные в расчёте.
  final List<String> norms;

  const CalculatorResult({
    required this.values,
    this.totalPrice,
    this.norms = const [],
  });
}

/// Контракт для любого калькулятора.
///
/// На вход: карта значений полей + прайс-лист.
/// На выход: CalculatorResult.
abstract class CalculatorUseCase {
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  );
}
