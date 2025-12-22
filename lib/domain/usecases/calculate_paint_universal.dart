// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

/// Универсальный калькулятор покраски (стены, потолок, или всё).
///
/// Поддерживает:
/// - Выбор типа: только стены / только потолок / стены и потолок
/// - Два режима ввода: по площади или по размерам комнаты
/// - Учёт проёмов (окна и двери)
/// - Настраиваемое количество слоёв и запас
///
/// Поля:
/// - paintType: 0=стены, 1=потолок, 2=стены и потолок
/// - inputMode: 0=по площади, 1=по размерам комнаты
/// - wallArea, ceilingArea: площади (режим 0)
/// - length, width, height: размеры комнаты (режим 1)
/// - doorsWindows: площадь проёмов (м²)
/// - layers: количество слоёв (1-4)
/// - reserve: запас в процентах
class CalculatePaintUniversal extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final layers = inputs['layers'] ?? 2;
    if (layers < 1 || layers > 4) {
      return 'Количество слоёв должно быть от 1 до 4';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Получаем базовые параметры
    final paintType = getIntInput(inputs, 'paintType', defaultValue: 0); // 0=стены, 1=потолок, 2=оба
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0); // 0=площадь, 1=размеры
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 4);
    final reservePercent = getInput(inputs, 'reserve', defaultValue: 10, minValue: 0);
    final doorsWindows = getInput(inputs, 'doorsWindows', defaultValue: 0, minValue: 0);
    final consumption = getInput(inputs, 'consumption', defaultValue: 0.11, minValue: 0.01);

    // Вычисляем площади в зависимости от режима
    double wallArea = 0;
    double ceilingArea = 0;

    if (inputMode == 0) {
      // Режим "По площади"
      wallArea = getInput(inputs, 'wallArea', defaultValue: 0, minValue: 0);
      ceilingArea = getInput(inputs, 'ceilingArea', defaultValue: 0, minValue: 0);
    } else {
      // Режим "По размерам комнаты"
      final length = getInput(inputs, 'length', defaultValue: 5, minValue: 1);
      final width = getInput(inputs, 'width', defaultValue: 4, minValue: 1);
      final height = getInput(inputs, 'height', defaultValue: 2.7, minValue: 2);

      // Площадь стен = периметр * высота
      wallArea = (length + width) * 2 * height;
      // Площадь потолка = длина * ширина
      ceilingArea = length * width;
    }

    // Определяем, что нужно красить
    final needWalls = paintType == 0 || paintType == 2;
    final needCeiling = paintType == 1 || paintType == 2;

    // Вычитаем проёмы только из стен
    final double usefulWallArea = needWalls
        ? (wallArea - doorsWindows).clamp(0, double.infinity).toDouble()
        : 0.0;
    final double usefulCeilingArea = needCeiling ? ceilingArea : 0.0;
    final double totalArea = usefulWallArea + usefulCeilingArea;

    if (totalArea <= 0) {
      return createResult(values: {'error': 1.0});
    }

    // Расчёт краски
    // Первый слой: +20% к расходу (впитывание), остальные: по номиналу
    final firstLayerConsumption = consumption * 1.2;
    final otherLayerConsumption = consumption;

    final paintConsumption = firstLayerConsumption + (layers - 1) * otherLayerConsumption;
    final rawPaint = totalArea * paintConsumption;
    final paintWithReserve = rawPaint * (1 + reservePercent / 100);

    // Грунтовка: 0.12 л/м², один слой
    const primerConsumption = 0.12;
    final rawPrimer = totalArea * primerConsumption;
    final primerWithReserve = rawPrimer * (1 + reservePercent / 100);

    // Расходные материалы
    final rollersNeeded = ceilToInt(totalArea / 50); // 1 валик на ~50 м²
    final brushesNeeded = ceilToInt(totalArea / 40).clamp(2, 10); // минимум 2 кисти

    // Малярный скотч: примерно периметр комнаты * 1.5
    final estimatedPerimeter = estimatePerimeter(totalArea);
    final tapeNeeded = estimatedPerimeter * 1.5 * (1 + reservePercent / 100);

    // Округление
    final finalPaintLiters = roundBulk(paintWithReserve);
    final finalPrimerLiters = roundBulk(primerWithReserve);
    final finalTapeMeters = roundBulk(tapeNeeded);

    // Расчёт стоимости
    final paintPrice = findPrice(priceList, ['paint', 'paint_water', 'краска']);
    final primerPrice = findPrice(priceList, ['primer', 'грунтовка']);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape', 'скотч']);

    final costs = [
      calculateCost(finalPaintLiters, paintPrice?.price),
      calculateCost(finalPrimerLiters, primerPrice?.price),
      calculateCost(finalTapeMeters, tapePrice?.price),
    ];

    return createResult(
      values: {
        'totalArea': roundBulk(totalArea),
        'wallArea': roundBulk(usefulWallArea),
        'ceilingArea': roundBulk(usefulCeilingArea),
        'paintLiters': finalPaintLiters,
        'primerLiters': finalPrimerLiters,
        'tapeMeters': finalTapeMeters,
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'layers': layers.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
