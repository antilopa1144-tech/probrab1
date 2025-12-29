// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор гипсокартона.
///
/// Нормативы:
/// - СП 163.1325800.2014 "Конструкции с применением гипсокартона"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - construction_type: тип конструкции (1=облицовка стен, 2=перегородка, 3=потолок)
/// - area: площадь (м²) - вводится напрямую
/// - profile_type: тип профиля для перегородок (50/75/100)
/// - layers: количество слоев ГКЛ (1 или 2)
/// - gkl_type: тип ГКЛ (1=обычный, 2=влагостойкий, 3=огнестойкий)
/// - use_insulation: использовать утеплитель (0/1)
class CalculateGypsum extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final constructionType = inputs['construction_type'] ?? 1;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (area > 10000) return 'Площадь превышает допустимый максимум';
    if (constructionType < 1 || constructionType > 3) {
      return 'Неверный тип конструкции';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(
      inputs,
      'area',
      minValue: 0.1,
      maxValue: 10000.0,
    );
    final constructionType = getIntInput(
      inputs,
      'construction_type',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    // profileType используется для выбора типа профиля перегородки (ПС-50/75/100)
    // В текущей версии расход одинаковый, различается только типоразмер
    // final profileType = getIntInput(
    //   inputs,
    //   'profile_type',
    //   defaultValue: 50,
    //   minValue: 50,
    //   maxValue: 100,
    // );
    final layers = getIntInput(
      inputs,
      'layers',
      defaultValue: 1,
      minValue: 1,
      maxValue: 2,
    );
    final gklType = getIntInput(
      inputs,
      'gkl_type',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final useInsulation = getIntInput(
      inputs,
      'use_insulation',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    ) == 1;

    // Площадь листа стандартного 2500×1200 мм = 3 м²
    const sheetArea = 3.0;

    // Расчет ГКЛ с запасом 5% (округляем в большую сторону)
    double gklMultiplier = 1.05;

    // Для перегородок - обшивка с двух сторон
    if (constructionType == 2) {
      gklMultiplier *= 2.0; // две стороны
    }

    final gklArea = area * layers * gklMultiplier;
    final gklSheets = (gklArea / sheetArea).ceil();

    // Расчет профилей в зависимости от типа конструкции
    // Стандартная длина профиля - 3 метра
    const profileLength = 3.0;

    double pnMeters = 0;
    double ppMeters = 0;
    int pnPieces = 0;
    int ppPieces = 0;
    int screwsTN25 = 0;
    int screwsTN35 = 0;
    int screwsLN = 0;
    int dowels = 0;
    int suspensions = 0;
    int connectors = 0;
    double sealingTape = 0;

    if (constructionType == 1) {
      // Облицовка стен (система Knauf C 623)
      pnMeters = area * 0.8;  // ПН 28×27 (направляющий)
      ppMeters = area * 2.0;  // ПП 60×27 (стоечный)
      pnPieces = (pnMeters / profileLength).ceil();
      ppPieces = (ppMeters / profileLength).ceil();
      suspensions = (area * 1.3).ceil();
      dowels = (area * 1.6).ceil();
      screwsTN25 = (area * 25).ceil();
      screwsLN = (area * 4).ceil();
      sealingTape = area * 0.8;
    } else if (constructionType == 2) {
      // Перегородка (система Knauf C 111)
      pnMeters = area * 0.7;  // ПН 50×40 (направляющий)
      ppMeters = area * 2.0;  // ПС 50×50 (стоечный)
      pnPieces = (pnMeters / profileLength).ceil();
      ppPieces = (ppMeters / profileLength).ceil();
      dowels = (area * 1.5).ceil();
      screwsTN25 = (area * 34).ceil();  // с обеих сторон
      screwsLN = (area * 4).ceil();
      sealingTape = area * 1.2;
    } else if (constructionType == 3) {
      // Потолок одноуровневый (система Knauf P 113)
      pnMeters = area * 0.4;  // ПНП 27×28 (периметр)
      ppMeters = area * 3.3;  // ПП 60×27 (несущий + основной)
      pnPieces = (pnMeters / profileLength).ceil();
      ppPieces = (ppMeters / profileLength).ceil();
      suspensions = (area * 0.7).ceil();
      connectors = (area * 1.7).ceil();  // крабы
      dowels = (suspensions * 2);  // анкер-клины по 2 на подвес
      screwsTN25 = (area * 23).ceil();
      screwsLN = (area * 7).ceil();
    }

    // Для второго слоя добавляем саморезы 35 мм
    if (layers == 2) {
      screwsTN35 = (area * 17 * (constructionType == 2 ? 2 : 1)).ceil();
    }

    // Утеплитель (минвата 50 мм)
    final insulationArea = useInsulation ? area * 1.05 : 0.0;

    // Материалы для заделки швов
    final armatureTape = area * 1.2; // серпянка/бумажная лента
    final fillerKg = area * (constructionType == 2 ? 0.6 : 0.3) * layers;
    final primerLiters = area * 0.1;

    // Расчёт стоимости
    final gklPrice = _getGKLPrice(priceList, gklType);
    final pnPrice = findPrice(priceList, ['profile_pn', 'pn_profile', 'guide_profile']);
    final ppPrice = findPrice(priceList, ['profile_pp', 'pp_profile', 'ceiling_profile']);
    final screwTN25Price = findPrice(priceList, ['screw_tn25', 'screw_gkl', 'screw']);
    final screwTN35Price = findPrice(priceList, ['screw_tn35', 'screw_gkl', 'screw']);
    final screwLNPrice = findPrice(priceList, ['screw_ln', 'screw_profile', 'screw']);
    final dowelPrice = findPrice(priceList, ['dowel', 'anchor', 'dowel_nail']);
    final suspensionPrice = findPrice(priceList, ['suspension', 'hanger', 'p_suspension']);
    final connectorPrice = findPrice(priceList, ['connector', 'crab', 'connector_crab']);
    final insulationPrice = findPrice(priceList, ['minvata', 'insulation', 'rockwool']);
    final tapePrice = findPrice(priceList, ['tape_sealing', 'sealing_tape', 'damper_tape']);
    final armatureTapePrice = findPrice(priceList, ['tape_armature', 'serpyanka', 'joint_tape']);
    final fillerPrice = findPrice(priceList, ['filler_fugen', 'filler', 'joint_compound']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(gklArea, gklPrice?.price),
      calculateCost(pnMeters, pnPrice?.price),
      calculateCost(ppMeters, ppPrice?.price),
      if (screwsTN25 > 0) calculateCost(screwsTN25.toDouble(), screwTN25Price?.price),
      if (screwsTN35 > 0) calculateCost(screwsTN35.toDouble(), screwTN35Price?.price),
      if (screwsLN > 0) calculateCost(screwsLN.toDouble(), screwLNPrice?.price),
      if (dowels > 0) calculateCost(dowels.toDouble(), dowelPrice?.price),
      if (suspensions > 0) calculateCost(suspensions.toDouble(), suspensionPrice?.price),
      if (connectors > 0) calculateCost(connectors.toDouble(), connectorPrice?.price),
      if (insulationArea > 0) calculateCost(insulationArea, insulationPrice?.price),
      if (sealingTape > 0) calculateCost(sealingTape, tapePrice?.price),
      calculateCost(armatureTape, armatureTapePrice?.price),
      calculateCost(fillerKg, fillerPrice?.price),
      calculateCost(primerLiters, primerPrice?.price),
    ];

    final result = <String, double>{
      'gklSheets': gklSheets.toDouble(),
      'gklArea': gklArea,
      'constructionType': constructionType.toDouble(),
    };

    if (pnPieces > 0) {
      result['pnPieces'] = pnPieces.toDouble();
      result['pnMeters'] = pnMeters;
    }
    if (ppPieces > 0) {
      result['ppPieces'] = ppPieces.toDouble();
      result['ppMeters'] = ppMeters;
    }
    if (screwsTN25 > 0) result['screwsTN25'] = screwsTN25.toDouble();
    if (screwsTN35 > 0) result['screwsTN35'] = screwsTN35.toDouble();
    if (screwsLN > 0) result['screwsLN'] = screwsLN.toDouble();
    if (dowels > 0) result['dowels'] = dowels.toDouble();
    if (suspensions > 0) result['suspensions'] = suspensions.toDouble();
    if (connectors > 0) result['connectors'] = connectors.toDouble();
    if (insulationArea > 0) result['insulationArea'] = insulationArea;
    if (sealingTape > 0) result['sealingTape'] = sealingTape;

    result['armatureTape'] = armatureTape;
    result['fillerKg'] = fillerKg;
    result['primerLiters'] = primerLiters;

    return createResult(
      values: result,
      totalPrice: sumCosts(costs),
      decimals: 1,
    );
  }

  PriceItem? _getGKLPrice(List<PriceItem> priceList, int gklType) {
    switch (gklType) {
      case 2:
        return findPrice(priceList, ['gklv', 'gkl_moisture', 'gkl']);
      case 3:
        return findPrice(priceList, ['gklo', 'gkl_fire', 'gkl']);
      default:
        return findPrice(priceList, ['gkl', 'drywall', 'gypsum_board']);
    }
  }
}
