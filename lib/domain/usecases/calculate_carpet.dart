import 'dart:math';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор ковролина.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь пола (м²)
/// - rollWidth: ширина рулона (м), по умолчанию 4.0
/// - rollLength: длина рулона (м), по умолчанию 25.0
/// - perimeter: периметр комнаты (м)
class CalculateCarpet implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final rollWidth = inputs['rollWidth'] ?? 4.0; // м
    final rollLength = inputs['rollLength'] ?? 25.0; // м
    final perimeter = inputs['perimeter'] ?? (4 * sqrt(area / 4));

    // Площадь рулона
    final rollArea = rollWidth * rollLength;

    // Количество рулонов с запасом 10%
    final rollsNeeded = (area / rollArea * 1.1).ceil();

    // Плинтус: периметр
    final plinthLength = perimeter;

    // Двухсторонний скотч: периметр + диагонали
    final tapeLength = perimeter * 1.2; // +20% на углы

    // Подложка: площадь пола
    final underlayArea = area;

    // Цены
    final carpetPrice = _findPrice(priceList, ['carpet', 'carpet_roll'])?.price;
    final plinthPrice = _findPrice(priceList, ['plinth', 'plinth_carpet'])?.price;
    final tapePrice = _findPrice(priceList, ['tape_double', 'tape_carpet'])?.price;
    final underlayPrice = _findPrice(priceList, ['underlay', 'underlay_carpet'])?.price;

    double? totalPrice;
    if (carpetPrice != null) {
      totalPrice = rollsNeeded * carpetPrice;
      if (plinthPrice != null) {
        totalPrice = totalPrice + plinthLength * plinthPrice;
      }
      if (tapePrice != null) {
        totalPrice = totalPrice + tapeLength * tapePrice;
      }
      if (underlayPrice != null) {
        totalPrice = totalPrice + underlayArea * underlayPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'rollsNeeded': rollsNeeded.toDouble(),
        'plinthLength': plinthLength,
        'tapeLength': tapeLength,
        'underlayArea': underlayArea,
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

