import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор мокрого фасада (утепление + штукатурка).
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - СП 23-101-2004 "Проектирование тепловой защиты зданий"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - insulationThickness: толщина утеплителя (мм), по умолчанию 100
/// - insulationType: тип утеплителя (1=минвата, 2=пенопласт), по умолчанию 2
class CalculateWetFacade implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final insulationThickness = inputs['insulationThickness'] ?? 100.0; // мм
    final insulationType = (inputs['insulationType'] ?? 2).round();

    // Утеплитель
    final insulationArea = area;
    final insulationVolume = area * (insulationThickness / 1000);

    // Площадь одного листа утеплителя (стандарт: 0.5 м² для пенопласта, 0.72 м² для минваты)
    final sheetArea = insulationType == 1 ? 0.72 : 0.5;
    final sheetsNeeded = (insulationArea / sheetArea * 1.05).ceil();

    // Клей для утеплителя: ~5 кг/м²
    final glueNeeded = area * 5.0;

    // Крепёж: дюбели-грибки, ~5 шт/м²
    final fastenersNeeded = (area * 5).ceil();

    // Армирующая сетка: площадь + 10%
    final meshArea = area * 1.1;

    // Штукатурка: ~5 кг/м²
    final plasterNeeded = area * 5.0;

    // Грунтовка: ~0.2 кг/м²
    final primerNeeded = area * 0.2;

    // Декоративная штукатурка/краска: ~0.5 кг/м²
    final finishNeeded = area * 0.5;

    // Цены
    final insulationPrice = insulationType == 1
        ? _findPrice(priceList, ['mineral_wool', 'wool_insulation'])?.price
        : _findPrice(priceList, ['foam', 'foam_insulation', 'eps'])?.price;
    final gluePrice = _findPrice(priceList, ['glue_insulation', 'glue_foam'])?.price;
    final fastenerPrice = _findPrice(priceList, ['fastener_insulation', 'dowel_umbrella'])?.price;
    final meshPrice = _findPrice(priceList, ['mesh_armor', 'mesh_facade'])?.price;
    final plasterPrice = _findPrice(priceList, ['plaster_facade', 'plaster'])?.price;
    final primerPrice = _findPrice(priceList, ['primer', 'primer_facade'])?.price;
    final finishPrice = _findPrice(priceList, ['finish_plaster', 'paint_facade'])?.price;

    double? totalPrice;
    if (insulationPrice != null) {
      totalPrice = sheetsNeeded * insulationPrice;
      if (gluePrice != null) {
        totalPrice = totalPrice + glueNeeded * gluePrice;
      }
      if (fastenerPrice != null) {
        totalPrice = totalPrice + fastenersNeeded * fastenerPrice;
      }
      if (meshPrice != null) {
        totalPrice = totalPrice + meshArea * meshPrice;
      }
      if (plasterPrice != null) {
        totalPrice = totalPrice + plasterNeeded * plasterPrice;
      }
      if (primerPrice != null) {
        totalPrice = totalPrice + primerNeeded * primerPrice;
      }
      if (finishPrice != null) {
        totalPrice = totalPrice + finishNeeded * finishPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'insulationVolume': insulationVolume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'meshArea': meshArea,
        'plasterNeeded': plasterNeeded,
        'primerNeeded': primerNeeded,
        'finishNeeded': finishNeeded,
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

