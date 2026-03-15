// ignore_for_file: prefer_const_declarations
import 'dart:math' show sqrt;

import '../../data/models/price_item.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';

class Calculate3dPanels extends BaseCalculator {
  static const _panelsMargin = 10.0;
  static const _gluePerM2 = 5.0;
  static const _primerPerM2 = 0.18;
  static const _puttyPerM2 = 1.0;
  static const _paintPerM2 = 0.24;
  static const _varnishPerM2 = 0.08;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final hasDimensions =
        (inputs['length'] ?? 0) > 0 && (inputs['height'] ?? 0) > 0;
    if (area <= 0 && !hasDimensions) {
      return wallAreaOrDimensionsRequiredMessage();
    }

    return null;
  }

  bool _hasScreenInputs(Map<String, double> inputs) {
    return inputs.containsKey('inputMode') ||
        inputs.containsKey('length') ||
        inputs.containsKey('height') ||
        inputs.containsKey('withVarnish');
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasScreenInputs(inputs)) {
      return _calculateScreenPath(inputs, priceList);
    }
    return _calculateLegacyPath(inputs, priceList);
  }

  CalculatorResult _calculateLegacyPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final panelSize = getInput(
      inputs,
      'panelSize',
      defaultValue: 50.0,
      minValue: 25.0,
      maxValue: 100.0,
    );
    final perimeter = inputs['perimeter'] ?? estimatePerimeter(area);
    return _calculateCore(
      area: area,
      perimeter: perimeter,
      panelSize: panelSize,
      paintable:
          getIntInput(
            inputs,
            'paintable',
            defaultValue: 0,
            minValue: 0,
            maxValue: 1,
          ) >
          0,
      withVarnish: true,
      inputMode: 0,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateScreenPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final inputMode = getIntInput(
      inputs,
      'inputMode',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final area = inputMode == 0
        ? getInput(inputs, 'area', minValue: 0.1)
        : getInput(inputs, 'length', minValue: 1.0, maxValue: 12.0) *
              getInput(inputs, 'height', minValue: 2.0, maxValue: 4.0);
    final perimeter = inputMode == 1
        ? (getInput(inputs, 'length', minValue: 1.0, maxValue: 12.0) +
                  getInput(inputs, 'height', minValue: 2.0, maxValue: 4.0)) *
              2
        : 4 * sqrt(area);
    return _calculateCore(
      area: area,
      perimeter: perimeter,
      panelSize: getInput(
        inputs,
        'panelSize',
        defaultValue: 50.0,
        minValue: 30.0,
        maxValue: 100.0,
      ),
      paintable:
          getIntInput(
            inputs,
            'paintable',
            defaultValue: 0,
            minValue: 0,
            maxValue: 1,
          ) >
          0,
      withVarnish:
          getIntInput(
            inputs,
            'withVarnish',
            defaultValue: 1,
            minValue: 0,
            maxValue: 1,
          ) >
          0,
      inputMode: inputMode,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateCore({
    required double area,
    required double perimeter,
    required double panelSize,
    required bool paintable,
    required bool withVarnish,
    required int inputMode,
    required List<PriceItem> priceList,
  }) {
    final panelArea = (panelSize / 100) * (panelSize / 100);
    final panelsNeeded = calculateUnitsNeeded(
      area,
      panelArea,
      marginPercent: _panelsMargin,
    );
    final glueNeeded = area * _gluePerM2;
    final primerNeeded = area * _primerPerM2;
    final puttyNeeded = area * _puttyPerM2;
    final paintNeeded = paintable ? area * _paintPerM2 : 0.0;
    final varnishNeeded = withVarnish ? area * _varnishPerM2 : 0.0;
    final moldingLength = perimeter;

    final panelPrice = findPrice(priceList, [
      'panel_3d',
      '3d_panel',
      'decorative_panel_3d',
    ]);
    final gluePrice = findPrice(priceList, [
      'glue_3d',
      'glue',
      'adhesive_panel',
    ]);
    final primerPrice = findPrice(priceList, [
      'primer',
      'primer_deep',
      'primer_adhesion',
    ]);
    final puttyPrice = findPrice(priceList, ['putty', 'putty_finish']);
    final paintPrice = paintable
        ? findPrice(priceList, ['paint', 'paint_white'])
        : null;
    final moldingPrice = findPrice(priceList, [
      'molding',
      'decorative_molding',
    ]);
    final varnishPrice = withVarnish
        ? findPrice(priceList, ['varnish', 'protective_coating'])
        : null;

    final costs = [
      calculateCost(panelsNeeded.toDouble(), panelPrice?.price),
      calculateCost(glueNeeded, gluePrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      calculateCost(puttyNeeded, puttyPrice?.price),
      if (paintable) calculateCost(paintNeeded, paintPrice?.price),
      calculateCost(moldingLength, moldingPrice?.price),
      if (withVarnish) calculateCost(varnishNeeded, varnishPrice?.price),
    ];

    return createResult(
      values: {
        'inputMode': inputMode.toDouble(),
        'area': area,
        'panelSize': panelSize,
        'panelArea': panelArea,
        'panelsNeeded': panelsNeeded.toDouble(),
        'panelsCount': panelsNeeded.toDouble(),
        'glueNeeded': glueNeeded,
        'glueKg': glueNeeded,
        'primerNeeded': primerNeeded,
        'primerLiters': primerNeeded,
        'puttyNeeded': puttyNeeded,
        'puttyKg': puttyNeeded,
        if (paintable) 'paintNeeded': paintNeeded,
        'paintLiters': paintNeeded,
        'moldingLength': moldingLength,
        'perimeter': perimeter,
        'withVarnish': withVarnish ? 1.0 : 0.0,
        'paintable': paintable ? 1.0 : 0.0,
        'varnishNeeded': varnishNeeded,
        'varnishLiters': varnishNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
