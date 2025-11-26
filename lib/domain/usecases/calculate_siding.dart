import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор сайдинга (винил / металл / фиброцемент).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 32603-2012 "Панели фасадные"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - panelWidth: ширина панели (см), по умолчанию 20
/// - panelLength: длина панели (см), по умолчанию 300
/// - perimeter: периметр здания (м)
class CalculateSiding implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final panelWidth = inputs['panelWidth'] ?? 20.0; // см
    final panelLength = inputs['panelLength'] ?? 300.0; // см
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь одной панели в м²
    final panelArea = (panelWidth / 100) * (panelLength / 100);

    // Количество панелей с запасом 10%
    final panelsNeeded = (area / panelArea * 1.1).ceil();

    // J-профиль: периметр (для вертикальных стыков)
    final jProfileLength = perimeter;

    // Углы: количество углов здания (обычно 4)
    final corners = (inputs['corners'] ?? 4).round();
    final cornerLength = corners * 2.5; // м на угол

    // Стартовая планка: периметр
    final startStripLength = perimeter;

    // Финишная планка: периметр
    final finishStripLength = perimeter;

    // Софиты (для карниза): если не указано, считаем 10% от периметра
    final soffitLength = inputs['soffitLength'] ?? (perimeter * 0.1);

    // Саморезы: ~8 шт на панель
    final screwsNeeded = panelsNeeded * 8;

    // Цены
    final sidingPrice = _findPrice(priceList, ['siding', 'siding_vinyl', 'siding_metal'])?.price;
    final jProfilePrice = _findPrice(priceList, ['profile_j', 'j_profile'])?.price;
    final cornerPrice = _findPrice(priceList, ['corner_siding', 'corner'])?.price;
    final startStripPrice = _findPrice(priceList, ['start_strip', 'strip_start'])?.price;
    final finishStripPrice = _findPrice(priceList, ['finish_strip', 'strip_finish'])?.price;
    final soffitPrice = _findPrice(priceList, ['soffit', 'soffit_siding'])?.price;

    double? totalPrice;
    if (sidingPrice != null) {
      totalPrice = panelsNeeded * sidingPrice;
      if (jProfilePrice != null) {
        totalPrice = totalPrice + jProfileLength * jProfilePrice;
      }
      if (cornerPrice != null) {
        totalPrice = totalPrice + cornerLength * cornerPrice;
      }
      if (startStripPrice != null) {
        totalPrice = totalPrice + startStripLength * startStripPrice;
      }
      if (finishStripPrice != null) {
        totalPrice = totalPrice + finishStripLength * finishStripPrice;
      }
      if (soffitPrice != null) {
        totalPrice = totalPrice + soffitLength * soffitPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'jProfileLength': jProfileLength,
        'cornerLength': cornerLength.toDouble(),
        'startStripLength': startStripLength,
        'finishStripLength': finishStripLength,
        'soffitLength': soffitLength,
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

