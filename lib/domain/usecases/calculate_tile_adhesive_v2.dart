import '../../data/models/price_item.dart';
import 'base_calculator.dart';
import 'calculator_usecase.dart';

/// Калькулятор плиточного клея V2.
///
/// Расчёт количества клея, затирки и аксессуаров для укладки плитки.
///
/// Входные параметры:
/// - inputMode: режим ввода (0 - по размерам, 1 - по площади)
/// - area: площадь в м² (для режима по площади)
/// - length: длина в м (для режима по размерам)
/// - width: ширина в м (для режима по размерам)
/// - tileType: тип плитки (0-мозаика, 1-керамика, 2-керамогранит, 3-крупноформат)
/// - surfaceType: тип поверхности (0-стена, 1-пол)
/// - bagWeight: вес мешка (20 или 25 кг)
/// - useSVP: использовать СВП (0-нет, 1-да)
/// - calculateGrout: рассчитать затирку (0-нет, 1-да)
/// - useWaterproofing: рассчитать гидроизоляцию (0-нет, 1-да)
/// - brandIndex: индекс марки клея (0-14, 14=средний расход)
///
/// Выходные значения:
/// - area: расчётная площадь (м²)
/// - adhesiveConsumption: расход клея (кг/м²)
/// - totalWeight: общий вес клея (кг)
/// - bagsNeeded: количество мешков (шт)
/// - primerLiters: грунтовка (л)
/// - crossesNeeded: крестики (шт)
/// - svpCount: СВП клипсы (шт)
/// - groutWeight: затирка (кг) - если выбрана опция
/// - waterproofingWeight: гидроизоляция (кг) - если выбрана опция
class CalculateTileAdhesiveV2 extends BaseCalculator {
  // Типы плитки с параметрами: (размер зуба шпателя мм, коэффициент, стандартный размер см)
  static const List<_TileTypeParams> _tileTypes = [
    _TileTypeParams(notchSize: 6, coefficient: 0.60, defaultSize: 10.0),  // мозаика
    _TileTypeParams(notchSize: 8, coefficient: 0.55, defaultSize: 30.0),  // керамика
    _TileTypeParams(notchSize: 10, coefficient: 0.55, defaultSize: 40.0), // керамогранит
    _TileTypeParams(notchSize: 12, coefficient: 0.80, defaultSize: 60.0), // крупноформат
  ];

  // Базовый расход клея для разных марок (кг/м²/мм)
  static const List<double> _brandConsumptions = [
    1.5, // Ceresit CM 11
    1.6, // Ceresit CM 12
    1.8, // Ceresit CM 14
    1.8, // Ceresit CM 17
    1.4, // Unis 21
    1.5, // Unis Плюс
    1.6, // Unis 2000
    1.7, // Unis Гранит
    1.6, // Unis Белфикс
    1.5, // Knauf Флизен
    1.6, // Knauf Флекс
    1.4, // Litokol X11
    1.6, // Litokol K80
    1.5, // Волма Керамик
    1.5, // Средний расход (default)
  ];

  // Коэффициенты поверхности
  static const double _wallSurfaceFactor = 1.1;
  static const double _floorSurfaceFactor = 1.0;

  // Нормативы расхода материалов
  static const double _adhesiveMarginPercent = 10.0;
  static const double _groutMarginPercent = 10.0;
  static const double _primerPerM2 = 0.15;
  static const double _waterproofingPerLayer = 0.4;
  static const int _waterproofingLayers = 2;

  // Параметры затирки
  static const double _jointWidth = 3.0;
  static const double _jointDepth = 2.0;
  static const double _groutDensity = 1.6;

  // Аксессуары
  static const int _crossesPerTile = 5;
  static const int _svpClipsSmall = 4;
  static const int _svpClipsMedium = 3;
  static const int _svpClipsLarge = 2;
  static const double _smallTileThreshold = 20.0;
  static const double _largeTileThreshold = 40.0;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final inputMode = getIntInput(inputs, 'inputMode', defaultValue: 1, minValue: 0, maxValue: 1);
    final area = getInput(inputs, 'area', defaultValue: 20.0, minValue: 1.0, maxValue: 1000.0);
    final length = getInput(inputs, 'length', defaultValue: 5.0, minValue: 0.1, maxValue: 100.0);
    final width = getInput(inputs, 'width', defaultValue: 4.0, minValue: 0.1, maxValue: 100.0);
    final tileTypeIndex = getIntInput(inputs, 'tileType', defaultValue: 1, minValue: 0, maxValue: 3);
    final surfaceTypeIndex = getIntInput(inputs, 'surfaceType', defaultValue: 0, minValue: 0, maxValue: 1);
    final bagWeight = getIntInput(inputs, 'bagWeight', defaultValue: 25, minValue: 20, maxValue: 25);
    final useSVP = getInput(inputs, 'useSVP', defaultValue: 0.0) == 1.0;
    final calculateGrout = getInput(inputs, 'calculateGrout', defaultValue: 0.0) == 1.0;
    final useWaterproofing = getInput(inputs, 'useWaterproofing', defaultValue: 0.0) == 1.0;
    final brandIndex = getIntInput(inputs, 'brandIndex', defaultValue: 14, minValue: 0, maxValue: 14);

    // Расчёт площади
    final calculatedArea = inputMode == 1 ? area : length * width;

    // Параметры плитки
    final tileType = _tileTypes[tileTypeIndex];
    final notchSize = tileType.notchSize;
    final coefficient = tileType.coefficient;
    final tileSize = tileType.defaultSize;

    // Коэффициент поверхности
    final surfaceFactor = getConstantDouble(
      'surface_factors',
      surfaceTypeIndex == 0 ? 'wall' : 'floor',
      defaultValue: surfaceTypeIndex == 0 ? _wallSurfaceFactor : _floorSurfaceFactor,
    );

    // Базовый расход клея
    final baseConsumption = _brandConsumptions[brandIndex];

    // Расход клея на м² (кг/м²)
    final adhesiveConsumption = baseConsumption * notchSize * coefficient * surfaceFactor;

    // Общий вес с запасом
    final adhesiveMargin = getConstantDouble('margins', 'adhesive_margin', defaultValue: 1 + _adhesiveMarginPercent / 100);
    final totalWeight = calculatedArea * adhesiveConsumption * adhesiveMargin;

    // Количество мешков
    final normalizedBagWeight = bagWeight == 20 ? 20 : 25;
    final bagsNeeded = (totalWeight / normalizedBagWeight).ceil();

    // Грунтовка
    final primerPerM2 = getConstantDouble('materials_consumption', 'primer_per_m2', defaultValue: _primerPerM2);
    final primerLiters = calculatedArea * primerPerM2;

    // Количество плиток
    final tileAreaM2 = (tileSize / 100) * (tileSize / 100);
    final tilesCount = (calculatedArea / tileAreaM2).ceil();

    // Крестики для швов
    final crossesPerTile = getConstantInt('accessories', 'crosses_per_tile', defaultValue: _crossesPerTile);
    final crossesNeeded = tilesCount * crossesPerTile;

    // СВП (система выравнивания плитки)
    int svpCount = 0;
    if (useSVP) {
      final smallThreshold = getConstantDouble('accessories', 'small_tile_threshold', defaultValue: _smallTileThreshold);
      final largeThreshold = getConstantDouble('accessories', 'large_tile_threshold', defaultValue: _largeTileThreshold);
      final clipsSmall = getConstantInt('accessories', 'svp_clips_small', defaultValue: _svpClipsSmall);
      final clipsMedium = getConstantInt('accessories', 'svp_clips_medium', defaultValue: _svpClipsMedium);
      final clipsLarge = getConstantInt('accessories', 'svp_clips_large', defaultValue: _svpClipsLarge);

      final clipsPerTile = tileSize < smallThreshold
          ? clipsSmall
          : (tileSize <= largeThreshold ? clipsMedium : clipsLarge);
      svpCount = tilesCount * clipsPerTile;
    }

    // Расчёт затирки
    double groutWeight = 0.0;
    if (calculateGrout) {
      final jointWidth = getConstantDouble('grout', 'joint_width', defaultValue: _jointWidth);
      final jointDepth = getConstantDouble('grout', 'joint_depth', defaultValue: _jointDepth);
      final groutDensity = getConstantDouble('grout', 'density', defaultValue: _groutDensity);
      final groutMargin = getConstantDouble('margins', 'grout_margin', defaultValue: 1 + _groutMarginPercent / 100);

      // Формула: (Длина + Ширина) / (Длина × Ширина) × Ширина_шва × Глубина_шва × Плотность × Площадь
      final groutConsumptionPerM2 =
          ((tileSize + tileSize) / (tileSize * tileSize)) *
          jointWidth *
          jointDepth *
          groutDensity;
      groutWeight = calculatedArea * groutConsumptionPerM2 * groutMargin;
    }

    // Гидроизоляция
    double waterproofingWeight = 0.0;
    if (useWaterproofing) {
      final perLayer = getConstantDouble('materials_consumption', 'waterproofing_per_layer', defaultValue: _waterproofingPerLayer);
      final layers = getConstantInt('materials_consumption', 'waterproofing_layers', defaultValue: _waterproofingLayers);
      waterproofingWeight = calculatedArea * perLayer * layers;
    }

    return createResult(
      values: {
        'area': calculatedArea,
        'tileType': tileTypeIndex.toDouble(),
        'surfaceType': surfaceTypeIndex.toDouble(),
        'notchSize': notchSize.toDouble(),
        'adhesiveConsumption': adhesiveConsumption,
        'totalWeight': totalWeight,
        'bagsNeeded': bagsNeeded.toDouble(),
        'bagWeight': normalizedBagWeight.toDouble(),
        'primerLiters': primerLiters,
        'crossesNeeded': crossesNeeded.toDouble(),
        'svpCount': svpCount.toDouble(),
        'tileSize': tileSize,
        'groutWeight': groutWeight,
        'waterproofingWeight': waterproofingWeight,
      },
      calculatorId: 'tile_adhesive',
    );
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final inputMode = inputs['inputMode']?.toInt() ?? 1;

    if (inputMode == 1) {
      final area = inputs['area'] ?? 0;
      if (area < 1.0) {
        return 'Площадь должна быть не менее 1 м²';
      }
      if (area > 1000.0) {
        return 'Площадь не может превышать 1000 м²';
      }
    } else {
      final length = inputs['length'] ?? 0;
      final width = inputs['width'] ?? 0;
      if (length < 0.1 || width < 0.1) {
        return 'Размеры должны быть не менее 0.1 м';
      }
    }

    return null;
  }
}

/// Вспомогательный класс для параметров типа плитки
class _TileTypeParams {
  final int notchSize;
  final double coefficient;
  final double defaultSize;

  const _TileTypeParams({
    required this.notchSize,
    required this.coefficient,
    required this.defaultSize,
  });
}
