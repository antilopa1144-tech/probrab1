import 'dart:math' as math;

import '../../data/models/price_item.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';
import './parquet_canonical_adapter.dart';

class CalculateParquetV2 extends BaseCalculator {
  Map<String, double> _toCanonicalInputs(Map<String, double> inputs) {
    final area = inputs['area'] ?? 0;
    final canonical = <String, double>{
      'packArea': (inputs['packArea'] ?? 2.0).toDouble(),
      'layoutProfileId': ((inputs['pattern'] ?? 0).round().clamp(0, 2) + 1)
          .toDouble(),
      'reservePercent': 0.0,
      'needUnderlayment': ((inputs['needUnderlay'] ?? 1) > 0 ? 1 : 0)
          .toDouble(),
      'needPlinth': ((inputs['needPlinth'] ?? 1) > 0 ? 1 : 0).toDouble(),
      'needGlue': ((inputs['needGlue'] ?? 0) > 0 ? 1 : 0).toDouble(),
      'doorThresholds': (inputs['doorThresholds'] ?? 1).toDouble(),
    };

    if (area > 0) {
      canonical['inputMode'] = 1.0;
      canonical['area'] = area.toDouble();
      if ((inputs['perimeter'] ?? 0) > 0) {
        canonical['perimeter'] = inputs['perimeter']!.toDouble();
      }
    } else {
      canonical['inputMode'] = 0.0;
      canonical['length'] = (inputs['roomLength'] ?? 5.0).toDouble();
      canonical['width'] = (inputs['roomWidth'] ?? 4.0).toDouble();
    }

    return canonical;
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];
    if (area <= 0 && (roomWidth == null || roomLength == null)) {
      return areaOrRoomDimensionsRequiredMessage();
    }
    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonicalParquet(_toCanonicalInputs(inputs));
    final area = contract.totals['area'] ?? 0;
    final roomWidth = contract.totals['roomWidth'] ?? math.sqrt(area);
    final roomLength = contract.totals['roomLength'] ?? math.sqrt(area);
    final pattern = ((inputs['pattern'] ?? 0).round().clamp(0, 2)).toDouble();
    final needUnderlay = (inputs['needUnderlay'] ?? 1) > 0;
    final needPlinth = (inputs['needPlinth'] ?? 1) > 0;
    final needGlue = (inputs['needGlue'] ?? 0) > 0;
    final rawPlinthLength = needPlinth
        ? math.max(0.0, 2 * (roomWidth + roomLength) - 0.9).toDouble()
        : 0.0;
    final plinthPieces = needPlinth ? (rawPlinthLength / 2.5).ceil() : 0;
    final glueLiters = needGlue ? area * 0.25 : 0.0;

    final parquetPrice = findPrice(priceList, [
      'parquet',
      'parquet_pack',
      'паркет',
    ]);
    final underlayPrice = findPrice(priceList, [
      'underlay',
      'underlay_roll',
      'подложка',
    ]);
    final plinthPrice = findPrice(priceList, ['plinth', 'плинтус']);
    final gluePrice = findPrice(priceList, ['glue', 'parquet_glue', 'клей']);

    return createResult(
      values: {
        'area': area,
        'roomWidth': roomWidth,
        'roomLength': roomLength,
        'pattern': pattern,
        'wastePercent': contract.totals['wastePercent'] ?? 0,
        'areaWithWaste': contract.totals['recExactNeedArea'] ?? 0,
        'packArea': contract.totals['packArea'] ?? 2.0,
        'packsNeeded': contract.totals['packsNeeded'] ?? 0,
        'needUnderlay': needUnderlay ? 1.0 : 0.0,
        'underlayArea': needUnderlay
            ? (contract.totals['underlayArea'] ?? 0)
            : 0.0,
        'needPlinth': needPlinth ? 1.0 : 0.0,
        'plinthLength': rawPlinthLength,
        'plinthPieces': plinthPieces.toDouble(),
        'needGlue': needGlue ? 1.0 : 0.0,
        'glueLiters': glueLiters,
      },
      totalPrice: sumCosts([
        calculateCost(contract.totals['packsNeeded'] ?? 0, parquetPrice?.price),
        calculateCost(
          (contract.totals['underlayArea'] ?? 0) / 10,
          underlayPrice?.price,
        ),
        calculateCost(plinthPieces.toDouble(), plinthPrice?.price),
        calculateCost(glueLiters, gluePrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'parquet-canonical-v2',
    );
  }
}
