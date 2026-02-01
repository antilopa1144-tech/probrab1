import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_pvc_panels_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип ПВХ панелей
enum PvcPanelType {
  wall('pvc_panels_calc.type.wall', 'pvc_panels_calc.type.wall_desc', Icons.view_module),
  ceiling('pvc_panels_calc.type.ceiling', 'pvc_panels_calc.type.ceiling_desc', Icons.grid_view),
  bathroom('pvc_panels_calc.type.bathroom', 'pvc_panels_calc.type.bathroom_desc', Icons.bathroom);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const PvcPanelType(this.nameKey, this.descKey, this.icon);
}

enum PvcPanelsInputMode { manual, dimensions }

class _PvcPanelsResult {
  final double area;
  final int panelsCount;
  final double profileLength;
  final int cornerCount;
  final double plinthLength;
  final int plinthPieces;

  const _PvcPanelsResult({
    required this.area,
    required this.panelsCount,
    required this.profileLength,
    required this.cornerCount,
    required this.plinthLength,
    required this.plinthPieces,
  });

  factory _PvcPanelsResult.fromCalculatorResult(Map<String, double> values) {
    return _PvcPanelsResult(
      area: values['area'] ?? 0,
      panelsCount: (values['panelsCount'] ?? 0).toInt(),
      profileLength: values['profileLength'] ?? 0,
      cornerCount: (values['cornerCount'] ?? 0).toInt(),
      plinthLength: values['plinthLength'] ?? 0,
      plinthPieces: (values['plinthPieces'] ?? 0).toInt(),
    );
  }
}

class PvcPanelsCalculatorScreen extends ConsumerStatefulWidget {
  const PvcPanelsCalculatorScreen({super.key});

  @override
  ConsumerState<PvcPanelsCalculatorScreen> createState() => _PvcPanelsCalculatorScreenState();
}

class _PvcPanelsCalculatorScreenState extends ConsumerState<PvcPanelsCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('pvc_panels_calc.title');

  // Domain layer calculator
  final _calculator = CalculatePvcPanelsV2();

  double _area = 15.0;
  double _wallWidth = 3.0;
  double _wallHeight = 2.5;
  double _panelWidth = 0.25; // м

  PvcPanelType _panelType = PvcPanelType.wall;
  PvcPanelsInputMode _inputMode = PvcPanelsInputMode.manual;
  bool _needProfile = true;
  bool _needCorners = true;

  late _PvcPanelsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _PvcPanelsResult _calculate() {
    final inputs = <String, double>{
      'area': _area,
      'wallWidth': _wallWidth,
      'wallHeight': _wallHeight,
      'panelWidth': _panelWidth,
      'panelType': _panelType.index.toDouble(),
      'inputMode': _inputMode.index.toDouble(),
      'needProfile': _needProfile ? 1.0 : 0.0,
      'needCorners': _needCorners ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _PvcPanelsResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('pvc_panels_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('pvc_panels_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('pvc_panels_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_panelType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('pvc_panels_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('pvc_panels_calc.export.panels')
        .replaceFirst('{value}', _result.panelsCount.toString()));
    if (_needProfile) {
      buffer.writeln(_loc.translate('pvc_panels_calc.export.profile')
          .replaceFirst('{value}', _result.profileLength.toStringAsFixed(1)));
    }
    if (_needCorners) {
      buffer.writeln(_loc.translate('pvc_panels_calc.export.corners')
          .replaceFirst('{value}', _result.cornerCount.toString()));
    }
    if (_result.plinthPieces > 0) {
      buffer.writeln(_loc.translate('pvc_panels_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('pvc_panels_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('pvc_panels_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('pvc_panels_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('pvc_panels_calc.result.panels').toUpperCase(),
            value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.view_module,
          ),
          ResultItem(
            label: _loc.translate('pvc_panels_calc.result.profile').toUpperCase(),
            value: '${_result.profileLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.straighten,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildPanelWidthCard(),
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

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_panelType) {
      case PvcPanelType.wall:
        tips.addAll([
          _loc.translate('pvc_panels_calc.tip.wall_1'),
          _loc.translate('pvc_panels_calc.tip.wall_2'),
        ]);
        break;
      case PvcPanelType.ceiling:
        tips.addAll([
          _loc.translate('pvc_panels_calc.tip.ceiling_1'),
          _loc.translate('pvc_panels_calc.tip.ceiling_2'),
        ]);
        break;
      case PvcPanelType.bathroom:
        tips.addAll([
          _loc.translate('pvc_panels_calc.tip.bathroom_1'),
          _loc.translate('pvc_panels_calc.tip.bathroom_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('pvc_panels_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: PvcPanelType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _panelType.index,
      onSelect: (index) {
        setState(() {
          _panelType = PvcPanelType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('pvc_panels_calc.mode.manual'),
              _loc.translate('pvc_panels_calc.mode.dimensions'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = PvcPanelsInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == PvcPanelsInputMode.manual ? _buildManualInputs() : _buildDimensionInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('pvc_panels_calc.label.area'),
      value: _area,
      min: 2,
      max: 100,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildDimensionInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('pvc_panels_calc.label.width'), value: _wallWidth, onChanged: (v) { setState(() { _wallWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.5, maxValue: 15)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('pvc_panels_calc.label.height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.5, maxValue: 5)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('pvc_panels_calc.label.total_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanelWidthCard() {
    return _card(
      child: CalculatorSliderField(
        label: _loc.translate('pvc_panels_calc.label.panel_width'),
        value: _panelWidth * 1000,
        min: 100,
        max: 500,
        divisions: 8,
        suffix: _loc.translate('common.mm'),
        accentColor: _accentColor,
        onChanged: (v) { setState(() { _panelWidth = v / 1000; _update(); }); },
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('pvc_panels_calc.option.profile'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('pvc_panels_calc.option.profile_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needProfile,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needProfile = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('pvc_panels_calc.option.corners'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('pvc_panels_calc.option.corners_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needCorners,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needCorners = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('pvc_panels_calc.materials.panels'),
        value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate(_panelType.nameKey),
        icon: Icons.view_module,
      ),
    ];

    if (_needProfile && _result.profileLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('pvc_panels_calc.materials.profile'),
        value: '${_result.profileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('pvc_panels_calc.materials.profile_desc'),
        icon: Icons.straighten,
      ));
    }

    if (_needCorners && _result.cornerCount > 0) {
      items.add(MaterialItem(
        name: _loc.translate('pvc_panels_calc.materials.corners'),
        value: '${_result.cornerCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('pvc_panels_calc.materials.corners_desc'),
        icon: Icons.rounded_corner,
      ));
    }

    if (_result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('pvc_panels_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.border_top,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('pvc_panels_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
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
