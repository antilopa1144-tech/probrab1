// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

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
class CalculateFence extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final length =
        getInput(inputs, 'length', defaultValue: 0.0, minValue: 0.0);
    final height =
        getInput(inputs, 'height', defaultValue: 2.0, minValue: 0.0);
    final materialType = getIntInput(
      inputs,
      'materialType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 4,
    );
    final gates =
        getIntInput(inputs, 'gates', defaultValue: 1, minValue: 0);
    final wickets =
        getIntInput(inputs, 'wickets', defaultValue: 1, minValue: 0);

    final fenceArea = length * height;

    double postSpacing;
    switch (materialType) {
      case 1:
        postSpacing = 2.5;
        break;
      case 2:
        postSpacing = 2.0;
        break;
      case 3:
        postSpacing = 3.0;
        break;
      case 4:
        postSpacing = 2.5;
        break;
      default:
        postSpacing = 2.5;
    }

    final postsNeeded = (length / postSpacing).ceil() + gates + wickets;

    final lagRows = height > 2.0 ? 3 : 2;
    final lagLength = length * lagRows;
    final lagCount = (lagLength / 6.0).ceil();

    double materialArea = fenceArea;
    if (materialType == 1) {
      const sheetWidth = 1.15;
      final sheetsNeeded = (length / sheetWidth * 1.1).ceil();
      materialArea = sheetsNeeded * sheetWidth * height;
    }

    double bricksNeeded = 0.0;
    double mortarNeeded = 0.0;
    if (materialType == 3) {
      bricksNeeded = fenceArea * 51 * 1.1;
      mortarNeeded = fenceArea * 0.02;
    }

    double foundationVolume = 0.0;
    if (materialType == 3) {
      foundationVolume = length * 0.3 * 0.5;
    }

    final fastenersNeeded = materialType == 1
        ? (fenceArea * 8).ceil()
        : materialType == 2
            ? (fenceArea * 12).ceil()
            : 0;

    final materialPrice = findPrice(
      priceList,
      materialType == 1
          ? ['profiled_sheet', 'corrugated_sheet', 'metal_sheet']
          : materialType == 2
              ? ['wood_fence', 'board', 'timber']
              : materialType == 3
                  ? ['brick', 'brick_facing']
                  : ['mesh', 'chain_link', 'wire_mesh'],
    )?.price;

    final postPrice = findPrice(
      priceList,
      ['fence_post', 'post', 'column'],
    )?.price;

    final lagPrice = findPrice(
      priceList,
      ['lag', 'crossbar', 'rail'],
    )?.price;

    final gatePrice = findPrice(
      priceList,
      ['gate', 'fence_gate'],
    )?.price;

    final wicketPrice = findPrice(
      priceList,
      ['wicket', 'fence_wicket'],
    )?.price;

    final brickPrice = findPrice(
      priceList,
      ['brick', 'brick_facing'],
    )?.price;

    final mortarPrice = findPrice(
      priceList,
      ['mortar', 'cement_mortar'],
    )?.price;

    final concretePrice = findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;
    if (materialType == 1 && materialPrice != null) {
      totalPrice = materialArea * materialPrice;
      if (postPrice != null) {
        totalPrice = totalPrice + postsNeeded * postPrice;
      }
      if (lagPrice != null) {
        totalPrice = totalPrice + lagCount * lagPrice;
      }
    } else if (materialType == 2 && materialPrice != null) {
      totalPrice = materialArea * materialPrice;
      if (postPrice != null) {
        totalPrice = totalPrice + postsNeeded * postPrice;
      }
      if (lagPrice != null) {
        totalPrice = totalPrice + lagCount * lagPrice;
      }
    } else if (materialType == 3 && brickPrice != null) {
      totalPrice = bricksNeeded * brickPrice;
      if (mortarPrice != null) {
        totalPrice = totalPrice + mortarNeeded * mortarPrice;
      }
      if (concretePrice != null && foundationVolume > 0) {
        totalPrice = totalPrice + foundationVolume * concretePrice;
      }
    } else if (materialType == 4 && materialPrice != null) {
      totalPrice = materialArea * materialPrice;
      if (postPrice != null) {
        totalPrice = totalPrice + postsNeeded * postPrice;
      }
    }

    if (gatePrice != null) {
      totalPrice = (totalPrice ?? 0) + gates * gatePrice;
    }
    if (wicketPrice != null) {
      totalPrice = (totalPrice ?? 0) + wickets * wicketPrice;
    }

    return createResult(
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
      calculatorId: 'fence',
    );
  }
}

