// ignore_for_file: prefer_const_declarations
import 'dart:math' as math;

import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './parquet_canonical_adapter.dart';

class CalculateParquet extends BaseCalculator {
  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (hasCanonicalParquetInputs(inputs)) {
      return Map<String, double>.from(inputs);
    }
    return normalizeLegacyParquetInputs(inputs);
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalParquet(_normalizeInputs(inputs));
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final normalized = _normalizeInputs(inputs);
    final hasArea = (normalized['area'] ?? 0) > 0;
    final hasRoom =
        (normalized['length'] ?? 0) > 0 && (normalized['width'] ?? 0) > 0;
    if (!hasArea && !hasRoom) return areaOrRoomDimensionsRequiredMessage();

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final normalized = _normalizeInputs(inputs);
    final contract = calculateCanonical(normalized);
    final area = contract.totals['area'] ?? 0;
    final plankWidthCm = (inputs['plankWidth'] ?? 7.0).clamp(5.0, 20.0);
    final plankLengthCm = (inputs['plankLength'] ?? 40.0).clamp(20.0, 100.0);
    final plankArea = (plankWidthCm / 100) * (plankLengthCm / 100);
    final plankWastePercent =
        normalized.containsKey('pattern') ||
            normalized.containsKey('layingMethod')
        ? (contract.totals['wastePercent'] ?? 0)
        : 7.0;
    final planksNeeded = plankArea > 0
        ? ((area / plankArea) * (1 + plankWastePercent / 100)).ceil()
        : 0;
    final varnishLayers = 3;
    final varnishNeeded = area * 0.1 * varnishLayers;
    final primerNeeded = area * 0.08;
    final glueNeeded = area * 1.5;
    final plywoodArea = area;
    final fillerNeeded = area * 0.3;
    final sandpaperSets = math.max(1, (area / 20).ceil());
    final plinthLength =
        ((inputs['perimeter'] != null && inputs['perimeter']! > 0)
                ? inputs['perimeter']!
                : (contract.totals['perimeter'] ?? 0))
            .toDouble();

    final parquetPrice = findPrice(priceList, [
      'parquet',
      'parquet_plank',
      'wood_floor',
      'hardwood',
    ]);
    final varnishPrice = findPrice(priceList, [
      'varnish',
      'varnish_parquet',
      'floor_finish',
    ]);
    final primerPrice = findPrice(priceList, [
      'primer_parquet',
      'primer',
      'wood_primer',
    ]);
    final plinthPrice = findPrice(priceList, [
      'plinth_parquet',
      'plinth',
      'wood_baseboard',
    ]);
    final gluePrice = findPrice(priceList, [
      'glue_parquet',
      'glue',
      'wood_adhesive',
    ]);
    final plywoodPrice = findPrice(priceList, ['plywood', 'plywood_sheet']);
    final fillerPrice = findPrice(priceList, [
      'filler',
      'wood_filler',
      'putty',
    ]);

    return createResult(
      values: {
        'area': area,
        'planksNeeded': planksNeeded.toDouble(),
        'varnishNeeded': varnishNeeded,
        'varnishLayers': varnishLayers.toDouble(),
        'primerNeeded': primerNeeded,
        'plinthLength': plinthLength,
        'glueNeeded': glueNeeded,
        'plywoodArea': plywoodArea,
        'fillerNeeded': fillerNeeded,
        'sandpaperSets': sandpaperSets.toDouble(),
        'packArea': contract.totals['packArea'] ?? 2.0,
        'packsNeeded': contract.totals['packsNeeded'] ?? 0,
        'wastePercent': contract.totals['wastePercent'] ?? 0,
      },
      totalPrice: sumCosts([
        calculateCost(planksNeeded.toDouble(), parquetPrice?.price),
        calculateCost(varnishNeeded, varnishPrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
        calculateCost(plinthLength, plinthPrice?.price),
        calculateCost(glueNeeded, gluePrice?.price),
        calculateCost(plywoodArea, plywoodPrice?.price),
        calculateCost(fillerNeeded, fillerPrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'parquet-canonical',
    );
  }
}
