// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор утепления пенопластом / ЭППС.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 15588-2014 "Плиты пенополистирольные"
///
/// Поля:
/// - area: площадь утепления (м²)
/// - thickness: толщина утеплителя (мм), по умолчанию 50
/// - density: плотность (кг/м³), по умолчанию 25 (пенопласт)
/// - type: тип (1=ПСБ/пенопласт, 2=ЭППС/экструдированный), по умолчанию 1
class CalculateInsulationFoam extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final thickness = inputs['thickness'] ?? 50;

    if (area <= 0) return 'Площадь должна быть больше нуля';
    if (thickness < 20 || thickness > 200) return 'Толщина должна быть от 20 до 200 мм';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 20.0, maxValue: 200.0);
    final density = getInput(inputs, 'density', defaultValue: 25.0, minValue: 15.0, maxValue: 50.0);
    final type = getIntInput(inputs, 'type', defaultValue: 1, minValue: 1, maxValue: 2);

    // Объём утеплителя в м³
    final volume = calculateVolume(area, thickness);

    // Площадь одного листа (стандарт: 1×0.5 м = 0.5 м² или 1.2×0.6 м = 0.72 м²)
    final sheetArea = type == 1 ? 0.5 : 0.72;

    // Количество листов с запасом 5%
    final sheetsNeeded = calculateUnitsNeeded(area, sheetArea, marginPercent: 5.0);

    // Вес утеплителя
    final weight = volume * density;

    // Пароизоляция: только для пенопласта (ПСБ), ЭППС сам паронепроницаем
    // ЭППС не требует пароизоляции согласно СП 50.13330.2012
    final vaporBarrierArea = type == 1 ? addMargin(area, 10.0) : 0.0;

    // Гидроизоляция/ветрозащита (для наружного утепления): площадь + 10%
    final windBarrierArea = addMargin(area, 10.0);

    // Соединительная лента: по швам
    final perimeter = inputs['perimeter'] != null && inputs['perimeter']! > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1)
        : estimatePerimeter(area);
    final tapeNeeded = perimeter * 1.5; // +50% на стыки

    // Клей для пенопласта: 4-6 кг/м² (зависит от неровности поверхности)
    final glueNeeded = area * 5.0;

    // Клей-пена (альтернатива сухой смеси): 1 баллон на 10-12 м²
    final foamGlueNeeded = ceilToInt(area / 11);

    // Крепёж: дюбели-грибки, ~5 шт/м²
    final fastenersNeeded = ceilToInt(area * 5);

    // Армирующая сетка (для фасада): площадь + 10% на нахлёсты
    final meshArea = addMargin(area, 10.0);

    // Базовый армирующий слой (для сетки): ~3-4 кг/м²
    final baseCoatNeeded = area * 3.5;

    // Грунтовка: ~0.2 л/м²
    final primerNeeded = area * 0.2;

    // Угловые профили с сеткой: по факту
    final cornerProfileLength = getInput(inputs, 'corners', defaultValue: 0.0);

    // Стартовый профиль (цокольный): по периметру фасада
    final startProfileLength = getInput(inputs, 'startProfile', defaultValue: 0.0);

    // Расчёт стоимости
    final foamPrice = type == 1
        ? findPrice(priceList, ['foam', 'foam_insulation', 'eps', 'polystyrene'])
        : findPrice(priceList, ['xps', 'extruded_polystyrene', 'epps', 'foam_extruded']);
    final gluePrice = findPrice(priceList, ['glue_foam', 'glue_insulation', 'adhesive_foam']);
    final foamGluePrice = findPrice(priceList, ['foam_glue', 'adhesive_foam_gun']);
    final fastenerPrice = findPrice(priceList, ['fastener_insulation', 'dowel_umbrella', 'mushroom_dowel']);
    final meshPrice = findPrice(priceList, ['mesh_armor', 'mesh_facade', 'fiberglass_mesh']);
    final baseCoatPrice = findPrice(priceList, ['base_coat', 'adhesive_layer']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_adhesion']);
    final vaporBarrierPrice = findPrice(priceList, ['vapor_barrier', 'film_vapor', 'barrier_membrane']);
    final windBarrierPrice = findPrice(priceList, ['wind_barrier', 'membrane_wind', 'windproof_membrane']);
    final tapePrice = findPrice(priceList, ['tape', 'joining_tape', 'sealing_tape']);
    final cornerProfilePrice = findPrice(priceList, ['profile_corner', 'corner_bead_mesh']);
    final startProfilePrice = findPrice(priceList, ['profile_start', 'base_profile']);

    final costs = [
      calculateCost(sheetsNeeded.toDouble(), foamPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(foamGlueNeeded.toDouble(), foamGluePrice?.price),
      calculateCost(fastenersNeeded.toDouble(), fastenerPrice?.price),
      if (vaporBarrierArea > 0) calculateCost(vaporBarrierArea, vaporBarrierPrice?.price),
      calculateCost(windBarrierArea, windBarrierPrice?.price),
      calculateCost(tapeNeeded, tapePrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(baseCoatNeeded, baseCoatPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (cornerProfileLength > 0) calculateCost(cornerProfileLength, cornerProfilePrice?.price),
      if (startProfileLength > 0) calculateCost(startProfileLength, startProfilePrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'density': density,
        'volume': volume,
        'sheetsNeeded': sheetsNeeded.toDouble(),
        'weight': weight,
        // Пароизоляция только для ПСБ (type=1), ЭППС паронепроницаем
        if (vaporBarrierArea > 0) 'vaporBarrierArea': vaporBarrierArea,
        'windBarrierArea': windBarrierArea,
        'glueNeeded': glueNeeded,
        'foamGlueNeeded': foamGlueNeeded.toDouble(),
        'fastenersNeeded': fastenersNeeded.toDouble(),
        'tapeNeeded': tapeNeeded,
        'meshArea': meshArea,
        'baseCoatNeeded': baseCoatNeeded,
        'primerNeeded': primerNeeded,
        if (cornerProfileLength > 0) 'cornerProfileLength': cornerProfileLength,
        if (startProfileLength > 0) 'startProfileLength': startProfileLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
