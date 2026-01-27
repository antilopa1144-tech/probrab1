// ignore_for_file: prefer_const_declarations
import 'dart:math';

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор балкона/лоджии.
///
/// Нормативы:
/// - СНиП 2.01.07-85 "Нагрузки и воздействия"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь балкона/лоджии (м2)
/// - height: высота ограждения (м), по умолчанию 1.1
/// - glazing: остекление (0 - нет, 1 - холодное, 2 - тёплое)
/// - insulation: утепление (0 - нет, 1 - да)
/// - floorType: тип пола (1 - плитка, 2 - наливной, 3 - дерево)
/// - wallFinish: отделка стен (1 - покраска, 2 - панели, 3 - плитка)
class CalculateBalcony extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area =
        getInput(inputs, 'area', defaultValue: 0.0, minValue: 0.0);
    final perimeter = _resolvePerimeter(inputs, area);
    final height =
        getInput(inputs, 'height', defaultValue: 1.1, minValue: 0.0);
    final glazing = getIntInput(
      inputs,
      'glazing',
      defaultValue: 0,
      minValue: 0,
      maxValue: 2,
    );
    final insulation = getIntInput(
      inputs,
      'insulation',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final floorType = getIntInput(
      inputs,
      'floorType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final wallFinish = getIntInput(
      inputs,
      'wallFinish',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );

    final floorArea = area;
    final wallArea = perimeter > 0 ? perimeter * height : 0.0;
    final ceilingArea = area;

    double glazingArea = 0.0;
    double glazingLength = 0.0;
    if (glazing > 0) {
      glazingArea = wallArea * 0.7;
      glazingLength = perimeter;
    }

    final insulationArea =
        insulation == 1 ? (wallArea + ceilingArea) * 1.1 : 0.0;
    final insulationVolume =
        insulation == 1 ? (wallArea + ceilingArea) * 0.05 : 0.0;
    // Для ЭППС (XPS) пароизоляция не требуется (СП 50.13330.2012)
    // Балкон использует ЭППС по умолчанию
    const vaporBarrierArea = 0.0;

    double tilesNeeded = 0.0;
    double selfLevelingMix = 0.0;
    double woodArea = 0.0;

    if (floorType == 1) {
      const tileArea = 0.09;
      tilesNeeded = (floorArea / tileArea * 1.1).ceil().toDouble();
    } else if (floorType == 2) {
      selfLevelingMix = floorArea * 1.5 * 0.005;
    } else if (floorType == 3) {
      woodArea = floorArea * 1.1;
    }

    double paintNeeded = 0.0;
    double panelsNeeded = 0.0;
    double wallTilesNeeded = 0.0;

    if (wallFinish == 1) {
      paintNeeded = wallArea * 0.15 * 2;
    } else if (wallFinish == 2) {
      const panelArea = 0.25;
      panelsNeeded = (wallArea / panelArea * 1.1).ceil().toDouble();
    } else if (wallFinish == 3) {
      const tileArea = 0.09;
      wallTilesNeeded = (wallArea / tileArea * 1.1).ceil().toDouble();
    }

    final ceilingPaintNeeded = ceilingArea * 0.12 * 2;
    final railingLength = glazing == 0 && perimeter > 0 ? perimeter : 0.0;

    final glazingPrice = findPrice(
      priceList,
      glazing == 2
          ? ['glazing_warm', 'windows_warm', 'glazing']
          : ['glazing_cold', 'windows_cold', 'glazing'],
    )?.price;
    final insulationPrice = findPrice(
      priceList,
      ['insulation_eps', 'eps', 'xps', 'insulation'],
    )?.price;
    final vaporBarrierPrice = findPrice(
      priceList,
      ['vapor_barrier', 'vapor_membrane'],
    )?.price;
    final tilePrice = findPrice(
      priceList,
      ['tile', 'tile_ceramic', 'tile_porcelain'],
    )?.price;
    final selfLevelingPrice = findPrice(
      priceList,
      ['self_leveling', 'leveling_compound'],
    )?.price;
    final woodPrice = findPrice(
      priceList,
      ['decking', 'terrace_board', 'wood'],
    )?.price;
    final paintPrice = findPrice(
      priceList,
      ['paint', 'paint_wall'],
    )?.price;
    final panelPrice = findPrice(
      priceList,
      ['pvc_panel', 'panel'],
    )?.price;
    final railingPrice = findPrice(
      priceList,
      ['railing', 'balcony_railing'],
    )?.price;

    double? totalPrice;

    if (glazingPrice != null && glazingArea > 0) {
      totalPrice = glazingArea * glazingPrice;
    }
    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice;
    }
    if (vaporBarrierPrice != null && vaporBarrierArea > 0) {
      totalPrice =
          (totalPrice ?? 0) + vaporBarrierArea * vaporBarrierPrice;
    }

    if (floorType == 1 && tilePrice != null) {
      totalPrice = (totalPrice ?? 0) + tilesNeeded * tilePrice;
    } else if (floorType == 2 && selfLevelingPrice != null) {
      totalPrice = (totalPrice ?? 0) + selfLevelingMix * selfLevelingPrice;
    } else if (floorType == 3 && woodPrice != null) {
      totalPrice = (totalPrice ?? 0) + woodArea * woodPrice;
    }

    if (wallFinish == 1 && paintPrice != null) {
      totalPrice = (totalPrice ?? 0) + paintNeeded * paintPrice;
    } else if (wallFinish == 2 && panelPrice != null) {
      totalPrice = (totalPrice ?? 0) + panelsNeeded * panelPrice;
    } else if (wallFinish == 3 && tilePrice != null) {
      totalPrice = (totalPrice ?? 0) + wallTilesNeeded * tilePrice;
    }

    if (paintPrice != null) {
      totalPrice =
          (totalPrice ?? 0) + ceilingPaintNeeded * paintPrice;
    }
    if (railingPrice != null && railingLength > 0) {
      totalPrice = (totalPrice ?? 0) + railingLength * railingPrice;
    }

    return createResult(
      values: {
        'area': area,
        'floorArea': floorArea,
        'wallArea': wallArea,
        'ceilingArea': ceilingArea,
        'glazingArea': glazingArea,
        'glazingLength': glazingLength,
        'insulationArea': insulationArea,
        'insulationVolume': insulationVolume,
        'vaporBarrierArea': vaporBarrierArea,
        'tilesNeeded': tilesNeeded,
        'selfLevelingMix': selfLevelingMix,
        'woodArea': woodArea,
        'paintNeeded': paintNeeded,
        'panelsNeeded': panelsNeeded,
        'wallTilesNeeded': wallTilesNeeded,
        'ceilingPaintNeeded': ceilingPaintNeeded,
        'railingLength': railingLength,
      },
      totalPrice: totalPrice,
      calculatorId: 'balcony',
    );
  }

  double _resolvePerimeter(Map<String, double> inputs, double area) {
    final perimeterInput = inputs['perimeter'] ?? 0.0;
    if (perimeterInput > 0) return perimeterInput;
    if (area <= 0) return 0.0;
    return sqrt(area) * 4;
  }
}

