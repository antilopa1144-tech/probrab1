import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор линолеума.
///
/// Рассчитывает количество линолеума, двустороннего скотча и плинтуса.
/// Использует размеры комнаты (ширина × длина) для точного расчёта.
///
/// Поля:
/// - roomWidth: ширина комнаты (м)
/// - roomLength: длина комнаты (м)
/// - rollWidth: ширина рулона (м), 2-5 м
/// - marginCm: запас по краям (см), по умолчанию 20 см
/// - needTape: нужен ли двусторонний скотч (0/1)
/// - needPlinth: нужен ли плинтус (0/1)
class CalculateLinoleumV2 extends BaseCalculator {
  /// Запас по умолчанию (см) — добавляется к каждой стороне
  static const double defaultMarginCm = 20.0;

  /// Длина рулона (м.п.)
  static const double rollLength = 25.0;

  /// Длина плинтуса (м)
  static const double plinthLength = 2.5;

  /// Ширина дверного проёма (м)
  static const double doorWidth = 0.9;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];

    if (roomWidth == null || roomLength == null) {
      return 'Необходимо указать размеры комнаты';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final rollWidth = getInput(inputs, 'rollWidth', defaultValue: 3.0, minValue: 2.0, maxValue: 5.0);
    final marginCm = getInput(inputs, 'marginCm', defaultValue: defaultMarginCm, minValue: 0, maxValue: 50);
    final needTape = getIntInput(inputs, 'needTape', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needPlinth = getIntInput(inputs, 'needPlinth', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Размеры комнаты
    final roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30);
    final roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 30);

    // Чистая площадь комнаты
    final area = roomWidth * roomLength;

    // Запас в метрах (добавляется к длине и ширине)
    final marginM = marginCm / 100;

    // Размеры с запасом
    final widthWithMargin = roomWidth + marginM;
    final lengthWithMargin = roomLength + marginM;

    // Площадь с запасом
    final areaWithWaste = widthWithMargin * lengthWithMargin;

    // Погонные метры: площадь с запасом / ширина рулона
    final linearMeters = areaWithWaste / rollWidth;

    // Количество рулонов
    final rollArea = rollWidth * rollLength;
    final rollsNeeded = areaWithWaste / rollArea;

    // Двусторонний скотч: периметр + швы
    double tapeLength = 0;
    if (needTape) {
      // Периметр + один шов по длине комнаты
      tapeLength = 2 * (roomWidth + roomLength) + roomLength;
    }

    // Плинтус
    double plinthTotalLength = 0;
    int plinthPieces = 0;
    if (needPlinth) {
      plinthTotalLength = 2 * (roomWidth + roomLength) - doorWidth;
      plinthPieces = (plinthTotalLength / plinthLength).ceil();
    }

    // Расчёт стоимости
    final linoleumPrice = findPrice(priceList, ['linoleum', 'линолеум']);
    final tapePrice = findPrice(priceList, ['tape', 'double_tape', 'скотч']);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус']);

    final costs = [
      calculateCost(areaWithWaste, linoleumPrice?.price),
      calculateCost(tapeLength, tapePrice?.price),
      calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'marginCm': marginCm,
        'areaWithWaste': areaWithWaste,
        'rollWidth': rollWidth,
        'rollLength': rollLength,
        'rollsNeeded': rollsNeeded,
        'linearMeters': linearMeters,
        'needTape': needTape ? 1.0 : 0.0,
        'tapeLength': tapeLength,
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'plinthLength': plinthTotalLength,
        'plinthPieces': plinthPieces.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
