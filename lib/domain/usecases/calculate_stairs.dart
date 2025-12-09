// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';

/// Калькулятор лестницы.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - СП 1.13130.2009 "Системы противопожарной защиты"
///
/// Поля:
/// - floorHeight: высота между этажами (м)
/// - stepHeight: высота ступени (м), по умолчанию 0.18
/// - stepWidth: ширина проступи (м), по умолчанию 0.28
/// - stepCount: количество ступеней (если 0, рассчитывается автоматически)
/// - width: ширина лестницы (м), по умолчанию 1.0
/// - materialType: тип материала (1 - дерево, 2 - бетон, 3 - металл)
class CalculateStairs implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final floorHeight = inputs['floorHeight'] ?? 0;
    final stepHeight = inputs['stepHeight'] ?? 0.18; // м
    final stepWidth = inputs['stepWidth'] ?? 0.28; // м
    var stepCount = (inputs['stepCount'] ?? 0).round();
    final width = inputs['width'] ?? 1.0; // м
    final materialType = (inputs['materialType'] ?? 1.0).round();

    // Если количество ступеней не указано, рассчитываем
    if (stepCount == 0 && floorHeight > 0 && stepHeight > 0) {
      stepCount = (floorHeight / stepHeight).round();
    }

    // Длина марша лестницы
    final flightLength = stepCount > 0 ? (stepCount - 1) * stepWidth : 0.0;

    // Площадь ступеней
    final stepArea = stepCount * stepWidth * width;

    // Площадь подступенков (вертикальная часть)
    final riserArea = stepCount * stepHeight * width;

    // Общая площадь отделки
    final totalArea = stepArea + riserArea;

    // Перила: длина = длина марша + высота * 2 (для двух сторон)
    final railingLength = flightLength + (floorHeight * 2);

    // Балясины: одна на каждые 10-15 см перил
    const balusterSpacing = 0.12; // м
    final balustersNeeded = (railingLength / balusterSpacing).ceil();

    // Опорные столбы: минимум 2 (в начале и конце), плюс один на каждые 2 метра
    final supportPosts = 2 + (railingLength / 2.0).ceil();

    // Косоуры/тетивы (несущие балки): 2-3 штуки в зависимости от ширины
    final stringersNeeded = width > 1.2 ? 3 : 2;

    // Объём бетона (для бетонной лестницы)
    final concreteVolume = materialType == 2
        ? (stepArea * stepHeight * 0.5) // примерный объём
        : 0.0;

    // Цены
    final materialPrice = _findPrice(
      priceList,
      materialType == 1
          ? ['wood_stairs', 'wood', 'timber']
          : materialType == 2
              ? ['concrete_stairs', 'concrete']
              : ['metal_stairs', 'metal', 'steel'],
    )?.price;

    final railingPrice = _findPrice(
      priceList,
      ['railing', 'handrail', 'balustrade'],
    )?.price;

    final balusterPrice = _findPrice(
      priceList,
      ['baluster', 'balustrade_post'],
    )?.price;

    final postPrice = _findPrice(
      priceList,
      ['post', 'support_post', 'newel_post'],
    )?.price;

    final concretePrice = _findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;
    if (materialType == 1 && materialPrice != null) {
      // Деревянная лестница
      totalPrice = totalArea * materialPrice;
      if (railingPrice != null) {
        totalPrice = totalPrice + railingLength * railingPrice;
      }
      if (balusterPrice != null) {
        totalPrice = totalPrice + balustersNeeded * balusterPrice;
      }
      if (postPrice != null) {
        totalPrice = totalPrice + supportPosts * postPrice;
      }
    } else if (materialType == 2 && concretePrice != null) {
      // Бетонная лестница
      totalPrice = concreteVolume * concretePrice;
      if (materialPrice != null) {
        // Отделка бетонной лестницы
        totalPrice = totalPrice + totalArea * materialPrice;
      }
    } else if (materialType == 3 && materialPrice != null) {
      // Металлическая лестница
      totalPrice = totalArea * materialPrice * 1.5; // металл дороже
      if (railingPrice != null) {
        totalPrice = totalPrice + railingLength * railingPrice;
      }
    }

    return CalculatorResult(
      values: {
        'floorHeight': floorHeight,
        'stepCount': stepCount.toDouble(),
        'stepHeight': stepHeight,
        'stepWidth': stepWidth,
        'flightLength': flightLength,
        'stepArea': stepArea,
        'totalArea': totalArea,
        'railingLength': railingLength,
        'balustersNeeded': balustersNeeded.toDouble(),
        'supportPosts': supportPosts.toDouble(),
        'stringersNeeded': stringersNeeded.toDouble(),
        'concreteVolume': concreteVolume,
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
