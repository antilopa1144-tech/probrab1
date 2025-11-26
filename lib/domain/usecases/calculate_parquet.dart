import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор паркета / массива.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 862.1-85 "Паркет штучный"
///
/// Поля:
/// - area: площадь пола (м²)
/// - plankWidth: ширина планки (см), по умолчанию 7
/// - plankLength: длина планки (см), по умолчанию 40
/// - thickness: толщина (мм), по умолчанию 15
class CalculateParquet implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final plankWidth = inputs['plankWidth'] ?? 7.0; // см
    final plankLength = inputs['plankLength'] ?? 40.0; // см

    // Площадь одной планки в м²
    final plankArea = (plankWidth / 100) * (plankLength / 100);

    // Количество планок с запасом 5% (для паркета меньше, чем для ламината)
    final planksNeeded = (area / plankArea * 1.05).ceil();

    // Лак: расход зависит от толщины, ~0.1 л/м² на слой (обычно 3 слоя)
    final varnishNeeded = area * 0.1 * 3;

    // Грунтовка для паркета: ~0.08 л/м²
    final primerNeeded = area * 0.08;

    // Плинтус: периметр
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));
    final plinthLength = perimeter;

    // Клей для паркета: ~1.5 кг/м²
    final glueNeeded = area * 1.5;

    // Цены
    final parquetPrice = _findPrice(priceList, ['parquet', 'parquet_plank', 'wood_floor'])?.price;
    final varnishPrice = _findPrice(priceList, ['varnish', 'varnish_parquet'])?.price;
    final primerPrice = _findPrice(priceList, ['primer_parquet', 'primer'])?.price;
    final plinthPrice = _findPrice(priceList, ['plinth_parquet', 'plinth'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_parquet', 'glue'])?.price;

    double? totalPrice;
    if (parquetPrice != null) {
      var basePrice = planksNeeded * parquetPrice;
      if (varnishPrice != null) {
        basePrice = basePrice + varnishNeeded * varnishPrice;
      }
      if (primerPrice != null) {
        basePrice = basePrice + primerNeeded * primerPrice;
      }
      if (plinthPrice != null) {
        basePrice = basePrice + plinthLength * plinthPrice;
      }
      if (gluePrice != null) {
        basePrice = basePrice + glueNeeded * gluePrice;
      }
      totalPrice = basePrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'planksNeeded': planksNeeded.toDouble(),
        'varnishNeeded': varnishNeeded,
        'primerNeeded': primerNeeded,
        'plinthLength': plinthLength,
        'glueNeeded': glueNeeded,
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

