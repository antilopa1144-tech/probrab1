import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';
import './calculate_paint_universal.dart';
import './paint_canonical_adapter.dart';

const _paintMaterialCategoryConsumables = 'Расходники';
const _paintMaterialCategoryTools = 'Инструмент';

class CalculatePaint extends BaseCalculator {
  final CalculatePaintUniversal _legacyCalculator = CalculatePaintUniversal();

  bool _hasCanonicalInputs(Map<String, double> inputs) =>
      hasCanonicalPaintInputs(inputs);
  bool _hasLegacyUniversalInputs(Map<String, double> inputs) =>
      hasLegacyUniversalPaintInputs(inputs);

  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (_hasLegacyUniversalInputs(inputs)) {
      return normalizeLegacyUniversalPaintInputs(inputs);
    }
    return inputs;
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalPaint(_normalizeInputs(inputs));
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    if (_hasCanonicalInputs(inputs) || _hasLegacyUniversalInputs(inputs)) {
      final normalized = _normalizeInputs(inputs);
      final area = normalized['area'] ?? 0;
      final splitArea =
          (normalized['wallArea'] ?? 0) + (normalized['ceilingArea'] ?? 0);
      final hasRoomDimensions =
          (normalized['roomWidth'] ?? 0) > 0 &&
          (normalized['roomLength'] ?? 0) > 0 &&
          (normalized['roomHeight'] ?? 0) > 0;
      if (area <= 0 && splitArea <= 0 && !hasRoomDimensions) {
        return areaOrRoomDimensionsRequiredMessage();
      }
      return null;
    }

    return _legacyCalculator.validateInputs(inputs);
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasLegacyUniversalInputs(inputs)) {
      return _calculateLegacyUniversal(inputs, priceList);
    }
    if (_hasCanonicalInputs(inputs)) {
      return _calculateCanonicalResult(_normalizeInputs(inputs), priceList);
    }
    return _legacyCalculator.calculate(inputs, priceList);
  }

  CalculatorResult _calculateCanonicalResult(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonicalPaint(inputs);
    final recScenario = contract.scenarios['REC']!;
    final paintPackageSize = recScenario.buyPlan.packageSize;
    final paintPackageCount = recScenario.buyPlan.packagesCount;
    final paintPurchaseLiters = paintPackageSize * paintPackageCount;

    final paintPrice = findPrice(priceList, [
      'paint',
      'paint_wall',
      'paint_facade',
      'краска',
    ]);
    final primerPrice = findPrice(priceList, [
      'primer',
      'primer_deep',
      'грунтовка',
    ]);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape', 'скотч']);

    final primerLiters = contract.totals['primerLiters'] ?? 0;
    final tapeMeters = contract.totals['tapeMeters'] ?? 0;

    return createResult(
      values: {
        'totalArea': contract.totals['area'] ?? 0,
        'wallArea': contract.totals['wallArea'] ?? 0,
        'ceilingArea': contract.totals['ceilingArea'] ?? 0,
        'paintLiters': recScenario.exactNeed,
        'paintCans': paintPackageCount.toDouble(),
        'paintPurchaseLiters': paintPurchaseLiters,
        'primerLiters': primerLiters,
        'tapeMeters': tapeMeters,
        'tapeRolls': _findMaterialPurchaseQty(
          contract,
          category: _paintMaterialCategoryConsumables,
          fallbackNamePart: 'Малярная лента',
        ).toDouble(),
        'rollersNeeded': _findMaterialPurchaseQty(
          contract,
          category: _paintMaterialCategoryTools,
          fallbackNamePart: 'Валик',
        ).toDouble(),
        'brushesNeeded': _findMaterialPurchaseQty(
          contract,
          category: _paintMaterialCategoryTools,
          fallbackNamePart: 'Кисть',
        ).toDouble(),
        'traysNeeded': _findMaterialPurchaseQty(
          contract,
          category: _paintMaterialCategoryTools,
          fallbackNamePart: 'Кювета',
        ).toDouble(),
        'layers': contract.totals['coats'] ?? 2,
        'paintType': contract.totals['paintType'] ?? 0,
        'surfaceType': contract.totals['surfaceType'] ?? 0,
        'surfacePrep': contract.totals['surfacePrep'] ?? 0,
        'colorIntensity': contract.totals['colorIntensity'] ?? 0,
        'coverage': contract.totals['coverage'] ?? 10,
        'canSize': paintPackageSize,
      },
      totalPrice: sumCosts([
        calculateCost(paintPurchaseLiters, paintPrice?.price),
        calculateCost(primerLiters, primerPrice?.price),
        calculateCost(tapeMeters, tapePrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'paint-canonical',
    );
  }

  CalculatorResult _calculateLegacyUniversal(
    Map<String, double> originalInputs,
    List<PriceItem> priceList,
  ) {
    final normalized = normalizeLegacyUniversalPaintInputs(originalInputs);
    final contract = calculateCanonicalPaint(normalized);
    final totalArea = contract.totals['area'] ?? 0;
    if (totalArea <= 0) {
      return createResult(values: {'error': 1.0});
    }

    final surfacePrepLegacy = (originalInputs['surfacePrep'] ?? 1)
        .round()
        .clamp(1, 3);
    final colorIntensityLegacy = (originalInputs['colorIntensity'] ?? 1)
        .round()
        .clamp(1, 3);
    final layers = (originalInputs['layers'] ?? 2).round().clamp(1, 4);
    final reservePercent = getInput(
      originalInputs,
      'reserve',
      defaultValue: 10,
      minValue: 0,
    );
    final normalizedPrep = normalized['surfacePrep'] ?? 0;
    final normalizedColor = normalized['colorIntensity'] ?? 0;
    final prepMultiplier = _resolvePreparationMultiplier(normalizedPrep);
    final colorMultiplier = _resolveColorMultiplier(normalizedColor);
    final consumption = getInput(
      originalInputs,
      'consumption',
      defaultValue: 0.11,
      minValue: 0.01,
    );
    final wallArea = contract.totals['wallArea'] ?? 0;
    final ceilingArea = contract.totals['ceilingArea'] ?? 0;
    final basePaintConsumption =
        consumption *
            paintCanonicalSpecV1.materialRules.legacyFirstCoatMultiplier +
        (layers - 1) * consumption;
    final rawWallPaint =
        wallArea * basePaintConsumption * prepMultiplier * colorMultiplier;
    final rawCeilingPaint =
        ceilingArea *
        basePaintConsumption *
        prepMultiplier *
        colorMultiplier *
        paintCanonicalSpecV1.materialRules.ceilingPremiumFactor;
    final rawPaint = rawWallPaint + rawCeilingPaint;
    final paintLiters = roundBulk(
      rawPaint * (1 + reservePercent / 100) +
          (totalArea > 0
              ? paintCanonicalSpecV1.materialRules.defaultRollerAbsorptionLiters
              : 0),
    );
    final primerLiters = roundBulk(
      totalArea *
          paintCanonicalSpecV1.materialRules.legacyUniversalPrimerLitersPerM2 *
          (1 + reservePercent / 100),
    );
    final tapeMeters = roundBulk(
      ((contract.totals['estimatedPerimeter'] ?? 0) +
              (contract.totals['openingsPerimeter'] ?? 0)) *
          paintCanonicalSpecV1.materialRules.tapeReserveFactor,
    );
    final rollersNeeded = ceilToInt(
      totalArea / paintCanonicalSpecV1.materialRules.rollerAreaM2PerPiece,
    );
    final brushesNeeded = totalArea > 0
        ? ceilToInt(
            totalArea /
                paintCanonicalSpecV1.materialRules.legacyBrushAreaM2PerPiece,
          ).clamp(
            paintCanonicalSpecV1.materialRules.legacyBrushesMin,
            paintCanonicalSpecV1.materialRules.legacyBrushesMax,
          )
        : 0;

    final paintPrice = findPrice(priceList, ['paint', 'paint_water', 'краска']);
    final primerPrice = findPrice(priceList, ['primer', 'грунтовка']);
    final tapePrice = findPrice(priceList, ['tape', 'masking_tape', 'скотч']);

    return createResult(
      values: {
        'totalArea': roundBulk(totalArea),
        'wallArea': roundBulk(wallArea),
        'ceilingArea': roundBulk(ceilingArea),
        'paintLiters': paintLiters,
        'primerLiters': primerLiters,
        'tapeMeters': tapeMeters,
        'rollersNeeded': rollersNeeded.toDouble(),
        'brushesNeeded': brushesNeeded.toDouble(),
        'layers': layers.toDouble(),
        'surfacePrep': surfacePrepLegacy.toDouble(),
        'colorIntensity': colorIntensityLegacy.toDouble(),
      },
      totalPrice: sumCosts([
        calculateCost(paintLiters, paintPrice?.price),
        calculateCost(primerLiters, primerPrice?.price),
        calculateCost(tapeMeters, tapePrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'paint-universal-canonical',
    );
  }

  double _resolvePreparationMultiplier(double canonicalSurfacePrep) {
    final preparation = paintCanonicalSpecV1.surfacePreparations.firstWhere(
      (item) => item.id == canonicalSurfacePrep.round(),
      orElse: () => paintCanonicalSpecV1.surfacePreparations.first,
    );
    return preparation.multiplier;
  }

  double _resolveColorMultiplier(double canonicalColorIntensity) {
    final color = paintCanonicalSpecV1.colorIntensities.firstWhere(
      (item) => item.id == canonicalColorIntensity.round(),
      orElse: () => paintCanonicalSpecV1.colorIntensities.first,
    );
    return color.multiplier;
  }

  int _findMaterialPurchaseQty(
    CanonicalCalculatorContractResult contract, {
    required String category,
    required String fallbackNamePart,
  }) {
    for (final material in contract.materials) {
      if (material.category == category &&
          material.name.contains(fallbackNamePart)) {
        return material.purchaseQty ?? 0;
      }
    }
    for (final material in contract.materials) {
      if (material.name.contains(fallbackNamePart)) {
        return material.purchaseQty ?? 0;
      }
    }
    return 0;
  }
}
