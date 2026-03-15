// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import '../generated/canonical_specs.g.dart';
import '../generated/spec_reader.dart';
import '../models/canonical_calculator_contract.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';
import './tile_canonical_adapter.dart';

const _tileSpec = SpecReader(tileSpecData);

class CalculateTile extends BaseCalculator {
  static const int _bathroomRoomType = 0;
  static const int _balconyRoomType = 4;
  static const int _mosaicMaterial = 2;

  Map<String, double> _normalizeInputs(Map<String, double> inputs) {
    if (hasCanonicalTileInputs(inputs)) {
      return Map<String, double>.from(inputs);
    }
    return normalizeLegacyTileInputs(inputs);
  }

  bool _isEnabled(Map<String, double> inputs, String key) {
    return (inputs[key] ?? 0) > 0;
  }

  bool _roomNeedsWaterproofing(int roomTypeId) {
    return roomTypeId == _bathroomRoomType || roomTypeId == _balconyRoomType;
  }

  double _resolveBoxArea(int materialId) {
    return materialId == _mosaicMaterial ? 0.5 : 1.44;
  }

  int _resolveSvpClipsPerTile(double averageTileSizeCm) {
    if (averageTileSizeCm < 20) return 4;
    if (averageTileSizeCm <= 40) return 3;
    return 2;
  }

  CanonicalCalculatorContractResult calculateCanonical(
    Map<String, double> inputs,
  ) {
    final normalized = _normalizeInputs(inputs);
    final contract = calculateCanonicalTile(normalized);
    final totals = Map<String, double>.from(contract.totals);

    final materialId = (normalized['material'] ?? 0).round().clamp(0, 3);
    final roomTypeId = (normalized['roomType'] ?? 1).round().clamp(0, 4);
    final useSVP = _isEnabled(normalized, 'useSVP');
    final useWaterproofing = _isEnabled(normalized, 'useWaterproofing');
    final useUnderlay = _isEnabled(normalized, 'useUnderlay');
    final effectiveWaterproofing =
        useWaterproofing || _roomNeedsWaterproofing(roomTypeId);

    final area = totals['area'] ?? 0;
    final tilesNeeded = (totals['tilesNeeded'] ?? 0).round();
    final tileArea = totals['tileArea'] ?? 0;
    final tilesArea = tileArea * tilesNeeded;
    final boxArea = _resolveBoxArea(materialId);
    final boxesNeeded = tilesArea > 0 ? (tilesArea / boxArea).ceil() : 0;
    final glueWeight = totals['glueNeededKg'] ?? 0;
    final glueBags = glueWeight > 0
        ? (glueWeight / _tileSpec.packagingRule<num>('glue_bag_kg').toDouble()).ceil()
        : 0;
    final averageTileSize = totals['averageTileSizeCm'] ?? 0;
    final svpCount = useSVP
        ? tilesNeeded * _resolveSvpClipsPerTile(averageTileSize)
        : 0;
    final waterproofingWeight = effectiveWaterproofing
        ? area * 1.5 * 2 * 1.1
        : 0.0;
    final underlayArea = useUnderlay ? area * 1.1 : 0.0;

    return CanonicalCalculatorContractResult(
      canonicalSpecId: contract.canonicalSpecId,
      formulaVersion: contract.formulaVersion,
      materials: contract.materials,
      warnings: contract.warnings,
      scenarios: contract.scenarios,
      totals: {
        ...totals,
        'material': materialId.toDouble(),
        'roomType': roomTypeId.toDouble(),
        'tilesArea': tilesArea,
        'boxArea': boxArea,
        'boxesNeeded': boxesNeeded.toDouble(),
        'glueBags': glueBags.toDouble(),
        'useSVP': useSVP ? 1.0 : 0.0,
        'svpCount': svpCount.toDouble(),
        'useWaterproofing': useWaterproofing ? 1.0 : 0.0,
        'effectiveWaterproofing': effectiveWaterproofing ? 1.0 : 0.0,
        'waterproofingWeight': waterproofingWeight,
        'useUnderlay': useUnderlay ? 1.0 : 0.0,
        'underlayArea': underlayArea,
      },
    );
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final normalized = _normalizeInputs(inputs);
    final inputMode = (normalized['inputMode'] ?? 1).toInt();
    if (inputMode == 0) {
      final length = normalized['length'] ?? 0;
      final width = normalized['width'] ?? 0;
      if (length <= 0) return positiveValueMessage('length');
      if (width <= 0) return positiveValueMessage('width');
    } else {
      final area = normalized['area'] ?? 0;
      if (area <= 0) return positiveValueMessage('area');
    }

    final tileWidthCm = normalized['tileWidthCm'] ?? 0;
    final tileHeightCm = normalized['tileHeightCm'] ?? 0;
    if (tileWidthCm <= 0 || tileWidthCm > 200) {
      return rangeMessage('tileWidthCm', 1, 200, unit: 'см');
    }
    if (tileHeightCm <= 0 || tileHeightCm > 200) {
      return rangeMessage('tileHeightCm', 1, 200, unit: 'см');
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final contract = calculateCanonical(inputs);
    final area = contract.totals['area'] ?? 0;
    if (area <= 0) {
      return createResult(values: {'error': 1.0});
    }

    final tilePrice = findPrice(priceList, [
      'tile',
      'tile_ceramic',
      'tile_porcelain',
    ]);
    final groutPrice = findPrice(priceList, ['grout', 'grout_tile']);
    final gluePrice = findPrice(priceList, ['glue_tile', 'glue']);
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep']);

    final tilesNeeded = contract.totals['tilesNeeded'] ?? 0;
    final groutNeeded = contract.totals['groutNeededKg'] ?? 0;
    final glueNeeded = contract.totals['glueNeededKg'] ?? 0;
    final primerNeeded = contract.totals['primerNeededL'] ?? 0;
    final avgSize = contract.totals['averageTileSizeCm'] ?? 0;
    final layoutPattern = contract.totals['layoutPattern']?.round() ?? 1;

    return createResult(
      values: {
        'area': area,
        'tilesNeeded': tilesNeeded,
        'groutNeeded': groutNeeded,
        'glueNeeded': glueNeeded,
        'crossesNeeded': contract.totals['crossesNeeded'] ?? 0,
        'primerNeeded': primerNeeded,
        'wastePercent': contract.totals['wastePercent'] ?? 0,
        'boxesNeeded': contract.totals['boxesNeeded'] ?? 0,
        'glueBags': contract.totals['glueBags'] ?? 0,
        'svpCount': contract.totals['svpCount'] ?? 0,
        'waterproofingWeight': contract.totals['waterproofingWeight'] ?? 0,
        'underlayArea': contract.totals['underlayArea'] ?? 0,
        'effectiveWaterproofing':
            contract.totals['effectiveWaterproofing'] ?? 0,
        if (avgSize >
            _tileSpec.warningRule<num>('large_tile_warning_threshold_cm').toDouble())
          'warningLargeTile': 1.0,
        if (layoutPattern == 4 &&
            area > _tileSpec.warningRule<num>('herringbone_large_area_m2').toDouble())
          'warningHerringboneLargeArea': 1.0,
      },
      totalPrice: sumCosts([
        calculateCost(tilesNeeded, tilePrice?.price),
        calculateCost(groutNeeded, groutPrice?.price),
        calculateCost(glueNeeded, gluePrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
      ]),
      norms: [...normativeSources, contract.formulaVersion],
      calculatorId: 'tile-canonical',
    );
  }
}
