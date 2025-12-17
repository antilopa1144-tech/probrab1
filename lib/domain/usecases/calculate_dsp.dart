// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

/// Калькулятор цементно-песчаной смеси (ЦПС) / стяжки пола.
///
/// Поддерживает два типа применения:
/// 1. **Стяжка пола** (applicationType = 0): М300 Пескобетон для прочной стяжки
/// 2. **Штукатурка стен** (applicationType = 1): М150 Универсальная смесь
///
/// Функции:
/// - Расчёт сухой смеси в мешках с учётом толщины слоя
/// - Выбор марки смеси (М300 Пескобетон или М150 Универсальная)
/// - Расчёт армирующей сетки для пола
/// - Расчёт демпферной ленты по периметру (для пола)
/// - Расчёт маяков (для пола)
/// - Расчёт грунтовки (для стен)
/// - Предупреждения о минимальной толщине
///
/// Поля:
/// - inputMode: режим ввода (0 = по размерам, 1 = по площади)
/// - length, width, height: размеры помещения (м) - для режима 0
/// - area, perimeter: площадь (м²) и периметр (м) - для режима 1
/// - applicationType: тип работ (0 = стяжка пола, 1 = штукатурка стен)
/// - mixType: марка смеси (0 = М300 Пескобетон, 1 = М150 Универсальная)
/// - thickness: толщина слоя (мм)
/// - bagWeight: вес мешка (кг), обычно 25, 40 или 50 кг
class CalculateDsp extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode'] ?? 0;
    if (inputMode == 1 && (inputs['area'] ?? 0) <= 0) {
      return 'Площадь должна быть больше нуля';
    }

    final thickness = inputs['thickness'] ?? 40;
    if (thickness < 1 || thickness > 200) {
      return 'Толщина слоя должна быть от 1 до 200 мм';
    }

    final bagWeight = inputs['bagWeight'] ?? 40;
    if (bagWeight < 1 || bagWeight > 100) {
      return 'Вес мешка должен быть от 1 до 100 кг';
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
    final applicationType = getIntInput(inputs, 'applicationType', defaultValue: 0); // 0 = пол, 1 = стены

    // Вычисляем площадь и периметр в зависимости от режима
    double area;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам"
      final length = getInput(inputs, 'length', defaultValue: 0.0);
      final width = getInput(inputs, 'width', defaultValue: 0.0);
      final height = getInput(inputs, 'height', defaultValue: 2.5);

      if (applicationType == 0) {
        // Для пола - площадь комнаты
        area = length * width;
        perimeter = (length + width) * 2;
      } else {
        // Для стен - площадь стен
        area = (length + width) * 2 * height;
        perimeter = (length + width) * 2;
      }
    } else {
      // Режим "По площади": берём готовые значения
      area = getInput(inputs, 'area', defaultValue: 0.0);
      perimeter = getInput(inputs, 'perimeter', defaultValue: 0.0);
    }

    // --- Получаем остальные входные данные ---
    final mixType = getIntInput(inputs, 'mixType', defaultValue: 0); // 0 = М300, 1 = М150
    final thickness = getInput(inputs, 'thickness', defaultValue: 40.0, minValue: 1.0, maxValue: 200.0);
    final bagWeight = getInput(inputs, 'bagWeight', defaultValue: 40.0, minValue: 1.0, maxValue: 100.0);

    // Учёт проёмов (только для стен)
    final windowsArea = applicationType == 1 ? getInput(inputs, 'windowsArea', defaultValue: 0.0) : 0.0;
    final doorsArea = applicationType == 1 ? getInput(inputs, 'doorsArea', defaultValue: 0.0) : 0.0;
    final usefulArea = calculateUsefulArea(area, windowsArea: windowsArea, doorsArea: doorsArea);

    if (usefulArea <= 0) {
      return createResult(values: {'error': 1.0, 'usefulArea': 0.0});
    }

    // --- Расход смеси ---
    // М300 Пескобетон: 2.0 кг/м²/мм (около 20-22 кг на 1 см)
    // М150 Универсальная: 1.8 кг/м²/мм (около 18 кг на 1 см)
    final consumption = mixType == 0 ? 2.0 : 1.8; // кг/м²/мм
    final totalWeight = usefulArea * thickness * consumption; // кг
    final bagsNeeded = ceilToInt(totalWeight / bagWeight);

    // --- Армирующая сетка (только для пола) ---
    // Сетка обычно 2м x 0.5м (1м²) или 2м x 1м (2м²)
    // Берём с перехлестом 10%
    final meshArea = applicationType == 0 ? usefulArea * 1.1 : 0.0;

    // --- Демпферная лента (только для пола) ---
    final tapeMeters = applicationType == 0 ? perimeter : 0.0;

    // --- Маяки (только для пола) ---
    // Грубый расчет: 1 маяк на 2 м² пола (шаг установки ~1м)
    final beaconsNeeded = applicationType == 0 ? ceilToInt(usefulArea / 2) : 0;

    // --- Грунтовка (только для стен) ---
    // Расход: 0.2 л/м² (1 слой)
    const primerConsumption = 0.2; // л/м²
    final primerLiters = applicationType == 1 ? usefulArea * primerConsumption : 0.0;
    final primerCanisters = applicationType == 1 ? ceilToInt(primerLiters / 10) : 0; // Канистры по 10л

    // --- Предупреждение о толщине ---
    double thicknessWarning = 0.0;
    if (applicationType == 0 && thickness < 30) {
      thicknessWarning = 1.0; // Стяжка тоньше 30мм может потрескаться
    }

    // --- Расчёт стоимости ---
    final mixSku = mixType == 0 ? 'dsp_m300' : 'dsp_m150';
    final mixPrice = findPrice(priceList, [mixSku, 'cement_sand_mix', 'dry_mix']);
    final meshPrice = findPrice(priceList, ['mesh_reinforcing', 'mesh']);
    final tapePrice = findPrice(priceList, ['tape_damper', 'damper_tape']);
    final beaconPrice = findPrice(priceList, ['beacon_metal', 'beacon']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final costs = [
      calculateCost(bagsNeeded.toDouble(), mixPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(tapeMeters, tapePrice?.price),
      calculateCost(beaconsNeeded.toDouble(), beaconPrice?.price),
      calculateCost(primerCanisters.toDouble(), primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': usefulArea,
        'totalWeightKg': totalWeight,
        'totalWeightTonnes': totalWeight / 1000,
        'bagsNeeded': bagsNeeded.toDouble(),
        'meshArea': meshArea,
        'tapeMeters': tapeMeters,
        'beaconsNeeded': beaconsNeeded.toDouble(),
        'primerCanisters': primerCanisters.toDouble(),
        'primerLiters': primerLiters,
        'thicknessWarning': thicknessWarning,
        'applicationType': applicationType.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
