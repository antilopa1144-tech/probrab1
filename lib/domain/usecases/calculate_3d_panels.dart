import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор 3D панелей.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - panelSize: размер панели (см), по умолчанию 50 (50×50 см)
class Calculate3dPanels implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final panelSize = inputs['panelSize'] ?? 50.0; // см

    // Площадь одной панели в м²
    final panelArea = (panelSize / 100) * (panelSize / 100);

    // Количество панелей с запасом 10%
    final panelsNeeded = (area / panelArea * 1.1).ceil();

    // Клей: ~5 кг/м²
    final glueNeeded = area * 5.0;

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = area * 0.2;

    // Цены
    final panelPrice = _findPrice(priceList, ['panel_3d', '3d_panel'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_3d', 'glue'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_deep'])?.price;

    double? totalPrice;
    if (panelPrice != null) {
      totalPrice = panelsNeeded * panelPrice;
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'primerNeeded': primerNeeded,
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

