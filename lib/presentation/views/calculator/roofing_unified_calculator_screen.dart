import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/usecases/calculate_unified_roofing.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

/// Единый калькулятор кровли
///
/// Поддерживает 6 типов кровельных материалов:
/// - Металлочерепица
/// - Мягкая кровля
/// - Профнастил
/// - Ондулин
/// - Шифер
/// - Керамическая черепица
class RoofingUnifiedCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const RoofingUnifiedCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<RoofingUnifiedCalculatorScreen> createState() =>
      _RoofingUnifiedCalculatorScreenState();
}

class _RoofingUnifiedCalculatorScreenState
    extends State<RoofingUnifiedCalculatorScreen> with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate(widget.definition.titleKey);

  static const double _minArea = 10.0;
  static const double _maxArea = 500.0;
  static const double _minSlope = 5.0;
  static const double _maxSlope = 60.0;

  double _area = 100.0;
  double _slope = 30.0;
  double _ridgeLength = 0.0;
  double _valleyLength = 0.0;
  double _sheetWidth = 1.18;
  double _sheetLength = 2.5;
  RoofingType _roofingType = RoofingType.metalTile;

  late _RoofingResult _result;
  late AppLocalizations _loc;

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
    if (initial['slope'] != null) {
      _slope = initial['slope']!.clamp(_minSlope, _maxSlope);
    }
    if (initial['ridgeLength'] != null) {
      _ridgeLength = initial['ridgeLength']!;
    }
    if (initial['valleyLength'] != null) {
      _valleyLength = initial['valleyLength']!;
    }
    if (initial['sheetWidth'] != null) {
      _sheetWidth = initial['sheetWidth']!;
    }
    if (initial['sheetLength'] != null) {
      _sheetLength = initial['sheetLength']!;
    }
    if (initial['roofingType'] != null) {
      final raw = initial['roofingType']!.round().clamp(0, 5);
      _roofingType = RoofingType.values[raw];
    }
  }

  _RoofingResult _calculate() {
    final slopeFactor = 1 / cos(_slope * pi / 180);
    final realArea = _area * slopeFactor;
    final ridgeLength = _ridgeLength > 0 ? _ridgeLength : sqrt(_area);

    int sheetsNeeded = 0;
    int packsNeeded = 0;
    int tilesNeeded = 0;
    final waterproofingArea = realArea * 1.1;
    final double battensLength;

    switch (_roofingType) {
      case RoofingType.metalTile:
        final effectiveWidth = _sheetWidth * 0.92;
        final sheetArea = effectiveWidth * _sheetLength;
        sheetsNeeded = (realArea / sheetArea * 1.1).ceil();
        battensLength = realArea / 0.35 * 1.05;
        break;
      case RoofingType.softRoofing:
        packsNeeded = (realArea / 3.0 * 1.1).ceil();
        battensLength = 0; // OSB вместо обрешетки
        break;
      case RoofingType.profiledSheet:
        final effectiveWidth = _sheetWidth * 0.95;
        final sheetArea = effectiveWidth * _sheetLength;
        sheetsNeeded = (realArea / sheetArea * 1.1).ceil();
        battensLength = realArea / 0.5 * 1.05;
        break;
      case RoofingType.ondulin:
        sheetsNeeded = (realArea / 1.6 * 1.15).ceil();
        battensLength = realArea / 0.45 * 1.05;
        break;
      case RoofingType.slate:
        sheetsNeeded = (realArea / 1.5 * 1.1).ceil();
        battensLength = realArea / 0.5 * 1.05;
        break;
      case RoofingType.ceramicTile:
        tilesNeeded = (realArea * 12 * 1.05).ceil();
        battensLength = realArea / 0.32 * 1.05;
        break;
    }

    return _RoofingResult(
      area: _area,
      realArea: realArea,
      ridgeLength: ridgeLength,
      sheetsNeeded: sheetsNeeded,
      packsNeeded: packsNeeded,
      tilesNeeded: tilesNeeded,
      waterproofingArea: waterproofingArea,
      battensLength: battensLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _getRoofingTypeLabel(RoofingType type) {
    return switch (type) {
      RoofingType.metalTile => _loc.translate('roofing.type.metal_tile'),
      RoofingType.softRoofing => _loc.translate('roofing.type.soft'),
      RoofingType.profiledSheet => _loc.translate('roofing.type.profiled'),
      RoofingType.ondulin => _loc.translate('roofing.type.ondulin'),
      RoofingType.slate => _loc.translate('roofing.type.slate'),
      RoofingType.ceramicTile => _loc.translate('roofing.type.ceramic'),
    };
  }

  IconData _getRoofingTypeIcon(RoofingType type) {
    return switch (type) {
      RoofingType.metalTile => Icons.roofing,
      RoofingType.softRoofing => Icons.layers,
      RoofingType.profiledSheet => Icons.table_chart,
      RoofingType.ondulin => Icons.view_module,
      RoofingType.slate => Icons.grid_view,
      RoofingType.ceramicTile => Icons.grid_on,
    };
  }

  String _getMainResultValue() {
    return switch (_roofingType) {
      RoofingType.metalTile ||
      RoofingType.profiledSheet ||
      RoofingType.ondulin ||
      RoofingType.slate =>
        '${_result.sheetsNeeded} ${_loc.translate('common.sheets')}',
      RoofingType.softRoofing =>
        '${_result.packsNeeded} ${_loc.translate('common.packs')}',
      RoofingType.ceramicTile =>
        '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('roofing_unified.export.title'));
    buffer.writeln('${_loc.translate('input.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('input.slope')}: ${_slope.toStringAsFixed(0)}°');
    buffer.writeln('${_loc.translate('input.roofingType')}: ${_getRoofingTypeLabel(_roofingType)}');
    buffer.writeln('${_loc.translate('roofing.realArea')}: ${_result.realArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');

    switch (_roofingType) {
      case RoofingType.metalTile:
      case RoofingType.profiledSheet:
      case RoofingType.ondulin:
      case RoofingType.slate:
        buffer.writeln('${_loc.translate('roofing.sheets')}: ${_result.sheetsNeeded}');
        break;
      case RoofingType.softRoofing:
        buffer.writeln('${_loc.translate('roofing.packs')}: ${_result.packsNeeded}');
        break;
      case RoofingType.ceramicTile:
        buffer.writeln('${_loc.translate('roofing.tiles')}: ${_result.tilesNeeded}');
        break;
    }

    buffer.writeln('${_loc.translate('roofing.waterproofing')}: ${_result.waterproofingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    if (_result.battensLength > 0) {
      buffer.writeln('${_loc.translate('roofing.battens')}: ${_result.battensLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}');
    }
    buffer.writeln('${_loc.translate('roofing.ridge')}: ${_result.ridgeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.roofing;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('roofing.realArea'),
            value: '${_result.realArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _getRoofingTypeLabel(_roofingType),
            value: _getMainResultValue(),
            icon: _getRoofingTypeIcon(_roofingType),
          ),
        ],
      ),
      children: [
        _buildRoofingTypeCard(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildSlopeCard(),
        const SizedBox(height: 16),
        if (_roofingType == RoofingType.metalTile ||
            _roofingType == RoofingType.profiledSheet)
          ...[
            _buildSheetDimensionsCard(),
            const SizedBox(height: 16),
          ],
        _buildAdditionalParamsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRoofingTypeCard() {
    const accentColor = CalculatorColors.roofing;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.roofingType'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RoofingType.values.map((type) {
              final isSelected = _roofingType == type;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoofingTypeIcon(type),
                      size: 16,
                      color: isSelected ? accentColor : CalculatorColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(_getRoofingTypeLabel(type)),
                  ],
                ),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() {
                    _roofingType = type;
                    _update();
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.roofing;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('input.area'),
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

  Widget _buildSlopeCard() {
    const accentColor = CalculatorColors.roofing;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('input.slope'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_slope.toStringAsFixed(0)}°',
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
              value: _slope,
              min: _minSlope,
              max: _maxSlope,
              divisions: (_maxSlope - _minSlope).round(),
              onChanged: (v) {
                setState(() {
                  _slope = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('roofing.slope_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetDimensionsCard() {
    const accentColor = CalculatorColors.roofing;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('roofing.sheet_dimensions'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('input.sheetWidth'),
                  value: _sheetWidth,
                  suffix: _loc.translate('common.meters'),
                  minValue: 0.5,
                  maxValue: 2.0,
                  decimalPlaces: 2,
                  accentColor: accentColor,
                  onChanged: (value) {
                    setState(() {
                      _sheetWidth = value;
                      _update();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('input.sheetLength'),
                  value: _sheetLength,
                  suffix: _loc.translate('common.meters'),
                  minValue: 1.0,
                  maxValue: 12.0,
                  decimalPlaces: 1,
                  accentColor: accentColor,
                  onChanged: (value) {
                    setState(() {
                      _sheetLength = value;
                      _update();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalParamsCard() {
    const accentColor = CalculatorColors.roofing;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('roofing.additional_params'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('input.ridgeLength'),
            value: _ridgeLength,
            suffix: _loc.translate('common.meters'),
            minValue: 0,
            maxValue: 100,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _ridgeLength = value;
                _update();
              });
            },
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('input.valleyLength'),
            value: _valleyLength,
            suffix: _loc.translate('common.meters'),
            minValue: 0,
            maxValue: 100,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _valleyLength = value;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('roofing.optional_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.roofing;
    final items = <MaterialItem>[];

    // Основной материал
    switch (_roofingType) {
      case RoofingType.metalTile:
        items.add(MaterialItem(
          name: _loc.translate('roofing.type.metal_tile'),
          value: '${_result.sheetsNeeded} ${_loc.translate('common.sheets')}',
          subtitle: _loc.translate('roofing.margin_10'),
          icon: Icons.roofing,
        ));
        break;
      case RoofingType.softRoofing:
        items.add(MaterialItem(
          name: _loc.translate('roofing.type.soft'),
          value: '${_result.packsNeeded} ${_loc.translate('common.packs')}',
          subtitle: _loc.translate('roofing.pack_3sqm'),
          icon: Icons.layers,
        ));
        break;
      case RoofingType.profiledSheet:
        items.add(MaterialItem(
          name: _loc.translate('roofing.type.profiled'),
          value: '${_result.sheetsNeeded} ${_loc.translate('common.sheets')}',
          subtitle: _loc.translate('roofing.margin_10'),
          icon: Icons.table_chart,
        ));
        break;
      case RoofingType.ondulin:
        items.add(MaterialItem(
          name: _loc.translate('roofing.type.ondulin'),
          value: '${_result.sheetsNeeded} ${_loc.translate('common.sheets')}',
          subtitle: _loc.translate('roofing.margin_15'),
          icon: Icons.view_module,
        ));
        break;
      case RoofingType.slate:
        items.add(MaterialItem(
          name: _loc.translate('roofing.type.slate'),
          value: '${_result.sheetsNeeded} ${_loc.translate('common.sheets')}',
          subtitle: _loc.translate('roofing.margin_10'),
          icon: Icons.grid_view,
        ));
        break;
      case RoofingType.ceramicTile:
        items.add(MaterialItem(
          name: _loc.translate('roofing.type.ceramic'),
          value: '${_result.tilesNeeded} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('roofing.tiles_12sqm'),
          icon: Icons.grid_on,
        ));
        break;
    }

    // Гидроизоляция
    items.add(MaterialItem(
      name: _loc.translate('roofing.waterproofing'),
      value: '${_result.waterproofingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      subtitle: _loc.translate('roofing.margin_10'),
      icon: Icons.water_drop,
    ));

    // Обрешётка
    if (_result.battensLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('roofing.battens'),
        value: '${_result.battensLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('roofing.battens_hint'),
        icon: Icons.view_agenda,
      ));
    }

    // Конёк
    items.add(MaterialItem(
      name: _loc.translate('roofing.ridge'),
      value: '${_result.ridgeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
      icon: Icons.horizontal_rule,
    ));

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

class _RoofingResult {
  final double area;
  final double realArea;
  final double ridgeLength;
  final int sheetsNeeded;
  final int packsNeeded;
  final int tilesNeeded;
  final double waterproofingArea;
  final double battensLength;

  const _RoofingResult({
    required this.area,
    required this.realArea,
    required this.ridgeLength,
    required this.sheetsNeeded,
    required this.packsNeeded,
    required this.tilesNeeded,
    required this.waterproofingArea,
    required this.battensLength,
  });
}
