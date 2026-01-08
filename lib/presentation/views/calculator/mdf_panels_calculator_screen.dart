import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип МДФ панелей
enum MdfPanelType {
  standard('mdf_panels_calc.type.standard', 'mdf_panels_calc.type.standard_desc', Icons.view_module),
  laminated('mdf_panels_calc.type.laminated', 'mdf_panels_calc.type.laminated_desc', Icons.layers),
  veneer('mdf_panels_calc.type.veneer', 'mdf_panels_calc.type.veneer_desc', Icons.texture);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const MdfPanelType(this.nameKey, this.descKey, this.icon);
}

enum MdfPanelsInputMode { manual, wall }

class _MdfPanelsResult {
  final double area;
  final int panelsCount;
  final double profileLength;
  final int clipsCount;
  final double plinthLength;
  final int plinthPieces;

  const _MdfPanelsResult({
    required this.area,
    required this.panelsCount,
    required this.profileLength,
    required this.clipsCount,
    required this.plinthLength,
    required this.plinthPieces,
  });
}

class MdfPanelsCalculatorScreen extends StatefulWidget {
  const MdfPanelsCalculatorScreen({super.key});

  @override
  State<MdfPanelsCalculatorScreen> createState() => _MdfPanelsCalculatorScreenState();
}

class _MdfPanelsCalculatorScreenState extends State<MdfPanelsCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('mdf_panels_calc.title');
  double _area = 20.0;
  double _wallWidth = 4.0;
  double _wallHeight = 2.7;
  double _panelWidth = 0.25; // м

  MdfPanelType _panelType = MdfPanelType.laminated;
  MdfPanelsInputMode _inputMode = MdfPanelsInputMode.manual;
  bool _needProfile = true;
  bool _needPlinth = true;

  late _MdfPanelsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _MdfPanelsResult _calculate() {
    double area = _area;
    double wallWidth = _wallWidth;
    double wallHeight = _wallHeight;

    if (_inputMode == MdfPanelsInputMode.wall) {
      area = wallWidth * wallHeight;
    } else {
      final side = math.sqrt(area);
      wallWidth = side * 1.5;
      wallHeight = side / 1.5;
    }

    // Панели: площадь + 10% запас, делим на площадь одной панели
    final panelArea = _panelWidth * 2.7; // стандартная длина 2.7м
    final panelsCount = (area * 1.1 / panelArea).ceil();

    // Профиль для обрешётки: через каждые 0.5м + периметр
    double profileLength = 0;
    if (_needProfile) {
      final horizontalProfiles = (wallHeight / 0.5).ceil() + 1;
      profileLength = horizontalProfiles * wallWidth * 1.1;
    }

    // Кляймеры: 5 шт на панель
    final clipsCount = panelsCount * 5;

    // Плинтус
    double plinthLength = 0;
    int plinthPieces = 0;
    if (_needPlinth) {
      plinthLength = wallWidth * 2 + 2; // периметр примерно
      plinthPieces = (plinthLength / 2.7).ceil();
    }

    return _MdfPanelsResult(
      area: area,
      panelsCount: panelsCount,
      profileLength: profileLength,
      clipsCount: clipsCount,
      plinthLength: plinthLength,
      plinthPieces: plinthPieces,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('mdf_panels_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('mdf_panels_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('mdf_panels_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_panelType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('mdf_panels_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('mdf_panels_calc.export.panels')
        .replaceFirst('{value}', _result.panelsCount.toString()));
    if (_needProfile) {
      buffer.writeln(_loc.translate('mdf_panels_calc.export.profile')
          .replaceFirst('{value}', _result.profileLength.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('mdf_panels_calc.export.clips')
        .replaceFirst('{value}', _result.clipsCount.toString()));
    if (_needPlinth) {
      buffer.writeln(_loc.translate('mdf_panels_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('mdf_panels_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('mdf_panels_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('mdf_panels_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('mdf_panels_calc.result.panels').toUpperCase(),
            value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.view_module,
          ),
          ResultItem(
            label: _loc.translate('mdf_panels_calc.result.clips').toUpperCase(),
            value: '${_result.clipsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.push_pin,
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: MdfPanelType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _panelType.index,
      onSelect: (index) {
        setState(() {
          _panelType = MdfPanelType.values[index];
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
              _loc.translate('mdf_panels_calc.mode.manual'),
              _loc.translate('mdf_panels_calc.mode.wall'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = MdfPanelsInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == MdfPanelsInputMode.manual ? _buildManualInputs() : _buildWallInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('mdf_panels_calc.label.area'),
      value: _area,
      min: 5,
      max: 100,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildWallInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('mdf_panels_calc.label.width'), value: _wallWidth, onChanged: (v) { setState(() { _wallWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('mdf_panels_calc.label.height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 5)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('mdf_panels_calc.label.wall_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
        label: _loc.translate('mdf_panels_calc.label.panel_width'),
        value: _panelWidth * 1000,
        min: 100,
        max: 400,
        divisions: 6,
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
            title: Text(_loc.translate('mdf_panels_calc.option.profile'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('mdf_panels_calc.option.profile_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needProfile,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needProfile = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('mdf_panels_calc.option.plinth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('mdf_panels_calc.option.plinth_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPlinth,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needPlinth = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('mdf_panels_calc.materials.panels'),
        value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate(_panelType.nameKey),
        icon: Icons.view_module,
      ),
      MaterialItem(
        name: _loc.translate('mdf_panels_calc.materials.clips'),
        value: '${_result.clipsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('mdf_panels_calc.materials.clips_desc'),
        icon: Icons.push_pin,
      ),
    ];

    if (_needProfile && _result.profileLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('mdf_panels_calc.materials.profile'),
        value: '${_result.profileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('mdf_panels_calc.materials.profile_desc'),
        icon: Icons.straighten,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('mdf_panels_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.border_bottom,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('mdf_panels_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
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
