// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import './wallpaper_canonical_adapter.dart';

class CalculateWallpaper extends BaseCalculator {
  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (hasCanonicalWallpaperInputs(inputs)) {
      return Map<String, double>.from(inputs);
    }
    return normalizeLegacyWallpaperInputs(inputs);
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    return calculateCanonicalWallpaper(_normalizeInputs(inputs));
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final normalized = _normalizeInputs(inputs);
    final inputMode = (normalized['inputMode'] ?? 0).toInt();
    if (inputMode == 0) {
      final hasPerimeter = (normalized['perimeter'] ?? 0) > 0;
      final hasRoom =
          (normalized['roomWidth'] ?? 0) > 0 &&
          (normalized['roomLength'] ?? 0) > 0;
      final hasLegacyRoom =
          (normalized['length'] ?? 0) > 0 && (normalized['width'] ?? 0) > 0;
      if (!hasPerimeter && !hasRoom && !hasLegacyRoom) {
        return perimeterOrRoomDimensionsRequiredMessage();
      }
    } else {
      final area = normalized['area'] ?? 0;
      if (area <= 0) return positiveValueMessage('area');
    }

    final wallHeight =
        normalized['wallHeight'] ??
        normalized['height'] ??
        normalized['roomHeight'] ??
        2.5;
    if (wallHeight <= 0 || wallHeight > 5) {
      return rangeMessage('wallHeight', 0.1, 5, unit: 'м');
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonical(inputs);
    final usefulArea = contract.totals['netArea'] ?? 0;
    if (usefulArea <= 0) {
      throw CalculationException.invalidInput('wallpaper', 'Площадь должна быть > 0');
    }

    final wallpaperPrice = findPrice(priceList, [
      'wallpaper',
      'wallpaper_vinyl',
      'wallpaper_fleece',
      'wallpaper_paper',
    ]);
    final gluePrice = findPrice(priceList, ['glue_wallpaper', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final rollsNeeded = contract.totals['rollsNeeded'] ?? 0;
    final pasteNeeded = contract.totals['pasteNeededKg'] ?? 0;
    final primerNeeded = contract.totals['primerNeededL'] ?? 0;

    return createResult(
      values: {
        'usefulArea': usefulArea,
        'rollsNeeded': rollsNeeded,
        'stripsNeeded': contract.totals['stripsNeeded'] ?? 0,
        'glueNeeded': pasteNeeded,
        'pasteNeeded': pasteNeeded,
        'pastePacks': contract.totals['pastePacks'] ?? 0,
        'primerNeeded': primerNeeded,
        'primerCans': contract.totals['primerCans'] ?? 0,
        'stripLength': contract.totals['stripLength'] ?? 0,
        'wallpaperType': contract.totals['wallpaperType'] ?? 1,
      },
      totalPrice: sumCosts([
        calculateCost(rollsNeeded, wallpaperPrice?.price),
        calculateCost(pasteNeeded, gluePrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'wallpaper-canonical',
    );
  }
}
