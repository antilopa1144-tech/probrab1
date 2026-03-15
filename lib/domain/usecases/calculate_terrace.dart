// ignore_for_file: prefer_const_declarations

import '../../data/models/price_item.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';

class CalculateTerrace extends BaseCalculator {
  bool _hasScreenInputs(Map<String, double> inputs) {
    return inputs.containsKey('inputMode') ||
        inputs.containsKey('length') ||
        inputs.containsKey('width');
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasScreenInputs(inputs)) {
      return _calculateScreenPath(inputs, priceList);
    }
    return _calculateLegacyPath(inputs, priceList);
  }

  CalculatorResult _calculateLegacyPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', defaultValue: 0.0, minValue: 0.0);
    final perimeter = _resolvePerimeter(inputs, area);
    return _calculateCore(
      area: area,
      perimeter: perimeter,
      floorType: getIntInput(inputs, 'floorType', defaultValue: 1, minValue: 1, maxValue: 7),
      railing: getIntInput(inputs, 'railing', defaultValue: 1, minValue: 0, maxValue: 1) == 1,
      roof: getIntInput(inputs, 'roof', defaultValue: 0, minValue: 0, maxValue: 1) == 1,
      roofType: getIntInput(inputs, 'roofType', defaultValue: 1, minValue: 1, maxValue: 6),
      inputMode: 0,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateScreenPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0, minValue: 0, maxValue: 1);
    final area = inputMode == 0
        ? getInput(inputs, 'area', defaultValue: 18.0, minValue: 4.0, maxValue: 200.0)
        : getInput(inputs, 'length', defaultValue: 5.0, minValue: 1.0, maxValue: 20.0) *
            getInput(inputs, 'width', defaultValue: 4.0, minValue: 1.0, maxValue: 20.0);
    final perimeter = inputMode == 1
        ? (getInput(inputs, 'length', defaultValue: 5.0, minValue: 1.0, maxValue: 20.0) +
                getInput(inputs, 'width', defaultValue: 4.0, minValue: 1.0, maxValue: 20.0)) *
            2
        : _resolvePerimeter(inputs, area);

    return _calculateCore(
      area: area,
      perimeter: perimeter,
      floorType: getIntInput(inputs, 'floorType', defaultValue: 1, minValue: 1, maxValue: 7),
      railing: getIntInput(inputs, 'railing', defaultValue: 1, minValue: 0, maxValue: 1) == 1,
      roof: getIntInput(inputs, 'roof', defaultValue: 0, minValue: 0, maxValue: 1) == 1,
      roofType: getIntInput(inputs, 'roofType', defaultValue: 1, minValue: 1, maxValue: 6),
      inputMode: inputMode,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateCore({
    required double area,
    required double perimeter,
    required int floorType,
    required bool railing,
    required bool roof,
    required int roofType,
    required int inputMode,
    required List<PriceItem> priceList,
  }) {
    final floorArea = area;

    double deckingArea = 0.0;
    double tilesNeeded = 0.0;
    double deckingBoards = 0.0;

    switch (floorType) {
      case 1:
        deckingArea = floorArea * 1.1;
        break;
      case 2:
        const tileArea = 0.25;
        tilesNeeded = (floorArea / tileArea * 1.1).ceil().toDouble();
        break;
      case 3:
        const boardArea = 0.1;
        deckingBoards = (floorArea / boardArea * 1.1).ceil().toDouble();
        break;
      case 4:
        const porcelainArea = 0.36;
        tilesNeeded = (floorArea / porcelainArea * 1.1).ceil().toDouble();
        break;
      case 5:
        deckingArea = floorArea * 1.1;
        break;
      case 6:
        deckingArea = floorArea * 1.1 * 1.15;
        break;
      case 7:
        const rubberArea = 0.25;
        tilesNeeded = (floorArea / rubberArea * 1.1).ceil().toDouble();
        break;
    }

    final railingLength = railing && perimeter > 0 ? perimeter : 0.0;
    final railingPosts = (railing && perimeter > 0 ? (perimeter / 2.0).ceil() : 0).toDouble();

    double roofArea = 0.0;
    double polycarbonateSheets = 0.0;
    double profiledSheets = 0.0;
    double roofingMaterial = 0.0;

    if (roof) {
      roofArea = area * 1.2;
      switch (roofType) {
        case 1:
          const sheetArea = 6.0;
          polycarbonateSheets = (roofArea / sheetArea * 1.1).ceil().toDouble();
          break;
        case 2:
          const sheetArea = 8.0;
          profiledSheets = (roofArea / sheetArea * 1.1).ceil().toDouble();
          break;
        case 3:
          roofingMaterial = roofArea * 1.1;
          break;
        case 4:
          const ondSheetArea = 1.9;
          profiledSheets = (roofArea / ondSheetArea * 1.15).ceil().toDouble();
          break;
        case 5:
          roofingMaterial = roofArea * 1.2;
          break;
        case 6:
          const glassSheetArea = 2.0;
          polycarbonateSheets = (roofArea / glassSheetArea * 1.1).ceil().toDouble();
          break;
      }
    }

    final roofPosts = (roof ? (area / 9.0).ceil() : 0).toDouble();
    final foundationVolume = roof ? roofPosts * 0.2 * 0.2 * 0.5 : 0.0;

    final deckingPrice = findPrice(priceList, ['decking', 'terrace_board', 'composite_decking'])?.price;
    final tilePrice = findPrice(priceList, ['tile', 'tile_porcelain', 'tile_outdoor'])?.price;
    final boardPrice = findPrice(priceList, ['board', 'wood', 'timber'])?.price;
    final porcelainPrice = findPrice(priceList, ['porcelain_tile', 'tile_porcelain', 'porcelain'])?.price;
    final wpcPrice = findPrice(priceList, ['wpc', 'composite_decking', 'wood_plastic_composite'])?.price;
    final solidWoodPrice = findPrice(priceList, ['solid_wood', 'larch', 'oak', 'hardwood'])?.price;
    final rubberTilesPrice = findPrice(priceList, ['rubber_tiles', 'rubber_flooring', 'modular_rubber'])?.price;
    final railingPrice = findPrice(priceList, ['railing', 'terrace_railing', 'balustrade'])?.price;
    final postPrice = findPrice(priceList, ['post', 'support_post', 'column'])?.price;
    final polycarbonatePrice = findPrice(priceList, ['polycarbonate', 'polycarbonate_sheet'])?.price;
    final profiledSheetPrice = findPrice(priceList, ['profiled_sheet', 'corrugated_sheet'])?.price;
    final roofingPrice = findPrice(priceList, ['soft_roofing', 'roofing_material'])?.price;
    final ondulinPrice = findPrice(priceList, ['ondulin', 'ondulina', 'bitumen_sheet'])?.price;
    final metalTilePrice = findPrice(priceList, ['metal_tile', 'metal_roofing', 'metallocherepitsa'])?.price;
    final glassPrice = findPrice(priceList, ['glass', 'tempered_glass', 'glass_roof'])?.price;
    final concretePrice = findPrice(priceList, ['concrete', 'concrete_m300'])?.price;

    double? totalPrice;

    switch (floorType) {
      case 1:
        if (deckingPrice != null) totalPrice = deckingArea * deckingPrice;
        break;
      case 2:
        if (tilePrice != null) totalPrice = tilesNeeded * tilePrice;
        break;
      case 3:
        if (boardPrice != null) totalPrice = deckingBoards * boardPrice;
        break;
      case 4:
        if (porcelainPrice != null) totalPrice = tilesNeeded * porcelainPrice;
        break;
      case 5:
        if (wpcPrice != null) totalPrice = deckingArea * wpcPrice;
        break;
      case 6:
        if (solidWoodPrice != null) totalPrice = deckingArea * solidWoodPrice;
        break;
      case 7:
        if (rubberTilesPrice != null) totalPrice = tilesNeeded * rubberTilesPrice;
        break;
    }

    if (railingPrice != null && railingLength > 0) {
      totalPrice = (totalPrice ?? 0) + railingLength * railingPrice;
    }
    if (postPrice != null && railingPosts > 0) {
      totalPrice = (totalPrice ?? 0) + railingPosts * postPrice;
    }

    if (roof) {
      switch (roofType) {
        case 1:
          if (polycarbonatePrice != null && polycarbonateSheets > 0) {
            totalPrice = (totalPrice ?? 0) + polycarbonateSheets * polycarbonatePrice;
          }
          break;
        case 2:
          if (profiledSheetPrice != null && profiledSheets > 0) {
            totalPrice = (totalPrice ?? 0) + profiledSheets * profiledSheetPrice;
          }
          break;
        case 3:
          if (roofingPrice != null && roofingMaterial > 0) {
            totalPrice = (totalPrice ?? 0) + roofingMaterial * roofingPrice;
          }
          break;
        case 4:
          if (ondulinPrice != null && profiledSheets > 0) {
            totalPrice = (totalPrice ?? 0) + profiledSheets * ondulinPrice;
          }
          break;
        case 5:
          if (metalTilePrice != null && roofingMaterial > 0) {
            totalPrice = (totalPrice ?? 0) + roofingMaterial * metalTilePrice;
          }
          break;
        case 6:
          if (glassPrice != null && polycarbonateSheets > 0) {
            totalPrice = (totalPrice ?? 0) + polycarbonateSheets * glassPrice;
          }
          break;
      }
    }

    if (concretePrice != null && foundationVolume > 0) {
      totalPrice = (totalPrice ?? 0) + foundationVolume * concretePrice;
    }

    return createResult(
      values: {
        'inputMode': inputMode.toDouble(),
        'area': area,
        'perimeter': perimeter,
        'floorArea': floorArea,
        'floorType': floorType.toDouble(),
        'railing': railing ? 1.0 : 0.0,
        'roof': roof ? 1.0 : 0.0,
        'roofType': roofType.toDouble(),
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
    if (inputs.containsKey('perimeter')) {
      return getInput(inputs, 'perimeter', defaultValue: 0.0, minValue: 0.0);
    }
    if (area <= 0) return 0.0;
    return estimatePerimeter(area);
  }
}

