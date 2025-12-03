import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор мокрого фасада (утепление + штукатурка).
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - СП 23-101-2004 "Проектирование тепловой защиты зданий"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - insulationThickness: толщина утеплителя (мм), по умолчанию 100
/// - insulationType: тип утеплителя (1=минвата, 2=пенопласт, 3=ЭППС), по умолчанию 2
class CalculateWetFacade extends BaseCalculator {
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
    final insulationThickness = getInput(inputs, 'insulationThickness', defaultValue: 100.0, minValue: 50.0, maxValue: 200.0);
    final insulationType = getIntInput(inputs, 'insulationType', defaultValue: 2, minValue: 1, maxValue: 3);

    // Объём утеплителя
    final insulationVolume = calculateVolume(area, insulationThickness);

    // Площадь одного листа утеплителя
    final sheetArea = insulationType == 1 ? 0.72 : (insulationType == 2 ? 0.5 : 0.72);
    final sheetsNeeded = calculateUnitsNeeded(area, sheetArea, marginPercent: 5.0);

    // Клей для утеплителя: 5-6 кг/м²
    final glueNeeded = area * 5;

    // Крепёж: дюбели-грибки, ~5-6 шт/м²
    final fastenersNeeded = ceilToInt(area * 5);

    // Армирующая сетка: площадь + 10% на нахлёсты
    final meshArea = addMargin(area, 10.0);

    // Базовый армирующий слой: ~3-4 кг/м²
    final baseCoatNeeded = area * 5.0;

    // Грунтовка: ~0.2 л/м²
    final primerNeeded = area * 0.2;

    // Декоративная штукатурка (короед/барашек): ~3 кг/м²
    final finishPlasterNeeded = area * 0.5;

    // Краска фасадная (при необходимости): ~0.15 л/м² в 2 слоя
    final paintNeeded = area * 0.15 * 2;

    // Угловые профили с сеткой: по факту
    final cornerProfileLength = getInput(inputs, 'corners', defaultValue: 0.0);

    // Стартовый профиль (цокольный): по периметру
    final startProfileLength = getInput(inputs, 'startProfile', defaultValue: 0.0);

    // Деформационный профиль: по факту
    final expansionProfileLength = getInput(inputs, 'expansion', defaultValue: 0.0);

    // Расчёт стоимости
    final insulationPrice = insulationType == 1
        ? findPrice(priceList, ['mineral_wool', 'wool_insulation', 'facade_wool'])
        : (insulationType == 2 
            ? findPrice(priceList, ['foam', 'foam_insulation', 'eps', 'polystyrene'])
            : findPrice(priceList, ['xps', 'extruded_polystyrene', 'epps']));
    final gluePrice = findPrice(priceList, ['glue_insulation', 'glue_foam', 'facade_adhesive']);
    final fastenerPrice = findPrice(priceList, ['fastener_insulation', 'dowel_umbrella']);
    final meshPrice = findPrice(priceList, ['mesh_armor', 'mesh_facade', 'fiberglass_mesh']);
    final baseCoatPrice = findPrice(priceList, ['base_coat', 'adhesive_layer']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_facade']);
    final finishPlasterPrice = findPrice(priceList, ['plaster_decorative', 'plaster_facade']);
    final paintPrice = findPrice(priceList, ['paint_facade', 'facade_paint']);
    final cornerProfilePrice = findPrice(priceList, ['profile_corner', 'corner_bead']);
    final startProfilePrice = findPrice(priceList, ['profile_start', 'base_profile']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), insulationPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(baseCoatNeeded, baseCoatPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(finishPlasterNeeded, finishPlasterPrice?.price),
      calculateCost(paintNeeded, paintPrice?.price),
      if (cornerProfileLength > 0) calculateCost(cornerProfileLength, cornerProfilePrice?.price),
      if (startProfileLength > 0) calculateCost(startProfileLength, startProfilePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'insulationThickness': insulationThickness,
        'insulationVolume': insulationVolume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'meshArea': meshArea,
        'plasterNeeded': baseCoatNeeded,
        'primerNeeded': primerNeeded,
        'finishNeeded': finishPlasterNeeded,
        'paintNeeded': paintNeeded,
        if (cornerProfileLength > 0) 'cornerProfileLength': cornerProfileLength,
        if (startProfileLength > 0) 'startProfileLength': startProfileLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
