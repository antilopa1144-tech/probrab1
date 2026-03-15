// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ленточного фундамента.
///
/// Поддерживает legacy perimeter/area path и screen-level contract:
/// - houseLength / houseWidth
/// - foundationType: 0=monolithic, 1=prefab, 2=shallow, 3=deep
/// - needWaterproof / needInsulation
/// - hasInternalWalls / internalWallsLength
///
/// Legacy поля сохранены:
/// - area / perimeter / concreteVolume / rebarWeight / formworkArea
/// - waterproofingArea / sandVolume / gravelVolume / cementBags
class CalculateStripFoundation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final houseLength = inputs['houseLength'] ?? 0;
    final houseWidth = inputs['houseWidth'] ?? 0;
    final area = inputs['area'] ?? 0;
    final perimeter = inputs['perimeter'] ?? 0;
    final width = inputs['width'] ?? 0;
    final height = inputs['height'] ?? 0;

    if ((houseLength <= 0 || houseWidth <= 0) && area <= 0 && perimeter <= 0) {
      return houseDimensionsAreaOrPerimeterRequiredMessage();
    }
    if (width <= 0 || width > 3) {
      return rangeMessage('width', 0.1, 3, unit: 'м');
    }
    if (height <= 0 || height > 3) {
      return rangeMessage('height', 0.1, 3, unit: 'м');
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final houseLengthInput = inputs['houseLength'] ?? 0.0;
    final houseWidthInput = inputs['houseWidth'] ?? 0.0;
    final hasHouseDimensions = houseLengthInput > 0 && houseWidthInput > 0;

    final houseLength = hasHouseDimensions
        ? getInput(inputs, 'houseLength', minValue: 1.0, maxValue: 100.0)
        : 0.0;
    final houseWidth = hasHouseDimensions
        ? getInput(inputs, 'houseWidth', minValue: 1.0, maxValue: 100.0)
        : 0.0;

    final inputPerimeter = inputs['perimeter'] ?? 0.0;
    final outerPerimeter = hasHouseDimensions
        ? 2 * (houseLength + houseWidth)
        : inputPerimeter > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1, maxValue: 10000.0)
        : estimatePerimeter(
            getInput(inputs, 'area', minValue: 0.1, maxValue: 10000.0),
          );

    final hasInternalWalls =
        getIntInput(inputs, 'hasInternalWalls', defaultValue: 0) != 0;
    final internalWallsLength = hasInternalWalls
        ? getInput(
            inputs,
            'internalWallsLength',
            defaultValue: 0.0,
            minValue: 0.0,
            maxValue: 500.0,
          )
        : 0.0;
    final perimeter = outerPerimeter + internalWallsLength;

    final inputArea = inputs['area'] ?? 0.0;
    final area = hasHouseDimensions
        ? houseLength * houseWidth
        : inputArea > 0
        ? getInput(inputs, 'area', minValue: 0.1, maxValue: 10000.0)
        : pow(outerPerimeter / 4, 2).toDouble();

    final width = getInput(
      inputs,
      'width',
      defaultValue: 0.4,
      minValue: 0.1,
      maxValue: 3.0,
    );
    final height = getInput(
      inputs,
      'height',
      defaultValue: 0.8,
      minValue: 0.1,
      maxValue: 3.0,
    );
    final foundationType = getIntInput(
      inputs,
      'foundationType',
      defaultValue: 0,
      minValue: 0,
      maxValue: 3,
    );
    final needWaterproof =
        getIntInput(inputs, 'needWaterproof', defaultValue: 1) != 0;
    final needInsulation =
        getIntInput(inputs, 'needInsulation', defaultValue: 0) != 0;

    final stripVolume = perimeter * width * height;

    double concreteVolume = stripVolume * 1.05;
    double rebarWeight = 0.0;
    double formworkArea = 0.0;
    int fbsBlocksCount = 0;

    if (foundationType == 1) {
      const fbsVolume = 2.4 * 0.6 * 0.58;
      fbsBlocksCount = (stripVolume / fbsVolume).ceil();
      concreteVolume = fbsBlocksCount * 0.02;
    } else {
      rebarWeight = stripVolume * 80;
      formworkArea = perimeter * height * 2;
    }

    final waterproofingArea = needWaterproof
        ? perimeter * (width + height * 2) * 1.1
        : 0.0;
    final insulationArea = needInsulation ? outerPerimeter * height * 1.1 : 0.0;

    final cushionArea = perimeter * (width + 0.2);
    final sandVolume = cushionArea * 0.15;
    final gravelVolume = cushionArea * 0.10;
    final cementBags = (stripVolume * 6.6).ceil();
    final longitudinalBars = foundationType == 1 ? 0 : 6;
    final longitudinalLength = perimeter * longitudinalBars;

    final concretePrice = findPrice(priceList, [
      'concrete_m300',
      'concrete_m250',
      'concrete',
    ]);
    final rebarPrice = findPrice(priceList, [
      'rebar',
      'rebar_12mm',
      'reinforcement',
    ]);
    final formworkPrice = findPrice(priceList, ['formwork', 'plywood']);
    final waterproofingPrice = findPrice(priceList, [
      'waterproofing',
      'film_pe',
      'bitumen',
    ]);
    final sandPrice = findPrice(priceList, ['sand', 'sand_construction']);
    final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone']);
    final fbsPrice = findPrice(priceList, [
      'fbs',
      'fbs_24_6_6',
      'foundation_block',
    ]);

    final costs = foundationType == 1
        ? [
            calculateCost(fbsBlocksCount.toDouble(), fbsPrice?.price),
            calculateCost(concreteVolume, concretePrice?.price),
            calculateCost(sandVolume, sandPrice?.price),
            calculateCost(gravelVolume, gravelPrice?.price),
            calculateCost(waterproofingArea, waterproofingPrice?.price),
          ]
        : [
            calculateCost(concreteVolume, concretePrice?.price),
            calculateCost(rebarWeight, rebarPrice?.price),
            calculateCost(formworkArea, formworkPrice?.price),
            calculateCost(waterproofingArea, waterproofingPrice?.price),
            calculateCost(sandVolume, sandPrice?.price),
            calculateCost(gravelVolume, gravelPrice?.price),
          ];

    return createResult(
      values: {
        'foundationType': foundationType.toDouble(),
        'area': area,
        'perimeter': perimeter,
        'outerPerimeter': outerPerimeter,
        'houseLength': houseLength,
        'houseWidth': houseWidth,
        'hasInternalWalls': hasInternalWalls ? 1.0 : 0.0,
        'internalWallsLength': internalWallsLength,
        'width': width,
        'height': height,
        'stripVolume': stripVolume,
        'concreteVolume': concreteVolume,
        'rebarWeight': rebarWeight,
        'longitudinalBars': longitudinalBars.toDouble(),
        'longitudinalLength': longitudinalLength,
        'formworkArea': formworkArea,
        'waterproofingArea': waterproofingArea,
        'insulationArea': insulationArea,
        'sandVolume': sandVolume,
        'gravelVolume': gravelVolume,
        'cementBags': cementBags.toDouble(),
        'fbsBlocksCount': fbsBlocksCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
