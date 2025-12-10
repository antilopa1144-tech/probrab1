// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';

/// Калькулятор утепления пола.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь пола (м²)
/// - insulationThickness: толщина утеплителя (мм), по умолчанию 100
/// - insulationType: тип утеплителя (1 - минвата, 2 - пенопласт, 3 - ЭППС)
class CalculateFloorInsulation extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final insulationThickness = inputs['insulationThickness'] ?? 100.0; // мм
    final insulationType = (inputs['insulationType'] ?? 1.0).round();
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? inputs['perimeter']!
        : (area > 0 ? estimatePerimeter(area) : 0.0);

    // Объём утеплителя в м³
    final volume = area * (insulationThickness / 1000);

    // Параметры утеплителя в зависимости от типа
    double sheetArea; // площадь одного листа/рулона в м²
    double density; // плотность в кг/м³
    
    switch (insulationType) {
      case 1: // Минвата
        sheetArea = 6.0; // стандартный лист 1x0.6 м
        density = 50.0;
        break;
      case 2: // Пенопласт
        sheetArea = 0.5; // лист 1x0.5 м
        density = 25.0;
        break;
      case 3: // ЭППС (экструдированный пенополистирол)
        sheetArea = 0.5; // лист 1x0.5 м
        density = 35.0;
        break;
      default:
        sheetArea = 6.0;
        density = 50.0;
    }

    // Количество листов/рулонов с запасом 10%
    final sheetsNeeded = (area / sheetArea * 1.1).ceil();

    // Вес утеплителя
    final weight = volume * density;

    // Пароизоляция: площадь пола + 10% на нахлёст
    final vaporBarrierArea = area * 1.1;

    // Гидроизоляция (для минваты обязательна)
    final waterproofingArea = insulationType == 1 ? area * 1.1 : 0.0;

    // Плинтус (если указан периметр)
    final plinthLength = perimeter > 0 ? perimeter : 0.0;

    // Крепёж: дюбеля для пенопласта/ЭППС (4-5 шт на м²)
    final fastenersNeeded = (insulationType == 2 || insulationType == 3)
        ? (area * 5).ceil()
        : 0;

    // Цены
    final insulationPrice = _findPrice(
      priceList,
      insulationType == 1
          ? ['insulation_mineral', 'mineral_wool', 'insulation']
          : insulationType == 2
              ? ['insulation_foam', 'foam', 'polystyrene']
              : ['insulation_eps', 'eps', 'xps'],
    )?.price;
    
    final vaporBarrierPrice = _findPrice(
      priceList,
      ['vapor_barrier', 'vapor_membrane', 'polyethylene'],
    )?.price;
    
    final waterproofingPrice = _findPrice(
      priceList,
      ['waterproofing', 'waterproofing_membrane'],
    )?.price;
    
    final plinthPrice = _findPrice(
      priceList,
      ['plinth', 'plinth_floor'],
    )?.price;

    double? totalPrice;
    if (insulationPrice != null) {
      totalPrice = sheetsNeeded * insulationPrice;
      
      if (vaporBarrierPrice != null) {
        totalPrice = totalPrice + vaporBarrierArea * vaporBarrierPrice;
      }
      
      if (waterproofingPrice != null && waterproofingArea > 0) {
        totalPrice = totalPrice + waterproofingArea * waterproofingPrice;
      }
      
      if (plinthPrice != null && plinthLength > 0) {
        totalPrice = totalPrice + plinthLength * plinthPrice;
      }
    }

    return CalculatorResult(
      values: {
        'area': area,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'weight': weight,
        'vaporBarrierArea': vaporBarrierArea,
        'waterproofingArea': waterproofingArea,
        'plinthLength': plinthLength,
        'fastenersNeeded': fastenersNeeded.toDouble(),
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
