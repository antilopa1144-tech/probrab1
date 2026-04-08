
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/price_item.dart';
import '../../../domain/usecases/calculate_terrace.dart';
import '../../mixins/exportable_mixin.dart';
import '../../mixins/accuracy_mode_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum TerraceFloorType {
  decking,      // Декинг (существующий)
  tile,         // Керамическая плитка (существующий)
  board,        // Доска (существующий)
  porcelain,    // Керамогранит (НОВЫЙ)
  wpc,          // ДПК - древесно-полимерный композит (НОВЫЙ)
  solidWood,    // Массив дерева (НОВЫЙ)
  rubberTiles,  // Резиновые покрытия (НОВЫЙ)
}

/// Режим ввода площади
enum TerraceInputMode { manual, dimensions }

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
    with ExportableMixin, AccuracyModeMixin {
  bool _isDark = false;

  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate(widget.definition.titleKey);

  static const double _minArea = 4.0;
  static const double _maxArea = 200.0;

  TerraceInputMode _inputMode = TerraceInputMode.manual;
  double _area = 18.0;
  double _length = 5.0; // м
  double _width = 4.0; // м
  TerraceFloorType _floorType = TerraceFloorType.decking;
  bool _hasRailing = true;
  bool _hasRoof = false;
  TerraceRoofType _roofType = TerraceRoofType.polycarbonate;

  late _TerraceResult _result;
  late AppLocalizations _loc;

  final CalculateTerrace _calculator = CalculateTerrace();

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  T _enumFromStoredIndex<T>(List<T> values, double? rawValue, T fallback, {bool oneBased = false}) {
    if (rawValue == null) return fallback;
    final index = rawValue.round() - (oneBased ? 1 : 0);
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    _inputMode = _enumFromStoredIndex(TerraceInputMode.values, initial['inputMode'], _inputMode);
    if (initial['area'] != null) _area = initial['area']!.clamp(_minArea, _maxArea);
    if (initial['length'] != null) _length = initial['length']!.clamp(1.0, 20.0);
    if (initial['width'] != null) _width = initial['width']!.clamp(1.0, 20.0);
    _floorType = _enumFromStoredIndex(TerraceFloorType.values, initial['floorType'], _floorType, oneBased: true);
    if (initial['railing'] != null) _hasRailing = initial['railing']!.round() == 1;
    if (initial['roof'] != null) _hasRoof = initial['roof']!.round() == 1;
    _roofType = _enumFromStoredIndex(TerraceRoofType.values, initial['roofType'], _roofType, oneBased: true);
  }

  Map<String, double> _buildCalculationInputs() {
    return {
      'inputMode': _inputMode.index.toDouble(),
      'area': _area,
      'length': _length,
      'width': _width,
      'floorType': (_floorType.index + 1).toDouble(),
      'railing': _hasRailing ? 1.0 : 0.0,
      'roof': _hasRoof ? 1.0 : 0.0,
      'roofType': (_roofType.index + 1).toDouble(),
          ...accuracyModeInput,
    };
  }

  _TerraceResult _calculate() {
    final values = _calculator(_buildCalculationInputs(), <PriceItem>[]).values;
    return _TerraceResult(
      area: values['area'] ?? 0,
      deckingArea: values['deckingArea'] ?? 0,
      tilesNeeded: (values['tilesNeeded'] ?? 0).round(),
      deckingBoards: (values['deckingBoards'] ?? 0).round(),
      railingLength: values['railingLength'] ?? 0,
      railingPosts: (values['railingPosts'] ?? 0).round(),
      roofArea: values['roofArea'] ?? 0,
      polycarbonateSheets: (values['polycarbonateSheets'] ?? 0).round(),
      profiledSheets: (values['profiledSheets'] ?? 0).round(),
      roofingMaterial: values['roofingMaterial'] ?? 0,
      roofPosts: (values['roofPosts'] ?? 0).round(),
      foundationVolume: values['foundationVolume'] ?? 0,
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
        buffer.writeln(_loc.translate('terrace_calc.export.porcelain').replaceFirst('{value}', _result.tilesNeeded.toString()));
        break;
      case TerraceFloorType.wpc:
        buffer.writeln(_loc.translate('terrace_calc.export.wpc').replaceFirst('{value}', _result.deckingArea.toStringAsFixed(1)));
        break;
      case TerraceFloorType.solidWood:
        buffer.writeln(_loc.translate('terrace_calc.export.solid_wood').replaceFirst('{value}', _result.deckingArea.toStringAsFixed(1)));
        break;
      case TerraceFloorType.rubberTiles:
        buffer.writeln(_loc.translate('terrace_calc.export.rubber_tiles').replaceFirst('{value}', _result.tilesNeeded.toString()));
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
    _isDark = Theme.of(context).brightness == Brightness.dark;
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
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('terrace_calc.section.area'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('terrace_calc.input_mode.manual'),
              _loc.translate('terrace_calc.input_mode.dimensions'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = TerraceInputMode.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          if (_inputMode == TerraceInputMode.manual)
            CalculatorSliderField(
              label: _loc.translate('terrace_calc.label.area'),
              value: _area,
              min: _minArea,
              max: _maxArea,
              suffix: _loc.translate('common.sqm'),
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CalculatorTextField(
                        label: _loc.translate('terrace_calc.label.length'),
                        value: _length,
                        onChanged: (v) {
                          setState(() {
                            _length = v;
                            _update();
                          });
                        },
                        suffix: _loc.translate('common.meters'),
                        accentColor: accentColor,
                        minValue: 1,
                        maxValue: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CalculatorTextField(
                        label: _loc.translate('terrace_calc.label.width'),
                        value: _width,
                        onChanged: (v) {
                          setState(() {
                            _width = v;
                            _update();
                          });
                        },
                        suffix: _loc.translate('common.meters'),
                        accentColor: accentColor,
                        minValue: 1,
                        maxValue: 20,
                      ),
                    ),
                  ],
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
                        _loc.translate('terrace_calc.label.calculated_area'),
                        style: CalculatorDesignSystem.bodyMedium.copyWith(
                          color: CalculatorColors.getTextSecondary(_isDark),
                        ),
                      ),
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
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TerraceFloorType.values.map((type) {
              final isSelected = _floorType == type;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFloorTypeIconForType(type),
                      size: 16,
                      color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                    ),
                    const SizedBox(width: 4),
                    Text(_getFloorTypeLabelForType(type)),
                  ],
                ),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() {
                    _floorType = type;
                    _update();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('terrace_calc.floor_type.margin_note'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  String _getFloorTypeLabelForType(TerraceFloorType type) {
    return switch (type) {
      TerraceFloorType.decking => _loc.translate('terrace_calc.floor_type.decking'),
      TerraceFloorType.tile => _loc.translate('terrace_calc.floor_type.tile'),
      TerraceFloorType.board => _loc.translate('terrace_calc.floor_type.board'),
      TerraceFloorType.porcelain => _loc.translate('terrace.floor.porcelain'),
      TerraceFloorType.wpc => _loc.translate('terrace.floor.wpc'),
      TerraceFloorType.solidWood => _loc.translate('terrace.floor.solidWood'),
      TerraceFloorType.rubberTiles => _loc.translate('terrace.floor.rubberTiles'),
    };
  }

  IconData _getFloorTypeIconForType(TerraceFloorType type) {
    return switch (type) {
      TerraceFloorType.decking => Icons.deck,
      TerraceFloorType.tile => Icons.grid_on,
      TerraceFloorType.board => Icons.view_agenda,
      TerraceFloorType.porcelain => Icons.texture,
      TerraceFloorType.wpc => Icons.dashboard,
      TerraceFloorType.solidWood => Icons.park,
      TerraceFloorType.rubberTiles => Icons.apps,
    };
  }

  String _getRoofTypeLabelForType(TerraceRoofType type) {
    return switch (type) {
      TerraceRoofType.polycarbonate => _loc.translate('terrace_calc.roof.polycarbonate'),
      TerraceRoofType.profiledSheet => _loc.translate('terrace_calc.roof.profiled_sheet'),
      TerraceRoofType.softRoof => _loc.translate('terrace_calc.materials.soft_roof'),
      TerraceRoofType.ondulin => _loc.translate('terrace.roof.ondulin'),
      TerraceRoofType.metalTile => _loc.translate('terrace.roof.metal_tile'),
      TerraceRoofType.glass => _loc.translate('terrace.roof.glass'),
    };
  }

  IconData _getRoofTypeIconForType(TerraceRoofType type) {
    return switch (type) {
      TerraceRoofType.polycarbonate => Icons.cloud_queue,
      TerraceRoofType.profiledSheet => Icons.table_chart,
      TerraceRoofType.softRoof => Icons.layers,
      TerraceRoofType.ondulin => Icons.view_module,
      TerraceRoofType.metalTile => Icons.roofing,
      TerraceRoofType.glass => Icons.window,
    };
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
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.getTextSecondary(_isDark),
            ),
            title: Text(
              _loc.translate('terrace_calc.railing.toggle'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('terrace_calc.railing.hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
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
                        color: CalculatorColors.getTextSecondary(_isDark),
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
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.getTextSecondary(_isDark),
            ),
            title: Text(
              _loc.translate('terrace_calc.roof.toggle'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('terrace_calc.roof.hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TerraceRoofType.values.map((type) {
                final isSelected = _roofType == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoofTypeIconForType(type),
                        size: 16,
                        color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(_getRoofTypeLabelForType(type)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: accentColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? accentColor : Colors.grey.shade300,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _roofType = type;
                      _update();
                    });
                  },
                );
              }).toList(),
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
                        color: CalculatorColors.getTextSecondary(_isDark),
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

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.facade;
    final tips = <String>[];

    switch (_floorType) {
      case TerraceFloorType.decking:
        tips.addAll([
          _loc.translate('terrace_calc.tip.decking_1'),
          _loc.translate('terrace_calc.tip.decking_2'),
        ]);
        break;
      case TerraceFloorType.tile:
      case TerraceFloorType.porcelain:
        tips.addAll([
          _loc.translate('terrace_calc.tip.tile_1'),
          _loc.translate('terrace_calc.tip.tile_2'),
        ]);
        break;
      case TerraceFloorType.board:
      case TerraceFloorType.solidWood:
        tips.addAll([
          _loc.translate('terrace_calc.tip.wood_1'),
          _loc.translate('terrace_calc.tip.wood_2'),
        ]);
        break;
      case TerraceFloorType.wpc:
        tips.addAll([
          _loc.translate('terrace_calc.tip.wpc_1'),
          _loc.translate('terrace_calc.tip.wpc_2'),
        ]);
        break;
      case TerraceFloorType.rubberTiles:
        tips.addAll([
          _loc.translate('terrace_calc.tip.rubber_1'),
          _loc.translate('terrace_calc.tip.rubber_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('terrace_calc.tip.common'));

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


