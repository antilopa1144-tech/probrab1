import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор панелей МДФ.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 32289-2013 "Плиты древесноволокнистые"
///
/// Поля:
/// - area: площадь стен (м²)
/// - panelWidth: ширина панели (см), по умолчанию 20
/// - panelLength: длина панели (см), по умолчанию 260
/// - perimeter: периметр комнаты (м)
class CalculateMdfPanels implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final panelWidth = inputs['panelWidth'] ?? 20.0; // см
    final panelLength = inputs['panelLength'] ?? 260.0; // см
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной панели в м²
    final panelArea = (panelWidth / 100) * (panelLength / 100);

    // Количество панелей с запасом 10%
    final panelsNeeded = (area / panelArea * 1.1).ceil();

    // Кляймеры: ~4 шт на панель
    final clampsNeeded = panelsNeeded * 4;

    // Уголки: периметр
    final cornersLength = perimeter;

    // Плинтус: периметр
    final plinthLength = perimeter;

    // Цены
    final panelPrice = _findPrice(priceList, ['mdf_panel', 'panel_mdf'])?.price;
    final clampPrice = _findPrice(priceList, ['clamp_mdf', 'clamp'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_mdf', 'corner'])?.price;
    final plinthPrice = _findPrice(priceList, ['plinth_mdf', 'plinth'])?.price;

    double? totalPrice;
    if (panelPrice != null) {
      totalPrice = panelsNeeded * panelPrice;
      if (clampPrice != null) {
        totalPrice = totalPrice + clampsNeeded * clampPrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornersLength * cornerPrice;
      }
      if (plinthPrice != null) {
        totalPrice = totalPrice + plinthLength * plinthPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'clampsNeeded': clampsNeeded.toDouble(),
        'cornersLength': cornersLength,
        'plinthLength': plinthLength,
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

