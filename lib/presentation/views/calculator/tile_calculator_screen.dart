import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../providers/constants_provider.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

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
    return value as T;
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
  double getGroutJointDepth() => _get('grout_calculation', 'joint_depth', 2.0);
  double getGroutDensity() => _get('grout_calculation', 'grout_density', 1.6);
  double getGroutMarginFactor() => _get('grout_calculation', 'margin_factor', 1.1);

  // Primer consumption
  double getPrimerBase() => _get('primer_consumption', 'base', 0.15);
  double getPrimerMarginFactor() => _get('primer_consumption', 'margin_factor', 1.1);

  // Crosses per tile
  int getCrossesPerTile() => _get<int>('crosses_per_tile', 'standard', 5);

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

class _TileCalculatorScreenState extends ConsumerState<TileCalculatorScreen> {
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  TileMaterial _material = TileMaterial.ceramic;
  LayoutPattern _layout = LayoutPattern.straight;
  RoomType _roomType = RoomType.kitchen;

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

  _TileResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Размер плитки в метрах
    final tileWidthM = _tileWidth / 100;
    final tileHeightM = _tileHeight / 100;
    final tileAreaM2 = tileWidthM * tileHeightM;

    // Запас в зависимости от способа укладки
    final reservePercent = _constants.getLayoutMargin(_layout);

    // Количество плиток с запасом
    final tilesNeeded = ((calculatedArea / tileAreaM2) * (1 + reservePercent / 100)).ceil();
    final tilesArea = tilesNeeded * tileAreaM2;

    // Упаковка плитки (обычно 1-1.5 м² в коробке)
    final boxArea = _constants.getBoxArea(_material);
    final boxesNeeded = (tilesArea / boxArea).ceil();

    // Клей (расход зависит от материала плитки) + запас 10%
    final glueWeight = calculatedArea * _constants.getGlueConsumption(_material) * 1.1;
    final glueBags = (glueWeight / _constants.getGlueBagSize()).ceil();

    // Затирка + запас
    // Формула: (tileWidth + tileHeight) / (tileWidth × tileHeight) × jointWidth × depth × density × area
    final jointDepth = _constants.getGroutJointDepth();
    final groutDensity = _constants.getGroutDensity();
    final groutConsumptionPerM2 = ((_tileWidth + _tileHeight) / (_tileWidth * _tileHeight)) *
        _jointWidth *
        jointDepth *
        groutDensity;
    final groutWeight = calculatedArea * groutConsumptionPerM2 * _constants.getGroutMarginFactor();

    // Грунтовка + запас
    final primerLiters = calculatedArea * _constants.getPrimerBase() * _constants.getPrimerMarginFactor();

    // Крестики
    final crossesNeeded = tilesNeeded * _constants.getCrossesPerTile();

    // СВП
    int? svpCount;
    if (_useSVP) {
      // Количество клипс зависит от размера плитки
      final avgSize = (_tileWidth + _tileHeight) / 2;
      final clipsPerTile = _constants.getSvpClipsPerTile(avgSize);
      svpCount = tilesNeeded * clipsPerTile;
    }

    // Гидроизоляция + запас
    double? waterproofingWeight;
    if (_useWaterproofing || _roomType.needsWaterproofing) {
      waterproofingWeight = calculatedArea *
          _constants.getWaterproofingPerLayer() *
          _constants.getWaterproofingLayers() *
          _constants.getWaterproofingMarginFactor();
    }

    // Подложка для выравнивания (с запасом)
    double? underlayArea;
    if (_useUnderlay) {
      underlayArea = calculatedArea * _constants.getUnderlayMarginFactor();
    }

    return _TileResult(
      area: calculatedArea,
      material: _material,
      layout: _layout,
      roomType: _roomType,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      jointWidth: _jointWidth,
      tilesNeeded: tilesNeeded,
      tilesArea: tilesArea,
      boxesNeeded: boxesNeeded,
      glueWeight: glueWeight,
      glueBags: glueBags,
      groutWeight: groutWeight,
      primerLiters: primerLiters,
      crossesNeeded: crossesNeeded,
      useSVP: _useSVP,
      svpCount: svpCount,
      useWaterproofing: _useWaterproofing || _roomType.needsWaterproofing,
      waterproofingWeight: waterproofingWeight,
      useUnderlay: _useUnderlay,
      underlayArea: underlayArea,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${_loc.translate('tile.export.title')}');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('${_loc.translate('tile.export.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('tile.export.material')}: ${_loc.translate(_result.material.nameKey)}');
    buffer.writeln('${_loc.translate('tile.export.tile_size')}: ${_result.tileWidth.toStringAsFixed(0)}×${_result.tileHeight.toStringAsFixed(0)} ${_loc.translate('common.cm')}');
    buffer.writeln('${_loc.translate('tile.export.layout')}: ${_loc.translate(_result.layout.nameKey)} (${_loc.translate('tile.export.reserve')} ${_constants.getLayoutMargin(_result.layout)}%)');
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

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(
      ShareParams(text: text, subject: _loc.translate('tile.export.subject')),
    );
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('tile.title'),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('tile.header.area'),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('tile.header.tiles'),
            value: '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
            icon: Icons.grid_on,
          ),
          ResultItem(
            label: _loc.translate('tile.header.boxes'),
            value: '${_result.boxesNeeded}',
            icon: Icons.inventory_2,
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
        const SizedBox(height: 16),
        _buildAdditionalInfoCard(),
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
            _loc.translate('tile.mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('tile.area.title'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            max: 200,
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
            _loc.translate('tile.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)} м',
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

  Widget _buildRoomTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.room.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
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
                              : CalculatorColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? accentColor : CalculatorColors.textSecondary,
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
                                    : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loc.translate(type.descKey),
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
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

  Widget _buildMaterialSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile.material.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
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
                              : CalculatorColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? accentColor : CalculatorColors.textSecondary,
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
                                    : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loc.translate(type.subtitleKey),
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
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
              color: CalculatorColors.textPrimary,
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
                  color: isSelected ? accentColor : CalculatorColors.textSecondary.withValues(alpha: 0.3),
                  width: 2,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.textPrimary,
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('tile.size.width'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_tileWidth.toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _tileWidth,
            min: 5,
            max: 150,
            divisions: 145,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _tileWidth = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('tile.size.height'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_tileHeight.toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _tileHeight,
            min: 5,
            max: 150,
            divisions: 145,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _tileHeight = v;
                _update();
              });
            },
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('tile.layout.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
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
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pattern.icon,
                        color: isSelected ? accentColor : CalculatorColors.textSecondary,
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
                                    : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_loc.translate(pattern.descKey)} • ${_loc.translate('tile.layout.reserve').replaceFirst('{value}', '${_constants.getLayoutMargin(pattern)}')}',
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.translate('tile.joint.title'),
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _loc.translate('tile.joint.hint'),
                      style: CalculatorDesignSystem.bodySmall.copyWith(
                        color: CalculatorColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_jointWidth.toStringAsFixed(1)} ${_loc.translate('common.mm')}',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _jointWidth,
            min: 1,
            max: 10,
            divisions: 18,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _jointWidth = v;
                _update();
              });
            },
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
              color: CalculatorColors.textPrimary,
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
                  color: CalculatorColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.textSecondary,
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

  Widget _buildAdditionalInfoCard() {
    const accentColor = CalculatorColors.interior;

    final infoItems = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('tile.info.material'),
        value: _loc.translate(_result.material.nameKey),
        icon: Icons.grid_on,
      ),
      MaterialItem(
        name: _loc.translate('tile.info.tile_size'),
        value: '${_result.tileWidth.toStringAsFixed(0)}×${_result.tileHeight.toStringAsFixed(0)} ${_loc.translate('common.cm')}',
        icon: Icons.square_foot,
      ),
      MaterialItem(
        name: _loc.translate('tile.info.layout'),
        value: _loc.translate(_result.layout.nameKey),
        subtitle: _loc.translate('tile.layout.reserve').replaceFirst('{value}', '${_constants.getLayoutMargin(_result.layout)}'),
        icon: Icons.pattern,
      ),
      MaterialItem(
        name: _loc.translate('tile.info.joint_width'),
        value: '${_result.jointWidth.toStringAsFixed(1)} ${_loc.translate('common.mm')}',
        icon: Icons.border_style,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('tile.info.title'),
      titleIcon: Icons.info_outline,
      items: infoItems,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
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
        const HintsList(
          hints: [
            CalculatorHint(
              type: HintType.important,
              messageKey: 'hint.tile.surface_preparation',
            ),
            CalculatorHint(
              type: HintType.tip,
              messageKey: 'hint.tile.layout_planning',
            ),
            CalculatorHint(
              type: HintType.tip,
              messageKey: 'hint.tile.adhesive_application',
            ),
            CalculatorHint(
              type: HintType.warning,
              messageKey: 'hint.tile.diagonal_cutting',
            ),
            CalculatorHint(
              type: HintType.important,
              messageKey: 'hint.tile.waterproofing_required',
            ),
          ],
        ),
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
