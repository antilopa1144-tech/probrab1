// ignore_for_file: prefer_const_declarations
import 'dart:math';
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './strip_foundation_canonical_adapter.dart';

/// Калькулятор ленточного фундамента.
///
/// Совместимый адаптер для старых perimeter/area и screen-level входов.
/// Публичный каталог использует canonical v3 напрямую; здесь сохранены только
/// безопасные выходные ключи для старых providers/истории.
///
/// Поддерживаемые legacy-входы:
/// - houseLength / houseWidth
/// - foundationType сохраняется в результате, но не меняет расчёт материалов
/// - hasInternalWalls / internalWallsLength
///
/// Legacy поля сохранены:
/// - area / perimeter / concreteVolume / rebarWeight / formworkArea
/// Неподтверждённые ФБС, подушка, гидроизоляция и утепление не рассчитываются.
class CalculateStripFoundation extends BaseCalculator {
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final houseLength = inputs['houseLength'] ?? 0;
    final houseWidth = inputs['houseWidth'] ?? 0;
    final area = inputs['area'] ?? 0;
    final perimeter = inputs['perimeter'] ?? 0;
    final width = inputs['width'] ?? 0;
    final height = inputs['height'] ?? 0;

    if ((houseLength <= 0 || houseWidth <= 0) && area <= 0 && perimeter <= 0) {
      return houseDimensionsAreaOrPerimeterRequiredMessage();
    }
    if (width <= 0 || width > 3) {
      return rangeMessage('width', 0.1, 3, unit: 'м');
    }
    if (height <= 0 || height > 3) {
      return rangeMessage('height', 0.1, 3, unit: 'м');
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final houseLengthInput = inputs['houseLength'] ?? 0.0;
    final houseWidthInput = inputs['houseWidth'] ?? 0.0;
    final hasHouseDimensions = houseLengthInput > 0 && houseWidthInput > 0;

    final houseLength = hasHouseDimensions
        ? getInput(inputs, 'houseLength', minValue: 1.0, maxValue: 100.0)
        : 0.0;
    final houseWidth = hasHouseDimensions
        ? getInput(inputs, 'houseWidth', minValue: 1.0, maxValue: 100.0)
        : 0.0;

    final inputPerimeter = inputs['perimeter'] ?? 0.0;
    final outerPerimeter = hasHouseDimensions
        ? 2 * (houseLength + houseWidth)
        : inputPerimeter > 0
        ? getInput(inputs, 'perimeter', minValue: 0.1, maxValue: 10000.0)
        : estimatePerimeter(
            getInput(inputs, 'area', minValue: 0.1, maxValue: 10000.0),
          );

    final hasInternalWalls =
        getIntInput(inputs, 'hasInternalWalls', defaultValue: 0) != 0;
    final internalWallsLength = hasInternalWalls
        ? getInput(
            inputs,
            'internalWallsLength',
            defaultValue: 0.0,
            minValue: 0.0,
            maxValue: 500.0,
          )
        : 0.0;
    final perimeter = outerPerimeter + internalWallsLength;

    final inputArea = inputs['area'] ?? 0.0;
    final area = hasHouseDimensions
        ? houseLength * houseWidth
        : inputArea > 0
        ? getInput(inputs, 'area', minValue: 0.1, maxValue: 10000.0)
        : pow(outerPerimeter / 4, 2).toDouble();

    final width = getInput(
      inputs,
      'width',
      defaultValue: 0.4,
      minValue: 0.1,
      maxValue: 3.0,
    );
    final height = getInput(
      inputs,
      'height',
      defaultValue: 0.8,
      minValue: 0.1,
      maxValue: 3.0,
    );
    final foundationType = getIntInput(
      inputs,
      'foundationType',
      defaultValue: 0,
      minValue: 0,
      maxValue: 3,
    );
    final stripVolume = perimeter * width * height;
    final canonical = calculateCanonicalStripFoundation({
      'perimeter': perimeter,
      'width': width * 1000,
      'depth': height * 1000,
      'aboveGround': 0,
      'formworkHeight': height * 1000,
      'reserve': inputs['reserve'] ?? 5,
      'readyMixOrderStepM3': inputs['readyMixOrderStepM3'] ?? 0.1,
      'deliveryAllowanceM3': inputs['deliveryAllowanceM3'] ?? 0,
      'reinforcement': inputs['reinforcement'] ?? 1,
      'clampStepMm': inputs['clampStepMm'] ?? 400,
      'concreteCoverMm': inputs['concreteCoverMm'] ?? 50,
      'clampHookAllowanceMm': inputs['clampHookAllowanceMm'] ?? 300,
      'rebarReserve': inputs['rebarReserve'] ?? 12,
      'rodLengthM': inputs['rodLengthM'] ?? 11.7,
      'formworkReserve': inputs['formworkReserve'] ?? 10,
    });
    final concreteVolume = canonical.totals['recPurchaseM3']!;
    final rebarWeight =
        canonical.totals['longPurchaseWeightKg']! +
        canonical.totals['clampPurchaseWeightKg']!;
    final formworkArea = canonical.totals['formworkWithReserve']!;
    final longitudinalBars = canonical.totals['threads']!.round();
    final longitudinalLength = canonical.totals['longPurchaseLen']!;
    final concretePrice = findPrice(priceList, [
      'concrete_m300',
      'concrete_m250',
      'concrete',
    ]);
    final rebarPrice = findPrice(priceList, [
      'rebar',
      'rebar_12mm',
      'reinforcement',
    ]);
    final formworkPrice = findPrice(priceList, ['formwork', 'plywood']);
    final costs = [
      calculateCost(concreteVolume, concretePrice?.price),
      calculateCost(rebarWeight, rebarPrice?.price),
      calculateCost(formworkArea, formworkPrice?.price),
    ];

    return createResult(
      values: {
        'foundationType': foundationType.toDouble(),
        'area': area,
        'perimeter': perimeter,
        'outerPerimeter': outerPerimeter,
        'houseLength': houseLength,
        'houseWidth': houseWidth,
        'hasInternalWalls': hasInternalWalls ? 1.0 : 0.0,
        'internalWallsLength': internalWallsLength,
        'width': width,
        'height': height,
        'stripVolume': stripVolume,
        'concreteVolume': concreteVolume,
        'rebarWeight': rebarWeight,
        'longitudinalBars': longitudinalBars.toDouble(),
        'longitudinalLength': longitudinalLength,
        'formworkArea': formworkArea,
        'waterproofingArea': 0,
        'insulationArea': 0,
        'sandVolume': 0,
        'gravelVolume': 0,
        'cementBags': 0,
        'fbsBlocksCount': 0,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
