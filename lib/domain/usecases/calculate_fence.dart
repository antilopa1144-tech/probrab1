// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';

/// Калькулятор забора.
///
/// Нормативы:
/// - СНиП 30-02-97 "Планировка и застройка территорий садоводческих объединений"
///
/// Поля:
/// - length: длина забора (м)
/// - height: высота забора (м), по умолчанию 2.0
/// - materialType: тип материала (1 - профлист, 2 - дерево, 3 - кирпич, 4 - сетка)
/// - gates: количество ворот (шт), по умолчанию 1
/// - wickets: количество калиток (шт), по умолчанию 1
class CalculateFence implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final length = inputs['length'] ?? 0;
    final height = inputs['height'] ?? 2.0; // м
    final materialType = (inputs['materialType'] ?? 1.0).round();
    final gates = (inputs['gates'] ?? 1.0).round();
    final wickets = (inputs['wickets'] ?? 1.0).round();

    // Площадь забора
    final fenceArea = length * height;

    // Столбы: один столб на каждые 2-3 метра в зависимости от материала
    double postSpacing;
    switch (materialType) {
      case 1: // Профлист
        postSpacing = 2.5;
        break;
      case 2: // Дерево
        postSpacing = 2.0;
        break;
      case 3: // Кирпич
        postSpacing = 3.0;
        break;
      case 4: // Сетка
        postSpacing = 2.5;
        break;
      default:
        postSpacing = 2.5;
    }

    final postsNeeded = (length / postSpacing).ceil() + gates + wickets;

    // Лаги (поперечины): 2-3 ряда в зависимости от высоты
    final lagRows = height > 2.0 ? 3 : 2;
    final lagLength = length * lagRows;
    final lagCount = (lagLength / 6.0).ceil(); // стандартная длина лаги 6 м

    // Материал для заполнения (профлист, доски, кирпич, сетка)
    double materialArea = fenceArea;
    
    // Для профлиста учитываем стандартную ширину листа (1.15 м)
    if (materialType == 1) {
      final sheetWidth = 1.15; // м
      final sheetsNeeded = (length / sheetWidth * 1.1).ceil(); // +10% запас
      materialArea = sheetsNeeded * sheetWidth * height;
    }

    // Кирпич: расчёт количества кирпичей
    double bricksNeeded = 0.0;
    double mortarNeeded = 0.0;
    if (materialType == 3) {
      // Стандартный кирпич 250x120x65 мм
      // Кладка в полкирпича: 51 шт/м²
      bricksNeeded = fenceArea * 51 * 1.1; // +10% запас
      // Раствор: ~0.02 м³ на м² кладки
      mortarNeeded = fenceArea * 0.02;
    }

    // Фундамент для кирпичного забора
    double foundationVolume = 0.0;
    if (materialType == 3) {
      // Ленточный фундамент: ширина 0.3 м, глубина 0.5 м
      foundationVolume = length * 0.3 * 0.5;
    }

    // Саморезы/гвозди/крепеж
    final fastenersNeeded = materialType == 1
        ? (fenceArea * 8).ceil() // саморезы для профлиста
        : materialType == 2
            ? (fenceArea * 12).ceil() // гвозди для дерева
            : 0;

    // Цены
    final materialPrice = _findPrice(
      priceList,
      materialType == 1
          ? ['profiled_sheet', 'corrugated_sheet', 'metal_sheet']
          : materialType == 2
              ? ['wood_fence', 'board', 'timber']
              : materialType == 3
                  ? ['brick', 'brick_facing']
                  : ['mesh', 'chain_link', 'wire_mesh'],
    )?.price;

    final postPrice = _findPrice(
      priceList,
      ['fence_post', 'post', 'column'],
    )?.price;

    final lagPrice = _findPrice(
      priceList,
      ['lag', 'crossbar', 'rail'],
    )?.price;

    final gatePrice = _findPrice(
      priceList,
      ['gate', 'fence_gate'],
    )?.price;

    final wicketPrice = _findPrice(
      priceList,
      ['wicket', 'fence_wicket'],
    )?.price;

    final brickPrice = _findPrice(
      priceList,
      ['brick', 'brick_facing'],
    )?.price;

    final mortarPrice = _findPrice(
      priceList,
      ['mortar', 'cement_mortar'],
    )?.price;

    final concretePrice = _findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;
    if (materialType == 1 && materialPrice != null) {
      // Профлист
      totalPrice = materialArea * materialPrice;
      if (postPrice != null) {
        totalPrice = totalPrice + postsNeeded * postPrice;
      }
      if (lagPrice != null) {
        totalPrice = totalPrice + lagCount * lagPrice;
      }
    } else if (materialType == 2 && materialPrice != null) {
      // Дерево
      totalPrice = materialArea * materialPrice;
      if (postPrice != null) {
        totalPrice = totalPrice + postsNeeded * postPrice;
      }
      if (lagPrice != null) {
        totalPrice = totalPrice + lagCount * lagPrice;
      }
    } else if (materialType == 3 && brickPrice != null) {
      // Кирпич
      totalPrice = bricksNeeded * brickPrice;
      if (mortarPrice != null) {
        totalPrice = totalPrice + mortarNeeded * mortarPrice;
      }
      if (concretePrice != null && foundationVolume > 0) {
        totalPrice = totalPrice + foundationVolume * concretePrice;
      }
    } else if (materialType == 4 && materialPrice != null) {
      // Сетка
      totalPrice = materialArea * materialPrice;
      if (postPrice != null) {
        totalPrice = totalPrice + postsNeeded * postPrice;
      }
    }

    // Ворота и калитки
    if (gatePrice != null) {
      totalPrice = (totalPrice ?? 0) + gates * gatePrice;
    }
    if (wicketPrice != null) {
      totalPrice = (totalPrice ?? 0) + wickets * wicketPrice;
    }

    return CalculatorResult(
      values: {
        'length': length,
        'height': height,
        'fenceArea': fenceArea,
        'postsNeeded': postsNeeded.toDouble(),
        'lagCount': lagCount.toDouble(),
        'lagLength': lagLength,
        'materialArea': materialArea,
        'bricksNeeded': bricksNeeded,
        'mortarNeeded': mortarNeeded,
        'foundationVolume': foundationVolume,
        'gates': gates.toDouble(),
        'wickets': wickets.toDouble(),
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
