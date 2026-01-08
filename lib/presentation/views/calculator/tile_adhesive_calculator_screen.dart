import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

/// Helper class for accessing tile adhesive calculator constants
class _TileAdhesiveConstants {
  final CalculatorConstants? _data;

  _TileAdhesiveConstants(this._data);

  double _getDouble(String category, String key, double defaultValue) {
    return _data?.getDouble(category, key, defaultValue: defaultValue) ?? defaultValue;
  }

  int _getInt(String category, String key, int defaultValue) {
    return _data?.getInt(category, key, defaultValue: defaultValue) ?? defaultValue;
  }

  // Surface factors
  double getSurfaceFactor(String surfaceKey) {
    final defaults = {'wall': 1.1, 'floor': 1.0};
    return _getDouble('surface_factors', surfaceKey, defaults[surfaceKey] ?? 1.0);
  }

  // Margins
  double get adhesiveMargin => _getDouble('margins', 'adhesive_margin', 1.1);
  double get groutMargin => _getDouble('margins', 'grout_margin', 1.1);

  // Materials consumption
  double get primerPerM2 => _getDouble('materials_consumption', 'primer_per_m2', 0.15);
  double get waterproofingPerLayer => _getDouble('materials_consumption', 'waterproofing_per_layer', 0.4);
  int get waterproofingLayers => _getInt('materials_consumption', 'waterproofing_layers', 2);

  // Tile sizes
  double getTileSize(String tileTypeKey) {
    final defaults = {
      'mosaic': 10.0,
      'ceramic': 30.0,
      'porcelain': 40.0,
      'largeFormat': 60.0,
    };
    return _getDouble('tile_sizes', tileTypeKey, defaults[tileTypeKey] ?? 30.0);
  }

  // Accessories
  int get crossesPerTile => _getInt('accessories', 'crosses_per_tile', 5);
  int get svpClipsSmall => _getInt('accessories', 'svp_clips_small', 4);
  int get svpClipsMedium => _getInt('accessories', 'svp_clips_medium', 3);
  int get svpClipsLarge => _getInt('accessories', 'svp_clips_large', 2);
  int get smallTileThreshold => _getInt('accessories', 'small_tile_threshold', 20);
  int get largeTileThreshold => _getInt('accessories', 'large_tile_threshold', 40);

  // Grout parameters
  double get jointWidth => _getDouble('grout', 'joint_width', 3.0);
  double get jointDepth => _getDouble('grout', 'joint_depth', 2.0);
  double get groutDensity => _getDouble('grout', 'density', 1.6);
}

enum InputMode { byDimensions, byArea }
enum BagWeight { kg20, kg25 }
enum SurfaceType { wall, floor }

enum TileType {
  mosaic(6, 0.6, 'tile_adhesive.tile_type.mosaic'),
  ceramic(8, 0.55, 'tile_adhesive.tile_type.ceramic'),
  porcelain(10, 0.55, 'tile_adhesive.tile_type.porcelain'),
  largeFormat(12, 0.8, 'tile_adhesive.tile_type.large_format');

  final int notchSize; // Размер зуба шпателя (мм)
  final double coefficient; // Коэффициент прижатия и нанесения
  final String nameKey;
  const TileType(this.notchSize, this.coefficient, this.nameKey);
}

enum AdhesiveBrand {
  ceresitCM11(1.5, 'Ceresit CM 11', [25]),
  ceresitCM12(1.6, 'Ceresit CM 12', [25]),
  ceresitCM14(1.8, 'Ceresit CM 14', [25]),
  ceresitCM17(1.8, 'Ceresit CM 17', [25]),
  unis21(1.4, 'Unis 21 (UniPlus)', [25]),
  unisPlus(1.5, 'Unis Плюс', [25]),
  unis2000(1.6, 'Unis 2000', [25]),
  unisGranit(1.7, 'Unis Гранит', [25]),
  unisBelix(1.6, 'Unis Белфикс', [20, 25]),
  knaufFliesen(1.5, 'Knauf Флизен', [25]),
  knaufFlex(1.6, 'Knauf Флекс', [25]),
  litokolX11(1.4, 'Litokol X11', [25]),
  litokolK80(1.6, 'Litokol K80', [25]),
  volmaCeramic(1.5, 'Волма Керамик', [25]),
  average(1.5, 'Средний расход', [20, 25]);

  final double baseConsumption; // Базовый расход (кг/м²/мм)
  final String name;
  final List<int> availableBagSizes;
  const AdhesiveBrand(this.baseConsumption, this.name, this.availableBagSizes);

  bool hasBagSize(int size) => availableBagSizes.contains(size);
  int get defaultBagSize => availableBagSizes.first;
  bool get hasMultipleSizes => availableBagSizes.length > 1;
}

class _TileAdhesiveResult {
  final double area;
  final TileType tileType;
  final AdhesiveBrand brand;
  final SurfaceType surfaceType;
  final int notchSize;
  final double adhesiveConsumption; // кг/м²
  final double totalWeight;
  final int bagsNeeded;
  final int bagWeight;
  final double primerLiters;
  final int crossesNeeded;
  final bool useSVP;
  final int svpCount;
  final double tileWidth;
  final double tileHeight;
  final double? groutWeight;
  final double? waterproofingWeight;

  const _TileAdhesiveResult({
    required this.area,
    required this.tileType,
    required this.brand,
    required this.surfaceType,
    required this.notchSize,
    required this.adhesiveConsumption,
    required this.totalWeight,
    required this.bagsNeeded,
    required this.bagWeight,
    required this.primerLiters,
    required this.crossesNeeded,
    required this.useSVP,
    required this.svpCount,
    required this.tileWidth,
    required this.tileHeight,
    this.groutWeight,
    this.waterproofingWeight,
  });
}

class TileAdhesiveCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const TileAdhesiveCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<TileAdhesiveCalculatorScreen> createState() =>
      _TileAdhesiveCalculatorScreenState();
}

class _TileAdhesiveCalculatorScreenState
    extends State<TileAdhesiveCalculatorScreen> with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('tile_adhesive.export.subject');
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  TileType _tileType = TileType.ceramic;
  AdhesiveBrand _adhesiveBrand = AdhesiveBrand.average;
  BagWeight _bagWeight = BagWeight.kg25;
  SurfaceType _surfaceType = SurfaceType.wall;
  bool _useSVP = false;
  bool _calculateGrout = false;
  bool _useWaterproofing = false;
  late _TileAdhesiveResult _result;
  late AppLocalizations _loc;

  // TODO: Подключить к calculatorConstantsProvider для получения Remote Config
  final _constants = _TileAdhesiveConstants(null);

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) {
      _length = initial['length']!.clamp(0.1, 100.0);
    }
    if (initial['width'] != null) _width = initial['width']!.clamp(0.1, 100.0);
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _TileAdhesiveResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Правильная формула расчета плиточного клея:
    // Расход = Базовый_расход × Размер_зуба × Коэффициент × Коэффициент_поверхности

    final notchSize = _tileType.notchSize;
    final coefficient = _tileType.coefficient;
    final surfaceFactor = _constants.getSurfaceFactor(_surfaceType.name);

    // Расход клея на м² (кг/м²)
    final adhesiveConsumption =
        _adhesiveBrand.baseConsumption * notchSize * coefficient * surfaceFactor;

    // Общий вес с запасом
    final totalWeight = calculatedArea * adhesiveConsumption * _constants.adhesiveMargin;

    // Вес мешка
    final bagWeightKg = _bagWeight == BagWeight.kg20 ? 20 : 25;

    // Количество мешков
    final bagsNeeded = (totalWeight / bagWeightKg).ceil();

    // Грунтовка
    final primerLiters = calculatedArea * _constants.primerPerM2;

    // Стандартные размеры плитки в зависимости от типа
    final tileWidth = _constants.getTileSize(_tileType.name);

    final tileHeight = tileWidth; // квадратная плитка

    // Рассчитываем количество плиток на основе стандартного размера
    final tileAreaM2 = (tileWidth / 100) * (tileHeight / 100);
    final tilesCount = (calculatedArea / tileAreaM2).ceil();

    // Крестики для швов
    final crossesNeeded = tilesCount * _constants.crossesPerTile;

    // СВП (система выравнивания плитки): количество клипс зависит от размера плитки
    final avgTileSize = (tileWidth + tileHeight) / 2;
    final clipsPerTile = avgTileSize < _constants.smallTileThreshold
        ? _constants.svpClipsSmall
        : (avgTileSize <= _constants.largeTileThreshold
            ? _constants.svpClipsMedium
            : _constants.svpClipsLarge);
    final svpCount = _useSVP ? tilesCount * clipsPerTile : 0;

    // Расчет затирки (опционально)
    double? groutWeight;
    if (_calculateGrout) {
      // Параметры затирки из констант
      final jointWidth = _constants.jointWidth;
      final jointDepth = _constants.jointDepth;
      final groutDensity = _constants.groutDensity;
      // Формула: (Длина + Ширина) / (Длина × Ширина) × Ширина_шва × Глубина_шва × Плотность × Площадь
      final groutConsumptionPerM2 =
          ((tileWidth + tileHeight) / (tileWidth * tileHeight)) *
          jointWidth *
          jointDepth *
          groutDensity;
      groutWeight = calculatedArea * groutConsumptionPerM2 * _constants.groutMargin;
    }

    // Гидроизоляция (опционально)
    double? waterproofingWeight;
    if (_useWaterproofing) {
      waterproofingWeight = calculatedArea *
          _constants.waterproofingPerLayer *
          _constants.waterproofingLayers;
    }

    return _TileAdhesiveResult(
      area: calculatedArea,
      tileType: _tileType,
      brand: _adhesiveBrand,
      surfaceType: _surfaceType,
      notchSize: notchSize,
      adhesiveConsumption: adhesiveConsumption,
      totalWeight: totalWeight,
      bagsNeeded: bagsNeeded,
      bagWeight: bagWeightKg,
      primerLiters: primerLiters,
      crossesNeeded: crossesNeeded,
      useSVP: _useSVP,
      svpCount: svpCount,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      groutWeight: groutWeight,
      waterproofingWeight: waterproofingWeight,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('tile_adhesive.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln(_loc.translate('tile_adhesive.export.area').replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('tile_adhesive.export.tile_type').replaceFirst('{value}', _loc.translate(_result.tileType.nameKey)));
    buffer.writeln(_loc.translate('tile_adhesive.export.tile_size')
        .replaceFirst('{width}', _result.tileWidth.toStringAsFixed(0))
        .replaceFirst('{height}', _result.tileHeight.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('tile_adhesive.export.notch_size').replaceFirst('{value}', _result.notchSize.toString()));
    final surfaceKey = _result.surfaceType == SurfaceType.wall
        ? 'tile_adhesive.export.surface_wall'
        : 'tile_adhesive.export.surface_floor';
    buffer.writeln(_loc.translate('tile_adhesive.export.surface').replaceFirst('{value}', _loc.translate(surfaceKey)));
    buffer.writeln();

    buffer.writeln(_loc.translate('tile_adhesive.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.adhesive_line').replaceFirst('{bags}', _result.bagsNeeded.toString()).replaceFirst('{weight}', _result.bagWeight.toString())}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.consumption_line').replaceFirst('{value}', _result.adhesiveConsumption.toStringAsFixed(2))}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.total_weight_line').replaceFirst('{value}', _result.totalWeight.toStringAsFixed(1))}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.primer_line').replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1))}');
    if (_result.groutWeight != null) {
      buffer.writeln('• ${_loc.translate('tile_adhesive.export.grout_line').replaceFirst('{value}', _result.groutWeight!.toStringAsFixed(2))}');
    }
    if (_result.waterproofingWeight != null) {
      buffer.writeln('• ${_loc.translate('tile_adhesive.export.waterproofing_line').replaceFirst('{value}', _result.waterproofingWeight!.toStringAsFixed(1))}');
    }
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.crosses_line').replaceFirst('{value}', _result.crossesNeeded.toString())}');
    if (_result.useSVP) {
      buffer.writeln('• ${_loc.translate('tile_adhesive.export.svp_line').replaceFirst('{value}', _result.svpCount.toString())}');
    }
    buffer.writeln();

    buffer.writeln(_loc.translate('tile_adhesive.export.tools_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.trowel_line').replaceFirst('{value}', _result.notchSize.toString())}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.container_line')}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.mixer_line')}');
    buffer.writeln();

    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('tile_adhesive.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('tile_adhesive.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('tile_adhesive.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('tile_adhesive.summary.bags').toUpperCase(),
            value: '${_result.bagsNeeded}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('tile_adhesive.summary.consumption').toUpperCase(),
            value: '${_result.adhesiveConsumption.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg_per_m2')}',
            icon: Icons.scale,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea
            ? _buildAreaCard()
            : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildSurfaceTypeSelector(),
        const SizedBox(height: 16),
        _buildTileTypeSelector(),
        const SizedBox(height: 16),
        _buildAdhesiveBrandSelector(),
        if (_adhesiveBrand.hasMultipleSizes) ...[
          const SizedBox(height: 16),
          _buildBagWeightSelector(),
        ],
        const SizedBox(height: 16),
        _buildSVPToggle(),
        const SizedBox(height: 16),
        _buildGroutToggle(),
        const SizedBox(height: 16),
        _buildWaterproofingToggle(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildToolsCard(),
        const SizedBox(height: 24),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('tile_adhesive.input_mode.by_dimensions'),
              _loc.translate('tile_adhesive.input_mode.by_area'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = InputMode.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('tile_adhesive.label.area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '${_area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 1,
            max: 500,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('tile_adhesive.dimensions.length'),
            value: _length,
            min: 0.5,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _length = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('tile_adhesive.dimensions.width'),
            value: _width,
            min: 0.5,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _width = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loc.translate('tile_adhesive.dimensions.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
              style: CalculatorDesignSystem.titleMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSurfaceTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.surface_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('tile_adhesive.surface_type.wall'),
              _loc.translate('tile_adhesive.surface_type.floor'),
            ],
            selectedIndex: _surfaceType.index,
            onSelect: (index) {
              setState(() {
                _surfaceType = SurfaceType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTileTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.tile_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('tile_adhesive.tile_type.subtitle'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: TileType.values.map((type) => _loc.translate(type.nameKey)).toList(),
            selectedIndex: _tileType.index,
            onSelect: (index) {
              setState(() {
                _tileType = TileType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAdhesiveBrandSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.brand.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options:
                AdhesiveBrand.values.map((brand) => brand.name).toList(),
            selectedIndex: _adhesiveBrand.index,
            onSelect: (index) {
              setState(() {
                _adhesiveBrand = AdhesiveBrand.values[index];
                // Автоматически устанавливаем доступный вес мешка
                final currentBagWeight = _bagWeight == BagWeight.kg20 ? 20 : 25;
                if (!_adhesiveBrand.hasBagSize(currentBagWeight)) {
                  _bagWeight = _adhesiveBrand.defaultBagSize == 20
                      ? BagWeight.kg20
                      : BagWeight.kg25;
                }
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBagWeightSelector() {
    if (!_adhesiveBrand.hasMultipleSizes) {
      return const SizedBox.shrink();
    }

    const accentColor = CalculatorColors.interior;
    final availableSizes = _adhesiveBrand.availableBagSizes;

    final options = <String>[];
    final indexMapping = <int, BagWeight>{};
    int currentMappedIndex = 0;

    for (var i = 0; i < BagWeight.values.length; i++) {
      final weight = BagWeight.values[i];
      final weightKg = weight == BagWeight.kg20 ? 20 : 25;

      if (availableSizes.contains(weightKg)) {
        options.add(_loc.translate('tile_adhesive.bag_weight.kg$weightKg'));
        indexMapping[currentMappedIndex] = weight;
        currentMappedIndex++;
      }
    }

    final currentWeightKg = _bagWeight == BagWeight.kg20 ? 20 : 25;
    final selectedIndex = availableSizes.indexOf(currentWeightKg);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.bag_weight.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: options,
            selectedIndex: selectedIndex.clamp(0, options.length - 1),
            onSelect: (index) {
              setState(() {
                _bagWeight = indexMapping[index]!;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSVPToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('tile_adhesive.svp.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.svp.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useSVP,
            onChanged: (value) {
              setState(() {
                _useSVP = value;
                _update();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGroutToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('tile_adhesive.grout.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.grout.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _calculateGrout,
            onChanged: (value) {
              setState(() {
                _calculateGrout = value;
                _update();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWaterproofingToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('tile_adhesive.waterproofing.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.waterproofing.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useWaterproofing,
            onChanged: (value) {
              setState(() {
                _useWaterproofing = value;
                _update();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.adhesive'),
        value: '${_result.bagsNeeded} ${_loc.translate('tile_adhesive.materials.bags_unit')}',
        subtitle: '× ${_result.bagWeight} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.consumption'),
        value: '${_result.adhesiveConsumption.toStringAsFixed(2)} ${_loc.translate('tile_adhesive.materials.kg_per_m2')}',
        icon: Icons.info_outline,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.total_weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.scale,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.liters')}',
        icon: Icons.water_drop,
      ),
    ];

    if (_result.groutWeight != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile_adhesive.materials.grout'),
        value: '${_result.groutWeight!.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.gradient,
      ));
    }

    if (_result.waterproofingWeight != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile_adhesive.materials.waterproofing'),
        value: '${_result.waterproofingWeight!.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.water,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('tile_adhesive.materials.crosses'),
      value: '${_result.crossesNeeded} ${_loc.translate('tile_adhesive.materials.pieces')}',
      icon: Icons.add,
    ));

    if (_result.useSVP) {
      items.add(MaterialItem(
        name: _loc.translate('tile_adhesive.materials.svp'),
        value: '${_result.svpCount} ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.construction,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('tile_adhesive.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildToolsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('tile_adhesive.tools.notched_trowel'),
        value: '${_result.notchSize} ${_loc.translate('common.mm')}',
        icon: Icons.handyman,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.tools.mixing_container'),
        value: '1 ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.shopping_basket,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.tools.mixer'),
        value: '1 ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.blender,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('tile_adhesive.tools.title'),
      titleIcon: Icons.build_circle,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    const hints = [
      CalculatorHint(
        type: HintType.important,
        messageKey: 'hint.tile_adhesive.surface_preparation',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tile_adhesive.notch_size',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tile_adhesive.mixing',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tile_adhesive.application',
      ),
      CalculatorHint(
        type: HintType.warning,
        messageKey: 'hint.tile_adhesive.working_time',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _loc.translate('common.tips'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
        ),
        const HintsList(hints: hints),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
