// ignore_for_file: prefer_const_declarations
import 'dart:math' as math;
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор линолеума с гибридным режимом ввода.
///
/// Поддерживает два режима ввода:
/// 1. **По размерам** (inputMode = 0): длина и ширина комнаты → точный расчёт резов
/// 2. **По площади** (inputMode = 1): площадь + ширина комнаты → расчёт резов
///
/// КРИТИЧНО: Требует ширину комнаты в режиме "По площади" для расчёта количества резов!
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 18108-80 "Линолеум поливинилхлоридный"
///
/// Поля:
/// - inputMode: режим ввода (0 = по размерам, 1 = по площади)
/// - length, width: размеры комнаты (м) - только для режима 0
/// - area: площадь пола (м²) - только для режима 1
/// - roomWidth: ширина комнаты (м) - ОБЯЗАТЕЛЬНО для режима 1
/// - rollWidth: ширина рулона (м), по умолчанию 3.0
/// - withGlue: использовать клей (bool)
/// - withPlinth: использовать плинтус (bool)
class CalculateLinoleum extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode'] ?? 0;
    if (inputMode == 1) {
      if ((inputs['area'] ?? 0) <= 0) return 'Площадь должна быть больше нуля';
      if ((inputs['roomWidth'] ?? 0) <= 0) return 'Укажите ширину комнаты для расчёта резов';
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
    double roomWidth;
    double roomLength;
    double perimeter;

    if (inputMode == 0) {
      // Режим "По размерам": точные размеры комнаты
      roomLength = getInput(inputs, 'length', minValue: 0.1);
      roomWidth = getInput(inputs, 'width', minValue: 0.1);

      area = roomLength * roomWidth;
      perimeter = (roomLength + roomWidth) * 2;
    } else {
      // Режим "По площади": требуем ширину для расчёта резов
      area = getInput(inputs, 'area', minValue: 0.1);
      roomWidth = getInput(inputs, 'roomWidth', minValue: 0.1);

      roomLength = area / roomWidth;
      final perimeterInput = inputs['perimeter'] ?? 0.0;
      perimeter = perimeterInput > 0 ? perimeterInput : estimatePerimeter(area);
    }

    // --- Получаем остальные входные данные ---
    final rollWidth = getInput(inputs, 'rollWidth', defaultValue: 3.0, minValue: 1.5, maxValue: 5.0);
    final withGlue = getIntInput(inputs, 'withGlue', defaultValue: 0) != 0;
    final withPlinth = getIntInput(inputs, 'withPlinth', defaultValue: 1) != 0;

    // --- Расчёт количества резов (полос) ---
    // Количество полос = ширина комнаты / ширина рулона (округление вверх)
    final cutsNeeded = (roomWidth / rollWidth).ceil();

    // Длина одного реза = длина комнаты + 10 см запаса
    final cutLength = roomLength + 0.1;

    // Общая площадь линолеума с учетом резов
    final totalLinoleumArea = cutsNeeded * cutLength * rollWidth;

    // --- Аксессуары ---
    // Холодная сварка для швов: 1 туба на 20-25 пог. м шва
    final seamsLength = cutsNeeded > 1 ? (cutsNeeded - 1) * roomLength : 0.0;
    final coldWeldingTubes = seamsLength > 0 ? math.max(1, (seamsLength / 20).ceil()) : 0;

    // Клей (если используется): ~0.3-0.5 кг/м²
    final glueNeeded = withGlue ? area * 0.4 : 0.0;

    // Плинтус (если используется): периметр + 5% на подрезку
    final plinthLength = withPlinth ? perimeter * 1.05 : 0.0;
    final plinthPieces = withPlinth ? (plinthLength / 2.5).ceil() : 0; // Плинтус обычно 2.5 м

    // --- Применяем правила округления ---
    final finalLinoleumArea = roundBulk(totalLinoleumArea);
    final finalGlue = withGlue ? roundBulk(glueNeeded) : 0.0;
    final finalPlinthLength = withPlinth ? roundBulk(plinthLength) : 0.0;

    // --- Расчёт стоимости ---
    final linoleumPrice = findPrice(priceList, ['linoleum', 'linoleum_pvc', 'vinyl_flooring']);
    final plinthPrice = findPrice(priceList, ['plinth', 'plinth_linoleum', 'baseboard']);
    final gluePrice = findPrice(priceList, ['glue_linoleum', 'glue', 'flooring_adhesive']);
    final coldWeldingPrice = findPrice(priceList, ['cold_welding', 'linoleum_welding']);

    final costs = [
      calculateCost(finalLinoleumArea, linoleumPrice?.price),
      withPlinth ? calculateCost(finalPlinthLength, plinthPrice?.price) : null,
      withGlue ? calculateCost(finalGlue, gluePrice?.price) : null,
      coldWeldingTubes > 0 ? calculateCost(coldWeldingTubes.toDouble(), coldWeldingPrice?.price) : null,
    ];

    // Погонные метры: количество полос × длина одной полосы
    final linearMeters = roundBulk(cutsNeeded * cutLength);

    return createResult(
      values: {
        'area': roundBulk(area),
        'linoleumAreaNeeded': finalLinoleumArea,
        'linearMeters': linearMeters,
        'rollWidth': rollWidth,
        'cutsNeeded': cutsNeeded.toDouble(),
        'cutLength': roundBulk(cutLength),
        if (coldWeldingTubes > 0) 'coldWeldingTubes': coldWeldingTubes.toDouble(),
        if (withGlue) 'glueNeededKg': finalGlue,
        if (withPlinth) 'plinthLengthMeters': finalPlinthLength,
        if (withPlinth) 'plinthPieces': plinthPieces.toDouble(),
      },
      totalPrice: sumCosts(costs),
      norms: ['СНиП 3.04.01-87', 'ГОСТ 18108-80'],
    );
  }
}
