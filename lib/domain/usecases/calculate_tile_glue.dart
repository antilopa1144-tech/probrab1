// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import 'calculator_usecase.dart';
import 'base_calculator.dart';

class _TileGlueTileProfile {
  final int id;
  final String key;
  final int notchSize;
  final double coefficient;
  final double defaultTileSizeCm;

  const _TileGlueTileProfile({
    required this.id,
    required this.key,
    required this.notchSize,
    required this.coefficient,
    required this.defaultTileSizeCm,
  });
}

class _TileGlueBrandProfile {
  final int id;
  final double baseConsumption;
  final List<int> bagSizes;

  const _TileGlueBrandProfile({
    required this.id,
    required this.baseConsumption,
    required this.bagSizes,
  });
}

const List<_TileGlueTileProfile> _screenTileProfiles = [
  _TileGlueTileProfile(
    id: 0,
    key: 'mosaic',
    notchSize: 6,
    coefficient: 0.6,
    defaultTileSizeCm: 10,
  ),
  _TileGlueTileProfile(
    id: 1,
    key: 'ceramic',
    notchSize: 8,
    coefficient: 0.55,
    defaultTileSizeCm: 30,
  ),
  _TileGlueTileProfile(
    id: 2,
    key: 'porcelain',
    notchSize: 10,
    coefficient: 0.55,
    defaultTileSizeCm: 40,
  ),
  _TileGlueTileProfile(
    id: 3,
    key: 'largeFormat',
    notchSize: 12,
    coefficient: 0.8,
    defaultTileSizeCm: 60,
  ),
];

const List<_TileGlueBrandProfile> _screenBrandProfiles = [
  _TileGlueBrandProfile(id: 0, baseConsumption: 1.2, bagSizes: [25]),
  _TileGlueBrandProfile(id: 1, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 2, baseConsumption: 1.6, bagSizes: [25]),
  _TileGlueBrandProfile(id: 3, baseConsumption: 1.8, bagSizes: [25]),
  _TileGlueBrandProfile(id: 4, baseConsumption: 1.9, bagSizes: [25]),
  _TileGlueBrandProfile(id: 5, baseConsumption: 1.4, bagSizes: [25]),
  _TileGlueBrandProfile(id: 6, baseConsumption: 1.4, bagSizes: [25]),
  _TileGlueBrandProfile(id: 7, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 8, baseConsumption: 1.6, bagSizes: [25]),
  _TileGlueBrandProfile(id: 9, baseConsumption: 1.7, bagSizes: [25]),
  _TileGlueBrandProfile(id: 10, baseConsumption: 1.6, bagSizes: [20, 25]),
  _TileGlueBrandProfile(id: 11, baseConsumption: 1.2, bagSizes: [25]),
  _TileGlueBrandProfile(id: 12, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 13, baseConsumption: 1.6, bagSizes: [25]),
  _TileGlueBrandProfile(id: 14, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 15, baseConsumption: 1.4, bagSizes: [25]),
  _TileGlueBrandProfile(id: 16, baseConsumption: 1.6, bagSizes: [25]),
  _TileGlueBrandProfile(id: 17, baseConsumption: 1.2, bagSizes: [20]),
  _TileGlueBrandProfile(id: 18, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 19, baseConsumption: 1.4, bagSizes: [25]),
  _TileGlueBrandProfile(id: 20, baseConsumption: 1.6, bagSizes: [25]),
  _TileGlueBrandProfile(id: 21, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 22, baseConsumption: 1.3, bagSizes: [25]),
  _TileGlueBrandProfile(id: 23, baseConsumption: 1.4, bagSizes: [25]),
  _TileGlueBrandProfile(id: 24, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 25, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 26, baseConsumption: 1.6, bagSizes: [25]),
  _TileGlueBrandProfile(id: 27, baseConsumption: 1.4, bagSizes: [25]),
  _TileGlueBrandProfile(id: 28, baseConsumption: 1.5, bagSizes: [25]),
  _TileGlueBrandProfile(id: 29, baseConsumption: 1.5, bagSizes: [20, 25]),
];

class CalculateTileGlue extends BaseCalculator {
  static const double _screenAdhesiveMargin = 1.1;
  static const double _screenPrimerPerM2 = 0.15;
  static const double _screenWaterproofingPerLayer = 0.4;
  static const int _screenWaterproofingLayers = 2;
  static const int _screenCrossesPerTile = 5;
  static const int _screenSvpClipsSmall = 4;
  static const int _screenSvpClipsMedium = 3;
  static const int _screenSvpClipsLarge = 2;
  static const int _screenSmallTileThreshold = 20;
  static const int _screenLargeTileThreshold = 40;
  static const double _screenJointWidth = 3.0;
  static const double _screenJointDepth = 2.0;
  static const double _screenGroutDensity = 1.6;
  static const double _screenGroutMargin = 1.1;

  bool _hasScreenInputs(Map<String, double> inputs) {
    const keys = [
      'inputMode',
      'tileType',
      'adhesiveBrand',
      'bagWeight',
      'surfaceType',
      'useSVP',
      'calculateGrout',
      'useWaterproofing',
      'length',
      'width',
    ];
    return keys.any(inputs.containsKey);
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    if (_hasScreenInputs(inputs)) {
      final area = _resolveScreenArea(inputs);
      if (area <= 0) return positiveValueMessage('area');
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
    if (_hasScreenInputs(inputs)) {
      return _calculateScreenPath(inputs, priceList);
    }
    return _calculateLegacyPath(inputs, priceList);
  }

  CalculatorResult _calculateScreenPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = _resolveScreenArea(inputs);
    final tileProfile = _resolveTileProfile(inputs);
    final brandProfile = _resolveBrandProfile(inputs);
    final bagWeight = _resolveBagWeight(inputs, brandProfile);
    final surfaceType = (inputs['surfaceType'] ?? 0).round().clamp(0, 1);
    final surfaceFactor = surfaceType == 0 ? 1.1 : 1.0;
    final adhesiveConsumption =
        brandProfile.baseConsumption *
        tileProfile.notchSize *
        tileProfile.coefficient *
        surfaceFactor;
    final totalWeight = area * adhesiveConsumption * _screenAdhesiveMargin;
    final bagsNeeded = (totalWeight / bagWeight).ceil();
    final primerNeeded = area * _screenPrimerPerM2;
    final tileWidth = tileProfile.defaultTileSizeCm;
    final tileHeight = tileProfile.defaultTileSizeCm;
    final tileAreaM2 = (tileWidth / 100) * (tileHeight / 100);
    final tilesCount = (area / tileAreaM2).ceil();
    final crossesNeeded = tilesCount * _screenCrossesPerTile;
    final avgTileSize = (tileWidth + tileHeight) / 2;
    final clipsPerTile = avgTileSize < _screenSmallTileThreshold
        ? _screenSvpClipsSmall
        : (avgTileSize <= _screenLargeTileThreshold
              ? _screenSvpClipsMedium
              : _screenSvpClipsLarge);
    final useSVP = (inputs['useSVP'] ?? 0) > 0;
    final calculateGrout = (inputs['calculateGrout'] ?? 0) > 0;
    final useWaterproofing = (inputs['useWaterproofing'] ?? 0) > 0;
    final svpCount = useSVP ? tilesCount * clipsPerTile : 0;

    double? groutWeight;
    if (calculateGrout) {
      final groutConsumptionPerM2 =
          ((tileWidth + tileHeight) / (tileWidth * tileHeight)) *
          _screenJointWidth *
          _screenJointDepth *
          _screenGroutDensity;
      groutWeight = area * groutConsumptionPerM2 * _screenGroutMargin;
    }

    double? waterproofingWeight;
    if (useWaterproofing) {
      waterproofingWeight =
          area * _screenWaterproofingPerLayer * _screenWaterproofingLayers;
    }

    final gluePrice = findPrice(priceList, [
      'glue_tile',
      'tile_adhesive',
      'glue',
      'mortar_tile',
    ]);
    final primerPrice = findPrice(priceList, ['primer', 'primer_adhesion']);

    return createResult(
      values: {
        'area': area,
        'tileWidth': tileWidth,
        'tileHeight': tileHeight,
        'notchSize': tileProfile.notchSize.toDouble(),
        'consumptionPerM2': adhesiveConsumption,
        'glueNeeded': totalWeight,
        'bagsNeeded': bagsNeeded.toDouble(),
        'bagWeight': bagWeight.toDouble(),
        'primerNeeded': primerNeeded,
        'crossesNeeded': crossesNeeded.toDouble(),
        'svpCount': svpCount.toDouble(),
        'tileType': tileProfile.id.toDouble(),
        'adhesiveBrand': brandProfile.id.toDouble(),
        'surfaceType': surfaceType.toDouble(),
        if (groutWeight != null) 'groutWeight': groutWeight,
        if (waterproofingWeight != null)
          'waterproofingWeight': waterproofingWeight,
      },
      totalPrice: sumCosts([
        calculateCost(totalWeight, gluePrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
      ]),
    );
  }

  CalculatorResult _calculateLegacyPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final tileSize = getInput(
      inputs,
      'tileSize',
      defaultValue: 30.0,
      minValue: 5.0,
      maxValue: 150.0,
    );
    final layerThickness = getInput(
      inputs,
      'layerThickness',
      defaultValue: 5.0,
      minValue: 2.0,
      maxValue: 15.0,
    );
    final surface = getIntInput(
      inputs,
      'surface',
      defaultValue: 2,
      minValue: 1,
      maxValue: 2,
    );

    var baseConsumption = 4.2;
    if (tileSize < 10) {
      baseConsumption *= 0.7;
    } else if (tileSize < 20) {
      baseConsumption *= 0.85;
    } else if (tileSize > 60) {
      baseConsumption *= 1.4;
    } else if (tileSize > 40) {
      baseConsumption *= 1.2;
    }

    final thicknessFactor = layerThickness / 5.0;
    final surfaceFactor = surface == 1 ? 1.1 : 1.0;
    final consumptionPerM2 = baseConsumption * thicknessFactor * surfaceFactor;
    final glueNeeded = area * consumptionPerM2 * 1.08;
    final primerNeeded = area * 0.15;
    final notchSize = tileSize < 20 ? 6 : (tileSize < 40 ? 8 : 10);
    const spatulasNeeded = 1;
    final tilesCount = ceilToInt(area / ((tileSize / 100) * (tileSize / 100)));
    final crossesNeeded = tilesCount * 5;
    const bucketsNeeded = 1;
    final waterNeeded = glueNeeded * 0.25;

    final gluePrice = findPrice(priceList, [
      'glue_tile',
      'tile_adhesive',
      'glue',
      'mortar_tile',
    ]);
    final primerPrice = findPrice(priceList, ['primer', 'primer_adhesion']);

    return createResult(
      values: {
        'area': area,
        'tileSize': tileSize,
        'layerThickness': layerThickness,
        'glueNeeded': glueNeeded,
        'consumptionPerM2': consumptionPerM2,
        'primerNeeded': primerNeeded,
        'notchSize': notchSize.toDouble(),
        'spatulasNeeded': spatulasNeeded.toDouble(),
        'crossesNeeded': crossesNeeded.toDouble(),
        'bucketsNeeded': bucketsNeeded.toDouble(),
        'waterNeeded': waterNeeded,
      },
      totalPrice: sumCosts([
        calculateCost(glueNeeded, gluePrice?.price),
        calculateCost(primerNeeded, primerPrice?.price),
      ]),
    );
  }

  double _resolveScreenArea(Map<String, double> inputs) {
    final inputMode = (inputs['inputMode'] ?? 1).round();
    if (inputMode == 0) {
      final length = (inputs['length'] ?? 0).clamp(0, 1000).toDouble();
      final width = (inputs['width'] ?? 0).clamp(0, 1000).toDouble();
      return length * width;
    }
    return (inputs['area'] ?? 0).clamp(0, 100000).toDouble();
  }

  _TileGlueTileProfile _resolveTileProfile(Map<String, double> inputs) {
    final id = (inputs['tileType'] ?? 1).round().clamp(
      0,
      _screenTileProfiles.length - 1,
    );
    return _screenTileProfiles[id];
  }

  _TileGlueBrandProfile _resolveBrandProfile(Map<String, double> inputs) {
    final id =
        (inputs['adhesiveBrand'] ??
                (_screenBrandProfiles.length - 1).toDouble())
            .round()
            .clamp(0, _screenBrandProfiles.length - 1);
    return _screenBrandProfiles[id];
  }

  int _resolveBagWeight(
    Map<String, double> inputs,
    _TileGlueBrandProfile brandProfile,
  ) {
    final requested =
        (inputs['bagWeight'] ?? brandProfile.bagSizes.first.toDouble()).round();
    if (brandProfile.bagSizes.contains(requested)) return requested;
    return brandProfile.bagSizes.first;
  }
}
