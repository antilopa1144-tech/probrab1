import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор плиточного клея.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 31377-2008 "Смеси сухие строительные"
///
/// Поля:
/// - area: площадь укладки (м²)
/// - tileSize: размер плитки (см), по умолчанию 30
/// - layerThickness: толщина слоя клея (мм), по умолчанию 5
/// - surface: тип поверхности (1=стена, 2=пол), по умолчанию 2
class CalculateTileGlue extends BaseCalculator {
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
    final tileSize = getInput(inputs, 'tileSize', defaultValue: 30.0, minValue: 5.0, maxValue: 150.0);
    final layerThickness = getInput(inputs, 'layerThickness', defaultValue: 5.0, minValue: 2.0, maxValue: 15.0);
    final surface = getIntInput(inputs, 'surface', defaultValue: 2, minValue: 1, maxValue: 2);

    // Расход клея зависит от размера плитки, толщины слоя и типа поверхности
    // Базовый расход для плитки 30×30 при слое 5 мм: 4-4.5 кг/м²
    // Для стены расход выше на ~10% (из-за потерь)
    
    var baseConsumption = 4.2; // кг/м²
    
    // Корректировка по размеру плитки
    if (tileSize < 10) {
      baseConsumption *= 1.3; // мозаика
    } else if (tileSize < 20) {
      baseConsumption *= 1.15;
    } else if (tileSize > 60) {
      baseConsumption *= 0.85; // крупная плитка
    }
    
    // Корректировка по толщине слоя
    final thicknessFactor = layerThickness / 5.0;
    
    // Корректировка по типу поверхности
    final surfaceFactor = surface == 1 ? 1.1 : 1.0;
    
    final consumptionPerM2 = baseConsumption * thicknessFactor * surfaceFactor;
    
    // Общий расход с запасом 8%
    final glueNeeded = area * consumptionPerM2 * 1.08;

    // Грунтовка перед укладкой: ~0.15 л/м²
    final primerNeeded = area * 0.15;

    // Зубчатые шпатели: размер зуба зависит от размера плитки
    // 6 мм для плитки до 20 см, 8 мм до 30 см, 10 мм более 30 см
    final notchSize = tileSize < 20 ? 6 : (tileSize < 40 ? 8 : 10);
    final spatulasNeeded = 1;

    // Крестики для швов: ~5 шт на плитку
    final tilesCount = ceilToInt(area / ((tileSize / 100) * (tileSize / 100)));
    final crossesNeeded = tilesCount * 5;

    // Ёмкость для замешивания: 1 шт
    final bucketsNeeded = 1;

    // Вода для замешивания (информативно): ~0.25 л на кг
    final waterNeeded = glueNeeded * 0.25;

    // Расчёт стоимости
    final gluePrice = findPrice(priceList, [
      'glue_tile', 
      'tile_adhesive', 
      'glue',
      'mortar_tile'
    ]);
    final primerPrice = findPrice(priceList, ['primer', 'primer_adhesion']);

    final costs = [
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'glueNeeded': glueNeeded,
        'consumptionPerM2': consumptionPerM2,
        'primerNeeded': primerNeeded,
        'notchSize': notchSize.toDouble(),
        'spatulasNeeded': spatulasNeeded.toDouble(),
        'crossesNeeded': crossesNeeded.toDouble(),
        'bucketsNeeded': bucketsNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
