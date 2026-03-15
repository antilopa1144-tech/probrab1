import '../../data/models/price_item.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор отделки балкона
///
/// Типы балкона:
/// - 0: Открытый (open) - без остекления
/// - 1: Остеклённый (glazed) - холодное остекление
/// - 2: Тёплый (warm) - с утеплением
class CalculateBalconyV2 extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    if ((inputs['length'] ?? 3.0) <= 0) {
      return positiveValueMessage('length');
    }
    if ((inputs['width'] ?? 1.2) <= 0) {
      return positiveValueMessage('width');
    }
    if ((inputs['height'] ?? 2.5) <= 0) {
      return positiveValueMessage('height');
    }

    return null;
  }

  // Константы расчёта
  static const double finishingWastePercent = 10.0;
  static const double insulationWastePercent = 10.0;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final length = getInput(
      inputs,
      'length',
      defaultValue: 3.0,
      minValue: 1,
      maxValue: 10,
    );
    final width = getInput(
      inputs,
      'width',
      defaultValue: 1.2,
      minValue: 0.5,
      maxValue: 3,
    );
    final height = getInput(
      inputs,
      'height',
      defaultValue: 2.5,
      minValue: 2,
      maxValue: 3.5,
    );
    final balconyType = getIntInput(
      inputs,
      'balconyType',
      defaultValue: 1,
      minValue: 0,
      maxValue: 2,
    );
    final needInsulation =
        getInput(
          inputs,
          'needInsulation',
          defaultValue: 1.0,
          minValue: 0,
          maxValue: 1,
        ) ==
        1.0;
    final needFloorFinishing =
        getInput(
          inputs,
          'needFloorFinishing',
          defaultValue: 1.0,
          minValue: 0,
          maxValue: 1,
        ) ==
        1.0;
    final needWallFinishing =
        getInput(
          inputs,
          'needWallFinishing',
          defaultValue: 1.0,
          minValue: 0,
          maxValue: 1,
        ) ==
        1.0;

    // Базовые площади
    final floorArea = length * width;
    final ceilingArea = floorArea;

    // Стены: 3 стороны (без стены дома)
    // 2 боковых (width * height) + 1 торцевая (length * height)
    final wallArea = 2 * width * height + length * height;

    // Утепление: только для тёплого балкона
    const insulationWasteFactor = 1 + insulationWastePercent / 100;
    double insulationArea = 0.0;
    if (balconyType == 2 && needInsulation) {
      // Утепляем пол, потолок и 3 стены
      insulationArea =
          (floorArea + ceilingArea + wallArea) * insulationWasteFactor;
    }

    // Отделка
    const finishingWasteFactor = 1 + finishingWastePercent / 100;
    double finishingArea = 0.0;
    if (needFloorFinishing) finishingArea += floorArea;
    if (needWallFinishing) finishingArea += wallArea;
    // Потолок отделываем только если балкон не открытый
    if (balconyType != 0) finishingArea += ceilingArea;
    finishingArea *= finishingWasteFactor;

    // Остекление: П-образное (если не открытый балкон)
    double glazingLength = 0.0;
    if (balconyType != 0) {
      glazingLength = length + 2 * width;
    }

    // Формируем результат
    final values = <String, double>{
      'length': length,
      'width': width,
      'height': height,
      'balconyType': balconyType.toDouble(),
      'floorArea': floorArea,
      'wallArea': wallArea,
      'ceilingArea': ceilingArea,
      'insulationArea': insulationArea,
      'finishingArea': finishingArea,
      'glazingLength': glazingLength,
      'needInsulation': needInsulation ? 1.0 : 0.0,
      'needFloorFinishing': needFloorFinishing ? 1.0 : 0.0,
      'needWallFinishing': needWallFinishing ? 1.0 : 0.0,
    };

    // Расчёт стоимости
    double? totalPrice;
    if (priceList.isNotEmpty) {
      var price = 0.0;

      // Остекление
      if (glazingLength > 0) {
        final glazingPrice = priceList
            .where((p) => p.sku == 'balcony_glazing')
            .firstOrNull
            ?.price;
        if (glazingPrice != null) {
          price += glazingLength * glazingPrice;
        }
      }

      // Утепление
      if (insulationArea > 0) {
        final insulationPrice = priceList
            .where((p) => p.sku == 'insulation')
            .firstOrNull
            ?.price;
        if (insulationPrice != null) {
          price += insulationArea * insulationPrice;
        }
      }

      // Отделка
      if (finishingArea > 0) {
        final finishingPrice = priceList
            .where((p) => p.sku == 'finishing_material')
            .firstOrNull
            ?.price;
        if (finishingPrice != null) {
          price += finishingArea * finishingPrice;
        }
      }

      if (price > 0) totalPrice = price;
    }

    return createResult(values: values, totalPrice: totalPrice);
  }
}
