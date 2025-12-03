import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор перегородок из ГКЛ.
///
/// Нормативы:
/// - СНиП 2.08.01-89 "Жилые здания"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - area: площадь перегородки (м²)
/// - layers: количество слоёв ГКЛ, по умолчанию 2
/// - height: высота перегородки (м), по умолчанию 2.5
/// - perimeter: периметр перегородки (м), опционально
class CalculateGklPartition extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final layers = inputs['layers'] ?? 2;
    final height = inputs['height'] ?? 2.5;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (layers < 1 || layers > 4) return 'Количество слоёв должно быть от 1 до 4';
    if (height <= 0 || height > 4) return 'Высота должна быть от 0.5 до 4 м';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 4);
    final height = getInput(inputs, 'height', defaultValue: 2.5, minValue: 0.5, maxValue: 4.0);

    // Периметр: если указан - используем, иначе оцениваем
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одного листа ГКЛ (стандарт 1.2×2.5 м = 3 м²)
    final sheetArea = 3.0; // м²

    // Количество листов с запасом 8-10% на подрезку
    final sheetsNeeded = calculateUnitsNeeded(
      area * layers, 
      sheetArea, 
      marginPercent: 10.0,
    );

    // Профили для каркаса:
    // Стоечный профиль (CW): устанавливаются вертикально с шагом 40-60 см
    final studSpacing = 0.6; // м (стандартный шаг)
    final studsCount = ceilToInt(perimeter / studSpacing);
    final studsLength = studsCount * height;

    // Направляющий профиль (UW): периметр × 2 (верх и низ)
    final guideLength = perimeter * 2;

    // Саморезы:
    // - Для крепления ГКЛ к каркасу: ~25-30 шт на лист
    // - Для крепления профиля: ~5-6 шт на м.п.
    final gklScrewsNeeded = sheetsNeeded * 30;
    final screwsNeeded = gklScrewsNeeded.toDouble();

    // Шпаклёвка:
    // - Стартовая (для швов): ~0.8-1.0 кг/м² на слой
    // - Финишная: ~0.5-0.6 кг/м² на слой
    final puttyNeeded = area * layers * 1.5;

    // Серпянка (лента для швов): длина швов ≈ периметр × высота / ширина листа
    final tapeNeeded = perimeter * height / 1.2;

    // Звукоизоляция (минеральная вата): заполняет внутреннее пространство
    final insulationArea = area / layers; // площадь внутри каркаса

    // Грунтовка: ~0.1 л/м² на каждую сторону
    final primerNeeded = area * layers * 0.1;

    // Дюбели для крепления направляющих: ~3-4 шт на метр
    final dowelsNeeded = ceilToInt(guideLength * 3.5);

    // Расчёт стоимости
    final gklPrice = findPrice(priceList, ['gkl', 'gkl_sheet', 'drywall', 'gypsum_board']);
    final studPrice = findPrice(priceList, ['profile_stud', 'stud_profile', 'profile_cw']);
    final guidePrice = findPrice(priceList, ['profile_guide', 'guide_profile', 'profile_uw']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish', 'joint_compound']);
    final tapePrice = findPrice(priceList, ['tape', 'serpyanka', 'joint_tape']);
    final insulationPrice = findPrice(priceList, ['insulation', 'mineral_wool', 'sound_insulation']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), gklPrice?.price),
      calculateCost(studsLength, studPrice?.price),
      calculateCost(guideLength, guidePrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      calculateCost(insulationArea, insulationPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'studsLength': studsLength,
        'studsCount': studsCount.toDouble(),
        'guideLength': guideLength,
        'screwsNeeded': screwsNeeded.toDouble(),
        'puttyNeeded': puttyNeeded,
        'tapeNeeded': tapeNeeded,
        'insulationArea': insulationArea,
        'primerNeeded': primerNeeded,
        'dowelsNeeded': dowelsNeeded.toDouble(),
        'layers': layers.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}

