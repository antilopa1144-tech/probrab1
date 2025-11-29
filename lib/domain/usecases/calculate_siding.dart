import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор сайдинга (винил / металл / фиброцемент).
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
/// - ГОСТ 32603-2012 "Панели фасадные"
///
/// Поля:
/// - area: площадь фасада (м²)
/// - panelWidth: ширина панели (см), по умолчанию 20
/// - panelLength: длина панели (см), по умолчанию 300
/// - perimeter: периметр здания (м), опционально
/// - corners: количество углов, по умолчанию 4
/// - soffitLength: длина софитов (м), опционально
class CalculateSiding extends BaseCalculator {
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
    // Получаем валидированные входные данные
    final area = getInput(inputs, 'area', minValue: 0.1);
    final panelWidth = getInput(inputs, 'panelWidth', defaultValue: 20.0, minValue: 10.0, maxValue: 30.0);
    final panelLength = getInput(inputs, 'panelLength', defaultValue: 300.0, minValue: 200.0, maxValue: 600.0);
    final corners = getIntInput(inputs, 'corners', defaultValue: 4, minValue: 0, maxValue: 20);

    // Периметр: если указан - используем, иначе оцениваем
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);

    // Площадь одной панели в м²
    final panelArea = calculateTileArea(panelWidth, panelLength);

    // Количество панелей с запасом 10-12% на подрезку
    final panelsNeeded = calculateUnitsNeeded(area, panelArea, marginPercent: 12.0);

    // J-профиль: для вертикальных стыков и обрамления проёмов
    // Периметр + окна/двери (примерно +20% от периметра)
    final jProfileLength = addMargin(perimeter, 20.0);

    // Внешние и внутренние углы
    // Обычно высота здания ~6-8 м, угол длиной 3 м
    final buildingHeight = getInput(inputs, 'buildingHeight', defaultValue: 6.0, minValue: 2.0, maxValue: 15.0);
    final cornerLength = corners * (buildingHeight / 3.0).ceil() * 3.0;

    // Стартовая планка: по всему периметру внизу
    final startStripLength = addMargin(perimeter, 5.0);

    // Финишная планка: по всему периметру вверху
    final finishStripLength = addMargin(perimeter, 5.0);

    // Софиты (подшивка карниза): если не указано, считаем 10% от периметра
    final soffitLength = inputs['soffitLength'] ?? (perimeter * 0.1);

    // Саморезы: ~8-10 шт на панель
    final screwsNeeded = panelsNeeded * 9;

    // Обрешётка (если нужна): вертикальные направляющие с шагом 40-60 см
    final battensLength = (perimeter / 0.5) * buildingHeight;

    // Ветро-влагозащитная мембрана: площадь фасада + 10%
    final membraneArea = addMargin(area, 10.0);

    // Утеплитель (если планируется): площадь фасада
    final insulationArea = getInput(inputs, 'insulationArea', defaultValue: 0.0);

    // Расчёт стоимости
    final sidingPrice = findPrice(priceList, ['siding', 'siding_vinyl', 'siding_metal']);
    final jProfilePrice = findPrice(priceList, ['profile_j', 'j_profile']);
    final cornerPrice = findPrice(priceList, ['corner_siding', 'corner']);
    final startStripPrice = findPrice(priceList, ['start_strip', 'strip_start']);
    final finishStripPrice = findPrice(priceList, ['finish_strip', 'strip_finish']);
    final soffitPrice = findPrice(priceList, ['soffit', 'soffit_siding']);
    final battensPrice = findPrice(priceList, ['battens', 'wood_batten']);
    final membranePrice = findPrice(priceList, ['membrane', 'wind_barrier']);
    final insulationPrice = findPrice(priceList, ['insulation', 'mineral_wool']);

    final costs = [
      calculateCost(panelsNeeded.toDouble(), sidingPrice?.price),
      calculateCost(jProfileLength, jProfilePrice?.price),
      calculateCost(cornerLength, cornerPrice?.price),
      calculateCost(startStripLength, startStripPrice?.price),
      calculateCost(finishStripLength, finishStripPrice?.price),
      calculateCost(soffitLength, soffitPrice?.price),
      calculateCost(battensLength, battensPrice?.price),
      calculateCost(membraneArea, membranePrice?.price),
      insulationArea > 0 ? calculateCost(insulationArea, insulationPrice?.price) : null,
    ];

    return createResult(
      values: {
        'area': area,
        'panelsNeeded': panelsNeeded.toDouble(),
        'jProfileLength': jProfileLength,
        'cornerLength': cornerLength,
        'startStripLength': startStripLength,
        'finishStripLength': finishStripLength,
        'soffitLength': soffitLength,
        'screwsNeeded': screwsNeeded.toDouble(),
        'battensLength': battensLength,
        'membraneArea': membraneArea,
        if (insulationArea > 0) 'insulationArea': insulationArea,
      },
      totalPrice: sumCosts(costs),
    );
  }
}

