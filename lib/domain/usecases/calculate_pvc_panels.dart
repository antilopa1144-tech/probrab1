import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор панелей ПВХ.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь стен (м²)
/// - panelWidth: ширина панели (см), по умолчанию 25
/// - panelLength: длина панели (см), по умолчанию 300
/// - perimeter: периметр комнаты (м)
class CalculatePvcPanels implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final panelWidth = inputs['panelWidth'] ?? 25.0; // см
    final panelLength = inputs['panelLength'] ?? 300.0; // см
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной панели в м²
    final panelArea = (panelWidth / 100) * (panelLength / 100);

    // Количество панелей с запасом 10%
    final panelsNeeded = (area / panelArea * 1.1).ceil();

    // Профили: стартовый, финишный, угловой
    final startProfileLength = perimeter;
    final finishProfileLength = perimeter;
    final cornerLength = perimeter;

    // Саморезы: ~6 шт на панель
    final screwsNeeded = panelsNeeded * 6;

    // Цены
    final panelPrice = _findPrice(priceList, ['pvc_panel', 'panel_pvc'])?.price;
    final startProfilePrice = _findPrice(priceList, ['profile_start_pvc', 'profile_start'])?.price;
    final finishProfilePrice = _findPrice(priceList, ['profile_finish_pvc', 'profile_finish'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_pvc', 'corner'])?.price;

    double? totalPrice;
    if (panelPrice != null) {
      totalPrice = panelsNeeded * panelPrice;
      if (startProfilePrice != null && finishProfilePrice != null) {
        totalPrice = totalPrice + (startProfileLength + finishProfileLength) * startProfilePrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornerLength * cornerPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'startProfileLength': startProfileLength,
        'finishProfileLength': finishProfileLength,
        'cornerLength': cornerLength,
        'screwsNeeded': screwsNeeded.toDouble(),
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

