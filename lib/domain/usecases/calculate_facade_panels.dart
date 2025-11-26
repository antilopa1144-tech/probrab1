import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор фасадных панелей.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 32603-2012 "Панели фасадные"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - panelWidth: ширина панели (см), по умолчанию 50
/// - panelHeight: высота панели (см), по умолчанию 100
/// - perimeter: периметр здания (м)
class CalculateFacadePanels implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final panelWidth = inputs['panelWidth'] ?? 50.0; // см
    final panelHeight = inputs['panelHeight'] ?? 100.0; // см
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной панели в м²
    final panelArea = (panelWidth / 100) * (panelHeight / 100);

    // Количество панелей с запасом 10%
    final panelsNeeded = (area / panelArea * 1.1).ceil();

    // Крепления: ~4 шт на панель
    final fastenersNeeded = panelsNeeded * 4;

    // Уголки: периметр
    final cornersLength = perimeter;

    // Стартовая планка: периметр
    final startStripLength = perimeter;

    // Цены
    final panelPrice = _findPrice(priceList, ['facade_panel', 'panel_facade'])?.price;
    final fastenerPrice = _findPrice(priceList, ['fastener_facade', 'fastener'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_facade', 'corner'])?.price;
    final startStripPrice = _findPrice(priceList, ['start_strip_facade', 'start_strip'])?.price;

    double? totalPrice;
    if (panelPrice != null) {
      totalPrice = panelsNeeded * panelPrice;
      if (fastenerPrice != null) {
        totalPrice = totalPrice + fastenersNeeded * fastenerPrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornersLength * cornerPrice;
      }
      if (startStripPrice != null) {
        totalPrice = totalPrice + startStripLength * startStripPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'cornersLength': cornersLength,
        'startStripLength': startStripLength,
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

