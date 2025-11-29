import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор гидроизоляции ванной комнаты.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - СП 28.13330.2017 "Защита строительных конструкций от коррозии"
///
/// Поля:
/// - floorArea: площадь пола (м²)
/// - wallHeight: высота обработки стен (м), по умолчанию 0.3
/// - perimeter: периметр ванной (м)
/// - layers: количество слоёв гидроизоляции, по умолчанию 2
class CalculateWaterproofing extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final floorArea = inputs['floorArea'] ?? 0;
    final perimeter = inputs['perimeter'] ?? 0;

    if (floorArea <= 0) return 'Площадь пола должна быть больше нуля';
    if (perimeter <= 0) return 'Периметр должен быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final floorArea = getInput(inputs, 'floorArea', minValue: 0.1);
    final wallHeight = getInput(inputs, 'wallHeight', defaultValue: 0.3, minValue: 0.1, maxValue: 2.5);
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(floorArea);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 3);

    // Площадь гидроизоляции: пол + стены на высоту
    final wallArea = perimeter * wallHeight;
    final totalArea = floorArea + wallArea;

    // Расход материала: ~1.5-2.0 кг/м² на слой для обмазочной гидроизоляции
    final consumptionPerLayer = 1.8; // кг/м²
    final materialNeeded = totalArea * consumptionPerLayer * layers * 1.05; // +5%

    // Грунтовка: ~0.2-0.25 л/м², 1 слой перед гидроизоляцией
    final primerNeeded = totalArea * 0.22;

    // Армирующая лента для углов и стыков: периметр + внутренние углы
    final tapeLength = perimeter * 1.3; // +30% на вертикальные углы

    // Гидроизоляционная лента для стыков: периметр пола
    final hydroTapeLength = perimeter;

    // Кисти/валики для нанесения: 1-2 комплекта
    final toolsNeeded = 1;

    // Проникающая гидроизоляция для швов: ~0.5 кг/м.п.
    final penetratingNeeded = perimeter * 0.5;

    // Расчёт стоимости
    final materialPrice = findPrice(priceList, [
      'waterproofing', 
      'waterproofing_bathroom', 
      'waterproofing_coating',
      'bitumen_mastic'
    ]);
    final primerPrice = findPrice(priceList, [
      'primer', 
      'primer_waterproofing', 
      'primer_adhesion'
    ]);
    final tapePrice = findPrice(priceList, [
      'tape_waterproofing', 
      'tape_armor', 
      'sealing_tape'
    ]);
    final hydroTapePrice = findPrice(priceList, [
      'tape_hydro', 
      'waterproof_tape'
    ]);
    final penetratingPrice = findPrice(priceList, [
      'waterproofing_penetrating',
      'penetrating_seal'
    ]);

    final costs = [
      calculateCost(materialNeeded, materialPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(tapeLength, tapePrice?.price),
      calculateCost(hydroTapeLength, hydroTapePrice?.price),
      calculateCost(penetratingNeeded, penetratingPrice?.price),
    ];

    return createResult(
      values: {
        'floorArea': floorArea,
        'wallArea': wallArea,
        'totalArea': totalArea,
        'materialNeeded': materialNeeded,
        'primerNeeded': primerNeeded,
        'tapeLength': tapeLength,
        'hydroTapeLength': hydroTapeLength,
        'penetratingNeeded': penetratingNeeded,
        'layers': layers.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
