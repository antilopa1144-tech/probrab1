import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор подвала/погреба.
///
/// Нормативы:
/// - СНиП 2.02.01-83 "Основания зданий и сооружений"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь подвала (м²)
/// - height: высота подвала (м), по умолчанию 2.5
/// - wallThickness: толщина стен (м), по умолчанию 0.4
/// - materialType: материал стен (1 - бетон, 2 - кирпич, 3 - блоки)
/// - waterproofing: гидроизоляция (0 - нет, 1 - да)
/// - insulation: утепление (0 - нет, 1 - да)
/// - ventilation: вентиляция (0 - нет, 1 - да)
class CalculateBasement implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final height = inputs['height'] ?? 2.5; // м
    final wallThickness = inputs['wallThickness'] ?? 0.4; // м
    final materialType = (inputs['materialType'] ?? 1.0).round();
    final waterproofing = (inputs['waterproofing'] ?? 1.0).round();
    final insulation = (inputs['insulation'] ?? 0.0).round();
    final ventilation = (inputs['ventilation'] ?? 1.0).round();

    // Объём подвала
    final volume = area * height;

    // Периметр (приблизительно, если не указан)
    final perimeter = inputs['perimeter'] ?? (4 * (area / 4).sqrt());

    // Площадь стен
    final wallArea = perimeter * height;

    // Объём стен
    final wallVolume = wallArea * wallThickness;

    // Площадь пола
    final floorArea = area;

    // Объём бетона для стен (если бетонные)
    double concreteVolume = 0.0;
    if (materialType == 1) {
      concreteVolume = wallVolume;
    }

    // Кирпич для стен
    double bricksNeeded = 0.0;
    double mortarNeeded = 0.0;
    if (materialType == 2) {
      // Кладка в 1.5 кирпича: ~153 шт/м² при толщине 38 см
      bricksNeeded = wallArea * 153 * 1.1; // +10% запас
      mortarNeeded = wallArea * 0.03; // м³ раствора на м²
    }

    // Блоки для стен
    double blocksNeeded = 0.0;
    if (materialType == 3) {
      // Газоблок 600x300x400 мм = 0.072 м²
      final blockArea = 0.072; // м²
      blocksNeeded = (wallArea / blockArea * 1.1).ceil().toDouble();
    }

    // Бетон для пола (стяжка 10 см)
    final floorConcreteVolume = floorArea * 0.1;

    // Гидроизоляция
    final waterproofingArea = waterproofing == 1
        ? (floorArea + wallArea) * 1.1 // +10% на нахлёст
        : 0.0;

    // Утепление (если требуется)
    final insulationArea = insulation == 1 ? wallArea * 1.1 : 0.0;
    final insulationVolume = insulation == 1 ? wallArea * 0.1 : 0.0; // 10 см утеплителя

    // Армирование для бетонных стен
    double rebarNeeded = 0.0;
    if (materialType == 1) {
      rebarNeeded = wallArea * 12; // кг/м²
    }

    // Вентиляция: трубы и решётки
    final ventilationPipes = ventilation == 1 ? 2.0 : 0.0; // приточная и вытяжная
    final ventilationGrilles = ventilation == 1 ? 2.0 : 0.0;

    // Лестница (если нужна)
    final stairsNeeded = inputs['stairs'] ?? 1.0;

    // Цены
    final concretePrice = _findPrice(
      priceList,
      ['concrete', 'concrete_m300', 'concrete_m200'],
    )?.price;

    final brickPrice = _findPrice(
      priceList,
      ['brick', 'brick_facing'],
    )?.price;

    final blockPrice = _findPrice(
      priceList,
      ['gas_block', 'foam_block', 'block'],
    )?.price;

    final mortarPrice = _findPrice(
      priceList,
      ['mortar', 'cement_mortar'],
    )?.price;

    final waterproofingPrice = _findPrice(
      priceList,
      ['waterproofing', 'waterproofing_membrane', 'bitumen'],
    )?.price;

    final insulationPrice = _findPrice(
      priceList,
      ['insulation_eps', 'eps', 'xps', 'insulation'],
    )?.price;

    final rebarPrice = _findPrice(
      priceList,
      ['rebar', 'reinforcement', 'rebar_12'],
    )?.price;

    double? totalPrice;

    // Стены
    if (materialType == 1 && concretePrice != null) {
      // Бетонные стены
      totalPrice = concreteVolume * concretePrice;
      if (rebarPrice != null) {
        totalPrice = totalPrice! + rebarNeeded * rebarPrice;
      }
    } else if (materialType == 2 && brickPrice != null) {
      // Кирпичные стены
      totalPrice = bricksNeeded * brickPrice;
      if (mortarPrice != null) {
        totalPrice = totalPrice! + mortarNeeded * mortarPrice;
      }
    } else if (materialType == 3 && blockPrice != null) {
      // Блочные стены
      totalPrice = blocksNeeded * blockPrice;
    }

    // Пол
    if (concretePrice != null) {
      totalPrice = (totalPrice ?? 0) + floorConcreteVolume * concretePrice;
    }

    // Гидроизоляция
    if (waterproofingPrice != null && waterproofingArea > 0) {
      totalPrice = (totalPrice ?? 0) + waterproofingArea * waterproofingPrice;
    }

    // Утепление
    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'height': height,
        'volume': volume,
        'perimeter': perimeter,
        'wallArea': wallArea,
        'wallVolume': wallVolume,
        'floorArea': floorArea,
        'concreteVolume': concreteVolume + floorConcreteVolume,
        'bricksNeeded': bricksNeeded,
        'blocksNeeded': blocksNeeded,
        'mortarNeeded': mortarNeeded,
        'waterproofingArea': waterproofingArea,
        'insulationArea': insulationArea,
        'insulationVolume': insulationVolume,
        'rebarNeeded': rebarNeeded,
        'ventilationPipes': ventilationPipes,
        'ventilationGrilles': ventilationGrilles,
        'stairsNeeded': stairsNeeded,
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
