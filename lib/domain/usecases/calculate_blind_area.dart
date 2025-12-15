// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор отмостки.
///
/// Поля:
/// - area: площадь дома (м?) - используется для оценки периметра
/// - width: ширина отмостки (м)
/// - thickness: толщина отмостки (мм)
/// - materialType: тип материала (1 - бетон, 2 - асфальт, 3 - тротуарная плитка)
/// - insulation: утепление (0 - нет, 1 - да)
class CalculateBlindArea extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final houseArea =
        getInput(inputs, 'area', defaultValue: 0.0, minValue: 0.0);
    final width =
        getInput(inputs, 'width', defaultValue: 1.0, minValue: 0.0);
    final thickness =
        getInput(inputs, 'thickness', defaultValue: 100.0, minValue: 0.0);
    final materialType = getIntInput(
      inputs,
      'materialType',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final insulation = getIntInput(
      inputs,
      'insulation',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );

    var perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', defaultValue: 0.0, minValue: 0.0)
        : 0.0;
    if (perimeter <= 0 && houseArea > 0) {
      perimeter = estimatePerimeter(houseArea);
    }

    // Площадь отмостки
    final area = perimeter * width;

    // Объём бетона/асфальта в м? (толщина в мм)
    final volume = calculateVolume(area, thickness);

    // Песчаная подушка: толщина 10-15 см
    const sandThickness = 0.15; // м
    final sandVolume = area * sandThickness;

    // Щебёночная подушка: толщина 5-10 см
    const gravelThickness = 0.10; // м
    final gravelVolume = area * gravelThickness;

    // Утеплитель (ЭППС): если требуется
    final insulationVolume =
        insulation == 1 ? area * 0.05 : 0.0; // 5 см утеплителя
    final insulationArea = insulation == 1 ? area : 0.0;

    // Тротуарная плитка: количество штук
    double tilesNeeded = 0.0;
    if (materialType == 3) {
      // Стандартная плитка 30x30 см = 0.09 м?
      const tileArea = 0.09; // м?
      tilesNeeded =
          (area / tileArea * 1.1).ceil().toDouble(); // +10% запас
    }

    // Бордюр: длина = периметр
    final curbLength = perimeter;

    // Армирование (для бетонной отмостки)
    double rebarNeeded = 0.0;
    if (materialType == 1) {
      rebarNeeded = area * 1.2; // кг/м? с учётом нахлёста
    }

    // Деформационные швы: каждые 2-3 метра
    const jointSpacing = 2.5; // м
    final jointsCount =
        perimeter > 0 ? (perimeter / jointSpacing).ceil() : 0;

    // Цены
    final concretePrice = findPrice(
      priceList,
      ['concrete', 'concrete_m300', 'concrete_m200'],
    )?.price;
    final asphaltPrice = findPrice(
      priceList,
      ['asphalt', 'asphalt_mix'],
    )?.price;
    final tilePrice = findPrice(
      priceList,
      ['paving_tile', 'tile_paving', 'tile'],
    )?.price;
    final sandPrice = findPrice(
      priceList,
      ['sand', 'sand_construction'],
    )?.price;
    final gravelPrice = findPrice(
      priceList,
      ['gravel', 'crushed_stone', 'gravel_20_40'],
    )?.price;
    final insulationPrice = findPrice(
      priceList,
      ['insulation_eps', 'eps', 'xps'],
    )?.price;
    final curbPrice = findPrice(
      priceList,
      ['curb', 'curbstone', 'border'],
    )?.price;
    final rebarPrice = findPrice(
      priceList,
      ['rebar', 'reinforcement', 'rebar_6'],
    )?.price;

    double? totalPrice;

    if (sandPrice != null && gravelPrice != null) {
      totalPrice = sandVolume * sandPrice + gravelVolume * gravelPrice;
    }

    if (materialType == 1 && concretePrice != null) {
      totalPrice = (totalPrice ?? 0) + volume * concretePrice;
      if (rebarPrice != null) {
        totalPrice = totalPrice + rebarNeeded * rebarPrice;
      }
    } else if (materialType == 2 && asphaltPrice != null) {
      totalPrice = (totalPrice ?? 0) + volume * asphaltPrice;
    } else if (materialType == 3 && tilePrice != null) {
      totalPrice = (totalPrice ?? 0) + tilesNeeded * tilePrice;
    }

    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice;
    }

    if (curbPrice != null) {
      totalPrice = (totalPrice ?? 0) + curbLength * curbPrice;
    }

    return createResult(
      values: {
        'houseArea': houseArea,
        'perimeter': perimeter,
        'width': width,
        'area': area,
        'thickness': thickness,
        'volume': volume,
        'sandVolume': sandVolume,
        'gravelVolume': gravelVolume,
        'insulationVolume': insulationVolume,
        'insulationArea': insulationArea,
        'tilesNeeded': tilesNeeded,
        'curbLength': curbLength,
        'rebarNeeded': rebarNeeded,
        'jointsCount': jointsCount.toDouble(),
      },
      totalPrice: totalPrice,
      calculatorId: 'foundation_blind_area',
    );
  }
}
