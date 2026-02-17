// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор установки окон.
///
/// Нормативы:
/// - СНиП 23-02-2003 "Тепловая защита зданий"
/// - ГОСТ 30674-99 "Блоки оконные"
///
/// Поля:
/// - windows: количество окон, по умолчанию 1
/// - windowWidth: ширина окна (м), по умолчанию 1.5
/// - windowHeight: высота окна (м), по умолчанию 1.4
class CalculateWindowInstallation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final windows = inputs['windows'] ?? 1;
    if (windows < 1) return 'Количество окон должно быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final windows = getIntInput(inputs, 'windows', defaultValue: 1, minValue: 1, maxValue: 50);
    final windowWidth = getInput(inputs, 'windowWidth', defaultValue: 1.5, minValue: 0.5, maxValue: 4.0);
    final windowHeight = getInput(inputs, 'windowHeight', defaultValue: 1.4, minValue: 0.5, maxValue: 3.0);

    // Площадь одного окна
    final windowArea = windowWidth * windowHeight;
    final totalArea = windowArea * windows;

    // Периметр одного окна
    final windowPerimeter = (windowWidth + windowHeight) * 2;

    // Монтажная пена: 1.5-2 баллона на окно (зависит от размера шва ~2-3 см)
    final foamPerWindow = windowArea > 2.5 ? 2.0 : 1.5;
    final foamNeeded = ceilToInt(windows * foamPerWindow);

    // Подоконники: длина окна + 5 см с каждой стороны
    final sillLength = (windowWidth + 0.1) * windows;
    final sillsNeeded = windows;

    // Откосы: периметр окна × ширина откоса (30 см) + 10% запас на подрезку
    final slopeWidth = getInput(inputs, 'slopeWidth', defaultValue: 0.3, minValue: 0.2, maxValue: 0.5);
    final slopeArea = windowPerimeter * slopeWidth * windows * 1.1;

    // Отливы: ширина окна + 5 см с каждой стороны
    final dripLength = (windowWidth + 0.1) * windows;

    // Уплотнительная лента ПСУЛ: периметр окон + 10% запас
    final sealantTapeLength = windowPerimeter * windows * 1.1;

    // Анкера/крепёж: ~8 шт на окно (по ГОСТ 30971, через каждые 60-70 см)
    final anchorsNeeded = windows * 8;

    // Силиконовый герметик: 1 туба на 2 окна
    final sealantTubes = ceilToInt(windows / 2);

    // Пароизоляционная лента: периметр окон + 10% на нахлёсты
    final vaporTapeLength = windowPerimeter * windows * 1.1;

    // Расчёт стоимости
    final windowPrice = findPrice(priceList, ['window', 'window_pvc', 'plastic_window']);
    final foamPrice = findPrice(priceList, ['foam_mounting', 'foam', 'polyurethane_foam']);
    final sillPrice = findPrice(priceList, ['sill', 'window_sill', 'windowsill']);
    final slopePrice = findPrice(priceList, ['slope', 'slope_material', 'slope_panel']);
    final dripPrice = findPrice(priceList, ['drip', 'drip_window', 'window_sill_exterior']);
    final sealantTapePrice = findPrice(priceList, ['tape_psul', 'sealing_tape']);
    final sealantPrice = findPrice(priceList, ['sealant', 'silicone', 'window_sealant']);
    final vaporTapePrice = findPrice(priceList, ['tape_vapor', 'vapor_barrier_tape']);

    final costs = [
      calculateCost(windows.toDouble(), windowPrice?.price),
      calculateCost(foamNeeded.toDouble(), foamPrice?.price),
      calculateCost(sillLength, sillPrice?.price),
      calculateCost(slopeArea, slopePrice?.price),
      calculateCost(dripLength, dripPrice?.price),
      calculateCost(sealantTapeLength, sealantTapePrice?.price),
      calculateCost(sealantTubes.toDouble(), sealantPrice?.price),
      calculateCost(vaporTapeLength, vaporTapePrice?.price),
    ];

    return createResult(
      values: {
        'windows': windows.toDouble(),
        'windowArea': windowArea,
        'totalArea': totalArea,
        'foamNeeded': foamNeeded.toDouble(),
        'sillsNeeded': sillsNeeded.toDouble(),
        'sillLength': sillLength,
        'slopeArea': slopeArea,
        'dripLength': dripLength,
        'sealantTapeLength': sealantTapeLength,
        'anchorsNeeded': anchorsNeeded.toDouble(),
        'sealantTubes': sealantTubes.toDouble(),
        'vaporTapeLength': vaporTapeLength,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
