import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор тёплого пола (электрический).
///
/// Нормативы:
/// - СНиП 41-01-2003 "Отопление, вентиляция и кондиционирование"
/// - ГОСТ Р 50571.7.701-2013 "Электроустановки зданий"
///
/// Поля:
/// - area: площадь пола (м²)
/// - power: мощность на м² (Вт/м²), по умолчанию 150
/// - type: тип (1=кабель, 2=мат), по умолчанию 2
class CalculateWarmFloor implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final power = inputs['power'] ?? 150.0; // Вт/м²
    final type = (inputs['type'] ?? 2).round(); // 1=кабель, 2=мат

    // Полезная площадь (без учёта мебели, обычно 70% от общей)
    final usefulArea = area * 0.7;

    // Общая мощность
    final totalPower = usefulArea * power; // Вт

    // Кабель или мат
    final cableLength = type == 1 ? usefulArea * 4 : 0.0; // м для кабеля
    final matArea = type == 2 ? usefulArea : 0.0; // м² для мата

    // Терморегулятор: 1 шт на комнату
    final thermostats = (inputs['thermostats'] ?? 1).round();

    // Теплоизоляция: площадь пола
    final insulationArea = area;

    // Цены
    final cablePrice = _findPrice(priceList, ['warm_floor_cable', 'cable_heating'])?.price;
    final matPrice = _findPrice(priceList, ['warm_floor_mat', 'mat_heating'])?.price;
    final thermostatPrice = _findPrice(priceList, ['thermostat', 'thermostat_floor'])?.price;
    final insulationPrice = _findPrice(priceList, ['insulation_foil', 'foil_insulation'])?.price;

    double? totalPrice;
    if (type == 1 && cablePrice != null) {
      totalPrice = cableLength * cablePrice;
    } else if (type == 2 && matPrice != null) {
      totalPrice = matArea * matPrice;
    }

    if (thermostatPrice != null) {
      totalPrice = (totalPrice ?? 0) + thermostats * thermostatPrice;
    }
    if (insulationPrice != null) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'usefulArea': usefulArea,
        'totalPower': totalPower,
        'cableLength': cableLength.toDouble(),
        'matArea': matArea.toDouble(),
        'thermostats': thermostats.toDouble(),
        'insulationArea': insulationArea,
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

