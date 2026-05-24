// ignore_for_file: prefer_const_declarations

import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';

/// Единый результат расчёта.
class CalculatorResult {
  /// Любые числовые результаты: объем, площадь, количество мешков и т.п.
  final Map<String, double> values;

  /// Основные итоги без служебных ключей материалов (для UI).
  final Map<String, double>? primaryTotals;

  /// Структурированный список материалов (canonical-адаптеры).
  final List<CanonicalMaterialResult>? materials;

  /// Итоговая стоимость, если считаем деньги.
  final double? totalPrice;

  /// Нормативные источники (например, ГЭСН, ФЕР), использованные в расчёте.
  final List<String> norms;

  const CalculatorResult({
    required this.values,
    this.primaryTotals,
    this.materials,
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
