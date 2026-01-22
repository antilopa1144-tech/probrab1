// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор наливного пола с гибридным режимом ввода.
///
/// Поддерживает два режима ввода:
/// 1. **По размерам** (inputMode = 0): длина и ширина → автоматический расчёт площади/периметра
/// 2. **По площади** (inputMode = 1): готовая площадь
///
/// Логика (согласно спецификации):
/// - Расход: Площадь × Толщина (мм) × Расход (~1.6 кг/мм)
/// - Вывод: Общий вес (кг) и количество мешков (20/25кг)
/// - Дополнительно: Грунтовка (литры), Демпферная лента (периметр)
///
/// Нормативы:
/// - СНиП 2.03.13-88 "Полы"
/// - ГОСТ 31356-2007 "Смеси сухие строительные"
///
/// Поля:
/// - inputMode: режим ввода (0 = по размерам, 1 = по площади)
/// - length, width: размеры помещения (м) - только для режима 0
/// - area: площадь пола (м²) - только для режима 1
/// - thickness: толщина слоя (мм), по умолчанию 10
/// - consumption: расход смеси (кг/м²·мм), по умолчанию 1.6
/// - bagWeight: вес мешка (20 или 25 кг)
class CalculateSelfLevelingFloor extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = (inputs['inputMode'] ?? 0).toInt();

    if (inputMode == 0) {
      // Режим "По размерам": проверяем length и width
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length <= 0) return 'Длина должна быть больше нуля';
      if (width <= 0) return 'Ширина должна быть больше нуля';
    } else {
      // Режим "По площади": проверяем area
      if ((inputs['area'] ?? 0) <= 0) return 'Площадь должна быть больше нуля';
    }

    final thickness = inputs['thickness'] ?? 10.0;
    if (thickness < 3 || thickness > 100) {
      return 'Толщина должна быть от 3 до 100 мм';
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

    // Вычисляем площадь и периметр в зависимости от режима
    double area;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам": вычисляем площадь и периметр
      final length = getInput(inputs, 'length', minValue: 0.1);
      final width = getInput(inputs, 'width', minValue: 0.1);

      area = length * width;
      perimeter = (length + width) * 2;
    } else {
      // Режим "По площади": берём готовую площадь, оцениваем периметр
      area = getInput(inputs, 'area', minValue: 0.1);
      perimeter = estimatePerimeter(area);
    }

    // --- Получаем остальные входные данные ---
    final thickness = getInput(inputs, 'thickness', defaultValue: 10.0, minValue: 3.0, maxValue: 100.0);
    final consumption = getInput(inputs, 'consumption', defaultValue: 1.6, minValue: 1.3, maxValue: 2.0);
    final bagWeight = getInput(inputs, 'bagWeight', defaultValue: 25.0);

    // --- Расчёт материалов (согласно спецификации) ---
    // Расход наливного пола: Площадь × Толщина (мм) × Расход (кг/м²·мм)
    final mixNeededKg = area * thickness * consumption;

    // Количество мешков (округление вверх до целых)
    final bagsNeeded = (mixNeededKg / bagWeight).ceil();

    // Грунтовка глубокого проникновения: ~0.15 л/м²
    final primerNeededLiters = area * 0.15;

    // Демпферная лента по периметру (м)
    final damperTapeLengthMeters = perimeter;

    // --- Применяем правила округления ---
    final finalMixKg = roundBulk(mixNeededKg);
    final finalPrimerLiters = roundBulk(primerNeededLiters);
    final finalDamperTapeMeters = roundBulk(damperTapeLengthMeters);

    // --- Расчёт стоимости ---
    final mixPrice = findPrice(priceList, ['self_leveling', 'self_leveling_floor', 'leveling_compound', 'floor_leveler']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_penetrating']);
    final damperTapePrice = findPrice(priceList, ['damper_tape', 'tape_edge', 'expansion_tape']);

    final costs = [
      calculateCost(finalMixKg, mixPrice?.price),
      calculateCost(finalPrimerLiters, primerPrice?.price),
      calculateCost(finalDamperTapeMeters, damperTapePrice?.price),
    ];

    return createResult(
      values: {
        'area': roundBulk(area),
        'thickness': thickness,
        'mixNeededKg': finalMixKg,
        'bagsNeeded': bagsNeeded.toDouble(),
        'bagWeight': bagWeight,
        'primerNeededLiters': finalPrimerLiters,
        'damperTapeLengthMeters': finalDamperTapeMeters,
      },
      totalPrice: sumCosts(costs),
      norms: ['СНиП 2.03.13-88', 'ГОСТ 31356-2007'],
    );
  }
}
