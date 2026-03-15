// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './putty_canonical_adapter.dart';

class CalculatePutty extends BaseCalculator {
  static const puttyMaterialCategoryStart = 'Стартовая';
  static const puttyMaterialNameFallbackStart = 'стартовая';
  static const puttyMaterialCategoryFinish = 'Финишная';
  static const puttyMaterialNameFallbackFinish = 'финишная';
  static const puttyMaterialCategoryPrimer = 'Подготовка';
  static const puttyMaterialNameFallbackPrimer = 'Грунтовка';
  static const puttyMaterialCategorySandpaper = 'Шлифовка';
  static const puttyMaterialNameFallbackSandpaper = 'Наждачная';
  static const _consumptionByQuality = {
    1: {'start': 1.8, 'finish': 1.0},
    2: {'start': 1.5, 'finish': 0.8},
    3: {'start': 1.2, 'finish': 0.5},
  };

  static const _layersByQuality = {
    1: {'start': 1, 'finish': 1},
    2: {'start': 2, 'finish': 1},
    3: {'start': 2, 'finish': 2},
  };

  bool _hasCanonicalInputs(Map<String, double> inputs) =>
      hasCanonicalPuttyInputs(inputs);

  double _resolvePackageWeight(
    Map<String, double> inputs,
    String key,
    double fallback,
  ) {
    final candidate = (inputs[key] ?? fallback).toDouble();
    return candidate > 0 ? candidate : fallback;
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    final contract = calculateCanonicalPutty(inputs);
    final totals = Map<String, double>.from(contract.totals);
    final bagWeight =
        totals['bagWeight'] ??
        puttyCanonicalSpecV1.packagingRules.defaultPackageSize;

    final startMaterial = _findCanonicalMaterial(
      contract,
      puttyMaterialCategoryStart,
      nameFallback: puttyMaterialNameFallbackStart,
    );
    final finishMaterial = _findCanonicalMaterial(
      contract,
      puttyMaterialCategoryFinish,
      nameFallback: puttyMaterialNameFallbackFinish,
    );
    final primerMaterial = _findCanonicalMaterial(
      contract,
      puttyMaterialCategoryPrimer,
      nameFallback: puttyMaterialNameFallbackPrimer,
    );
    final sandpaperMaterial = _findCanonicalMaterial(
      contract,
      puttyMaterialCategorySandpaper,
      nameFallback: puttyMaterialNameFallbackSandpaper,
    );

    final startExactNeedKg = (startMaterial?.quantity ?? 0) * bagWeight;
    final finishExactNeedKg = (finishMaterial?.quantity ?? 0) * bagWeight;
    final startPackageWeight = _resolvePackageWeight(
      inputs,
      'startPackageWeight',
      bagWeight,
    );
    final finishPackageWeight = _resolvePackageWeight(
      inputs,
      'finishPackageWeight',
      bagWeight,
    );
    final startPackages = startExactNeedKg > 0
        ? (startExactNeedKg / startPackageWeight).ceil()
        : 0;
    final finishPackages = finishExactNeedKg > 0
        ? (finishExactNeedKg / finishPackageWeight).ceil()
        : 0;
    final primerVolumeLiters = (primerMaterial?.quantity ?? 0) * 10;
    final primerCanisters = primerMaterial?.purchaseQty ?? 0;
    final sandingSheets = sandpaperMaterial?.purchaseQty ?? 0;

    return CanonicalCalculatorContractResult(
      canonicalSpecId: contract.canonicalSpecId,
      formulaVersion: contract.formulaVersion,
      materials: contract.materials,
      warnings: contract.warnings,
      scenarios: contract.scenarios,
      totals: {
        ...totals,
        'startExactNeedKg': startExactNeedKg,
        'finishExactNeedKg': finishExactNeedKg,
        'startPackageWeight': startPackageWeight,
        'finishPackageWeight': finishPackageWeight,
        'startPackages': startPackages.toDouble(),
        'finishPackages': finishPackages.toDouble(),
        'primerVolumeLiters': primerVolumeLiters,
        'primerCanisters': primerCanisters.toDouble(),
        'sandingSheets': sandingSheets.toDouble(),
      },
    );
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    if (_hasCanonicalInputs(inputs)) {
      final inputMode = (inputs['inputMode'] ?? 0).round();
      if (inputMode == 0) {
        final length = inputs['length'] ?? 0;
        final width = inputs['width'] ?? 0;
        final height = inputs['height'] ?? 0;
        if (length <= 0) return positiveValueMessage('length');
        if (width <= 0) return positiveValueMessage('width');
        if (height <= 0) return positiveValueMessage('height');
      } else {
        final area = inputs['area'] ?? 0;
        if (area <= 0) return positiveValueMessage('area');
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
    final type = getIntInput(
      inputs,
      'type',
      defaultValue: 1,
      minValue: 1,
      maxValue: 2,
    );
    final qualityClass = getIntInput(
      inputs,
      'qualityClass',
      defaultValue: 2,
      minValue: 1,
      maxValue: 3,
    );
    final typeKey = type == 1 ? 'start' : 'finish';
    final consumptionData = _consumptionByQuality[qualityClass]!;
    final consumptionPerLayer = consumptionData[typeKey]!;
    final defaultLayers = _layersByQuality[qualityClass]![typeKey]!;
    final layers = getIntInput(
      inputs,
      'layers',
      defaultValue: defaultLayers,
      minValue: 1,
      maxValue: 5,
    );
    final puttyNeeded = area * consumptionPerLayer * layers * 1.1;
    final primerCoats = qualityClass == 3 ? layers + 1 : 2;
    final primerNeeded = area * 0.2 * primerCoats;
    final meshArea = type == 1 ? area : 0.0;
    final sandpaperMultiplier = qualityClass == 3 ? 2.0 : 1.0;
    final sandpaperSets = ceilToInt(area / 25 * sandpaperMultiplier);
    const spatulasNeeded = 3;
    final waterNeeded = puttyNeeded * 0.4;
    final puttyPrice = _findPuttyPrice(priceList, type, qualityClass);
    final primerPrice = findPrice(priceList, [
      'primer',
      'primer_deep',
      'primer_adhesion',
    ]);
    final meshPrice = findPrice(priceList, [
      'mesh',
      'fiberglass_mesh',
      'serpyanka',
    ]);

    final costs = [
      calculateCost(puttyNeeded, puttyPrice?.price),
      calculateCost(primerNeeded, primerPrice?.price),
      if (type == 1) calculateCost(meshArea, meshPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'puttyNeeded': puttyNeeded,
        'primerNeeded': primerNeeded,
        'layers': layers.toDouble(),
        'qualityClass': qualityClass.toDouble(),
        'consumptionPerLayer': consumptionPerLayer,
        if (type == 1) 'meshArea': meshArea,
        'sandpaperSets': sandpaperSets.toDouble(),
        'spatulasNeeded': spatulasNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts(costs),
    );
  }

  CalculatorResult _calculateFromCanonical(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonical(inputs);
    final puttyType = contract.totals['puttyType']?.round() ?? 0;
    final area = contract.totals['wallArea'] ?? 0;
    final recScenario = contract.scenarios['REC']!;
    final startMaterial = _findCanonicalMaterial(
      contract,
      puttyMaterialCategoryStart,
      nameFallback: puttyMaterialNameFallbackStart,
    );
    final finishMaterial = _findCanonicalMaterial(
      contract,
      puttyMaterialCategoryFinish,
      nameFallback: puttyMaterialNameFallbackFinish,
    );
    final meshArea = puttyType >= 1 ? area : 0.0;
    final primerNeeded = contract.totals['primerVolumeLiters'] ?? 0;
    final sandpaperSets = contract.totals['sandingSheets'] ?? 0;
    final waterNeeded = recScenario.exactNeed * 0.4;
    final puttyPriceCosts = <double?>[];

    if (startMaterial != null) {
      final startPrice = _findPuttyPrice(priceList, 1, 2);
      puttyPriceCosts.add(
        calculateCost(
          startMaterial.purchaseQty?.toDouble() ?? 0,
          startPrice?.price,
        ),
      );
    }
    if (finishMaterial != null) {
      final finishPrice = _findPuttyPrice(priceList, 2, 2);
      puttyPriceCosts.add(
        calculateCost(
          finishMaterial.purchaseQty?.toDouble() ?? 0,
          finishPrice?.price,
        ),
      );
    }

    final primerPrice = findPrice(priceList, [
      'primer',
      'primer_deep',
      'primer_adhesion',
    ]);
    final meshPrice = findPrice(priceList, [
      'mesh',
      'fiberglass_mesh',
      'serpyanka',
    ]);

    return createResult(
      values: {
        'area': area,
        'wallArea': area,
        'puttyNeeded': recScenario.exactNeed,
        'puttyPurchaseKg': recScenario.purchaseQuantity,
        'bagWeight': contract.totals['bagWeight'] ?? 0,
        'puttyType': puttyType.toDouble(),
        'primerNeeded': primerNeeded,
        'primerCanisters': contract.totals['primerCanisters'] ?? 0,
        'layers': [
          contract.totals['startLayers'] ?? 0,
          contract.totals['finishLayers'] ?? 0,
        ].reduce((maxLayers, value) => value > maxLayers ? value : maxLayers),
        'startLayers': contract.totals['startLayers'] ?? 0,
        'finishLayers': contract.totals['finishLayers'] ?? 0,
        'meshArea': meshArea,
        'sandpaperSets': sandpaperSets,
        'startExactNeedKg': contract.totals['startExactNeedKg'] ?? 0,
        'finishExactNeedKg': contract.totals['finishExactNeedKg'] ?? 0,
        'startPackages': contract.totals['startPackages'] ?? 0,
        'finishPackages': contract.totals['finishPackages'] ?? 0,
        'spatulasNeeded': 3.0,
        'waterNeeded': waterNeeded,
        'scenarioMinExactNeed': contract.scenarios['MIN']!.exactNeed,
        'scenarioRecExactNeed': recScenario.exactNeed,
        'scenarioMaxExactNeed': contract.scenarios['MAX']!.exactNeed,
        'scenarioMinPurchase': contract.scenarios['MIN']!.purchaseQuantity,
        'scenarioRecPurchase': recScenario.purchaseQuantity,
        'scenarioMaxPurchase': contract.scenarios['MAX']!.purchaseQuantity,
      },
      totalPrice: sumCosts([
        ...puttyPriceCosts,
        calculateCost(primerNeeded, primerPrice?.price),
        if (meshArea > 0) calculateCost(meshArea, meshPrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'putty-canonical',
    );
  }

  CanonicalMaterialResult? _findCanonicalMaterial(
    CanonicalCalculatorContractResult contract,
    String categoryPart, {
    String? nameFallback,
  }) {
    for (final material in contract.materials) {
      if ((material.category ?? '').contains(categoryPart)) return material;
    }
    if (nameFallback != null) {
      for (final material in contract.materials) {
        if (material.name.contains(nameFallback)) return material;
      }
    }
    return null;
  }

  PriceItem? _findPuttyPrice(
    List<PriceItem> priceList,
    int type,
    int qualityClass,
  ) {
    final qualitySkus = {
      1: ['volma', 'osnovit', 'economy'],
      2: ['knauf', 'bergauf', 'standard'],
      3: ['sheetrock', 'danogips', 'premium'],
    };

    final typeSkus = type == 1
        ? ['putty_start', 'putty_base', 'putty']
        : ['putty_finish', 'putty_final', 'putty'];

    final qualitySku = qualitySkus[qualityClass]!;
    for (final qs in qualitySku) {
      for (final ts in typeSkus) {
        final combined = findPrice(priceList, ['${qs}_$ts', '${ts}_$qs']);
        if (combined != null) return combined;
      }
    }

    return findPrice(priceList, typeSkus);
  }
}
