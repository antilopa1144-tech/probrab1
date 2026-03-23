import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/usecases/calculate_tile.dart';
import '../../providers/constants_provider.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum InputMode { byArea, byDimensions }

enum TileMaterial {
  ceramic(
    'tile.material.ceramic',
    'tile.material.ceramic_desc',
    'tile.material.ceramic_adv',
    Icons.grid_on,
  ),
  porcelain(
    'tile.material.porcelain',
    'tile.material.porcelain_desc',
    'tile.material.porcelain_adv',
    Icons.view_module,
  ),
  mosaic(
    'tile.material.mosaic',
    'tile.material.mosaic_desc',
    'tile.material.mosaic_adv',
    Icons.apps,
  ),
  largeFormat(
    'tile.material.large_format',
    'tile.material.large_format_desc',
    'tile.material.large_format_adv',
    Icons.crop_square,
  );

  final String nameKey;
  final String subtitleKey;
  final String advantageKey;
  final IconData icon;
  const TileMaterial(
    this.nameKey,
    this.subtitleKey,
    this.advantageKey,
    this.icon,
  );
}

enum LayoutPattern {
  straight(
    'tile.layout.straight',
    'tile.layout.straight_desc',
    Icons.grid_3x3,
  ),
  diagonal(
    'tile.layout.diagonal',
    'tile.layout.diagonal_desc',
    Icons.rotate_right,
  ),
  offset(
    'tile.layout.offset',
    'tile.layout.offset_desc',
    Icons.view_week,
  ),
  herringbone(
    'tile.layout.herringbone',
    'tile.layout.herringbone_desc',
    Icons.trending_up,
  );

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LayoutPattern(this.nameKey, this.descKey, this.icon);
}

enum RoomType {
  bathroom(
    'tile.room.bathroom',
    Icons.bathroom,
    'tile.room.bathroom_desc',
    true, // нужна гидроизоляция
  ),
  kitchen(
    'tile.room.kitchen',
    Icons.kitchen,
    'tile.room.kitchen_desc',
    false,
  ),
  hallway(
    'tile.room.hallway',
    Icons.meeting_room,
    'tile.room.hallway_desc',
    false,
  ),
  living(
    'tile.room.living',
    Icons.weekend,
    'tile.room.living_desc',
    false,
  ),
  balcony(
    'tile.room.balcony',
    Icons.balcony,
    'tile.room.balcony_desc',
    true, // нужна гидроизоляция
  );

  final String nameKey;
  final IconData icon;
  final String descKey;
  final bool needsWaterproofing;
  const RoomType(this.nameKey, this.icon, this.descKey, this.needsWaterproofing);
}

/// Сложность помещения (дополнительный % отходов, аддитивный)
enum RoomComplexity {
  simple('tile.complexity.simple', 0),
  lShaped('tile.complexity.l_shaped', 5),
  complex('tile.complexity.complex', 10);

  final String nameKey;
  /// Дополнительный процент отходов за сложность помещения
  final int bonusPercent;
  const RoomComplexity(this.nameKey, this.bonusPercent);
}

/// Helper class для работы с константами калькулятора плитки
class _TileConstants {
  final CalculatorConstants? _data;

  const _TileConstants(this._data);

  T _get<T>(String constantKey, String valueKey, T defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value == null) return defaultValue;
    if (value is T) return value;
    if (T == double && value is num) return value.toDouble() as T;
    if (T == int && value is num) return value.toInt() as T;
    return defaultValue;
  }

  // Glue consumption
  double getGlueConsumption(TileMaterial material) {
    final defaults = {
      'ceramic': 4.0,
      'porcelain': 5.5,
      'mosaic': 3.5,
      'large_format': 6.0,
    };
    return _get('glue_consumption', material.name, defaults[material.name] ?? 4.0);
  }

  // Layout margins
  int getLayoutMargin(LayoutPattern pattern) {
    final defaults = {
      'straight': 10,
      'diagonal': 15,
      'offset': 10,
      'herringbone': 20,
    };
    return _get<int>('layout_margins', pattern.name, defaults[pattern.name] ?? 10);
  }

  // Box sizes
  double getBoxArea(TileMaterial material) {
    return material == TileMaterial.mosaic
        ? _get('box_sizes', 'mosaic', 0.5)
        : _get('box_sizes', 'standard', 1.44);
  }

  // Glue bag size
  int getGlueBagSize() => _get<int>('glue_bag_size', 'standard', 25);

  // Grout calculation
  /// Глубина затирки (мм) зависит от размера плитки:
  /// малая <15см → 4мм, стандартная 15-40см → 6мм,
  /// крупная 40-60см → 8мм, крупноформат >60см → 10мм
  double getGroutJointDepth(double avgTileSizeCm) {
    if (avgTileSizeCm < 15) return _get('grout_calculation', 'joint_depth_small', 4.0);
    if (avgTileSizeCm < 40) return _get('grout_calculation', 'joint_depth_standard', 6.0);
    if (avgTileSizeCm <= 60) return _get('grout_calculation', 'joint_depth_large', 8.0);
    return _get('grout_calculation', 'joint_depth_xlarge', 10.0);
  }
  double getGroutDensity() => _get('grout_calculation', 'grout_density', 1.6);
  double getGroutMarginFactor() => _get('grout_calculation', 'margin_factor', 1.1);

  // Primer consumption
  double getPrimerBase() => _get('primer_consumption', 'base', 0.15);
  double getPrimerMarginFactor() => _get('primer_consumption', 'margin_factor', 1.1);

  // Множитель крестиков на плитку (~1 на пересечение + запас)
  double getCrossesMultiplier() => _get('crosses_per_tile', 'multiplier', 1.2);

  // SVP calculation
  int getSvpClipsPerTile(double avgTileSize) {
    final smallThreshold = _get('svp_calculation', 'small_size_threshold', 20.0);
    final mediumThreshold = _get('svp_calculation', 'medium_size_threshold', 40.0);
    final smallClips = _get<int>('svp_calculation', 'small_clips_per_tile', 4);
    final mediumClips = _get<int>('svp_calculation', 'medium_clips_per_tile', 3);
    final largeClips = _get<int>('svp_calculation', 'large_clips_per_tile', 2);

    if (avgTileSize < smallThreshold) return smallClips;
    if (avgTileSize <= mediumThreshold) return mediumClips;
    return largeClips;
  }

  // Waterproofing
  double getWaterproofingPerLayer() => _get('waterproofing', 'per_layer', 1.5);
  int getWaterproofingLayers() => _get<int>('waterproofing', 'layers', 2);
  double getWaterproofingMarginFactor() => _get('waterproofing', 'margin_factor', 1.1);

  // Underlay margin
  double getUnderlayMarginFactor() => _get('underlay_margin', 'margin_factor', 1.1);
}

class _TileResult {
  final double area;
  final TileMaterial material;
  final LayoutPattern layout;
  final RoomType roomType;
  final double tileWidth;
  final double tileHeight;
  final double jointWidth;

  // Плитка
  final int tilesNeeded;
  final double tilesArea; // м²
  final int boxesNeeded;

  // Клей
  final double glueWeight; // кг
  final int glueBags; // мешков по 25 кг

  // Затирка
  final double groutWeight; // кг

  // Грунтовка
  final double primerLiters;

  // Крестики/СВП
  final int crossesNeeded;
  final bool useSVP;
  final int? svpCount;

  // Гидроизоляция
  final bool useWaterproofing;
  final double? waterproofingWeight;

  // Подложка
  final bool useUnderlay;
  final double? underlayArea;
  final double wastePercent;

  const _TileResult({
    required this.area,
    required this.material,
    required this.layout,
    required this.roomType,
    required this.tileWidth,
    required this.tileHeight,
    required this.jointWidth,
    required this.tilesNeeded,
    required this.tilesArea,
    required this.boxesNeeded,
    required this.glueWeight,
    required this.glueBags,
    required this.groutWeight,
    required this.primerLiters,
    required this.crossesNeeded,
    required this.useSVP,
    this.svpCount,
    required this.useWaterproofing,
    this.waterproofingWeight,
    required this.useUnderlay,
    this.underlayArea,
    required this.wastePercent,
  });
}

class TileCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const TileCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<TileCalculatorScreen> createState() => _TileCalculatorScreenState();
}

class _TileCalculatorScreenState extends ConsumerState<TileCalculatorScreen>
    with ExportableConsumerMixin {
  final CalculateTile _calculator = CalculateTile();
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('tile.export.subject');
  bool _isDark = false;
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  TileMaterial _material = TileMaterial.ceramic;
  LayoutPattern _layout = LayoutPattern.straight;
  RoomType _roomType = RoomType.kitchen;
  RoomComplexity _roomComplexity = RoomComplexity.simple;

  // Размер плитки
  int _tileSizePreset = 30; // 0 = custom
  double _tileWidth = 30.0; // см
  double _tileHeight = 30.0; // см
  double _jointWidth = 3.0; // мм

  // Опции
  bool _useSVP = false;
  bool _useWaterproofing = false;
  bool _useUnderlay = false;

  late _TileResult _result;
  late AppLocalizations _loc;
  late _TileConstants _constants;

  @override
  void initState() {
    super.initState();
    // Загружаем константы (синхронно, из кеша или fallback на defaults)
    final constantsAsync = ref.read(calculatorConstantsProvider('tile'));
    _constants = _TileConstants(constantsAsync.value);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) _length = initial['length']!.clamp(0.1, 100.0);
    if (initial['width'] != null) _width = initial['width']!.clamp(0.1, 100.0);
    final tileWidth = initial['tileWidthCm'] ?? initial['tileWidth'];
    final tileHeight = initial['tileHeightCm'] ?? initial['tileHeight'];
    if (tileWidth != null) _tileWidth = tileWidth.clamp(5.0, 200.0);
    if (tileHeight != null) _tileHeight = tileHeight.clamp(5.0, 200.0);
    if (initial['jointWidth'] != null) _jointWidth = initial['jointWidth']!.clamp(1.0, 10.0);

    if (initial['inputMode'] != null) {
      final mode = initial['inputMode']!.round();
      _inputMode = mode == 0 ? InputMode.byDimensions : InputMode.byArea;
    }

    if (initial['material'] != null) {
      final mat = initial['material']!.toInt();
      if (mat >= 0 && mat < TileMaterial.values.length) {
        _material = TileMaterial.values[mat];
      }
    }

    final layout = (initial['layoutPattern'] ?? initial['layout'])?.toInt();
    if (layout != null) {
      final resolved = layout > 0 ? layout - 1 : layout;
      if (resolved >= 0 && resolved < LayoutPattern.values.length) {
        _layout = LayoutPattern.values[resolved];
      }
    }

    final complexity = initial['roomComplexity']?.toInt();
    if (complexity != null) {
      final resolved = complexity > 0 ? complexity - 1 : complexity;
      if (resolved >= 0 && resolved < RoomComplexity.values.length) {
        _roomComplexity = RoomComplexity.values[resolved];
      }
    }

    if (initial['roomType'] != null) {
      final room = initial['roomType']!.toInt();
      if (room >= 0 && room < RoomType.values.length) {
        _roomType = RoomType.values[room];
      }
    }

    final tileSize = initial['tileSize']?.toInt();
    if (tileSize != null) {
      _tileSizePreset = tileSize;
    }

    if (initial['useSVP'] != null) _useSVP = initial['useSVP']! > 0;
    if (initial['useWaterproofing'] != null) _useWaterproofing = initial['useWaterproofing']! > 0;
    if (initial['useUnderlay'] != null) _useUnderlay = initial['useUnderlay']! > 0;
  }

  Map<String, double> _buildCalculationInputs() {
    return {
      'inputMode': _inputMode == InputMode.byDimensions ? 0 : 1,
      'area': _area,
      'length': _length,
      'width': _width,
      'tileWidthCm': _tileWidth,
      'tileHeightCm': _tileHeight,
      'jointWidth': _jointWidth,
      'layoutPattern': (_layout.index + 1).toDouble(),
      'roomComplexity': (_roomComplexity.index + 1).toDouble(),
      'material': _material.index.toDouble(),
      'roomType': _roomType.index.toDouble(),
      'useSVP': _useSVP ? 1.0 : 0.0,
      'useWaterproofing': _useWaterproofing ? 1.0 : 0.0,
      'useUnderlay': _useUnderlay ? 1.0 : 0.0,
    };
  }

  _TileResult _calculate() {
    final contract = _calculator.calculateCanonical(_buildCalculationInputs());
    final totals = contract.totals;
    final calculatedArea = totals['area'] ?? 0;
    final tileWidthCm = totals['tileWidthCm'] ?? _tileWidth;
    final tileHeightCm = totals['tileHeightCm'] ?? _tileHeight;
    final tilesNeeded = (totals['tilesNeeded'] ?? 0).round();
    final tilesArea = totals['tilesArea'] ?? 0;
    final glueWeight = totals['glueNeededKg'] ?? 0;
    final groutWeight = totals['groutNeededKg'] ?? 0;
    final primerLiters = totals['primerNeededL'] ?? 0;
    final crossesNeeded = (totals['crossesNeeded'] ?? 0).round();
    final svpCount = (totals['svpCount'] ?? 0).round();
    final waterproofingWeight = totals['waterproofingWeight'] ?? 0;
    final underlayArea = totals['underlayArea'] ?? 0;
    final effectiveWaterproofing = (totals['effectiveWaterproofing'] ?? 0) > 0;

    return _TileResult(
      area: calculatedArea,
      material: _material,
      layout: _layout,
      roomType: _roomType,
      tileWidth: tileWidthCm,
      tileHeight: tileHeightCm,
      jointWidth: totals['jointWidth'] ?? _jointWidth,
      tilesNeeded: tilesNeeded,
      tilesArea: tilesArea,
      boxesNeeded: (totals['boxesNeeded'] ?? 0).round(),
      glueWeight: glueWeight,
      glueBags: (totals['glueBags'] ?? 0).round(),
      groutWeight: groutWeight,
      primerLiters: primerLiters,
      crossesNeeded: crossesNeeded,
      useSVP: _useSVP,
      svpCount: svpCount > 0 ? svpCount : null,
      useWaterproofing: effectiveWaterproofing,
      waterproofingWeight: waterproofingWeight > 0 ? waterproofingWeight : null,
      useUnderlay: _useUnderlay,
      underlayArea: underlayArea > 0 ? underlayArea : null,
      wastePercent: totals['wastePercent'] ?? (_constants.getLayoutMargin(_layout) + _roomComplexity.bonusPercent).toDouble(),
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String? get calculatorId => 'tile';

  @override
  Map<String, dynamic>? getCurrentInputs() {
    return {
      'inputMode': (_inputMode == InputMode.byArea ? 0 : 1).toDouble(),
      'area': _area,
      'length': _length,
      'width': _width,
      'tileWidth': _tileWidth,
      'tileHeight': _tileHeight,
      'jointWidth': _jointWidth,
      'material': _material.index.toDouble(),
      'layout': _layout.index.toDouble(),
      'roomType': _roomType.index.toDouble(),
      'useSVP': _useSVP ? 1.0 : 0.0,
      'useWaterproofing': _useWaterproofing ? 1.0 : 0.0,
      'useUnderlay': _useUnderlay ? 1.0 : 0.0,
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${_loc.translate('tile.export.title')}');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('${_loc.translate('tile.export.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('tile.export.material')}: ${_loc.translate(_result.material.nameKey)}');
    buffer.writeln('${_loc.translate('tile.export.tile_size')}: ${_result.tileWidth.toStringAsFixed(0)}×${_result.tileHeight.toStringAsFixed(0)} ${_loc.translate('common.cm')}');
    buffer.writeln('${_loc.translate('tile.export.layout')}: ${_loc.translate(_result.layout.nameKey)} (${_loc.translate('tile.export.reserve')} ${_constants.getLayoutMargin(_result.layout)}${_loc.translate('common.percent')})');
    buffer.writeln('${_loc.translate('tile.export.room')}: ${_loc.translate(_result.roomType.nameKey)}');
    buffer.writeln();

    buffer.writeln(_loc.translate('tile.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('tile.export.tiles')}: ${_result.tilesNeeded} ${_loc.translate('common.pcs')} (${_result.tilesArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')})');
    buffer.writeln('• ${_loc.translate('tile.export.boxes')}: ${_result.boxesNeeded} ${_loc.translate('tile.export.boxes_unit')}');
    buffer.writeln('• ${_loc.translate('tile.export.glue')}: ${_result.glueBags} ${_loc.translate('tile.export.glue_bags')} (${_result.glueWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')})');
    buffer.writeln('• ${_loc.translate('tile.export.grout')}: ${_result.groutWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')}');
    buffer.writeln('• ${_loc.translate('tile.export.primer')}: ${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}');
    buffer.writeln('• ${_loc.translate('tile.export.crosses')}: ${_result.crossesNeeded} ${_loc.translate('common.pcs')}');

    if (_result.useSVP && _result.svpCount != null) {
      buffer.writeln('• ${_loc.translate('tile.export.svp')}: ${_result.svpCount} ${_loc.translate('tile.export.svp_unit')}');
    }

    if (_result.useWaterproofing && _result.waterproofingWeight != null) {
      buffer.writeln('• ${_loc.translate('tile.export.waterproofing')}: ${_result.waterproofingWeight!.toStringAsFixed(1)} ${_loc.translate('common.kg')}');
    }

    if (_result.useUnderlay && _result.underlayArea != null) {
      buffer.writeln('• ${_loc.translate('tile.export.underlay')}: ${_result.underlayArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('tile.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('tile.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('tile.header.area'),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('tile.header.boxes'),
            value: '${_result.boxesNeeded}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('tile.header.glue'),
            value: '${_result.glueBags}',
            icon: Icons.shopping_bag,
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
        _buildRoomTypeSelector(),
        const SizedBox(height: 16),
        _buildRoomComplexitySelector(),
        const SizedBox(height: 16),
        _buildMaterialSelector(),
        const SizedBox(height: 16),
        _buildTileSizeSelector(),
        if (_tileSizePreset == 0) ...[
          const SizedBox(height: 16),
          _buildCustomTileSize(),
        ],
        const SizedBox(height: 16),
        _buildLayoutPatternSelector(),
        const SizedBox(height: 16),
        _buildJointWidthSlider(),
        const SizedBox(height: 16),
        _buildOptionsToggles(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
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
            _loc.translate('tile.mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('tile.mode.by_area'),
              _loc.translate('tile.mode.by_dimensions'),
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
      child: CalculatorSliderField(
        label: _loc.translate('tile.area.title'),
        value: _area,
        min: 1,
        max: 200,
        suffix: _loc.translate('common.sqm'),
        accentColor: accentColor,
        onChanged: (v) {
          setState(() {
            _area = v;
            _update();
          });
        },
        decimalPlaces: 1,
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
            _loc.translate('tile.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('tile.dimensions.length'),
            value: _length,
            min: 0.5,
            max: 20.0,
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
            label: _loc.translate('tile.dimensions.width'),
            value: _width,
            min: 0.5,
            max: 20.0,
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
              children: [
                Expanded(
                  child: Text(
                    _loc.translate('tile.area.room_area'),
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
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
    return CalculatorSliderField(
      label: label,
      value: value,
      min: min,
      max: max,
      divisions: ((max - min) * 10).toInt(),
      suffix: _loc.translate('common.meters'),
      accentColor: accentColor,
      onChanged: onChanged,
      decimalPlaces: 1,
    );
  }

  Widget _buildRoomTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.room.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...RoomType.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _roomType == type;

            return Padding(
              padding: EdgeInsets.only(bottom: index < RoomType.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _roomType = type;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.translate(type.nameKey),
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.getTextPrimary(_isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loc.translate(type.descKey),
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.getTextSecondary(_isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomComplexitySelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.complexity.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: RoomComplexity.values.map((c) => _loc.translate(c.nameKey)).toList(),
            selectedIndex: _roomComplexity.index,
            onSelect: (index) {
              setState(() {
                _roomComplexity = RoomComplexity.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.material.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...TileMaterial.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _material == type;

            return Padding(
              padding: EdgeInsets.only(bottom: index < TileMaterial.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _material = type;
                    // Автоматически подбираем размер плитки
                    if (type == TileMaterial.mosaic && _tileSizePreset >= 20) {
                      _tileSizePreset = 10;
                      _tileWidth = 10.0;
                      _tileHeight = 10.0;
                    } else if (type == TileMaterial.largeFormat && _tileSizePreset < 60) {
                      _tileSizePreset = 60;
                      _tileWidth = 60.0;
                      _tileHeight = 60.0;
                    }
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.translate(type.nameKey),
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.getTextPrimary(_isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loc.translate(type.subtitleKey),
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.getTextSecondary(_isDark),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Text(
                                '✓ ${_loc.translate(type.advantageKey)}',
                                style: CalculatorDesignSystem.bodySmall.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTileSizeSelector() {
    const accentColor = CalculatorColors.interior;
    final sizes = _material == TileMaterial.mosaic
        ? [10, 0]
        : _material == TileMaterial.largeFormat
            ? [60, 80, 120, 0]
            : [20, 30, 40, 60, 0];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final isSelected = _tileSizePreset == size;
              return ChoiceChip(
                label: Text(size == 0 ? _loc.translate('tile.size.custom') : size == 120 ? '120×60' : '$size×$size'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tileSizePreset = size;
                    if (size != 0) {
                      if (size == 120) {
                        _tileWidth = 120.0;
                        _tileHeight = 60.0;
                      } else {
                        _tileWidth = size.toDouble();
                        _tileHeight = size.toDouble();
                      }
                    }
                    _update();
                  });
                },
                selectedColor: accentColor.withValues(alpha: 0.2),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.3),
                  width: 2,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTileSize() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.size.custom_title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          CalculatorSliderField(
            label: _loc.translate('tile.size.width'),
            value: _tileWidth,
            min: 5,
            max: 150,
            divisions: 145,
            suffix: _loc.translate('common.cm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _tileWidth = v;
                _update();
              });
            },
            decimalPlaces: 0,
          ),
          const SizedBox(height: 8),
          CalculatorSliderField(
            label: _loc.translate('tile.size.height'),
            value: _tileHeight,
            min: 5,
            max: 150,
            divisions: 145,
            suffix: _loc.translate('common.cm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _tileHeight = v;
                _update();
              });
            },
            decimalPlaces: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutPatternSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.layout.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('tile.layout.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...LayoutPattern.values.asMap().entries.map((entry) {
            final index = entry.key;
            final pattern = entry.value;
            final isSelected = _layout == pattern;

            return Padding(
              padding: EdgeInsets.only(bottom: index < LayoutPattern.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _layout = pattern;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pattern.icon,
                        color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.translate(pattern.nameKey),
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.getTextPrimary(_isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_loc.translate(pattern.descKey)} • ${_loc.translate('tile.layout.reserve').replaceFirst('{value}', '${_constants.getLayoutMargin(pattern)}')}',
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.getTextSecondary(_isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJointWidthSlider() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.joint.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          CalculatorSliderField(
            label: _loc.translate('tile.joint.title'),
            value: _jointWidth,
            min: 1,
            max: 10,
            divisions: 18,
            suffix: _loc.translate('common.mm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _jointWidth = v;
                _update();
              });
            },
            decimalPlaces: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsToggles() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.options.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            title: _loc.translate('tile.options.svp'),
            subtitle: _loc.translate('tile.options.svp_desc'),
            value: _useSVP,
            onChanged: (v) {
              setState(() {
                _useSVP = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _buildToggle(
            title: _loc.translate('tile.options.waterproofing'),
            subtitle: _roomType.needsWaterproofing
                ? _loc.translate('tile.options.waterproofing_recommended').replaceFirst('{room}', _loc.translate(_roomType.nameKey).toLowerCase())
                : _loc.translate('tile.options.waterproofing_desc'),
            value: _useWaterproofing || _roomType.needsWaterproofing,
            onChanged: _roomType.needsWaterproofing ? null : (v) {
              setState(() {
                _useWaterproofing = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _buildToggle(
            title: _loc.translate('tile.options.underlay'),
            subtitle: _loc.translate('tile.options.underlay_desc'),
            value: _useUnderlay,
            onChanged: (v) {
              setState(() {
                _useUnderlay = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('tile.materials.tiles'),
        value: '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.tilesArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.grid_on,
      ),
      MaterialItem(
        name: _loc.translate('tile.materials.boxes'),
        value: '${_result.boxesNeeded}',
        subtitle: _loc.translate('tile.materials.boxes_unit'),
        icon: Icons.inventory_2,
      ),
      MaterialItem(
        name: _loc.translate('tile.materials.glue'),
        value: '${_result.glueBags} ${_loc.translate('tile.materials.glue_bags')}',
        subtitle: _loc.translate('tile.materials.glue_per_bag').replaceFirst('{weight}', _result.glueWeight.toStringAsFixed(0)),
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: _loc.translate('tile.materials.grout'),
        value: '${_result.groutWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        icon: Icons.gradient,
      ),
      MaterialItem(
        name: _loc.translate('tile.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: _loc.translate('tile.materials.crosses'),
        value: '${_result.crossesNeeded} ${_loc.translate('common.pcs')}',
        icon: Icons.add,
      ),
    ];

    if (_result.useSVP && _result.svpCount != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile.materials.svp'),
        value: '${_result.svpCount} ${_loc.translate('tile.export.svp_unit')}',
        subtitle: _loc.translate('tile.materials.svp_desc'),
        icon: Icons.construction,
      ));
    }

    if (_result.useWaterproofing && _result.waterproofingWeight != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile.materials.waterproofing'),
        value: '${_result.waterproofingWeight!.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('tile.materials.waterproofing_layers'),
        icon: Icons.water,
      ));
    }

    if (_result.useUnderlay && _result.underlayArea != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile.materials.underlay'),
        value: '${_result.underlayArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('tile.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[
      _loc.translate('hint.tile.surface_preparation'),
      _loc.translate('hint.tile.layout_planning'),
      _loc.translate('hint.tile.adhesive_application'),
      _loc.translate('hint.tile.diagonal_cutting'),
      _loc.translate('hint.tile.waterproofing_required'),
    ];

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}






