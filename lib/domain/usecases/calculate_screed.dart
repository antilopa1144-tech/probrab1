import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор стяжки пола.
///
/// Нормативы:
/// - СНиП 2.03.13-88 "Полы"
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - thickness: толщина стяжки (мм), по умолчанию 50
/// - cementGrade: марка цемента (М400/М500), влияет на пропорции
class CalculateScreed implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 50.0; // мм
    final cementGrade = inputs['cementGrade'] ?? 400.0; // М400 или М500

    // Объём стяжки в м³
    final volume = area * (thickness / 1000);

    // Пропорции цементно-песчаной смеси по СНиП 2.03.13-88:
    // М400: 1:3 (цемент:песок), М500: 1:4
    final cementRatio = cementGrade >= 500 ? 0.25 : 0.33; // доля цемента
    final sandRatio = 1.0 - cementRatio;

    // Плотность раствора ~2000 кг/м³
    final solutionDensity = 2000.0; // кг/м³
    final totalWeight = volume * solutionDensity;

    // Количество цемента и песка
    final cementNeeded = totalWeight * cementRatio;
    final sandNeeded = totalWeight * sandRatio;

    // Мешки цемента (50 кг)
    final cementBags = (cementNeeded / 50).ceil();

    // Песок в м³ (плотность ~1600 кг/м³)
    final sandVolume = sandNeeded / 1600;

    // Гидроизоляция (если нужна): ~1.2 м² на 1 м² пола (с нахлёстом)
    final waterproofingArea = area * 1.2;

    // Цены
    final cementPrice = _findPrice(priceList, ['cement_m400', 'cement_m500', 'cement'])?.price;
    final sandPrice = _findPrice(priceList, ['sand', 'sand_construction'])?.price;
    final waterproofingPrice = _findPrice(priceList, ['waterproofing', 'film_pe'])?.price;

    double? totalPrice;
    if (cementPrice != null && sandPrice != null) {
      final basePrice = cementBags * cementPrice + sandVolume * sandPrice;
      if (waterproofingPrice != null) {
        totalPrice = basePrice + waterproofingArea * waterproofingPrice;
      } else {
        totalPrice = basePrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'cementBags': cementBags.toDouble(),
        'sandVolume': sandVolume,
        'thickness': thickness,
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

