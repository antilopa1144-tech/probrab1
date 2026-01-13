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
/// - floorType: тип покрытия пола (1 - декинг, 2 - плитка, 3 - настил, 4 - керамогранит, 5 - ДПК, 6 - массив дерева, 7 - резиновая плитка)
/// - railing: ограждение (0 - нет, 1 - да)
/// - roof: кровля (0 - нет, 1 - да)
/// - roofType: тип кровли (1 - поликарбонат, 2 - профлист, 3 - мягкая кровля, 4 - ондулин, 5 - металлочерепица, 6 - стекло)
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
      maxValue: 7,
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
      maxValue: 6,
    );

    final floorArea = area;

    double deckingArea = 0.0;
    double tilesNeeded = 0.0;
    double deckingBoards = 0.0;

    // Расчёт материала пола в зависимости от типа
    switch (floorType) {
      case 1: // Декинг
        deckingArea = floorArea * 1.1;
        break;
      case 2: // Плитка (50x50 см)
        const tileArea = 0.25;
        tilesNeeded = (floorArea / tileArea * 1.1).ceil().toDouble();
        break;
      case 3: // Доска
        const boardArea = 0.1;
        deckingBoards = (floorArea / boardArea * 1.1).ceil().toDouble();
        break;
      case 4: // Керамогранит (60x60 см)
        const porcelainArea = 0.36;
        tilesNeeded = (floorArea / porcelainArea * 1.1).ceil().toDouble();
        break;
      case 5: // ДПК (древесно-полимерный композит)
        deckingArea = floorArea * 1.1;
        break;
      case 6: // Массив дерева (больше отходов)
        deckingArea = floorArea * 1.1 * 1.15;
        break;
      case 7: // Резиновая плитка (50x50 см)
        const rubberArea = 0.25;
        tilesNeeded = (floorArea / rubberArea * 1.1).ceil().toDouble();
        break;
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

      // Расчёт материала кровли в зависимости от типа
      switch (roofType) {
        case 1: // Поликарбонат
          const sheetArea = 6.0;
          polycarbonateSheets =
              (roofArea / sheetArea * 1.1).ceil().toDouble();
          break;
        case 2: // Профнастил
          const sheetArea = 8.0;
          profiledSheets =
              (roofArea / sheetArea * 1.1).ceil().toDouble();
          break;
        case 3: // Мягкая кровля
          roofingMaterial = roofArea * 1.1;
          break;
        case 4: // Ондулин (стандартный лист 1.9 м²)
          const ondSheetArea = 1.9;
          profiledSheets =
              (roofArea / ondSheetArea * 1.15).ceil().toDouble();
          break;
        case 5: // Металлочерепица
          roofingMaterial = roofArea * 1.2;
          break;
        case 6: // Стеклянная крыша
          const glassSheetArea = 2.0;
          polycarbonateSheets =
              (roofArea / glassSheetArea * 1.1).ceil().toDouble();
          break;
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
    final porcelainPrice = findPrice(
      priceList,
      ['porcelain_tile', 'tile_porcelain', 'porcelain'],
    )?.price;
    final wpcPrice = findPrice(
      priceList,
      ['wpc', 'composite_decking', 'wood_plastic_composite'],
    )?.price;
    final solidWoodPrice = findPrice(
      priceList,
      ['solid_wood', 'larch', 'oak', 'hardwood'],
    )?.price;
    final rubberTilesPrice = findPrice(
      priceList,
      ['rubber_tiles', 'rubber_flooring', 'modular_rubber'],
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
    final ondulinPrice = findPrice(
      priceList,
      ['ondulin', 'ondulina', 'bitumen_sheet'],
    )?.price;
    final metalTilePrice = findPrice(
      priceList,
      ['metal_tile', 'metal_roofing', 'metallocherepitsa'],
    )?.price;
    final glassPrice = findPrice(
      priceList,
      ['glass', 'tempered_glass', 'glass_roof'],
    )?.price;
    final concretePrice = findPrice(
      priceList,
      ['concrete', 'concrete_m300'],
    )?.price;

    double? totalPrice;

    // Расчёт стоимости пола в зависимости от типа
    switch (floorType) {
      case 1: // Декинг
        if (deckingPrice != null) {
          totalPrice = deckingArea * deckingPrice;
        }
        break;
      case 2: // Плитка
        if (tilePrice != null) {
          totalPrice = tilesNeeded * tilePrice;
        }
        break;
      case 3: // Доска
        if (boardPrice != null) {
          totalPrice = deckingBoards * boardPrice;
        }
        break;
      case 4: // Керамогранит
        if (porcelainPrice != null) {
          totalPrice = tilesNeeded * porcelainPrice;
        }
        break;
      case 5: // ДПК
        if (wpcPrice != null) {
          totalPrice = deckingArea * wpcPrice;
        }
        break;
      case 6: // Массив дерева
        if (solidWoodPrice != null) {
          totalPrice = deckingArea * solidWoodPrice;
        }
        break;
      case 7: // Резиновая плитка
        if (rubberTilesPrice != null) {
          totalPrice = tilesNeeded * rubberTilesPrice;
        }
        break;
    }

    if (railingPrice != null && railingLength > 0) {
      totalPrice = (totalPrice ?? 0) + railingLength * railingPrice;
    }
    if (postPrice != null && railingPosts > 0) {
      totalPrice = (totalPrice ?? 0) + railingPosts * postPrice;
    }

    // Расчёт стоимости крыши в зависимости от типа
    if (roof == 1) {
      switch (roofType) {
        case 1: // Поликарбонат
          if (polycarbonatePrice != null && polycarbonateSheets > 0) {
            totalPrice =
                (totalPrice ?? 0) + polycarbonateSheets * polycarbonatePrice;
          }
          break;
        case 2: // Профнастил
          if (profiledSheetPrice != null && profiledSheets > 0) {
            totalPrice =
                (totalPrice ?? 0) + profiledSheets * profiledSheetPrice;
          }
          break;
        case 3: // Мягкая кровля
          if (roofingPrice != null && roofingMaterial > 0) {
            totalPrice = (totalPrice ?? 0) + roofingMaterial * roofingPrice;
          }
          break;
        case 4: // Ондулин
          if (ondulinPrice != null && profiledSheets > 0) {
            totalPrice = (totalPrice ?? 0) + profiledSheets * ondulinPrice;
          }
          break;
        case 5: // Металлочерепица
          if (metalTilePrice != null && roofingMaterial > 0) {
            totalPrice = (totalPrice ?? 0) + roofingMaterial * metalTilePrice;
          }
          break;
        case 6: // Стеклянная крыша
          if (glassPrice != null && polycarbonateSheets > 0) {
            totalPrice = (totalPrice ?? 0) + polycarbonateSheets * glassPrice;
          }
          break;
      }
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

