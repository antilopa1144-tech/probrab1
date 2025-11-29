import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

/// Калькулятор откосов.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - windows: количество окон, по умолчанию 1
/// - windowWidth: ширина окна (м), по умолчанию 1.5
/// - windowHeight: высота окна (м), по умолчанию 1.4
/// - slopeWidth: ширина откоса (м), по умолчанию 0.3
/// - material: материал откосов (1=штукатурка, 2=ПВХ панели, 3=ГКЛ), по умолчанию 2
class CalculateSlopes extends BaseCalculator {
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
    final slopeWidth = getInput(inputs, 'slopeWidth', defaultValue: 0.3, minValue: 0.15, maxValue: 0.6);
    final material = getIntInput(inputs, 'material', defaultValue: 2, minValue: 1, maxValue: 3);

    // Периметр одного окна
    final windowPerimeter = (windowWidth + windowHeight) * 2;

    // Площадь откосов: периметр × ширина × количество окон
    final slopeArea = windowPerimeter * slopeWidth * windows;

    // Материалы зависят от типа откосов
    
    // 1. Штукатурка
    double plasterNeeded = 0;
    double puttyNeeded = 0;
    double primerNeeded = 0;
    double paintNeeded = 0;
    
    // 2. ПВХ панели
    double panelArea = 0;
    double startProfileLength = 0;
    double fProfileLength = 0;
    
    // 3. ГКЛ
    double gklArea = 0;
    double profileLength = 0;

    if (material == 1) {
      // Штукатурка
      plasterNeeded = slopeArea * 10.0; // ~10 кг/м² при слое 10 мм
      puttyNeeded = slopeArea * 1.2; // ~1.2 кг/м²
      primerNeeded = slopeArea * 0.2; // ~0.2 л/м²
      paintNeeded = slopeArea * 0.15 * 2; // ~0.15 л/м² в 2 слоя
    } else if (material == 2) {
      // ПВХ панели
      panelArea = slopeArea * 1.05; // +5% запас
      startProfileLength = windowPerimeter * windows; // стартовый профиль по периметру
      fProfileLength = windowPerimeter * windows; // F-профиль для стыка
    } else if (material == 3) {
      // ГКЛ
      gklArea = slopeArea * 1.08; // +8% запас
      profileLength = windowPerimeter * windows * 1.5; // направляющие
      puttyNeeded = slopeArea * 0.8; // шпаклёвка швов
      primerNeeded = slopeArea * 0.15;
      paintNeeded = slopeArea * 0.12 * 2;
    }

    // Общие материалы
    
    // Угловые профили (перфоуголки): периметр окон
    final cornerLength = windowPerimeter * windows;

    // Утеплитель (минвата, опционально): площадь откосов
    final insulationNeeded = getInput(inputs, 'insulation', defaultValue: 0.0) > 0 
        ? slopeArea 
        : 0.0;

    // Монтажная пена: ~0.5 баллона на окно для откосов
    final foamNeeded = windows * 0.5;

    // Саморезы/клей: комплект на окно
    final fixingSets = windows;

    // Расчёт стоимости
    final plasterPrice = findPrice(priceList, ['plaster', 'plaster_gypsum']);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);
    final paintPrice = findPrice(priceList, ['paint', 'paint_white', 'paint_water_disp']);
    final panelPrice = findPrice(priceList, ['panel_pvc', 'pvc_panel', 'slope_panel']);
    final startProfilePrice = findPrice(priceList, ['profile_start', 'start_profile']);
    final fProfilePrice = findPrice(priceList, ['profile_f', 'f_profile']);
    final gklPrice = findPrice(priceList, ['gkl', 'drywall']);
    final profilePrice = findPrice(priceList, ['profile', 'guide_profile']);
    final cornerPrice = findPrice(priceList, ['corner_slope', 'corner', 'angle_bead']);
    final insulationPrice = findPrice(priceList, ['insulation', 'mineral_wool']);
    final foamPrice = findPrice(priceList, ['foam', 'foam_mounting']);

    final costs = [
      if (material == 1) ...[
        calculateCost(plasterNeeded, plasterPrice?.price),
        calculateCost(puttyNeeded, puttyPrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
        calculateCost(paintNeeded, paintPrice?.price),
      ],
      if (material == 2) ...[
        calculateCost(panelArea, panelPrice?.price),
        calculateCost(startProfileLength, startProfilePrice?.price),
        calculateCost(fProfileLength, fProfilePrice?.price),
      ],
      if (material == 3) ...[
        calculateCost(gklArea, gklPrice?.price),
        calculateCost(profileLength, profilePrice?.price),
        calculateCost(puttyNeeded, puttyPrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
        calculateCost(paintNeeded, paintPrice?.price),
      ],
      calculateCost(cornerLength, cornerPrice?.price),
      if (insulationNeeded > 0) calculateCost(insulationNeeded, insulationPrice?.price),
      calculateCost(foamNeeded, foamPrice?.price),
    ];

    final values = {
      'windows': windows.toDouble(),
      'slopeArea': slopeArea,
      'cornerLength': cornerLength,
      'foamNeeded': foamNeeded,
    };

    if (material == 1) {
      values.addAll({
        'plasterNeeded': plasterNeeded,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'paintNeeded': paintNeeded,
      });
    } else if (material == 2) {
      values.addAll({
        'panelArea': panelArea,
        'startProfileLength': startProfileLength,
        'fProfileLength': fProfileLength,
      });
    } else if (material == 3) {
      values.addAll({
        'gklArea': gklArea,
        'profileLength': profileLength,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'paintNeeded': paintNeeded,
      });
    }

    if (insulationNeeded > 0) {
      values['insulationNeeded'] = insulationNeeded;
    }

    return createResult(
      values: values,
      totalPrice: sumCosts(costs),
    );
  }
}
