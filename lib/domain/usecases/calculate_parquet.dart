import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор паркета / массива.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 862.1-85 "Паркет штучный"
///
/// Поля:
/// - area: площадь пола (м²)
/// - plankWidth: ширина планки (см), по умолчанию 7
/// - plankLength: длина планки (см), по умолчанию 40
/// - thickness: толщина (мм), по умолчанию 15
/// - perimeter: периметр комнаты (м), опционально
class CalculateParquet extends BaseCalculator {
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
    final plankWidth = getInput(inputs, 'plankWidth', defaultValue: 7.0, minValue: 5.0, maxValue: 20.0);
    final plankLength = getInput(inputs, 'plankLength', defaultValue: 40.0, minValue: 20.0, maxValue: 100.0);
    final thickness = getInput(inputs, 'thickness', defaultValue: 15.0, minValue: 10.0, maxValue: 22.0);
    
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной планки
    final plankArea = calculateTileArea(plankWidth, plankLength);

    // Количество планок с запасом 5-7% (для паркета)
    final planksNeeded = calculateUnitsNeeded(area, plankArea, marginPercent: 7.0);

    // Лак: расход ~0.1 л/м² на слой, обычно 3 слоя
    final varnishLayers = 3;
    final varnishNeeded = area * 0.1 * varnishLayers * 1.05;

    // Грунтовка для паркета: ~0.08 л/м²
    final primerNeeded = area * 0.08 * 1.05;

    // Плинтус: периметр + 5%
    final plinthLength = addMargin(perimeter, 5.0);

    // Клей для паркета: ~1.2-1.5 кг/м²
    final glueNeeded = area * 1.4;

    // Подложка (фанера): площадь пола (для массивной доски)
    final plywoodArea = area;

    // Шпатлёвка для швов: ~0.3 кг/м²
    final fillerNeeded = area * 0.3;

    // Шлифовальная бумага: комплект на комнату
    final sandpaperSets = ceilToInt(area / 20); // 1 комплект на 20 м²

    // Расчёт стоимости
    final parquetPrice = findPrice(priceList, ['parquet', 'parquet_plank', 'wood_floor', 'hardwood']);
    final varnishPrice = findPrice(priceList, ['varnish', 'varnish_parquet', 'floor_finish']);
    final primerPrice = findPrice(priceList, ['primer_parquet', 'primer', 'wood_primer']);
    final plinthPrice = findPrice(priceList, ['plinth_parquet', 'plinth', 'wood_baseboard']);
    final gluePrice = findPrice(priceList, ['glue_parquet', 'glue', 'wood_adhesive']);
    final plywoodPrice = findPrice(priceList, ['plywood', 'plywood_sheet']);
    final fillerPrice = findPrice(priceList, ['filler', 'wood_filler', 'putty']);

    final costs = [
      calculateCost(planksNeeded.toDouble(), parquetPrice?.price),
      calculateCost(varnishNeeded, varnishPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(plinthLength, plinthPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(plywoodArea, plywoodPrice?.price),
      calculateCost(fillerNeeded, fillerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'planksNeeded': planksNeeded.toDouble(),
        'varnishNeeded': varnishNeeded,
        'varnishLayers': varnishLayers.toDouble(),
        'primerNeeded': primerNeeded,
        'plinthLength': plinthLength,
        'glueNeeded': glueNeeded,
        'plywoodArea': plywoodArea,
        'fillerNeeded': fillerNeeded,
        'sandpaperSets': sandpaperSets.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
