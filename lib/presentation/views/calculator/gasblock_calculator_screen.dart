import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

enum InputMode { byArea, byDimensions }

enum WallType {
  partition(
    'Перегородка',
    'Лёгкие внутренние стены',
    Icons.view_agenda,
    3,
    100,
  ),
  bearing(
    'Несущая',
    'Капитальные и наружные стены',
    Icons.home_work_outlined,
    2,
    300,
  );

  final String name;
  final String description;
  final IconData icon;
  final int reinforcementStep;
  final int defaultThickness;

  const WallType(
    this.name,
    this.description,
    this.icon,
    this.reinforcementStep,
    this.defaultThickness,
  );
}

enum BlockMaterial {
  gasblock('Газоблок', 'Тёплый и лёгкий', Icons.cloud_outlined),
  foamblock('Пеноблок', 'Доступный и тёплый', Icons.bubble_chart_outlined);

  final String name;
  final String description;
  final IconData icon;

  const BlockMaterial(this.name, this.description, this.icon);
}

enum MasonryMix {
  glue('Клей', 'Шов 2-3 мм', Icons.grain, 25.0, 0.0),
  mortar('Раствор', 'Шов 10-12 мм', Icons.construction, 0.0, 0.2);

  final String name;
  final String description;
  final IconData icon;
  final double glueKgPerM3;
  final double mortarM3PerM3;

  const MasonryMix(
    this.name,
    this.description,
    this.icon,
    this.glueKgPerM3,
    this.mortarM3PerM3,
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
  BlockSizePreset(label: 'Свой размер', lengthCm: 0.0, heightCm: 0.0, isCustom: true),
];

const List<int> kPartitionThicknesses = [75, 100, 150];
const List<int> kBearingThicknesses = [200, 250, 300, 400];

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
}

class GasblockCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const GasblockCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<GasblockCalculatorScreen> createState() =>
      _GasblockCalculatorScreenState();
}

class _GasblockCalculatorScreenState extends State<GasblockCalculatorScreen> {
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

  @override
  void initState() {
    super.initState();
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
      _blockThickness = _wallType.defaultThickness;
    }
  }

  List<int> _thicknessOptions() {
    return _wallType == WallType.partition
        ? kPartitionThicknesses
        : kBearingThicknesses;
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

  _GasblockResult _calculate() {
    final grossArea = _getGrossArea();
    final openings = math.min(_openingsArea, grossArea);
    final netArea = math.max(0.0, grossArea - openings);
    if (netArea <= 0) {
      return const _GasblockResult(
        area: 0,
        netArea: 0,
        blocks: 0,
        volume: 0,
        glueKg: 0,
        glueBags: 0,
        mortarM3: 0,
        reinforcementLength: 0,
        primerLiters: 0,
        plasterKg: 0,
        meshArea: 0,
        lintels: 0,
      );
    }

    final blockFaceArea = _blockFaceArea();
    final reserveFactor = 1 + _reserve / 100;
    final blocksNeeded = (netArea / blockFaceArea * reserveFactor).ceil();
    final volume = netArea * (_blockThickness / 1000);

    double glueKg = 0;
    int glueBags = 0;
    double mortarM3 = 0;
    if (_masonryMix == MasonryMix.glue) {
      glueKg = volume * _masonryMix.glueKgPerM3 * 1.1;
      glueBags = (glueKg / 25).ceil();
    } else {
      mortarM3 = volume * _masonryMix.mortarM3PerM3 * 1.1;
    }

    final blockHeightM = _blockHeight / 100;
    final rows = blockHeightM > 0 ? (_height / blockHeightM).ceil() : 0;
    final reinforcementRows = _wallType.reinforcementStep > 0
        ? (rows / _wallType.reinforcementStep).ceil()
        : 0;
    final wallLength = _inputMode == InputMode.byDimensions
        ? _length
        : (_height > 0 ? netArea / _height : 0.0);
    final reinforcementLength = reinforcementRows * wallLength * 2;

    final primerLiters = netArea * 0.2 * 2;
    final plasterKg = netArea * 10 * 2;
    final meshArea = netArea * 2 * 1.05;

    return _GasblockResult(
      area: grossArea,
      netArea: netArea,
      blocks: blocksNeeded,
      volume: volume,
      glueKg: glueKg,
      glueBags: glueBags,
      mortarM3: mortarM3,
      reinforcementLength: _useReinforcement ? reinforcementLength : 0.0,
      primerLiters: _usePrimer ? primerLiters : 0,
      plasterKg: _usePlaster ? plasterKg : 0,
      meshArea: _useMesh ? meshArea : 0,
      lintels: _useLintels ? _lintelsCount : 0,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _exportText() {
    final buffer = StringBuffer();
    buffer.writeln('РАСЧЁТ СТЕН ИЗ БЛОКОВ');
    buffer.writeln('Площадь кладки: ${_result.netArea.toStringAsFixed(2)} м²');
    buffer.writeln('Тип стены: ${_wallType.name}');
    buffer.writeln('Материал: ${_blockMaterial.name}');
    buffer.writeln(
      'Размер блока: ${_blockLength.toStringAsFixed(1)}x${_blockHeight.toStringAsFixed(1)} см',
    );
    buffer.writeln('Толщина: ${_blockThickness} мм');
    buffer.writeln('Кладка: ${_masonryMix.name}');
    buffer.writeln('Запас: ${_reserve.toInt()}%');
    buffer.writeln('');
    buffer.writeln('Блоки: ${_result.blocks} шт');
    buffer.writeln('Объём кладки: ${_result.volume.toStringAsFixed(2)} м³');
    if (_masonryMix == MasonryMix.glue) {
      buffer.writeln(
        'Клей: ${_result.glueKg.toStringAsFixed(1)} кг (${_result.glueBags} меш.)',
      );
    } else {
      buffer.writeln(
        'Раствор: ${_result.mortarM3.toStringAsFixed(2)} м³',
      );
    }
    if (_useReinforcement) {
      buffer.writeln(
        'Армирование: ${_result.reinforcementLength.toStringAsFixed(1)} м',
      );
    }
    if (_usePrimer) {
      buffer.writeln(
        'Грунтовка: ${_result.primerLiters.toStringAsFixed(1)} л',
      );
    }
    if (_usePlaster) {
      buffer.writeln(
        'Штукатурка: ${_result.plasterKg.toStringAsFixed(1)} кг',
      );
    }
    if (_useMesh) {
      buffer.writeln(
        'Сетка: ${_result.meshArea.toStringAsFixed(1)} м²',
      );
    }
    if (_useLintels && _result.lintels > 0) {
      buffer.writeln('Перемычки: ${_result.lintels} шт');
    }
    return buffer.toString();
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: _exportText(),
        subject: _loc.translate(widget.definition.titleKey),
      ),
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _exportText()));
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
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: _loc.translate('common.copy'),
          onPressed: _copy,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: _loc.translate('common.share'),
          onPressed: _share,
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: 'ПЛОЩАДЬ',
            value: '${_result.netArea.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'БЛОКИ',
            value: '${_result.blocks} шт',
            icon: Icons.view_module,
          ),
          ResultItem(
            label: 'ОБЪЁМ',
            value: '${_result.volume.toStringAsFixed(2)} м³',
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
        _buildTipsSection(),
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
            'Режим ввода',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['По площади', 'По размерам'],
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
            'Размеры стены',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_inputMode == InputMode.byArea) ...[
            _buildSliderField(
              label: 'Площадь стены',
              value: _area,
              min: 1.0,
              max: 1000.0,
              suffix: 'м²',
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
              label: 'Длина',
              value: _length,
              min: 0.5,
              max: 200.0,
              suffix: 'м',
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
            label: 'Высота',
            value: _height,
            min: 2.0,
            max: 6.0,
            suffix: 'м',
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
                      'Площадь стены',
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_getGrossArea().toStringAsFixed(1)} м²',
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
            'Проёмы',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderField(
            label: 'Площадь проёмов',
            value: _openingsArea,
            min: 0.0,
            max: maxOpenings,
            suffix: 'м²',
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
                    'Площадь кладки',
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${_result.netArea.toStringAsFixed(1)} м²',
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
            'Тип стены',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<WallType>(
            options: WallType.values,
            minItemWidth: 200,
            minItemHeight: 96,
            itemBuilder: (type) {
              final isSelected = _wallType == type;
              return TypeSelectorCardCompact(
                icon: type.icon,
                title: type.name,
                subtitle: type.description,
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
            'Материал блока',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<BlockMaterial>(
            options: BlockMaterial.values,
            minItemWidth: 200,
            minItemHeight: 96,
            itemBuilder: (material) {
              final isSelected = _blockMaterial == material;
              return TypeSelectorCardCompact(
                icon: material.icon,
                title: material.name,
                subtitle: material.description,
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
            'Размер блока',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<BlockSizePreset>(
            options: kBlockSizePresets,
            minItemWidth: 160,
            minItemHeight: 88,
            itemBuilder: (preset) {
              final isSelected = _blockSizePreset == preset;
              return TypeSelectorCardCompact(
                icon: Icons.crop_square,
                title: preset.label,
                subtitle: preset.isCustom ? 'Длина и высота' : null,
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
                    'Площадь блока: ${faceArea.toStringAsFixed(3)} м², объём: ${blockVolume.toStringAsFixed(3)} м³',
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
            'Пользовательский размер',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderField(
            label: 'Длина блока',
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
            label: 'Высота блока',
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
            'Толщина стены',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<int>(
            options: options,
            minItemWidth: 120,
            minItemHeight: 72,
            itemBuilder: (thickness) {
              final isSelected = _blockThickness == thickness;
              return TypeSelectorCardCompact(
                icon: Icons.swap_horiz,
                title: '$thickness мм',
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
        ? 'Расход: ~25 кг на 1 м³ кладки'
        : 'Расход: ~0.2 м³ раствора на 1 м³ кладки';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Кладка',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<MasonryMix>(
            options: MasonryMix.values,
            minItemWidth: 200,
            minItemHeight: 88,
            itemBuilder: (mix) {
              final isSelected = _masonryMix == mix;
              return TypeSelectorCardCompact(
                icon: mix.icon,
                title: mix.name,
                subtitle: mix.description,
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
        label: 'Запас на бой',
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
            'Дополнительные материалы',
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
            title: const Text(
              'Армирование',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _wallType == WallType.bearing
                  ? 'Каждые 2 ряда'
                  : 'Каждые 3 ряда',
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
            title: const Text(
              'Грунтовка',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              'Расход ~0.2 л/м² на сторону',
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
            title: const Text(
              'Штукатурка',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              'Слой ~5 мм на сторону',
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
            title: const Text(
              'Сетка',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              'Армирование с двух сторон',
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
            title: const Text(
              'Перемычки',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              'Над проёмами',
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
              label: 'Количество перемычек',
              value: _lintelsCount,
              min: 0,
              max: 20,
              suffix: 'шт',
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
        name: 'Блоки',
        value: '${_result.blocks} шт',
        subtitle: 'Объём: ${_result.volume.toStringAsFixed(2)} м³',
        icon: Icons.view_module,
      ),
    ];

    if (_masonryMix == MasonryMix.glue) {
      items.add(MaterialItem(
        name: 'Клей',
        value: '${_result.glueBags} меш.',
        subtitle: '${_result.glueKg.toStringAsFixed(0)} кг (25 кг/меш.)',
        icon: Icons.grain,
      ));
    } else {
      items.add(MaterialItem(
        name: 'Раствор',
        value: '${_result.mortarM3.toStringAsFixed(2)} м³',
        subtitle: 'Цементно-песчаный',
        icon: Icons.construction,
      ));
    }

    if (_useReinforcement) {
      items.add(MaterialItem(
        name: 'Армирование',
        value: '${_result.reinforcementLength.toStringAsFixed(0)} м',
        subtitle: '2 прута по длине',
        icon: Icons.tune,
      ));
    }

    if (_usePrimer) {
      items.add(MaterialItem(
        name: 'Грунтовка',
        value: '${_result.primerLiters.toStringAsFixed(1)} л',
        subtitle: 'Две стороны',
        icon: Icons.water_drop,
      ));
    }

    if (_usePlaster) {
      items.add(MaterialItem(
        name: 'Штукатурка',
        value: '${_result.plasterKg.toStringAsFixed(0)} кг',
        subtitle: 'Две стороны',
        icon: Icons.layers,
      ));
    }

    if (_useMesh) {
      items.add(MaterialItem(
        name: 'Сетка',
        value: '${_result.meshArea.toStringAsFixed(1)} м²',
        subtitle: 'Армирование',
        icon: Icons.grid_on,
      ));
    }

    if (_useLintels && _result.lintels > 0) {
      items.add(MaterialItem(
        name: 'Перемычки',
        value: '${_result.lintels} шт',
        subtitle: 'Над проёмами',
        icon: Icons.call_split,
      ));
    }

    return MaterialsCardModern(
      title: 'Необходимые материалы',
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    final hints = widget.definition.beforeHints;
    if (hints.isEmpty) return const SizedBox.shrink();

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
        HintsList(hints: hints),
      ],
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
