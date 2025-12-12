// ignore_for_file: prefer_const_declarations
import 'dart:math';

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор террасы/веранды.
///
/// Нормативы:
/// - СНиП 2.01.07-85 "Нагрузки и воздействия"
/// - СП 20.13330.2016 "Нагрузки и воздействия"
///
/// Поля:
/// - area: площадь террасы (м2)
/// - floorType: тип покрытия пола (1 - декинг, 2 - плитка, 3 - настил)
/// - railing: ограждение (0 - нет, 1 - да)
/// - roof: кровля (0 - нет, 1 - да)
/// - roofType: тип кровли (1 - поликарбонат, 2 - профлист, 3 - мягкая кровля)
class CalculateTerrace extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area =
        getInput(inputs, 'area', defaultValue: 0.0, minValue: 0.0);
    final perimeter = _resolvePerimeter(inputs, area);
    final floorType = getIntInput(
      inputs,
      'floorType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final railing = getIntInput(
      inputs,
      'railing',
      defaultValue: 1,
      minValue: 0,
      maxValue: 1,
    );
    final roof =
        getIntInput(inputs, 'roof', defaultValue: 0, minValue: 0, maxValue: 1);
    final roofType = getIntInput(
      inputs,
      'roofType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );

    final floorArea = area;

    double deckingArea = 0.0;
    double tilesNeeded = 0.0;
    double deckingBoards = 0.0;

    if (floorType == 1) {
      deckingArea = floorArea * 1.1;
    } else if (floorType == 2) {
      const tileArea = 0.25;
      tilesNeeded = (floorArea / tileArea * 1.1).ceil().toDouble();
    } else if (floorType == 3) {
      const boardArea = 0.1;
      deckingBoards = (floorArea / boardArea * 1.1).ceil().toDouble();
    }

    final railingLength = railing == 1 && perimeter > 0 ? perimeter : 0.0;
    final railingPosts = (railing == 1 && perimeter > 0
            ? (perimeter / 2.0).ceil()
            : 0)
        .toDouble();

    double roofArea = 0.0;
    double polycarbonateSheets = 0.0;
    double profiledSheets = 0.0;
    double roofingMaterial = 0.0;

    if (roof == 1) {
      roofArea = area * 1.2;

      if (roofType == 1) {
        const sheetArea = 6.0;
        polycarbonateSheets =
            (roofArea / sheetArea * 1.1).ceil().toDouble();
      } else if (roofType == 2) {
        const sheetArea = 8.0;
        profiledSheets =
            (roofArea / sheetArea * 1.1).ceil().toDouble();
      } else if (roofType == 3) {
        roofingMaterial = roofArea * 1.1;
      }
    }

    final roofPosts = (roof == 1 ? (area / 9.0).ceil() : 0).toDouble();
    final foundationVolume = roof == 1
        ? roofPosts * 0.2 * 0.2 * 0.5
        : 0.0;

    final deckingPrice = findPrice(
      priceList,
      ['decking', 'terrace_board', 'composite_decking'],
    )?.price;
    final tilePrice = findPrice(
      priceList,
      ['tile', 'tile_porcelain', 'tile_outdoor'],
    )?.price;
    final boardPrice = findPrice(
      priceList,
      ['board', 'wood', 'timber'],
    )?.price;
    final railingPrice = findPrice(
      priceList,
      ['railing', 'terrace_railing', 'balustrade'],
    )?.price;
    final postPrice = findPrice(
      priceList,
      ['post', 'support_post', 'column'],
    )?.price;
    final polycarbonatePrice = findPrice(
      priceList,
      ['polycarbonate', 'polycarbonate_sheet'],
    )?.price;
    final profiledSheetPrice = findPrice(
      priceList,
      ['profiled_sheet', 'corrugated_sheet'],
    )?.price;
    final roofingPrice = findPrice(
      priceList,
      ['soft_roofing', 'roofing_material'],
    )?.price;
    final concretePrice = findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;

    if (floorType == 1 && deckingPrice != null) {
      totalPrice = deckingArea * deckingPrice;
    } else if (floorType == 2 && tilePrice != null) {
      totalPrice = tilesNeeded * tilePrice;
    } else if (floorType == 3 && boardPrice != null) {
      totalPrice = deckingBoards * boardPrice;
    }

    if (railingPrice != null && railingLength > 0) {
      totalPrice = (totalPrice ?? 0) + railingLength * railingPrice;
    }
    if (postPrice != null && railingPosts > 0) {
      totalPrice = (totalPrice ?? 0) + railingPosts * postPrice;
    }

    if (roofType == 1 &&
        polycarbonatePrice != null &&
        polycarbonateSheets > 0) {
      totalPrice =
          (totalPrice ?? 0) + polycarbonateSheets * polycarbonatePrice;
    } else if (roofType == 2 &&
        profiledSheetPrice != null &&
        profiledSheets > 0) {
      totalPrice =
          (totalPrice ?? 0) + profiledSheets * profiledSheetPrice;
    } else if (roofType == 3 && roofingPrice != null && roofingMaterial > 0) {
      totalPrice = (totalPrice ?? 0) + roofingMaterial * roofingPrice;
    }

    if (postPrice != null && roofPosts > 0) {
      totalPrice = (totalPrice ?? 0) + roofPosts * postPrice;
    }

    if (concretePrice != null && foundationVolume > 0) {
      totalPrice =
          (totalPrice ?? 0) + foundationVolume * concretePrice;
    }

    return createResult(
      values: {
        'area': area,
        'floorArea': floorArea,
        'deckingArea': deckingArea,
        'tilesNeeded': tilesNeeded,
        'deckingBoards': deckingBoards,
        'railingLength': railingLength,
        'railingPosts': railingPosts,
        'roofArea': roofArea,
        'polycarbonateSheets': polycarbonateSheets,
        'profiledSheets': profiledSheets,
        'roofingMaterial': roofingMaterial,
        'roofPosts': roofPosts,
        'foundationVolume': foundationVolume,
      },
      totalPrice: totalPrice,
      calculatorId: 'terrace',
    );
  }

  double _resolvePerimeter(Map<String, double> inputs, double area) {
    final perimeterInput = inputs['perimeter'] ?? 0.0;
    if (perimeterInput > 0) return perimeterInput;
    if (area <= 0) return 0.0;
    return sqrt(area) * 4;
  }
}

