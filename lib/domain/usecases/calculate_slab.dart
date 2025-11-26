import '../../data/models/foundation_input.dart';
import '../../data/models/price_item.dart';
import '../entities/foundation_result.dart';

/// Юзкейс для расчёта монолитной плиты.
/// Формулы аналогичны ленточному фундаменту, но объём считается по
/// площади плиты и толщине. Армирование в две сетки (обычно 1 % от объёма)
/// считается упрощённо. В реальном приложении нужно учитывать рёбра,
/// утеплитель и сетки.
class CalculateSlab {
  final List<PriceItem> priceList;
  CalculateSlab({required this.priceList});

  FoundationResult call(FoundationInput input) {
    final area = input.perimeter * input.width; // здесь perimeter=длина, width=ширина
    final concreteVolume = area * input.height; // высота = толщина
    final rebarVolume = concreteVolume * 0.01; // 1% армирование
    final rebarWeight = rebarVolume * 7850;
    final concretePrice = _findPrice('concrete')?.price ?? 5000;
    final rebarPrice = _findPrice('rebar12')?.price ?? 80;
    final cost = concreteVolume * concretePrice + rebarWeight * rebarPrice;
    return FoundationResult(
      concreteVolume: concreteVolume,
      rebarWeight: rebarWeight,
      cost: cost,
    );
  }

  PriceItem? _findPrice(String sku) {
  return priceList.firstWhere(
    (item) => item.sku == sku,
    orElse: () => PriceItem(
      sku: sku,
      name: sku,
      price: 0,
      unit: '',
      imageUrl: '',
    ),
  );
}
}