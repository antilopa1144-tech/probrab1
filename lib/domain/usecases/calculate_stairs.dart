// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

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
class CalculateStairs extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final floorHeight =
        getInput(inputs, 'floorHeight', defaultValue: 0.0, minValue: 0.0);
    final stepHeight =
        getInput(inputs, 'stepHeight', defaultValue: 0.18, minValue: 0.0);
    final stepWidth =
        getInput(inputs, 'stepWidth', defaultValue: 0.28, minValue: 0.0);
    var stepCount =
        getIntInput(inputs, 'stepCount', defaultValue: 0, minValue: 0);
    final width =
        getInput(inputs, 'width', defaultValue: 1.0, minValue: 0.0);
    final materialType = getIntInput(
      inputs,
      'materialType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );

    if (stepCount == 0 && floorHeight > 0 && stepHeight > 0) {
      stepCount = (floorHeight / stepHeight).round();
    }

    final flightLength =
        stepCount > 0 ? (stepCount - 1) * stepWidth : 0.0;
    final stepArea = stepCount * stepWidth * width;
    final riserArea = stepCount * stepHeight * width;
    final totalArea = stepArea + riserArea;

    final railingLength = flightLength + (floorHeight * 2);
    const balusterSpacing = 0.12;
    final balustersNeeded = (railingLength / balusterSpacing).ceil();
    final supportPosts = 2 + (railingLength / 2.0).ceil();
    final stringersNeeded = width > 1.2 ? 3 : 2;

    final concreteVolume = materialType == 2
        ? (stepArea * stepHeight * 0.5)
        : 0.0;

    final materialPrice = findPrice(
      priceList,
      materialType == 1
          ? ['wood_stairs', 'wood', 'timber']
          : materialType == 2
              ? ['concrete_stairs', 'concrete']
              : ['metal_stairs', 'metal', 'steel'],
    )?.price;
    final railingPrice = findPrice(
      priceList,
      ['railing', 'handrail', 'balustrade'],
    )?.price;
    final balusterPrice = findPrice(
      priceList,
      ['baluster', 'balustrade_post'],
    )?.price;
    final postPrice = findPrice(
      priceList,
      ['post', 'support_post', 'newel_post'],
    )?.price;
    final concretePrice = findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;
    if (materialType == 1 && materialPrice != null) {
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
      totalPrice = concreteVolume * concretePrice;
      if (materialPrice != null) {
        totalPrice = totalPrice + totalArea * materialPrice;
      }
    } else if (materialType == 3 && materialPrice != null) {
      totalPrice = totalArea * materialPrice * 1.5;
      if (railingPrice != null) {
        totalPrice = totalPrice + railingLength * railingPrice;
      }
    }

    return createResult(
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
      calculatorId: 'stairs',
    );
  }
}

