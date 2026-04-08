
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/price_item.dart';
import '../../../domain/usecases/calculate_3d_panels.dart';
import '../../mixins/exportable_mixin.dart';
import '../../mixins/accuracy_mode_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum PanelsInputMode { byArea, byDimensions }

class _PanelsResult {
  final double area;
  final int panelsCount;
  final double panelSizeCm;
  final double panelArea;
  final double glueKg;
  final double primerLiters;
  final double puttyKg;
  final double paintLiters;
  final double varnishLiters;
  final double moldingLength;

  const _PanelsResult({
    required this.area,
    required this.panelsCount,
    required this.panelSizeCm,
    required this.panelArea,
    required this.glueKg,
    required this.primerLiters,
    required this.puttyKg,
    required this.paintLiters,
    required this.varnishLiters,
    required this.moldingLength,
  });
}

class ThreeDPanelsCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ThreeDPanelsCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<ThreeDPanelsCalculatorScreen> createState() =>
      _ThreeDPanelsCalculatorScreenState();
}

class _ThreeDPanelsCalculatorScreenState
    extends State<ThreeDPanelsCalculatorScreen>
    with ExportableMixin, AccuracyModeMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('three_d_panels.export.subject');

  bool _isDark = false;
  PanelsInputMode _inputMode = PanelsInputMode.byArea;
  double _area = 12.0;
  double _length = 4.0;
  double _height = 2.7;
  double _panelSize = 50.0;
  bool _paintable = false;
  bool _withVarnish = true;

  late _PanelsResult _result;
  late AppLocalizations _loc;

  final Calculate3dPanels _calculator = Calculate3dPanels();

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  T _enumFromStoredIndex<T>(List<T> values, double? rawValue, T fallback) {
    if (rawValue == null) return fallback;
    final index = rawValue.round();
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    _inputMode = _enumFromStoredIndex(PanelsInputMode.values, initial['inputMode'], _inputMode);
    if (initial['area'] != null) _area = initial['area']!.clamp(3.0, 150.0);
    if (initial['length'] != null) _length = initial['length']!.clamp(1.0, 12.0);
    if (initial['height'] != null) _height = initial['height']!.clamp(2.0, 4.0);
    if (initial['panelSize'] != null) {
      final raw = initial['panelSize']!;
      _panelSize = (raw < 5 ? raw * 100 : raw).clamp(30.0, 100.0);
    }
    if (initial['paintable'] != null) _paintable = initial['paintable']!.round() == 1;
    if (initial['withVarnish'] != null) _withVarnish = initial['withVarnish']!.round() == 1;
  }

  Map<String, double> _buildCalculationInputs() {
    return {
      'inputMode': _inputMode.index.toDouble(),
      'area': _area,
      'length': _length,
      'height': _height,
      'panelSize': _panelSize,
      'paintable': _paintable ? 1.0 : 0.0,
      'withVarnish': _withVarnish ? 1.0 : 0.0,
          ...accuracyModeInput,
    };
  }

  _PanelsResult _calculate() {
    final result = _calculator(_buildCalculationInputs(), <PriceItem>[]).values;
    return _PanelsResult(
      area: result['area'] ?? 0,
      panelsCount: (result['panelsCount'] ?? result['panelsNeeded'] ?? 0).round(),
      panelSizeCm: result['panelSize'] ?? _panelSize,
      panelArea: result['panelArea'] ?? ((_panelSize / 100) * (_panelSize / 100)),
      glueKg: result['glueKg'] ?? result['glueNeeded'] ?? 0,
      primerLiters: result['primerLiters'] ?? result['primerNeeded'] ?? 0,
      puttyKg: result['puttyKg'] ?? result['puttyNeeded'] ?? 0,
      paintLiters: result['paintLiters'] ?? result['paintNeeded'] ?? 0,
      varnishLiters: result['varnishLiters'] ?? result['varnishNeeded'] ?? 0,
      moldingLength: result['moldingLength'] ?? result['perimeter'] ?? 0,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('three_d_panels.export.title'));
    buffer.writeln(_loc.translate('three_d_panels.export.area').replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('three_d_panels.export.panel_size')
        .replaceFirst('{width}', _result.panelSizeCm.toStringAsFixed(0))
        .replaceFirst('{height}', _result.panelSizeCm.toStringAsFixed(0))
        .replaceFirst('{area}', _result.panelArea.toStringAsFixed(3)));
    buffer.writeln(_loc.translate('three_d_panels.export.panels_count').replaceFirst('{value}', _result.panelsCount.toString()));
    buffer.writeln(_loc.translate('three_d_panels.export.glue').replaceFirst('{value}', _result.glueKg.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('three_d_panels.export.primer').replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('three_d_panels.export.putty').replaceFirst('{value}', _result.puttyKg.toStringAsFixed(1)));
    if (_result.paintLiters > 0) {
      buffer.writeln(_loc.translate('three_d_panels.export.paint').replaceFirst('{value}', _result.paintLiters.toStringAsFixed(1)));
    }
    if (_result.varnishLiters > 0) {
      buffer.writeln(_loc.translate('three_d_panels.export.varnish').replaceFirst('{value}', _result.varnishLiters.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('three_d_panels.export.molding').replaceFirst('{value}', _result.moldingLength.toStringAsFixed(1)));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('three_d_panels.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('three_d_panels.header.area'),
            value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('three_d_panels.header.panels'),
            value: _result.panelsCount.toString(),
            icon: Icons.apps,
          ),
          ResultItem(
            label: _loc.translate('three_d_panels.header.glue'),
            value: '${_result.glueKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
            icon: Icons.construction,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == PanelsInputMode.byArea
            ? _buildAreaCard()
            : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildPanelSizeCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
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
            _loc.translate('three_d_panels.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('three_d_panels.input_mode.by_area'),
              _loc.translate('three_d_panels.input_mode.by_dimensions'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = PanelsInputMode.values[index];
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
                  _loc.translate('three_d_panels.field.wall_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              min: 3,
              max: 150,
              divisions: ((150 - 3) * 10).round(),
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
            label: _loc.translate('three_d_panels.field.area'),
            value: _area,
            suffix: _loc.translate('common.sqm'),
            minValue: 3,
            maxValue: 150,
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

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('three_d_panels.field.wall_size'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('three_d_panels.field.length'),
            value: _length,
            min: 1.0,
            max: 12.0,
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
            label: _loc.translate('three_d_panels.field.height'),
            value: _height,
            min: 2.0,
            max: 4.0,
            onChanged: (v) {
              setState(() {
                _height = v;
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
                    _loc.translate('three_d_panels.field.wall_area'),
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
              style: CalculatorDesignSystem.titleMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
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
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: label,
          value: value,
          suffix: _loc.translate('common.meters'),
          minValue: min,
          maxValue: max,
          decimalPlaces: 1,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPanelSizeCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('three_d_panels.panel_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('three_d_panels.panel_size.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('three_d_panels.panel_size.side'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_panelSize.toStringAsFixed(0)} ${_loc.translate('common.cm')}',
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
              value: _panelSize,
              min: 30,
              max: 100,
              divisions: 70,
              onChanged: (v) {
                setState(() {
                  _panelSize = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('three_d_panels.panel_size.side'),
            value: _panelSize,
            suffix: _loc.translate('common.cm'),
            minValue: 30,
            maxValue: 100,
            isInteger: true,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _panelSize = value;
                _update();
              });
            },
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('three_d_panels.panel_size.area_note').replaceFirst('{value}', _result.panelArea.toStringAsFixed(3)),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('three_d_panels.options.title'),
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
              _loc.translate('three_d_panels.options.paintable'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('three_d_panels.options.paintable_hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _paintable,
            onChanged: (value) {
              setState(() {
                _paintable = value;
                _update();
              });
            },
          ),
          const SizedBox(height: 4),
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
              _loc.translate('three_d_panels.options.varnish'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('three_d_panels.options.varnish_hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _withVarnish,
            onChanged: (value) {
              setState(() {
                _withVarnish = value;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('three_d_panels.materials.panels'),
        value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.panelSizeCm.toStringAsFixed(0)}×${_result.panelSizeCm.toStringAsFixed(0)} ${_loc.translate('common.cm')}',
        icon: Icons.apps,
      ),
      MaterialItem(
        name: _loc.translate('three_d_panels.materials.glue'),
        value: '${_result.glueKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        icon: Icons.construction,
      ),
      MaterialItem(
        name: _loc.translate('three_d_panels.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: _loc.translate('three_d_panels.materials.putty'),
        value: '${_result.puttyKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('three_d_panels.materials.putty_hint'),
        icon: Icons.format_paint,
      ),
    ];

    if (_result.paintLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('three_d_panels.materials.paint'),
        value: '${_result.paintLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('three_d_panels.materials.paint_hint'),
        icon: Icons.brush,
      ));
    }

    if (_result.varnishLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('three_d_panels.materials.varnish'),
        value: '${_result.varnishLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        icon: Icons.shield,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('three_d_panels.materials.molding'),
      value: '${_result.moldingLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
      icon: Icons.straighten,
    ));

    return MaterialsCardModern(
      title: _loc.translate('three_d_panels.materials.title'),
      titleIcon: Icons.inventory_2,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[
      _loc.translate('hint.walls.proverte_rovnost_sten_pered'),
      _loc.translate('hint.walls.ispolzuyte_spetsialnyy_kley_dlya_2'),
      _loc.translate('hint.walls.nachinayte_montazh_ot_tsentra'),
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

