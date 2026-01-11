import 'dart:math';
import '../../data/models/price_item.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор 3D панелей V2.
///
/// Расчёт количества 3D панелей и сопутствующих материалов для отделки стен.
///
/// Входные параметры:
/// - inputMode: режим ввода (0 - по площади, 1 - по размерам)
/// - area: площадь в м² (для режима по площади)
/// - length: длина стены в м (для режима по размерам)
/// - height: высота стены в м (для режима по размерам)
/// - panelSize: размер панели в см (30-100 см)
/// - paintable: нужна ли краска (0 - нет, 1 - да)
/// - withVarnish: нужен ли лак (0 - нет, 1 - да)
///
/// Выходные значения:
/// - area: расчётная площадь (м²)
/// - panelsCount: количество панелей (шт)
/// - panelArea: площадь одной панели (м²)
/// - glueKg: клей (кг)
/// - primerLiters: грунтовка (л)
/// - puttyKg: шпаклёвка (кг)
/// - paintLiters: краска (л) - если выбрана опция
/// - varnishLiters: лак (л) - если выбрана опция
/// - moldingLength: длина молдингов (м)
class CalculateThreeDPanelsV2 extends BaseCalculator {
  // Нормативы расхода материалов
  static const double _panelsMarginPercent = 10.0; // +10% запас на подрезку
  static const double _gluePerM2 = 5.0; // кг клея на м²
  static const double _primerPerM2 = 0.18; // л грунтовки на м²
  static const double _puttyPerM2 = 1.0; // кг шпаклёвки на м²
  static const double _paintPerM2 = 0.24; // л краски на м²
  static const double _varnishPerM2 = 0.08; // л лака на м²

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 0, minValue: 0, maxValue: 1);
    final area = getInput(inputs, 'area', defaultValue: 12.0, minValue: 3.0, maxValue: 150.0);
    final length = getInput(inputs, 'length', defaultValue: 4.0, minValue: 1.0, maxValue: 12.0);
    final height = getInput(inputs, 'height', defaultValue: 2.7, minValue: 2.0, maxValue: 4.0);
    final panelSizeCm = getInput(inputs, 'panelSize', defaultValue: 50.0, minValue: 30.0, maxValue: 100.0);
    final paintable = getInput(inputs, 'paintable', defaultValue: 0.0) == 1.0;
    final withVarnish = getInput(inputs, 'withVarnish', defaultValue: 1.0) == 1.0;

    // Расчёт площади в зависимости от режима
    final calculatedArea = inputMode == 0 ? area : length * height;

    // Площадь одной панели в м²
    final panelArea = (panelSizeCm / 100) * (panelSizeCm / 100);

    // Количество панелей с запасом
    final panelsMargin = getConstantDouble('margins', 'panels_margin', defaultValue: 1 + _panelsMarginPercent / 100);
    final panelsCount = (calculatedArea / panelArea * panelsMargin).ceil();

    // Расход материалов по нормативам
    final gluePerM2 = getConstantDouble('materials_consumption', 'glue_per_m2', defaultValue: _gluePerM2);
    final primerPerM2 = getConstantDouble('materials_consumption', 'primer_per_m2', defaultValue: _primerPerM2);
    final puttyPerM2 = getConstantDouble('materials_consumption', 'putty_per_m2', defaultValue: _puttyPerM2);
    final paintPerM2 = getConstantDouble('materials_consumption', 'paint_per_m2', defaultValue: _paintPerM2);
    final varnishPerM2 = getConstantDouble('materials_consumption', 'varnish_per_m2', defaultValue: _varnishPerM2);

    final glueKg = calculatedArea * gluePerM2;
    final primerLiters = calculatedArea * primerPerM2;
    final puttyKg = calculatedArea * puttyPerM2;
    final paintLiters = paintable ? calculatedArea * paintPerM2 : 0.0;
    final varnishLiters = withVarnish ? calculatedArea * varnishPerM2 : 0.0;

    // Периметр для молдингов
    final perimeter = inputMode == 1
        ? (length + height) * 2
        : 4 * sqrt(calculatedArea);

    return createResult(
      values: {
        'area': calculatedArea,
        'panelsCount': panelsCount.toDouble(),
        'panelArea': panelArea,
        'panelSizeCm': panelSizeCm,
        'glueKg': glueKg,
        'primerLiters': primerLiters,
        'puttyKg': puttyKg,
        'paintLiters': paintLiters,
        'varnishLiters': varnishLiters,
        'moldingLength': perimeter,
      },
      calculatorId: 'three_d_panels',
    );
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode']?.toInt() ?? 0;

    if (inputMode == 0) {
      // Режим по площади
      final area = inputs['area'] ?? 0;
      if (area < 3.0) {
        return 'Площадь должна быть не менее 3 м²';
      }
      if (area > 150.0) {
        return 'Площадь не может превышать 150 м²';
      }
    } else {
      // Режим по размерам
      final length = inputs['length'] ?? 0;
      final height = inputs['height'] ?? 0;
      if (length < 1.0) {
        return 'Длина стены должна быть не менее 1 м';
      }
      if (height < 2.0) {
        return 'Высота стены должна быть не менее 2 м';
      }
    }

    final panelSize = inputs['panelSize'] ?? 50.0;
    if (panelSize < 30.0 || panelSize > 100.0) {
      return 'Размер панели должен быть от 30 до 100 см';
    }

    return null;
  }
}
