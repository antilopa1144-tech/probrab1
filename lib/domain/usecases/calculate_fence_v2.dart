import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор забора v2.
///
/// Рассчитывает материалы для забора: столбы, лаги, листы/штакетник, крепёж.
///
/// Поля:
/// - fenceLength: длина забора (м)
/// - fenceHeight: высота забора (м), 1.0-3.0
/// - postSpacing: шаг столбов (м), 2.0-3.5
/// - fenceType: тип забора (0 - профлист, 1 - штакетник, 2 - сетка)
class CalculateFenceV2 extends BaseCalculator {
  /// Ширина профлиста с учётом нахлёста (м)
  static const double profiledSheetWidth = 1.1;

  /// Ширина штакетины с зазором (м)
  static const double picketWidth = 0.15;

  /// Длина рулона сетки (м)
  static const double chainRollLength = 10.0;

  /// Крепёж на м² забора
  static const double fastenersPerSqm = 8.0;

  /// Крепёж в упаковке (шт)
  static const int fastenersPerBag = 200;

  /// Запас на лаги (%)
  static const double lagsWastePercent = 5.0;

  /// Высота для 3 рядов лаг (м)
  static const double heightFor3Lags = 1.8;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final fenceLength = inputs['fenceLength'] ?? 0;
    if (fenceLength <= 0) {
      return 'Длина забора должна быть больше нуля';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final fenceLength = getInput(inputs, 'fenceLength', defaultValue: 50.0, minValue: 1.0, maxValue: 1000.0);
    final fenceHeight = getInput(inputs, 'fenceHeight', defaultValue: 2.0, minValue: 1.0, maxValue: 3.0);
    final postSpacing = getInput(inputs, 'postSpacing', defaultValue: 2.5, minValue: 2.0, maxValue: 3.5);
    final fenceType = getIntInput(inputs, 'fenceType', defaultValue: 0, minValue: 0, maxValue: 2);

    // Площадь забора
    final fenceArea = fenceLength * fenceHeight;

    // Столбы: длина / шаг + 1 (крайний)
    final postsCount = (fenceLength / postSpacing).ceil() + 1;

    // Лаги (поперечины): 2-3 ряда в зависимости от высоты
    final lagsRows = fenceHeight > heightFor3Lags ? 3 : 2;
    final lagsLength = fenceLength * lagsRows * (1 + lagsWastePercent / 100);

    // Листы/штакетник/сетка
    int sheetsCount;
    switch (fenceType) {
      case 0: // Профлист
        sheetsCount = (fenceLength / profiledSheetWidth).ceil();
      case 1: // Штакетник
        sheetsCount = (fenceLength / picketWidth).ceil();
      case 2: // Сетка
        sheetsCount = (fenceLength / chainRollLength).ceil();
      default:
        sheetsCount = (fenceLength / profiledSheetWidth).ceil();
    }

    // Крепёж: примерно 8 саморезов на м², 200 шт в упаковке
    final fastenersTotal = (fenceArea * fastenersPerSqm).ceil();
    final fastenersBags = (fastenersTotal / fastenersPerBag).ceil();

    // Расчёт стоимости
    final postsPrice = findPrice(priceList, ['post', 'столб', 'fence_post']);
    final lagsPrice = findPrice(priceList, ['lag', 'лага', 'crossbar']);
    final fastenersPrice = findPrice(priceList, ['fasteners', 'саморезы', 'screws']);

    PriceItem? sheetsPrice;
    switch (fenceType) {
      case 0:
        sheetsPrice = findPrice(priceList, ['profiled', 'профлист', 'profiled_sheet']);
      case 1:
        sheetsPrice = findPrice(priceList, ['picket', 'штакетник', 'fence_picket']);
      case 2:
        sheetsPrice = findPrice(priceList, ['chain', 'сетка', 'chain_link']);
    }

    final costs = [
      calculateCost(postsCount.toDouble(), postsPrice?.price),
      calculateCost(lagsLength, lagsPrice?.price),
      calculateCost(sheetsCount.toDouble(), sheetsPrice?.price),
      calculateCost(fastenersBags.toDouble(), fastenersPrice?.price),
    ];

    return createResult(
      values: {
        'fenceLength': fenceLength,
        'fenceHeight': fenceHeight,
        'postSpacing': postSpacing,
        'fenceType': fenceType.toDouble(),
        'fenceArea': fenceArea,
        'postsCount': postsCount.toDouble(),
        'lagsRows': lagsRows.toDouble(),
        'lagsLength': lagsLength,
        'sheetsCount': sheetsCount.toDouble(),
        'fastenersTotal': fastenersTotal.toDouble(),
        'fastenersBags': fastenersBags.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
