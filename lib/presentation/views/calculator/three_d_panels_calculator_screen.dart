import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_result_header.dart';
import '../../widgets/calculator/calculator_scaffold.dart';
import '../../widgets/calculator/calculator_text_field.dart';
import '../../widgets/calculator/mode_selector.dart';
import '../../widgets/calculator/result_card.dart';
import '../../widgets/existing/hint_card.dart';

/// Вспомогательный класс для работы с константами калькулятора 3D панелей
class _PanelsConstants {
  final CalculatorConstants? _data;

  const _PanelsConstants([this._data]);

  double _getDouble(String constantKey, String valueKey, double defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  // Margins
  double get panelsMargin => _getDouble('margins', 'panels_margin', 1.1);

  // Materials consumption
  double get gluePerM2 => _getDouble('materials_consumption', 'glue_per_m2', 5.0);
  double get primerPerM2 => _getDouble('materials_consumption', 'primer_per_m2', 0.18);
  double get puttyPerM2 => _getDouble('materials_consumption', 'putty_per_m2', 1.0);
  double get paintPerM2 => _getDouble('materials_consumption', 'paint_per_m2', 0.24);
  double get varnishPerM2 => _getDouble('materials_consumption', 'varnish_per_m2', 0.08);
}

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
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('three_d_panels.export.subject');

  PanelsInputMode _inputMode = PanelsInputMode.byArea;
  double _area = 12.0;
  double _length = 4.0;
  double _height = 2.7;
  double _panelSize = 50.0;
  bool _paintable = false;
  bool _withVarnish = true;

  late _PanelsResult _result;
  late AppLocalizations _loc;

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _PanelsConstants _constants;

  @override
  void initState() {
    super.initState();
    // TODO: Загрузить константы из provider когда понадобится Remote Config
    _constants = const _PanelsConstants(null);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['area'] != null) {
      _area = initial['area']!.clamp(3.0, 150.0);
    }
    if (initial['length'] != null) {
      _length = initial['length']!.clamp(1.0, 12.0);
    }
    if (initial['height'] != null) {
      _height = initial['height']!.clamp(2.0, 4.0);
    }
    if (initial['panelSize'] != null) {
      final raw = initial['panelSize']!;
      _panelSize = (raw < 5 ? raw * 100 : raw).clamp(30.0, 100.0);
    }
    if (initial['paintable'] != null) {
      _paintable = initial['paintable']!.round() == 1;
    }
  }

  double _getCalculatedArea() {
    if (_inputMode == PanelsInputMode.byArea) return _area;
    return _length * _height;
  }

  _PanelsResult _calculate() {
    final area = _getCalculatedArea();

    // Размер панели в м²
    final panelArea = (_panelSize / 100) * (_panelSize / 100);

    // Количество панелей с запасом из констант
    final panelsCount = (area / panelArea * _constants.panelsMargin).ceil();

    // Материалы по нормативам из констант
    final glueKg = area * _constants.gluePerM2;
    final primerLiters = area * _constants.primerPerM2;
    final puttyKg = area * _constants.puttyPerM2;
    final paintLiters = _paintable ? area * _constants.paintPerM2 : 0.0;
    final varnishLiters = _withVarnish ? area * _constants.varnishPerM2 : 0.0;

    // Периметр для молдингов
    final perimeter = _inputMode == PanelsInputMode.byDimensions
        ? (_length + _height) * 2
        : 4 * sqrt(area);

    return _PanelsResult(
      area: area,
      panelsCount: panelsCount,
      panelSizeCm: _panelSize,
      panelArea: panelArea,
      glueKg: glueKg,
      primerLiters: primerLiters,
      puttyKg: puttyKg,
      paintLiters: paintLiters,
      varnishLiters: varnishLiters,
      moldingLength: perimeter,
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
            _loc.translate('three_d_panels.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
                    color: CalculatorColors.textSecondary,
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
              color: CalculatorColors.textPrimary,
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
                      color: CalculatorColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('three_d_panels.panel_size.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('three_d_panels.panel_size.side'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
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
              color: CalculatorColors.textSecondary,
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
              _loc.translate('three_d_panels.options.paintable'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _loc.translate('three_d_panels.options.paintable_hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
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
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              _loc.translate('three_d_panels.options.varnish'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _loc.translate('three_d_panels.options.varnish_hint'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
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

  Widget _buildTipsSection() {
    final hints = <CalculatorHint>[
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.walls.proverte_rovnost_sten_pered',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.walls.ispolzuyte_spetsialnyy_kley_dlya_2',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.walls.nachinayte_montazh_ot_tsentra',
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
