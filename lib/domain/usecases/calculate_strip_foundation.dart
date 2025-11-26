import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Ленточный фундамент.
///
/// Поля:
/// - perimeter: м
/// - width: м
/// - height: м
class CalculateStripFoundation implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final perimeter = inputs['perimeter'] ?? 0;
    final width = inputs['width'] ?? 0;
    final height = inputs['height'] ?? 0;

    // Формула объёма бетона
    final volume = perimeter * width * height;
    final rebarWeight = volume * 0.01 * 7850; // грубая оценка 1% армирования

    // Получаем цену бетона из прайса
    final pricePerM3 = _findPrice(priceList, ['concrete_m3', 'concrete'])?.price;
    final totalPrice = pricePerM3 != null ? volume * pricePerM3 : null;

    // Пример: расчёт мешков цемента, пока грубо
    final bagsCement = volume * 7;

    return CalculatorResult(
      values: {
        'concreteVolume': volume,
        'rebarWeight': rebarWeight,
        'bagsCement': bagsCement,
      },
      totalPrice: totalPrice,
    );
  }

  PriceItem? _findPrice(List<PriceItem> priceList, List<String> skus) {
    for (final sku in skus) {
      try {
        return priceList.firstWhere((item) => item.sku == sku);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
