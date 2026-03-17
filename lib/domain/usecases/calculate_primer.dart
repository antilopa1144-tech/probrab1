// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './primer_canonical_adapter.dart';

/// Калькулятор грунтовки.
///
/// Legacy path сохранён для обратной совместимости.
/// Canonical path включается только для canonical input shape.
class CalculatePrimer extends BaseCalculator {
  static const List<double> availableCanSizes = [5.0, 10.0, 15.0, 20.0];

  static Map<double, int> selectOptimalCans(
    double litersNeeded,
    double preferredCanSize,
  ) {
    final result = <double, int>{};

    if (litersNeeded <= availableCanSizes.first) {
      result[availableCanSizes.first] = 1;
      return result;
    }

    if (preferredCanSize > 0 && availableCanSizes.contains(preferredCanSize)) {
      final fullCans = (litersNeeded / preferredCanSize).floor();
      final remainder = litersNeeded - fullCans * preferredCanSize;

      if (fullCans > 0) {
        result[preferredCanSize] = fullCans;
      }

      if (remainder > 0) {
        for (final size in availableCanSizes) {
          if (size >= remainder) {
            result[size] = (result[size] ?? 0) + 1;
            break;
          }
        }
        if (remainder > availableCanSizes.last) {
          result[availableCanSizes.last] =
              (result[availableCanSizes.last] ?? 0) + 1;
        }
      }
    } else {
      var remaining = litersNeeded;
      final sizes = List<double>.from(availableCanSizes)
        ..sort((a, b) => b.compareTo(a));

      for (final size in sizes) {
        final count = (remaining / size).floor();
        if (count > 0) {
          result[size] = count;
          remaining -= count * size;
        }
      }

      if (remaining > 0) {
        final smallestSize = sizes.last;
        result[smallestSize] = (result[smallestSize] ?? 0) + 1;
      }
    }

    return result;
  }

  bool _hasCanonicalInputs(Map<String, double> inputs) =>
      hasCanonicalPrimerInputs(inputs);

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalPrimer(inputs);
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    if (_hasCanonicalInputs(inputs)) {
      final area = inputs['area'] ?? 0;
      final hasRoomDimensions =
          (inputs['roomWidth'] ?? 0) > 0 &&
          (inputs['roomLength'] ?? 0) > 0 &&
          (inputs['roomHeight'] ?? 0) > 0;
      if (area <= 0 && !hasRoomDimensions) {
        return areaOrRoomDimensionsRequiredMessage();
      }
      return null;
    }

    final area = inputs['area'] ?? 0;
    if (area <= 0) return positiveValueMessage('area');
    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasCanonicalInputs(inputs)) {
      return _calculateFromCanonical(inputs, priceList);
    }

    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(
      inputs,
      'layers',
      defaultValue: 1,
      minValue: 1,
      maxValue: 3,
    );
    final type = getIntInput(
      inputs,
      'type',
      defaultValue: 2,
      minValue: 1,
      maxValue: 3,
    );
    final canSize = getInput(
      inputs,
      'canSize',
      defaultValue: 10.0,
      minValue: 1.0,
      maxValue: 50.0,
    );

    final consumptionPerLayer = type == 1 ? 0.1 : (type == 2 ? 0.15 : 0.3);
    final primerNeeded = area * consumptionPerLayer * layers * 1.1;
    final optimalCans = selectOptimalCans(primerNeeded, canSize);

    double totalLiters = 0;
    int totalCans = 0;
    for (final entry in optimalCans.entries) {
      totalLiters += entry.key * entry.value;
      totalCans += entry.value;
    }

    final excess = totalLiters - primerNeeded;
    final rollersNeeded = ceilToInt(area / 30);
    const brushesNeeded = 2;
    const traysNeeded = 1;
    final dryingTime = type == 1 ? 2.0 : (type == 2 ? 4.0 : 3.0);
    final primerPrice = type == 1
        ? findPrice(priceList, [
            'primer',
            'primer_standard',
            'primer_universal',
          ])
        : (type == 2
              ? findPrice(priceList, [
                  'primer_deep',
                  'primer_penetrating',
                  'primer',
                ])
              : findPrice(priceList, [
                  'primer_adhesion',
                  'concrete_contact',
                  'betokontakt',
                ]));

    final costs = [calculateCost(totalLiters, primerPrice?.price)];

    final values = <String, double>{
      'area': area,
      'primerNeeded': primerNeeded,
      'totalLiters': totalLiters,
      'totalCans': totalCans.toDouble(),
      'excess': excess,
      'layers': layers.toDouble(),
      'rollersNeeded': rollersNeeded.toDouble(),
      'brushesNeeded': brushesNeeded.toDouble(),
      'traysNeeded': traysNeeded.toDouble(),
      'dryingTime': dryingTime,
    };

    for (final entry in optimalCans.entries) {
      values['cans_${entry.key.toInt()}l'] = entry.value.toDouble();
    }

    return createResult(values: values, totalPrice: sumCosts(costs));
  }

  CalculatorResult _calculateFromCanonical(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonical(inputs);
    final recScenario = contract.scenarios['REC']!;
    final canSize = contract.totals['canSize'] ?? 5;
    final totalCans = recScenario.buyPlan.packagesCount;
    final totalLiters = totalCans * canSize;
    final primerPrice = findPrice(priceList, [
      'primer',
      'primer_deep',
      'primer_contact',
      'primer_universal',
      'грунтовка',
    ]);

    final values = <String, double>{
      'area': contract.totals['area'] ?? 0,
      'primerNeeded': recScenario.exactNeed,
      'totalLiters': totalLiters,
      'totalCans': totalCans.toDouble(),
      'excess': totalLiters - recScenario.exactNeed,
      'layers': contract.totals['coats'] ?? 1,
      'rollersNeeded': _findMaterialPurchaseQty(contract, 'Валик').toDouble(),
      'brushesNeeded': _findMaterialPurchaseQty(contract, 'Кисть').toDouble(),
      'traysNeeded': _findMaterialPurchaseQty(contract, 'Кювета').toDouble(),
      'dryingTime': contract.totals['dryingTimeHours'] ?? 4,
      'surfaceType': contract.totals['surfaceType'] ?? 0,
      'primerType': contract.totals['primerType'] ?? 0,
      'canSize': canSize,
      'litersNeeded': recScenario.exactNeed,
      'cans_${canSize.toInt()}l': totalCans.toDouble(),
    };

    return createResult(
      values: values,
      totalPrice: calculateCost(totalLiters, primerPrice?.price),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'primer-canonical',
    );
  }

  double _findMaterialPurchaseQty(
    CanonicalCalculatorContractResult contract,
    String namePart,
  ) {
    for (final material in contract.materials) {
      if (material.name.contains(namePart)) return material.purchaseQty ?? 0;
    }
    return 0;
  }
}
