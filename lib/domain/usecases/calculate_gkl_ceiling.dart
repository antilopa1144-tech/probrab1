import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор подвесного потолка из ГКЛ.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - area: площадь потолка (м²)
/// - layers: количество слоёв ГКЛ, по умолчанию 1
/// - ceilingHeight: высота потолка (м), для расчёта профилей
/// - dropHeight: высота опускания (м), по умолчанию 0.1
/// - perimeter: периметр комнаты (м), опционально
class CalculateGklCeiling extends BaseCalculator {
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
    final ceilingHeight = getInput(inputs, 'ceilingHeight', defaultValue: 2.5, minValue: 2.0, maxValue: 4.0);
    final dropHeight = getInput(inputs, 'dropHeight', defaultValue: 0.1, minValue: 0.05, maxValue: 0.5);

    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одного листа ГКЛ (1.2×2.5 м = 3 м²)
    final sheetArea = 3.0;

    // Количество листов с запасом 8%
    final sheetsNeeded = calculateUnitsNeeded(area * layers, sheetArea, marginPercent: 8.0);

    // Направляющий профиль (UD): периметр + 5%
    final guideLength = addMargin(perimeter, 5.0);

    // Потолочный профиль (CD): шаг 40-60 см
    // Количество профилей = ширина комнаты / 0.6
    final ceilingProfileCount = ceilToInt(perimeter / 4 / 0.6); // примерное количество
    final ceilingProfileLength = ceilingProfileCount * (perimeter / 4);

    // Подвесы: шаг 60×120 см
    final hangersNeeded = ceilToInt(area / (0.6 * 1.2));

    // Краб-соединители: на каждое пересечение профилей
    final crabsNeeded = hangersNeeded;

    // Саморезы:
    // - Для ГКЛ к профилю: ~25 шт/лист
    // - Для профиля между собой: ~8 шт/м.п.
    final gklScrewsNeeded = sheetsNeeded * 25;
    final profileScrewsNeeded = ceilToInt((guideLength + ceilingProfileLength) * 8);
    final screwsNeeded = gklScrewsNeeded + profileScrewsNeeded;

    // Дюбели для крепления профиля: ~3 шт/м.п.
    final dowelsNeeded = ceilToInt(guideLength * 3);

    // Шпаклёвка: ~1.2 кг/м² на слой
    final puttyNeeded = area * layers * 1.2;

    // Серпянка: длина швов
    final tapeNeeded = area / 1.2 * 2; // примерно 2 м швов на 1.2 м² листа

    // Грунтовка: ~0.1 л/м² на слой
    final primerNeeded = area * layers * 0.1;

    // Расчёт стоимости
    final gklPrice = findPrice(priceList, ['gkl', 'gkl_sheet', 'drywall', 'gypsum_board']);
    final guidePrice = findPrice(priceList, ['profile_guide', 'guide_profile', 'profile_ud']);
    final ceilingProfilePrice = findPrice(priceList, ['profile_ceiling', 'ceiling_profile', 'profile_cd']);
    final hangerPrice = findPrice(priceList, ['hanger', 'hanger_ceiling', 'suspension']);
    final crabPrice = findPrice(priceList, ['crab', 'cross_connector']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish', 'joint_compound']);
    final tapePrice = findPrice(priceList, ['tape', 'serpyanka', 'joint_tape']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), gklPrice?.price),
      calculateCost(guideLength, guidePrice?.price),
      calculateCost(ceilingProfileLength, ceilingProfilePrice?.price),
      calculateCost(hangersNeeded.toDouble(), hangerPrice?.price),
      calculateCost(crabsNeeded.toDouble(), crabPrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'guideLength': guideLength,
        'ceilingProfileLength': ceilingProfileLength,
        'hangersNeeded': hangersNeeded.toDouble(),
        'crabsNeeded': crabsNeeded.toDouble(),
        'screwsNeeded': screwsNeeded.toDouble(),
        'dowelsNeeded': dowelsNeeded.toDouble(),
        'puttyNeeded': puttyNeeded,
        'tapeNeeded': tapeNeeded,
        'primerNeeded': primerNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
