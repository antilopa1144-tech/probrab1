import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/usecases/calculate_gasblock_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../providers/constants_provider.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum InputMode { byArea, byDimensions }

enum WallType {
  partition(
    'gasblock.wall_type.partition',
    'gasblock.wall_type.partition_desc',
    Icons.view_agenda,
  ),
  bearing(
    'gasblock.wall_type.bearing',
    'gasblock.wall_type.bearing_desc',
    Icons.home_work_outlined,
  );

  final String nameKey;
  final String descKey;
  final IconData icon;

  const WallType(
    this.nameKey,
    this.descKey,
    this.icon,
  );
}

enum BlockMaterial {
  gasblock('gasblock.material.gasblock', 'gasblock.material.gasblock_desc', Icons.cloud_outlined),
  foamblock('gasblock.material.foamblock', 'gasblock.material.foamblock_desc', Icons.bubble_chart_outlined);

  final String nameKey;
  final String descKey;
  final IconData icon;

  const BlockMaterial(this.nameKey, this.descKey, this.icon);
}

enum MasonryMix {
  glue('gasblock.masonry.glue', 'gasblock.masonry.glue_desc', Icons.grain),
  mortar('gasblock.masonry.mortar', 'gasblock.masonry.mortar_desc', Icons.construction);

  final String nameKey;
  final String descKey;
  final IconData icon;

  const MasonryMix(
    this.nameKey,
    this.descKey,
    this.icon,
  );
}

class BlockSizePreset {
  final String label;
  final double lengthCm;
  final double heightCm;
  final bool isCustom;

  const BlockSizePreset({
    required this.label,
    required this.lengthCm,
    required this.heightCm,
    this.isCustom = false,
  });
}

const List<BlockSizePreset> kBlockSizePresets = [
  BlockSizePreset(label: '600x300', lengthCm: 60.0, heightCm: 30.0),
  BlockSizePreset(label: '600x250', lengthCm: 60.0, heightCm: 25.0),
  BlockSizePreset(label: '625x250', lengthCm: 62.5, heightCm: 25.0),
  BlockSizePreset(label: 'Свой', lengthCm: 0.0, heightCm: 0.0, isCustom: true),
];

/// Helper class для работы с константами газобетонного калькулятора
class _GasblockConstants {
  final CalculatorConstants? _data;

  const _GasblockConstants(this._data);

  T _get<T>(String constantKey, String valueKey, T defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value == null) return defaultValue;
    return value as T;
  }

  // Block sizes
  double getBlockLength(String sizeKey) {
    final defaults = {'600x300': 60.0, '600x250': 60.0, '625x250': 62.5};
    return _get('block_sizes', '${sizeKey}_length', defaults[sizeKey] ?? 60.0);
  }

  double getBlockHeight(String sizeKey) {
    final defaults = {'600x300': 30.0, '600x250': 25.0, '625x250': 25.0};
    return _get('block_sizes', '${sizeKey}_height', defaults[sizeKey] ?? 30.0);
  }

  // Thicknesses
  List<int> getPartitionThicknesses() {
    return [
      _get<int>('thicknesses', 'partition_min', 75),
      _get<int>('thicknesses', 'partition_mid1', 100),
      _get<int>('thicknesses', 'partition_max', 150),
    ];
  }

  List<int> getBearingThicknesses() {
    return [
      _get<int>('thicknesses', 'bearing_min', 200),
      _get<int>('thicknesses', 'bearing_mid1', 250),
      _get<int>('thicknesses', 'bearing_mid2', 300),
      _get<int>('thicknesses', 'bearing_max', 400),
    ];
  }

  int getDefaultThickness(WallType type) {
    return type == WallType.partition
        ? _get<int>('thicknesses', 'partition_mid1', 100)
        : _get<int>('thicknesses', 'bearing_mid2', 300);
  }

  // Glue consumption
  double getGlueKgPerM3() => _get('glue_consumption', 'kg_per_m3', 25.0);
  double getGlueMarginFactor() => _get('glue_consumption', 'margin_factor', 1.1);
  int getGlueBagSizeKg() => _get('glue_consumption', 'bag_size_kg', 25);

  // Mortar consumption
  double getMortarM3PerM3() => _get('mortar_consumption', 'm3_per_m3', 0.2);
  double getMortarMarginFactor() => _get('mortar_consumption', 'margin_factor', 1.1);

  // Primer consumption
  double getPrimerPerLayer() => _get('primer_consumption', 'per_layer', 0.2);
  int getPrimerLayers() => _get('primer_consumption', 'layers', 2);

  // Plaster consumption
  double getPlasterPerLayer() => _get('plaster_consumption', 'per_layer', 10.0);
  int getPlasterLayers() => _get('plaster_consumption', 'layers', 2);

  // Reinforcement
  int getReinforcementStepRows(WallType type) {
    return type == WallType.partition
        ? _get<int>('reinforcement', 'partition_step_rows', 3)
        : _get<int>('reinforcement', 'bearing_step_rows', 2);
  }

  int getRodsPerRow() => _get('reinforcement', 'rods_per_row', 2);

  // Mesh
  int getMeshSides() => _get('mesh', 'sides', 2);
  double getMeshMarginFactor() => _get('mesh', 'margin_factor', 1.05);
}

class _GasblockResult {
  final double area;
  final double netArea;
  final int blocks;
  final double volume;
  final double glueKg;
  final int glueBags;
  final double mortarM3;
  final double reinforcementLength;
  final double primerLiters;
  final double plasterKg;
  final double meshArea;
  final int lintels;

  const _GasblockResult({
    required this.area,
    required this.netArea,
    required this.blocks,
    required this.volume,
    required this.glueKg,
    required this.glueBags,
    required this.mortarM3,
    required this.reinforcementLength,
    required this.primerLiters,
    required this.plasterKg,
    required this.meshArea,
    required this.lintels,
  });

  factory _GasblockResult.fromCalculatorResult(Map<String, double> values) {
    return _GasblockResult(
      area: values['grossArea'] ?? 0,
      netArea: values['netArea'] ?? 0,
      blocks: (values['blocksCount'] ?? 0).toInt(),
      volume: values['volume'] ?? 0,
      glueKg: values['glueKg'] ?? 0,
      glueBags: (values['glueBags'] ?? 0).toInt(),
      mortarM3: values['mortarM3'] ?? 0,
      reinforcementLength: values['reinforcementLength'] ?? 0,
      primerLiters: values['primerLiters'] ?? 0,
      plasterKg: values['plasterKg'] ?? 0,
      meshArea: values['meshArea'] ?? 0,
      lintels: (values['lintelsCount'] ?? 0).toInt(),
    );
  }
}

class GasblockCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const GasblockCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<GasblockCalculatorScreen> createState() =>
      _GasblockCalculatorScreenState();
}

class _GasblockCalculatorScreenState extends ConsumerState<GasblockCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('gasblock.export.subject');

  // Domain layer calculator
  final _calculator = CalculateGasblockV2();

  InputMode _inputMode = InputMode.byDimensions;
  double _area = 15.0;
  double _length = 6.0;
  double _height = 2.7;
  double _openingsArea = 0.0;

  WallType _wallType = WallType.partition;
  BlockMaterial _blockMaterial = BlockMaterial.gasblock;
  BlockSizePreset _blockSizePreset = kBlockSizePresets.first;
  double _blockLength = 60.0;
  double _blockHeight = 30.0;
  int _blockThickness = 100;
  MasonryMix _masonryMix = MasonryMix.glue;
  double _reserve = 5.0;

  bool _useReinforcement = true;
  bool _usePrimer = true;
  bool _usePlaster = true;
  bool _useMesh = true;
  bool _useLintels = false;
  int _lintelsCount = 0;

  late _GasblockResult _result;
  late AppLocalizations _loc;
  late _GasblockConstants _constants;

  @override
  void initState() {
    super.initState();
    // Загружаем константы (синхронно, из кеша или fallback на defaults)
    final constantsAsync = ref.read(calculatorConstantsProvider('gasblock'));
    _constants = _GasblockConstants(constantsAsync.value);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final inputs = widget.initialInputs;
    if (inputs == null) return;

    final area = inputs['area'] ?? 0;
    final length = inputs['length'] ?? 0;
    final height = inputs['height'] ?? 0;
    if (area > 0) {
      _inputMode = InputMode.byArea;
      _area = area.clamp(1.0, 1000.0);
    } else if (length > 0 && height > 0) {
      _inputMode = InputMode.byDimensions;
      _length = length.clamp(0.1, 200.0);
    }
    if (height > 0) {
      _height = height.clamp(2.0, 6.0);
    }

    final thickness = inputs['thickness'];
    if (thickness != null && thickness > 0) {
      _blockThickness = thickness.round().clamp(75, 400);
      _wallType = _blockThickness >= 200 ? WallType.bearing : WallType.partition;
    }

    if (inputs['reserve'] != null) {
      _reserve = inputs['reserve']!.clamp(0.0, 20.0);
    }
    if (inputs['openingsArea'] != null) {
      _openingsArea = inputs['openingsArea']!.clamp(0.0, 500.0);
    }
    if (inputs['blockLength'] != null && inputs['blockHeight'] != null) {
      _blockLength = inputs['blockLength']!.clamp(50.0, 70.0);
      _blockHeight = inputs['blockHeight']!.clamp(20.0, 35.0);
      _blockSizePreset = kBlockSizePresets.last;
    }

    _ensureThicknessOption();
  }

  void _ensureThicknessOption() {
    final options = _thicknessOptions();
    if (!options.contains(_blockThickness)) {
      _blockThickness = _constants.getDefaultThickness(_wallType);
    }
  }

  List<int> _thicknessOptions() {
    return _wallType == WallType.partition
        ? _constants.getPartitionThicknesses()
        : _constants.getBearingThicknesses();
  }

  double _getGrossArea() {
    return _inputMode == InputMode.byArea ? _area : _length * _height;
  }

  double _blockFaceArea() {
    return (_blockLength / 100) * (_blockHeight / 100);
  }

  double _blockVolume() {
    return _blockFaceArea() * (_blockThickness / 1000);
  }

  /// Использует domain layer для расчёта
  _GasblockResult _calculate() {
    final inputs = <String, double>{
      'inputMode': _inputMode == InputMode.byArea ? 0.0 : 1.0,
      'area': _area,
      'length': _length,
      'height': _height,
      'openingsArea': _openingsArea,
      'wallType': _wallType.index.toDouble(),
      'blockMaterial': _blockMaterial.index.toDouble(),
      'blockLength': _blockLength,
      'blockHeight': _blockHeight,
      'blockThickness': _blockThickness.toDouble(),
      'masonryMix': _masonryMix.index.toDouble(),
      'reserve': _reserve,
      'useReinforcement': _useReinforcement ? 1.0 : 0.0,
      'usePrimer': _usePrimer ? 1.0 : 0.0,
      'usePlaster': _usePlaster ? 1.0 : 0.0,
      'useMesh': _useMesh ? 1.0 : 0.0,
      'useLintels': _useLintels ? 1.0 : 0.0,
      'lintelsCount': _lintelsCount.toDouble(),
    };

    final result = _calculator(inputs, []);
    return _GasblockResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('gasblock.export.title'));
    buffer.writeln('${_loc.translate('gasblock.export.masonry_area')}: ${_result.netArea.toStringAsFixed(2)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('gasblock.export.wall_type')}: ${_loc.translate(_wallType.nameKey)}');
    buffer.writeln('${_loc.translate('gasblock.export.material')}: ${_loc.translate(_blockMaterial.nameKey)}');
    buffer.writeln(
      '${_loc.translate('gasblock.export.block_size')}: ${_blockLength.toStringAsFixed(1)}x${_blockHeight.toStringAsFixed(1)} см',
    );
    buffer.writeln('${_loc.translate('gasblock.export.thickness')}: $_blockThickness ${_loc.translate('gasblock.thickness.mm')}');
    buffer.writeln('${_loc.translate('gasblock.export.masonry')}: ${_loc.translate(_masonryMix.nameKey)}');
    buffer.writeln('${_loc.translate('gasblock.export.reserve')}: ${_reserve.toInt()}%');
    buffer.writeln('');
    buffer.writeln('${_loc.translate('gasblock.export.blocks')}: ${_result.blocks} ${_loc.translate('common.pcs')}');
    buffer.writeln('${_loc.translate('gasblock.export.masonry_volume')}: ${_result.volume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}');
    if (_masonryMix == MasonryMix.glue) {
      buffer.writeln(
        '${_loc.translate('gasblock.export.glue')}: ${_result.glueKg.toStringAsFixed(1)} ${_loc.translate('common.kg')} (${_result.glueBags} ${_loc.translate('gasblock.export.glue_bags')})',
      );
    } else {
      buffer.writeln(
        '${_loc.translate('gasblock.export.mortar')}: ${_result.mortarM3.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
      );
    }
    if (_useReinforcement) {
      buffer.writeln(
        '${_loc.translate('gasblock.export.reinforcement')}: ${_result.reinforcementLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
      );
    }
    if (_usePrimer) {
      buffer.writeln(
        '${_loc.translate('gasblock.export.primer')}: ${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
      );
    }
    if (_usePlaster) {
      buffer.writeln(
        '${_loc.translate('gasblock.export.plaster')}: ${_result.plasterKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
      );
    }
    if (_useMesh) {
      buffer.writeln(
        '${_loc.translate('gasblock.export.mesh')}: ${_result.meshArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      );
    }
    if (_useLintels && _result.lintels > 0) {
      buffer.writeln('${_loc.translate('gasblock.export.lintels')}: ${_result.lintels} ${_loc.translate('common.pcs')}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('gasblock.header.area'),
            value: '${_result.netArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('gasblock.header.blocks'),
            value: '${_result.blocks} ${_loc.translate('common.pcs')}',
            icon: Icons.view_module,
          ),
          ResultItem(
            label: _loc.translate('gasblock.header.volume'),
            value: '${_result.volume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildOpeningsCard(),
        const SizedBox(height: 16),
        _buildWallTypeCard(),
        const SizedBox(height: 16),
        _buildBlockMaterialCard(),
        const SizedBox(height: 16),
        _buildBlockSizeCard(),
        if (_blockSizePreset.isCustom) ...[
          const SizedBox(height: 16),
          _buildCustomBlockSizeCard(),
        ],
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        _buildMasonryMixCard(),
        const SizedBox(height: 16),
        _buildReserveCard(),
        const SizedBox(height: 16),
        _buildAdditionalMaterialsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('gasblock.mode.by_area'),
              _loc.translate('gasblock.mode.by_dimensions'),
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

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_inputMode == InputMode.byArea) ...[
            _buildSliderField(
              label: _loc.translate('gasblock.dimensions.wall_area'),
              value: _area,
              min: 1.0,
              max: 1000.0,
              suffix: _loc.translate('common.sqm'),
              divisions: 200,
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ] else ...[
            _buildSliderField(
              label: _loc.translate('gasblock.dimensions.length'),
              value: _length,
              min: 0.5,
              max: 200.0,
              suffix: _loc.translate('common.meters'),
              divisions: 200,
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _length = v;
                  _update();
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          _buildSliderField(
            label: _loc.translate('gasblock.dimensions.height'),
            value: _height,
            min: 2.0,
            max: 6.0,
            suffix: _loc.translate('common.meters'),
            divisions: 40,
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _height = v;
                _update();
              });
            },
          ),
          if (_inputMode == InputMode.byDimensions) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _loc.translate('gasblock.dimensions.wall_area'),
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_getGrossArea().toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpeningsCard() {
    const accentColor = CalculatorColors.walls;
    final maxOpenings = math.max(1.0, _getGrossArea());
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.openings.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderField(
            label: _loc.translate('gasblock.openings.area'),
            value: _openingsArea,
            min: 0.0,
            max: maxOpenings,
            suffix: _loc.translate('common.sqm'),
            divisions: 100,
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _openingsArea = v;
                _update();
              });
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loc.translate('gasblock.openings.masonry_area'),
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${_result.netArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallTypeCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.wall_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<WallType>(
            options: WallType.values,
            minItemWidth: 140,
            minItemHeight: 72,
            itemBuilder: (type) {
              final isSelected = _wallType == type;
              return TypeSelectorCardCompact(
                icon: type.icon,
                title: _loc.translate(type.nameKey),
                subtitle: _loc.translate(type.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _wallType = type;
                    _ensureThicknessOption();
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlockMaterialCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.material.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<BlockMaterial>(
            options: BlockMaterial.values,
            minItemWidth: 140,
            minItemHeight: 72,
            itemBuilder: (material) {
              final isSelected = _blockMaterial == material;
              return TypeSelectorCardCompact(
                icon: material.icon,
                title: _loc.translate(material.nameKey),
                subtitle: _loc.translate(material.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _blockMaterial = material;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlockSizeCard() {
    const accentColor = CalculatorColors.walls;
    final faceArea = _blockFaceArea();
    final blockVolume = _blockVolume();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.block_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<BlockSizePreset>(
            options: kBlockSizePresets,
            minItemWidth: 110,
            minItemHeight: 64,
            itemBuilder: (preset) {
              final isSelected = _blockSizePreset == preset;
              return TypeSelectorCardCompact(
                icon: Icons.crop_square,
                title: preset.isCustom ? _loc.translate('gasblock.block_size.custom') : preset.label,
                subtitle: preset.isCustom ? _loc.translate('gasblock.block_size.custom') : null,
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _blockSizePreset = preset;
                    if (!preset.isCustom) {
                      _blockLength = preset.lengthCm;
                      _blockHeight = preset.heightCm;
                    }
                    _update();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loc.translate('gasblock.block_size.info')
                        .replaceFirst('{area}', faceArea.toStringAsFixed(3))
                        .replaceFirst('{volume}', blockVolume.toStringAsFixed(3)),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBlockSizeCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.block_size.custom_title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderField(
            label: _loc.translate('gasblock.block_size.block_length'),
            value: _blockLength,
            min: 50.0,
            max: 70.0,
            suffix: 'см',
            divisions: 40,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _blockLength = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildSliderField(
            label: _loc.translate('gasblock.block_size.block_height'),
            value: _blockHeight,
            min: 20.0,
            max: 35.0,
            suffix: 'см',
            divisions: 30,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _blockHeight = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }
  Widget _buildThicknessCard() {
    const accentColor = CalculatorColors.walls;
    final options = _thicknessOptions();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.thickness.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<int>(
            options: options,
            minItemWidth: 80,
            minItemHeight: 56,
            itemBuilder: (thickness) {
              final isSelected = _blockThickness == thickness;
              return TypeSelectorCardCompact(
                icon: Icons.swap_horiz,
                title: '$thickness ${_loc.translate('gasblock.thickness.mm')}',
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _blockThickness = thickness;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMasonryMixCard() {
    const accentColor = CalculatorColors.walls;
    final mixInfo = _masonryMix == MasonryMix.glue
        ? _loc.translate('gasblock.masonry.glue_consumption').replaceFirst('{value}', '${_constants.getGlueKgPerM3().toInt()}')
        : _loc.translate('gasblock.masonry.mortar_consumption').replaceFirst('{value}', '${_constants.getMortarM3PerM3()}');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.masonry.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<MasonryMix>(
            options: MasonryMix.values,
            minItemWidth: 140,
            minItemHeight: 72,
            itemBuilder: (mix) {
              final isSelected = _masonryMix == mix;
              return TypeSelectorCardCompact(
                icon: mix.icon,
                title: _loc.translate(mix.nameKey),
                subtitle: _loc.translate(mix.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _masonryMix = mix;
                    _update();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            mixInfo,
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: _buildSliderField(
        label: _loc.translate('gasblock.reserve.title'),
        value: _reserve,
        min: 0.0,
        max: 15.0,
        suffix: '%',
        divisions: 15,
        accentColor: accentColor,
        onChanged: (v) {
          setState(() {
            _reserve = v;
            _update();
          });
        },
      ),
    );
  }

  Widget _buildAdditionalMaterialsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gasblock.additional.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              _loc.translate('gasblock.additional.reinforcement'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _loc.translate('gasblock.additional.reinforcement_desc').replaceFirst('{rows}', '${_constants.getReinforcementStepRows(_wallType)}'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useReinforcement,
            onChanged: (v) {
              setState(() {
                _useReinforcement = v;
                _update();
              });
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              _loc.translate('gasblock.additional.primer'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _loc.translate('gasblock.additional.primer_desc').replaceFirst('{value}', '${_constants.getPrimerPerLayer()}'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _usePrimer,
            onChanged: (v) {
              setState(() {
                _usePrimer = v;
                _update();
              });
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              _loc.translate('gasblock.additional.plaster'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _loc.translate('gasblock.additional.plaster_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _usePlaster,
            onChanged: (v) {
              setState(() {
                _usePlaster = v;
                _update();
              });
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              _loc.translate('gasblock.additional.mesh'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _loc.translate('gasblock.additional.mesh_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useMesh,
            onChanged: (v) {
              setState(() {
                _useMesh = v;
                _update();
              });
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              _loc.translate('gasblock.additional.lintels'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _loc.translate('gasblock.additional.lintels_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useLintels,
            onChanged: (v) {
              setState(() {
                _useLintels = v;
                _update();
              });
            },
          ),
          if (_useLintels) ...[
            const SizedBox(height: 8),
            _buildIntSliderField(
              label: _loc.translate('gasblock.additional.lintels_count'),
              value: _lintelsCount,
              min: 0,
              max: 20,
              suffix: _loc.translate('common.pcs'),
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _lintelsCount = v;
                  _update();
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('gasblock.materials.blocks'),
        value: '${_result.blocks} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gasblock.materials.blocks_volume').replaceFirst('{value}', _result.volume.toStringAsFixed(2)),
        icon: Icons.view_module,
      ),
    ];

    if (_masonryMix == MasonryMix.glue) {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.glue'),
        value: '${_result.glueBags} ${_loc.translate('gasblock.materials.bags')}',
        subtitle: '${_result.glueKg.toStringAsFixed(0)} ${_loc.translate('common.kg')} (${_constants.getGlueBagSizeKg()} ${_loc.translate('common.kg')}/${_loc.translate('gasblock.materials.bags')})',
        icon: Icons.grain,
      ));
    } else {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.mortar'),
        value: '${_result.mortarM3.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('gasblock.materials.mortar_desc'),
        icon: Icons.construction,
      ));
    }

    if (_useReinforcement) {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.reinforcement'),
        value: '${_result.reinforcementLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('gasblock.materials.reinforcement_desc').replaceFirst('{rods}', '${_constants.getRodsPerRow()}'),
        icon: Icons.tune,
      ));
    }

    if (_usePrimer) {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('gasblock.materials.primer_desc'),
        icon: Icons.water_drop,
      ));
    }

    if (_usePlaster) {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.plaster'),
        value: '${_result.plasterKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('gasblock.materials.plaster_desc'),
        icon: Icons.layers,
      ));
    }

    if (_useMesh) {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.mesh'),
        value: '${_result.meshArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('gasblock.materials.mesh_desc'),
        icon: Icons.grid_on,
      ));
    }

    if (_useLintels && _result.lintels > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gasblock.materials.lintels'),
        value: '${_result.lintels} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gasblock.materials.lintels_desc'),
        icon: Icons.call_split,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('gasblock.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.walls;
    final hints = widget.definition.beforeHints;
    if (hints.isEmpty) return const SizedBox.shrink();

    final tips = hints.map((h) => h.message ?? _loc.translate(h.messageKey ?? '')).toList();

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildOptionGrid<T>({
    required List<T> options,
    required double minItemWidth,
    double minItemHeight = 88,
    required Widget Function(T option) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final maxWidth = constraints.maxWidth;
        final targetColumns = math.max(
          1,
          ((maxWidth + spacing) / (minItemWidth + spacing)).floor(),
        ).toInt();
        final columns =
            math.max(1, math.min(options.length, targetColumns)).toInt();
        final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options
              .map((option) => SizedBox(
                    width: itemWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minItemHeight),
                      child: itemBuilder(option),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    int? divisions,
    int? decimalPlaces,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    final effectivePlaces = decimalPlaces ?? (value < 10 ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(effectivePlaces)} $suffix',
              style: CalculatorDesignSystem.headlineMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.2),
            thumbColor: accentColor,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions ?? ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: label,
          value: value,
          suffix: suffix,
          minValue: min,
          maxValue: max,
          decimalPlaces: effectivePlaces,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIntSliderField({
    required String label,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required Color accentColor,
    required ValueChanged<int> onChanged,
  }) {
    final sliderValue =
        value.toDouble().clamp(min.toDouble(), max.toDouble()).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value $suffix',
              style: CalculatorDesignSystem.headlineMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.2),
            thumbColor: accentColor,
          ),
          child: Slider(
            value: sliderValue,
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: math.max(1, max - min),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: label,
          value: value.toDouble(),
          suffix: suffix,
          minValue: min.toDouble(),
          maxValue: max.toDouble(),
          decimalPlaces: 0,
          accentColor: accentColor,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: CalculatorDesignSystem.cardPadding,
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
