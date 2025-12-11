// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

/// Калькулятор покраски стен.
///
/// Поддерживает два режима ввода:
/// 1. **По размерам** (inputMode = 0): длина, ширина, высота → автоматический расчёт площади/периметра
/// 2. **По площади** (inputMode = 1): готовая площадь и периметр
///
/// Функции:
/// - Вычисление площади и периметра из размеров помещения (режим 0)
/// - Учёт проёмов (окна, двери)
/// - Расчёт краски с учётом количества слоёв
/// - Расчёт грунтовки и расходных материалов
/// - Настраиваемый запас материала (слайдер %)
/// - Правила округления для разных объёмов
///
/// Поля:
/// - inputMode: режим ввода (0 = по размерам, 1 = по площади)
/// - length, width, height: размеры помещения (м) - только для режима 0
/// - area, perimeter: площадь (м²) и периметр (м) - только для режима 1
/// - layers: количество слоёв краски (обычно 2)
/// - consumption: расход краски (л/м²), по умолчанию 0.12
/// - reserve: запас материала в процентах (%)
/// - windowsArea: площадь окон (м²)
/// - doorsArea: площадь дверей (м²)
class CalculateWallPaint extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    // В режиме "по размерам" area вычисляется и может быть 0 до ввода данных
    final inputMode = inputs['inputMode'] ?? 0;
    if (inputMode == 1 && (inputs['area'] ?? 0) <= 0) {
      return 'Площадь должна быть больше нуля';
    }
    if ((inputs['layers'] ?? 2) < 1) {
      return 'Количество слоёв должно быть не меньше 1';
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
      final height = getInput(inputs, 'height', minValue: 0.1);

      area = (length + width) * 2 * height;
      perimeter = (length + width) * 2;
    } else {
      // Режим "По площади": берём готовые значения
      area = getInput(inputs, 'area', minValue: 0.1);
      perimeter = getInput(inputs, 'perimeter', minValue: 0.1);
    }

    // --- Получаем остальные входные данные ---
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 5);
    final consumption = getInput(inputs, 'consumption', defaultValue: 0.12, minValue: 0.08, maxValue: 0.25);
    final reservePercent = getInput(inputs, 'reserve', defaultValue: 5, minValue: 0);

    final windowsArea = getInput(inputs, 'windowsArea', minValue: 0.0);
    final doorsArea = getInput(inputs, 'doorsArea', minValue: 0.0);

    // --- Вычисляем полезную площадь ---
    final usefulArea = calculateUsefulArea(area, windowsArea: windowsArea, doorsArea: doorsArea);

    if (usefulArea <= 0) {
      return createResult(values: {'error': 1.0, 'usefulArea': 0.0});
    }

    // --- Расчёт материалов ---
    final reserveFactor = 1.0 + (reservePercent / 100.0);

    // Расход краски: первый слой берёт на 20% больше
    final firstLayerConsumption = consumption * 1.2;
    final otherLayersConsumption = layers > 1 ? (layers - 1) * consumption : 0.0;
    final totalPaintConsumption = firstLayerConsumption + otherLayersConsumption;
    
    final rawPaintNeeded = usefulArea * totalPaintConsumption;
    final paintWithReserve = rawPaintNeeded * reserveFactor;

    // Грунтовка: расход 0.12 л/м², один слой
    const primerConsumption = 0.12; // л/м²
    final rawPrimerNeeded = usefulArea * primerConsumption;
    final primerWithReserve = rawPrimerNeeded * reserveFactor;

    // Малярный скотч: периметр проёмов + периметр комнаты
    // Для простоты берём периметр комнаты * 1.2 (запас на проёмы)
    final tapeNeeded = perimeter * 1.2 * reserveFactor;

    // Расходные материалы (штучные)
    final rollersNeeded = ceilToInt(usefulArea / 50); // 1 валик на ~50 м²
    final brushesNeeded = ceilToInt(usefulArea / 40); // 1 кисть на ~40 м²

    // --- Применяем правила округления ---
    final finalPaintLiters = roundBulk(paintWithReserve);
    final finalPrimerLiters = roundBulk(primerWithReserve);
    final finalTapeMeters = roundBulk(tapeNeeded);

    // --- Расчёт стоимости ---
    final paintPrice = findPrice(priceList, ['paint_wall', 'paint']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape']);

    final costs = [
      calculateCost(finalPaintLiters, paintPrice?.price),
      calculateCost(finalPrimerLiters, primerPrice?.price),
      calculateCost(finalTapeMeters, tapePrice?.price),
    ];

    return createResult(
      values: {
        'usefulArea': roundBulk(usefulArea),
        'paintNeededLiters': finalPaintLiters,
        'primerNeededLiters': finalPrimerLiters,
        'tapeNeededMeters': finalTapeMeters,
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'layers': layers.toDouble(),
        'reserve': reservePercent,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
