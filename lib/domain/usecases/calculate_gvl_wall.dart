// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор обшивки стен ГВЛ.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - area: площадь стен (м²)
/// - layers: количество слоёв ГВЛ, по умолчанию 1
/// - height: высота стен (м), по умолчанию 2.5
/// - perimeter: периметр комнаты (м), опционально
class CalculateGvlWall extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(inputs, 'layers', defaultValue: 1, minValue: 1, maxValue: 2);
    final wallHeight = getInput(inputs, 'height', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одного листа ГВЛ (стандарт 1.2×2.5 м = 3 м²)
    final sheetArea = 3.0;

    // Количество листов с запасом 8%
    final sheetsNeeded = calculateUnitsNeeded(area * layers, sheetArea, marginPercent: 10.0);

    // Стоечный профиль (CW): шаг 40-60 см
    final studsCount = ceilToInt((perimeter / 4) / 0.6);
    final studsLength = studsCount * wallHeight;

    // Направляющий профиль (UW): верх и низ
    final guideLength = perimeter * 2;

    // Подвесы (для выравнивания стен): ~1 шт на 0.5 м.п. профиля
    final hangersNeeded = ceilToInt(studsLength / 0.5);

    // Саморезы: для ГВЛ к профилю ~30 шт на лист, для профилей ~8 шт/м.п.
    final gvlScrewsNeeded = sheetsNeeded * 30;
    final screwsNeeded = gvlScrewsNeeded.toDouble();

    // Дюбели для крепления профиля: ~3 шт/м.п.
    final dowelsNeeded = ceilToInt(guideLength * 3);

    // Шпаклёвка: ~1.0-1.2 кг/м² на слой
    final puttyNeeded = area * layers * 1.5;

    // Серпянка для швов: длина швов
    final tapeNeeded = area / 1.2 * 2; // примерно 2 м швов на 1.2 м² листа

    // Грунтовка: ~0.15 л/м² на слой
    final primerNeeded = area * layers * 0.15;

    // Утеплитель (опционально, в каркас): объём каркаса
    final insulationNeeded = getInput(inputs, 'insulation', defaultValue: 0.0);

    // Расчёт стоимости
    final gvlPrice = findPrice(priceList, ['gvl', 'gvl_sheet', 'gypsum_fiber_board']);
    final studPrice = findPrice(priceList, ['profile_stud', 'stud_profile', 'profile_cw']);
    final guidePrice = findPrice(priceList, ['profile_guide', 'guide_profile', 'profile_uw']);
    final hangerPrice = findPrice(priceList, ['hanger', 'hanger_wall', 'direct_hanger']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish', 'joint_compound']);
    final tapePrice = findPrice(priceList, ['tape', 'serpyanka', 'joint_tape']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final insulationPrice = findPrice(priceList, ['insulation', 'mineral_wool']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), gvlPrice?.price),
      calculateCost(studsLength, studPrice?.price),
      calculateCost(guideLength, guidePrice?.price),
      calculateCost(hangersNeeded.toDouble(), hangerPrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (insulationNeeded > 0) calculateCost(insulationNeeded, insulationPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'studsLength': studsLength,
        'guideLength': guideLength,
        'hangersNeeded': hangersNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
        'dowelsNeeded': dowelsNeeded.toDouble(),
        'puttyNeeded': puttyNeeded,
        'tapeNeeded': tapeNeeded,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        if (insulationNeeded > 0) 'insulationNeeded': insulationNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
