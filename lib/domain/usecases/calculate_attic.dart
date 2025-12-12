// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор мансарды.
///
/// Нормативы:
/// - СНиП 2.01.07-85 "Нагрузки и воздействия"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь мансарды (м?)
/// - roofArea: площадь кровли (м?)
/// - wallArea: площадь стен (м?)
/// - floorArea: площадь пола (м?)
/// - windows: количество окон (шт)
/// - insulation: утепление кровли (0 - нет, 1 - да)
/// - wallFinish: отделка стен (1 - вагонка, 2 - гипсокартон, 3 - панели)
/// - floorType: тип пола (1 - ламинат, 2 - паркет, 3 - линолеум)
class CalculateAttic extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area =
        getInput(inputs, 'area', defaultValue: 0.0, minValue: 0.0);
    final roofArea =
        getInput(inputs, 'roofArea', defaultValue: 0.0, minValue: 0.0);
    final wallArea =
        getInput(inputs, 'wallArea', defaultValue: 0.0, minValue: 0.0);
    final floorArea = getInput(
      inputs,
      'floorArea',
      defaultValue: area,
      minValue: 0.0,
    );
    final windows =
        getIntInput(inputs, 'windows', defaultValue: 0, minValue: 0);
    final insulation = getIntInput(
      inputs,
      'insulation',
      defaultValue: 1,
      minValue: 0,
      maxValue: 1,
    );
    final wallFinish = getIntInput(
      inputs,
      'wallFinish',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final floorType = getIntInput(
      inputs,
      'floorType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );

    final insulationArea =
        insulation == 1 ? roofArea * 1.1 : 0.0;
    final insulationVolume =
        insulation == 1 ? roofArea * 0.15 : 0.0;
    final vaporBarrierArea =
        insulation == 1 ? roofArea * 1.1 : 0.0;

    double woodArea = 0.0;
    double gklSheets = 0.0;
    double panelsNeeded = 0.0;

    if (wallFinish == 1) {
      const boardArea = 0.1;
      woodArea = (wallArea / boardArea * 1.1).ceil().toDouble();
    } else if (wallFinish == 2) {
      const sheetArea = 3.0;
      gklSheets = (wallArea / sheetArea * 1.1).ceil().toDouble();
    } else if (wallFinish == 3) {
      const panelArea = 0.25;
      panelsNeeded = (wallArea / panelArea * 1.1).ceil().toDouble();
    }

    double laminatePacks = 0.0;
    double parquetPlanks = 0.0;
    double linoleumRolls = 0.0;

    if (floorType == 1) {
      const packArea = 2.0;
      laminatePacks = (floorArea / packArea * 1.05).ceil().toDouble();
    } else if (floorType == 2) {
      const plankArea = 0.28;
      parquetPlanks = (floorArea / plankArea * 1.1).ceil().toDouble();
    } else if (floorType == 3) {
      const rollArea = 30.0;
      linoleumRolls = (floorArea / rollArea * 1.1).ceil().toDouble();
    }

    final windowArea = windows * 1.5;
    final fixturesNeeded = (area / 5.0).ceil();

    final insulationPrice = findPrice(
      priceList,
      ['insulation_mineral', 'mineral_wool', 'insulation'],
    )?.price;
    final vaporBarrierPrice = findPrice(
      priceList,
      ['vapor_barrier', 'vapor_membrane'],
    )?.price;
    final woodPrice = findPrice(
      priceList,
      ['wood', 'clapboard', 'timber'],
    )?.price;
    final gklPrice = findPrice(
      priceList,
      ['gkl', 'drywall', 'gypsum_board'],
    )?.price;
    final panelPrice = findPrice(
      priceList,
      ['pvc_panel', 'panel'],
    )?.price;
    final laminatePrice = findPrice(
      priceList,
      ['laminate', 'laminate_pack'],
    )?.price;
    final parquetPrice = findPrice(
      priceList,
      ['parquet', 'wood_floor'],
    )?.price;
    final linoleumPrice = findPrice(
      priceList,
      ['linoleum', 'flooring'],
    )?.price;
    final windowPrice = findPrice(
      priceList,
      ['attic_window', 'roof_window', 'window'],
    )?.price;

    double? totalPrice;

    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = insulationArea * insulationPrice;
    }
    if (vaporBarrierPrice != null && vaporBarrierArea > 0) {
      totalPrice =
          (totalPrice ?? 0) + vaporBarrierArea * vaporBarrierPrice;
    }

    if (wallFinish == 1 && woodPrice != null) {
      totalPrice = (totalPrice ?? 0) + woodArea * woodPrice;
    } else if (wallFinish == 2 && gklPrice != null) {
      totalPrice = (totalPrice ?? 0) + gklSheets * gklPrice;
    } else if (wallFinish == 3 && panelPrice != null) {
      totalPrice = (totalPrice ?? 0) + panelsNeeded * panelPrice;
    }

    if (floorType == 1 && laminatePrice != null) {
      totalPrice = (totalPrice ?? 0) + laminatePacks * laminatePrice;
    } else if (floorType == 2 && parquetPrice != null) {
      totalPrice = (totalPrice ?? 0) + parquetPlanks * parquetPrice;
    } else if (floorType == 3 && linoleumPrice != null) {
      totalPrice = (totalPrice ?? 0) + linoleumRolls * linoleumPrice;
    }

    if (windowPrice != null && windows > 0) {
      totalPrice = (totalPrice ?? 0) + windows * windowPrice;
    }

    return createResult(
      values: {
        'area': area,
        'roofArea': roofArea,
        'wallArea': wallArea,
        'floorArea': floorArea,
        'insulationArea': insulationArea,
        'insulationVolume': insulationVolume,
        'vaporBarrierArea': vaporBarrierArea,
        'woodArea': woodArea,
        'gklSheets': gklSheets,
        'panelsNeeded': panelsNeeded,
        'laminatePacks': laminatePacks,
        'parquetPlanks': parquetPlanks,
        'linoleumRolls': linoleumRolls,
        'windows': windows.toDouble(),
        'windowArea': windowArea,
        'fixturesNeeded': fixturesNeeded.toDouble(),
      },
      totalPrice: totalPrice,
      calculatorId: 'attic',
    );
  }
}

