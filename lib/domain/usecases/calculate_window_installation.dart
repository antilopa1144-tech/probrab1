import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор установки окон.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 30674-99 "Блоки оконные"
///
/// Поля:
/// - windows: количество окон, по умолчанию 1
/// - windowWidth: ширина окна (м), по умолчанию 1.5
/// - windowHeight: высота окна (м), по умолчанию 1.4
class CalculateWindowInstallation implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final windows = (inputs['windows'] ?? 1).round();
    final windowWidth = inputs['windowWidth'] ?? 1.5; // м
    final windowHeight = inputs['windowHeight'] ?? 1.4; // м

    // Площадь одного окна
    final windowArea = windowWidth * windowHeight;

    // Монтажная пена: ~1 баллон на окно
    final foamNeeded = windows;

    // Подоконники: по количеству окон
    final sillsNeeded = windows;
    final sillLength = windowWidth * windows;

    // Откосы: периметр окна × количество
    final slopePerimeter = (windowWidth + windowHeight) * 2;
    final slopeArea = slopePerimeter * 0.3 * windows; // ширина откоса 30 см

    // Отливы: по ширине окна
    final dripLength = windowWidth * windows;

    // Цены
    final windowPrice = _findPrice(priceList, ['window', 'window_pvc'])?.price;
    final foamPrice = _findPrice(priceList, ['foam_mounting', 'foam'])?.price;
    final sillPrice = _findPrice(priceList, ['sill', 'window_sill'])?.price;
    final slopePrice = _findPrice(priceList, ['slope', 'slope_material'])?.price;
    final dripPrice = _findPrice(priceList, ['drip', 'drip_window'])?.price;

    double? totalPrice;
    if (windowPrice != null) {
      totalPrice = windows * windowPrice;
      if (foamPrice != null) {
        totalPrice = totalPrice + foamNeeded * foamPrice;
      }
      if (sillPrice != null) {
        totalPrice = totalPrice + sillLength * sillPrice;
      }
      if (slopePrice != null) {
        totalPrice = totalPrice + slopeArea * slopePrice;
      }
      if (dripPrice != null) {
        totalPrice = totalPrice + dripLength * dripPrice;
      }
    }

    return CalculatorResult(
      values: {
        'windows': windows.toDouble(),
        'windowArea': windowArea,
        'foamNeeded': foamNeeded.toDouble(),
        'sillsNeeded': sillsNeeded.toDouble(),
        'sillLength': sillLength,
        'slopeArea': slopeArea,
        'dripLength': dripLength,
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

