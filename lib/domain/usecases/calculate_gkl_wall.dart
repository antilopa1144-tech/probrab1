// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор обшивки стен ГКЛ (гипсокартон) с гибридным режимом ввода.
///
/// Поддерживает два режима ввода:
/// 1. **По размерам** (inputMode = 0): длина и высота стены → точный расчёт
/// 2. **По площади** (inputMode = 1): готовая площадь стены
///
/// Логика (согласно спецификации):
/// - Направляющий профиль (PN/UD): Периметр × 2 (пол + потолок)
/// - Стоечный профиль (PS/CD): Длина стены / шаг (0.6м или 0.4м)
/// - Листы ГКЛ: Площадь / 3.0 м² (стандартный лист 2.5×1.2м)
/// - Крепеж: раздельно "Металл-Металл" (блошки) и "ГКЛ-Металл" (саморезы 25мм)
///
/// Нормативы:
/// - СНиП 3.03.01-87 "Несущие и ограждающие конструкции"
/// - ГОСТ 6266-97 "Листы гипсокартонные"
///
/// Поля:
/// - inputMode: режим ввода (0 = по размерам, 1 = по площади)
/// - wallLength, wallHeight: размеры стены (м) - только для режима 0
/// - area: площадь стены (м²) - только для режима 1
/// - profileStep: шаг стоечного профиля (40 или 60 см)
/// - layers: количество слоёв ГКЛ (1 или 2)
/// - doubleSided: двухсторонняя обшивка (bool)
/// - windowsArea, doorsArea: площадь проёмов (м²)
class CalculateGklWall extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode'] ?? 0;
    if (inputMode == 1 && (inputs['area'] ?? 0) <= 0) {
      return 'Площадь должна быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // --- Режим ввода: по размерам (0) или по площади (1) ---
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0);

    // Вычисляем площадь и размеры в зависимости от режима
    double area;
    double wallLength;
    double wallHeight;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам": точные размеры стены
      wallLength = getInput(inputs, 'wallLength', minValue: 0.5);
      wallHeight = getInput(inputs, 'wallHeight', defaultValue: 2.7, minValue: 2.0, maxValue: 6.0);

      area = wallLength * wallHeight;
      perimeter = (wallLength + wallHeight) * 2;
    } else {
      // Режим "По площади": оцениваем размеры
      area = getInput(inputs, 'area', minValue: 1.0);

      // Оценка размеров для расчета профилей (предполагаем стандартную высоту)
      wallHeight = 2.7;
      wallLength = area / wallHeight;
      perimeter = estimatePerimeter(area);
    }

    // --- Получаем остальные входные данные ---
    final profileStep = getInput(inputs, 'profileStep', defaultValue: 60.0) / 100.0; // переводим в метры
    final layers = getIntInput(inputs, 'layers', defaultValue: 1, minValue: 1, maxValue: 2);
    final doubleSided = getIntInput(inputs, 'doubleSided', defaultValue: 0) != 0;
    final windowsArea = getInput(inputs, 'windowsArea', minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', minValue: 0.0);

    // --- Расчёт материалов (согласно спецификации) ---

    // 1. Направляющий профиль (PN/UD) - по периметру: пол + потолок
    final guideProfileMeters = perimeter * 2; // Периметр × 2
    final guideProfilePieces = (guideProfileMeters / 3.0).ceil(); // Профиль обычно 3м

    // 2. Стоечный профиль (PS/CD) - вертикальные стойки
    // Количество стоек = (длина стены / шаг) + 1 (крайняя стойка)
    final racksCount = (wallLength / profileStep).ceil() + 1;
    final rackProfileMeters = racksCount * wallHeight;
    final rackProfilePieces = (rackProfileMeters / 3.0).ceil(); // Профиль обычно 3м

    // 3. Листы ГКЛ
    // Полезная площадь (с учётом проёмов)
    final usefulArea = calculateUsefulArea(area, windowsArea: windowsArea, doorsArea: doorsArea);

    // Площадь на одну сторону с учётом количества слоёв
    final areaSingleSide = usefulArea * layers;

    // Общая площадь (одна или две стороны)
    final totalGklArea = doubleSided ? areaSingleSide * 2 : areaSingleSide;

    // Листы: площадь / 3.0 м² (стандартный лист 2.5м × 1.2м = 3.0 м²)
    final gklSheets = (totalGklArea / 3.0).ceil();

    // 4. Крепеж
    // Саморезы "Металл-Металл" (блошки) для крепления профилей
    // ~30-40 шт на 1 направляющий профиль (3м)
    final screwsMetalToMetal = guideProfilePieces * 35;

    // Саморезы "ГКЛ-Металл" (25мм) для крепления листов к профилям
    // ~25-30 шт на 1 лист ГКЛ
    final screwsGklToMetal = gklSheets * 27;

    // 5. Дополнительные материалы
    // Лента-серпянка для швов: ~1.2 м на 1 м² ГКЛ
    final seamTapeMeters = totalGklArea * 1.2;

    // Шпаклёвка для швов: ~0.3 кг на 1 м² ГКЛ
    final jointCompoundKg = totalGklArea * 0.3;

    // Грунтовка: ~0.1 л/м²
    final primerLiters = totalGklArea * 0.1;

    // --- Применяем правила округления ---
    final finalGuideProfileMeters = roundBulk(guideProfileMeters);
    final finalRackProfileMeters = roundBulk(rackProfileMeters);
    final finalSeamTapeMeters = roundBulk(seamTapeMeters);
    final finalJointCompoundKg = roundBulk(jointCompoundKg);
    final finalPrimerLiters = roundBulk(primerLiters);

    // --- Расчёт стоимости ---
    final guideProfilePrice = findPrice(priceList, ['profile_pn', 'profile_ud', 'profile_guide']);
    final rackProfilePrice = findPrice(priceList, ['profile_ps', 'profile_cd', 'profile_rack']);
    final gklSheetPrice = findPrice(priceList, ['gkl', 'drywall', 'gypsum_board']);
    final screwsMetalPrice = findPrice(priceList, ['screws_metal', 'screws_bloshki']);
    final screwsGklPrice = findPrice(priceList, ['screws_gkl', 'screws_drywall']);
    final seamTapePrice = findPrice(priceList, ['tape_seam', 'serpyanka']);
    final jointCompoundPrice = findPrice(priceList, ['joint_compound', 'shpaklevka_joints']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(finalGuideProfileMeters, guideProfilePrice?.price),
      calculateCost(finalRackProfileMeters, rackProfilePrice?.price),
      calculateCost(gklSheets.toDouble(), gklSheetPrice?.price),
      calculateCost(screwsMetalToMetal.toDouble(), screwsMetalPrice?.price),
      calculateCost(screwsGklToMetal.toDouble(), screwsGklPrice?.price),
      calculateCost(finalSeamTapeMeters, seamTapePrice?.price),
      calculateCost(finalJointCompoundKg, jointCompoundPrice?.price),
      calculateCost(finalPrimerLiters, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': roundBulk(area),
        'usefulArea': roundBulk(usefulArea),
        'guideProfileMeters': finalGuideProfileMeters,
        'guideProfilePieces': guideProfilePieces.toDouble(),
        'rackProfileMeters': finalRackProfileMeters,
        'rackProfilePieces': rackProfilePieces.toDouble(),
        'racksCount': racksCount.toDouble(),
        'gklSheets': gklSheets.toDouble(),
        'screwsMetalToMetal': screwsMetalToMetal.toDouble(),
        'screwsGklToMetal': screwsGklToMetal.toDouble(),
        'seamTapeMeters': finalSeamTapeMeters,
        'jointCompoundKg': finalJointCompoundKg,
        'primerLiters': finalPrimerLiters,
      },
      totalPrice: sumCosts(costs),
      norms: ['СНиП 3.03.01-87', 'ГОСТ 6266-97'],
    );
  }
}
