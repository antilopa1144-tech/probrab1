import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

/// Helper class for accessing terrace calculator constants
class _TerraceConstants {
  final CalculatorConstants? _data;

  _TerraceConstants(this._data);

  double _getDouble(String category, String key, double defaultValue) {
    return _data?.getDouble(category, key, defaultValue: defaultValue) ?? defaultValue;
  }

  // Margins
  double get floorMargin => _getDouble('margins', 'floor_margin', 1.1);
  double get roofMargin => _getDouble('margins', 'roof_margin', 1.2);
  double get roofingMargin => _getDouble('margins', 'roofing_margin', 1.1);

  // Floor materials
  double get tileArea => _getDouble('floor_materials', 'tile_area', 0.25);
  double get boardArea => _getDouble('floor_materials', 'board_area', 0.1);

  // Railing
  double get postStep => _getDouble('railing', 'post_step', 2.0);

  // Roofing
  double get polycarbonateSheetArea => _getDouble('roofing', 'polycarbonate_sheet_area', 6.0);
  double get profiledSheetArea => _getDouble('roofing', 'profiled_sheet_area', 8.0);
  double get areaPerPost => _getDouble('roofing', 'area_per_post', 9.0);

  // Foundation
  double get foundationWidth => _getDouble('foundation', 'post_width', 0.2);
  double get foundationDepth => _getDouble('foundation', 'post_depth', 0.2);
  double get foundationHeight => _getDouble('foundation', 'post_height', 0.5);
}

enum TerraceFloorType {
  decking,      // Декинг (существующий)
  tile,         // Керамическая плитка (существующий)
  board,        // Доска (существующий)
  porcelain,    // Керамогранит (НОВЫЙ)
  wpc,          // ДПК - древесно-полимерный композит (НОВЫЙ)
  solidWood,    // Массив дерева (НОВЫЙ)
  rubberTiles,  // Резиновые покрытия (НОВЫЙ)
}

enum TerraceRoofType {
  polycarbonate,  // Поликарбонат (существующий)
  profiledSheet,  // Профнастил (существующий)
  softRoof,       // Мягкая кровля (существующий)
  ondulin,        // Ондулин (НОВЫЙ)
  metalTile,      // Металлочерепица (НОВЫЙ)
  glass,          // Стеклянная крыша (НОВЫЙ)
}

class _TerraceResult {
  final double area;
  final double deckingArea;
  final int tilesNeeded;
  final int deckingBoards;
  final double railingLength;
  final int railingPosts;
  final double roofArea;
  final int polycarbonateSheets;
  final int profiledSheets;
  final double roofingMaterial;
  final int roofPosts;
  final double foundationVolume;

  const _TerraceResult({
    required this.area,
    required this.deckingArea,
    required this.tilesNeeded,
    required this.deckingBoards,
    required this.railingLength,
    required this.railingPosts,
    required this.roofArea,
    required this.polycarbonateSheets,
    required this.profiledSheets,
    required this.roofingMaterial,
    required this.roofPosts,
    required this.foundationVolume,
  });
}

class TerraceCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const TerraceCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<TerraceCalculatorScreen> createState() =>
      _TerraceCalculatorScreenState();
}

class _TerraceCalculatorScreenState extends State<TerraceCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate(widget.definition.titleKey);

  static const double _minArea = 4.0;
  static const double _maxArea = 200.0;

  double _area = 18.0;
  TerraceFloorType _floorType = TerraceFloorType.decking;
  bool _hasRailing = true;
  bool _hasRoof = false;
  TerraceRoofType _roofType = TerraceRoofType.polycarbonate;

  late _TerraceResult _result;
  late AppLocalizations _loc;

  final _constants = _TerraceConstants(null);

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['area'] != null) {
      _area = initial['area']!.clamp(_minArea, _maxArea);
    }
    if (initial['floorType'] != null) {
      final raw = initial['floorType']!.round().clamp(1, 3);
      _floorType = TerraceFloorType.values[raw - 1];
    }
    if (initial['railing'] != null) {
      _hasRailing = initial['railing']!.round() == 1;
    }
    if (initial['roof'] != null) {
      _hasRoof = initial['roof']!.round() == 1;
    }
    if (initial['roofType'] != null) {
      final raw = initial['roofType']!.round().clamp(1, 3);
      _roofType = TerraceRoofType.values[raw - 1];
    }
  }

  _TerraceResult _calculate() {
    final area = _area;

    double deckingArea = 0.0;
    int tilesNeeded = 0;
    int deckingBoards = 0;

    switch (_floorType) {
      case TerraceFloorType.decking:
        deckingArea = area * _constants.floorMargin;
        break;
      case TerraceFloorType.tile:
        final tileArea = _constants.tileArea; // 50x50cm
        tilesNeeded = (area / tileArea * _constants.floorMargin).ceil();
        break;
      case TerraceFloorType.board:
        final boardArea = _constants.boardArea;
        deckingBoards = (area / boardArea * _constants.floorMargin).ceil();
        break;
      case TerraceFloorType.porcelain:
        const porcelainArea = 0.36; // 60x60cm
        tilesNeeded = (area / porcelainArea * _constants.floorMargin).ceil();
        break;
      case TerraceFloorType.wpc:
        deckingArea = area * _constants.floorMargin;
        break;
      case TerraceFloorType.solidWood:
        deckingArea = area * _constants.floorMargin * 1.15; // Больше отходов
        break;
      case TerraceFloorType.rubberTiles:
        const rubberArea = 0.25; // 50x50cm
        tilesNeeded = (area / rubberArea * _constants.floorMargin).ceil();
        break;
    }

    final perimeter = area > 0 ? sqrt(area) * 4 : 0.0;
    final railingLength = _hasRailing ? perimeter : 0.0;
    final railingPosts =
        _hasRailing && perimeter > 0 ? (perimeter / _constants.postStep).ceil() : 0;

    double roofArea = 0.0;
    int polycarbonateSheets = 0;
    int profiledSheets = 0;
    double roofingMaterial = 0.0;
    int roofPosts = 0;
    double foundationVolume = 0.0;

    if (_hasRoof) {
      roofArea = area * _constants.roofMargin;

      switch (_roofType) {
        case TerraceRoofType.polycarbonate:
          final sheetArea = _constants.polycarbonateSheetArea;
          polycarbonateSheets = (roofArea / sheetArea * _constants.roofingMargin).ceil();
          break;
        case TerraceRoofType.profiledSheet:
          final sheetArea = _constants.profiledSheetArea;
          profiledSheets = (roofArea / sheetArea * _constants.roofingMargin).ceil();
          break;
        case TerraceRoofType.softRoof:
          roofingMaterial = roofArea * _constants.roofingMargin;
          break;
        case TerraceRoofType.ondulin:
          const ondSheetArea = 1.9; // Стандартный лист
          profiledSheets = (roofArea / ondSheetArea * 1.15).ceil();
          break;
        case TerraceRoofType.metalTile:
          roofingMaterial = roofArea * 1.2; // м²
          break;
        case TerraceRoofType.glass:
          const glassSheetArea = 2.0;
          polycarbonateSheets = (roofArea / glassSheetArea * _constants.roofingMargin).ceil();
          break;
      }

      roofPosts = (area / _constants.areaPerPost).ceil();
      foundationVolume = roofPosts *
          _constants.foundationWidth *
          _constants.foundationDepth *
          _constants.foundationHeight;
    }

    return _TerraceResult(
      area: area,
      deckingArea: deckingArea,
      tilesNeeded: tilesNeeded,
      deckingBoards: deckingBoards,
      railingLength: railingLength,
      railingPosts: railingPosts,
      roofArea: roofArea,
      polycarbonateSheets: polycarbonateSheets,
      profiledSheets: profiledSheets,
      roofingMaterial: roofingMaterial,
      roofPosts: roofPosts,
      foundationVolume: foundationVolume,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _floorLabel() {
    return switch (_floorType) {
      TerraceFloorType.decking => _loc.translate('terrace_calc.floor_type.decking'),
      TerraceFloorType.tile => _loc.translate('terrace_calc.floor_type.tile'),
      TerraceFloorType.board => _loc.translate('terrace_calc.floor_type.board'),
      TerraceFloorType.porcelain => _loc.translate('terrace.floor.porcelain'),
      TerraceFloorType.wpc => _loc.translate('terrace.floor.wpc'),
      TerraceFloorType.solidWood => _loc.translate('terrace.floor.solidWood'),
      TerraceFloorType.rubberTiles => _loc.translate('terrace.floor.rubberTiles'),
    };
  }

  String _floorValue() {
    return switch (_floorType) {
      TerraceFloorType.decking =>
        '${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      TerraceFloorType.tile => '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
      TerraceFloorType.board => '${_result.deckingBoards} ${_loc.translate('common.pcs')}',
      TerraceFloorType.porcelain => '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
      TerraceFloorType.wpc =>
        '${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      TerraceFloorType.solidWood =>
        '${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      TerraceFloorType.rubberTiles => '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
    };
  }

  IconData _floorIcon() {
    return switch (_floorType) {
      TerraceFloorType.decking => Icons.deck,
      TerraceFloorType.tile => Icons.grid_on,
      TerraceFloorType.board => Icons.view_agenda,
      TerraceFloorType.porcelain => Icons.texture,
      TerraceFloorType.wpc => Icons.dashboard,
      TerraceFloorType.solidWood => Icons.park,
      TerraceFloorType.rubberTiles => Icons.apps,
    };
  }

  String _roofTypeLabel() {
    return switch (_roofType) {
      TerraceRoofType.polycarbonate => _loc.translate('terrace_calc.roof.polycarbonate'),
      TerraceRoofType.profiledSheet => _loc.translate('terrace_calc.roof.profiled_sheet'),
      TerraceRoofType.softRoof => _loc.translate('terrace_calc.materials.soft_roof'),
      TerraceRoofType.ondulin => _loc.translate('terrace.roof.ondulin'),
      TerraceRoofType.metalTile => _loc.translate('terrace.roof.metal_tile'),
      TerraceRoofType.glass => _loc.translate('terrace.roof.glass'),
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('terrace_calc.export.title'));
    buffer.writeln(_loc.translate('terrace_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('terrace_calc.export.floor_type')
        .replaceFirst('{value}', _floorLabel()));
    switch (_floorType) {
      case TerraceFloorType.decking:
        buffer.writeln(_loc.translate('terrace_calc.export.decking')
            .replaceFirst('{value}', _result.deckingArea.toStringAsFixed(1)));
        break;
      case TerraceFloorType.tile:
        buffer.writeln(_loc.translate('terrace_calc.export.tile')
            .replaceFirst('{value}', _result.tilesNeeded.toString()));
        break;
      case TerraceFloorType.board:
        buffer.writeln(_loc.translate('terrace_calc.export.board')
            .replaceFirst('{value}', _result.deckingBoards.toString()));
        break;
      case TerraceFloorType.porcelain:
        buffer.writeln('${_loc.translate('terrace.floor.porcelain')}: ${_result.tilesNeeded} ${_loc.translate('common.pcs')}');
        break;
      case TerraceFloorType.wpc:
        buffer.writeln('${_loc.translate('terrace.floor.wpc')}: ${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
        break;
      case TerraceFloorType.solidWood:
        buffer.writeln('${_loc.translate('terrace.floor.solidWood')}: ${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
        break;
      case TerraceFloorType.rubberTiles:
        buffer.writeln('${_loc.translate('terrace.floor.rubberTiles')}: ${_result.tilesNeeded} ${_loc.translate('common.pcs')}');
        break;
    }
    if (_hasRailing) {
      buffer.writeln(_loc.translate('terrace_calc.export.railing')
          .replaceFirst('{value}', _result.railingLength.toStringAsFixed(1)));
      buffer.writeln(_loc.translate('terrace_calc.export.railing_posts')
          .replaceFirst('{value}', _result.railingPosts.toString()));
    }
    if (_hasRoof) {
      buffer.writeln(_loc.translate('terrace_calc.export.roof_area')
          .replaceFirst('{value}', _result.roofArea.toStringAsFixed(1)));
      buffer.writeln(_loc.translate('terrace_calc.export.roof_type')
          .replaceFirst('{value}', _roofTypeLabel()));
      if (_roofType == TerraceRoofType.polycarbonate) {
        buffer.writeln(_loc.translate('terrace_calc.export.polycarbonate')
            .replaceFirst('{value}', _result.polycarbonateSheets.toString()));
      } else if (_roofType == TerraceRoofType.profiledSheet) {
        buffer.writeln(_loc.translate('terrace_calc.export.profiled_sheet')
            .replaceFirst('{value}', _result.profiledSheets.toString()));
      } else {
        buffer.writeln(_loc.translate('terrace_calc.export.soft_roof')
            .replaceFirst('{value}', _result.roofingMaterial.toStringAsFixed(1)));
      }
      buffer.writeln(_loc.translate('terrace_calc.export.roof_posts')
          .replaceFirst('{value}', _result.roofPosts.toString()));
      buffer.writeln(_loc.translate('terrace_calc.export.foundation')
          .replaceFirst('{value}', _result.foundationVolume.toStringAsFixed(2)));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.facade;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('input.area'),
            value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _floorLabel(),
            value: _floorValue(),
            icon: _floorIcon(),
          ),
        ],
      ),
      children: [
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildFloorCard(),
        const SizedBox(height: 16),
        _buildRailingCard(),
        const SizedBox(height: 16),
        _buildRoofCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('terrace_calc.field.area'),
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
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
            ),
            child: Slider(
              value: _area,
              min: _minArea,
              max: _maxArea,
              divisions: ((_maxArea - _minArea) * 2).round(),
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('input.area'),
            value: _area,
            suffix: _loc.translate('common.sqm'),
            minValue: _minArea,
            maxValue: _maxArea,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _area = value;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.floorType'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorWithIcons(
            options: [
              ModeSelectorIconOption(label: _loc.translate('terrace_calc.floor_type.decking'), icon: Icons.deck),
              ModeSelectorIconOption(label: _loc.translate('terrace_calc.floor_type.tile'), icon: Icons.grid_on),
              ModeSelectorIconOption(label: _loc.translate('terrace_calc.floor_type.board'), icon: Icons.view_agenda),
            ],
            selectedIndex: _floorType.index,
            onSelect: (index) {
              setState(() {
                _floorType = TerraceFloorType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('terrace_calc.floor_type.margin_note'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailingCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.railing'),
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
              _loc.translate('terrace_calc.railing.toggle'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _loc.translate('terrace_calc.railing.hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _hasRailing,
            onChanged: (value) {
              setState(() {
                _hasRailing = value;
                _update();
              });
            },
          ),
          if (_hasRailing) ...[
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
                      _loc.translate('terrace_calc.railing.perimeter'),
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_result.railingLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_result.railingPosts} ${_loc.translate('common.pcs')}',
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

  Widget _buildRoofCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.roof'),
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
              _loc.translate('terrace_calc.roof.toggle'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _loc.translate('terrace_calc.roof.hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _hasRoof,
            onChanged: (value) {
              setState(() {
                _hasRoof = value;
                _update();
              });
            },
          ),
          if (_hasRoof) ...[
            const SizedBox(height: 12),
            ModeSelectorWithIcons(
              options: [
                ModeSelectorIconOption(
                  label: _loc.translate('terrace_calc.roof.polycarbonate'),
                  icon: Icons.cloud_queue,
                ),
                ModeSelectorIconOption(
                  label: _loc.translate('terrace_calc.roof.profiled_sheet'),
                  icon: Icons.table_chart,
                ),
                ModeSelectorIconOption(
                  label: _loc.translate('terrace_calc.roof.soft_roof'),
                  icon: Icons.layers,
                ),
              ],
              selectedIndex: _roofType.index,
              onSelect: (index) {
                setState(() {
                  _roofType = TerraceRoofType.values[index];
                  _update();
                });
              },
              accentColor: accentColor,
            ),
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
                      _loc.translate('terrace_calc.roof.area'),
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_result.roofArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
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

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.facade;
    final items = <MaterialItem>[];

    switch (_floorType) {
      case TerraceFloorType.decking:
        items.add(MaterialItem(
          name: _loc.translate('terrace_calc.materials.decking'),
          value: '${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.deck,
        ));
        break;
      case TerraceFloorType.tile:
        items.add(MaterialItem(
          name: _loc.translate('terrace_calc.materials.tile'),
          value: '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.grid_on,
        ));
        break;
      case TerraceFloorType.board:
        items.add(MaterialItem(
          name: _loc.translate('terrace_calc.materials.board'),
          value: '${_result.deckingBoards} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.view_agenda,
        ));
        break;
      case TerraceFloorType.porcelain:
        items.add(MaterialItem(
          name: _loc.translate('terrace.floor.porcelain'),
          value: '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.texture,
        ));
        break;
      case TerraceFloorType.wpc:
        items.add(MaterialItem(
          name: _loc.translate('terrace.floor.wpc'),
          value: '${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.dashboard,
        ));
        break;
      case TerraceFloorType.solidWood:
        items.add(MaterialItem(
          name: _loc.translate('terrace.floor.solidWood'),
          value: '${_result.deckingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.park,
        ));
        break;
      case TerraceFloorType.rubberTiles:
        items.add(MaterialItem(
          name: _loc.translate('terrace.floor.rubberTiles'),
          value: '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('terrace_calc.materials.margin_10'),
          icon: Icons.apps,
        ));
        break;
    }

    if (_hasRailing) {
      items.addAll([
        MaterialItem(
          name: _loc.translate('terrace_calc.materials.railing'),
          value: '${_result.railingLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
          subtitle: _loc.translate('terrace_calc.materials.railing_hint'),
          icon: Icons.straighten,
        ),
        MaterialItem(
          name: _loc.translate('terrace_calc.materials.railing_posts'),
          value: '${_result.railingPosts} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('terrace_calc.materials.railing_posts_hint'),
          icon: Icons.flag,
        ),
      ]);
    }

    if (_hasRoof) {
      items.add(MaterialItem(
        name: _loc.translate('terrace_calc.materials.roof_area'),
        value: '${_result.roofArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('terrace_calc.materials.roof_area_hint'),
        icon: Icons.roofing,
      ));

      if (_roofType == TerraceRoofType.polycarbonate) {
        items.add(MaterialItem(
          name: _loc.translate('terrace_calc.materials.polycarbonate'),
          value: '${_result.polycarbonateSheets} ${_loc.translate('common.sheets')}',
          subtitle: _loc.translate('terrace_calc.materials.polycarbonate_hint'),
          icon: Icons.cloud_queue,
        ));
      } else if (_roofType == TerraceRoofType.profiledSheet) {
        items.add(MaterialItem(
          name: _loc.translate('terrace_calc.materials.profiled_sheet'),
          value: '${_result.profiledSheets} ${_loc.translate('common.sheets')}',
          subtitle: _loc.translate('terrace_calc.materials.profiled_sheet_hint'),
          icon: Icons.table_chart,
        ));
      } else {
        items.add(MaterialItem(
          name: _loc.translate('terrace_calc.materials.soft_roof'),
          value: '${_result.roofingMaterial.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
          icon: Icons.layers,
        ));
      }

      items.addAll([
        MaterialItem(
          name: _loc.translate('terrace_calc.materials.roof_posts'),
          value: '${_result.roofPosts} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('terrace_calc.materials.roof_posts_hint'),
          icon: Icons.vertical_align_bottom,
        ),
        MaterialItem(
          name: _loc.translate('terrace_calc.materials.foundation'),
          value: '${_result.foundationVolume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
          subtitle: _loc.translate('terrace_calc.materials.foundation_hint'),
          icon: Icons.foundation,
        ),
      ]);
    }

    return MaterialsCardModern(
      title: _loc.translate('group.materials'),
      titleIcon: Icons.inventory_2,
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
